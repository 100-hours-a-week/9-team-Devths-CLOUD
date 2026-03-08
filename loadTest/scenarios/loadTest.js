/**
 * 통합 부하 테스트 — 회원가입 + 커뮤니티 활동 + AI 채팅 + 유저 간 채팅(WebSocket)
 * 목적: 회원가입 트래픽과 게시글/댓글/AI채팅/유저간채팅 트래픽을 한 번의 실행으로 검증
 *
 * 동작 순서:
 *   1) setup에서 최소 회원가입 요청으로 기본 유저 풀 준비
 *   2) 발급된 토큰을 /api/users/me로 검증해 사용 가능한 토큰만 선별
 *   3) 선별된 토큰 풀 + 런타임 회원가입 트래픽을 함께 실행
 */

import { group, sleep } from 'k6';
import encoding from 'k6/encoding';
import exec from 'k6/execution';
import { thresholds } from '../lib/config.js';
import { summarize, randomSleep } from '../lib/helpers.js';
import { getToken, registerWithGoogle } from '../api/auth.js';
import {
  getPosts,
  getPost,
  getComments,
  likePost,
  createPost,
  updatePost,
  createComment,
  deleteComment,
  deletePost,
} from '../api/post.js';
import { getMe, getUnreadCount } from '../api/user.js';
import { attachImageForPost } from '../api/file.js';
import { createChatRoom, sendChatMessage, getChatHistory, deleteChatRoom } from '../api/ai.js';
import { createPrivateChatRoom, leaveChatRoom } from '../api/chat.js';
import { connectWebSocketChat } from '../api/websocket.js';

// TPS 설정 (GitHub Actions에서 주입 가능)
const TPS_START = parseInt(__ENV.K6_TPS_START || '10', 10);
const TPS_TARGET = parseInt(__ENV.K6_TPS_TARGET || '200', 10);
const DURATION_MINUTES = parseInt(__ENV.K6_DURATION_MINUTES || '7', 10);

// 회원가입 설정
const INITIAL_REGISTER_USER_COUNT = parseInt(
  __ENV.K6_INITIAL_REGISTER_USER_COUNT || __ENV.K6_REGISTER_USER_COUNT || '10',
  10
);
const REGISTER_PROGRESS_LOG_STEP = parseInt(__ENV.K6_REGISTER_PROGRESS_LOG_STEP || '10', 10);
const SEED_POST_COUNT = parseInt(__ENV.K6_SEED_POST_COUNT || '3', 10);
const ENABLE_REGISTER_FLOW = (__ENV.K6_ENABLE_REGISTER_FLOW || 'true').toLowerCase() === 'true';
const REGISTER_FLOW_RATE = parseNonNegativeFloat(__ENV.K6_REGISTER_FLOW_RATE, 0.2, 'K6_REGISTER_FLOW_RATE');

// 게시글/AI 워크플로우 세부 설정
const ENABLE_POST_CREATE = (__ENV.K6_ENABLE_POST_CREATE || 'true').toLowerCase() === 'true';
const POST_CREATE_RATE = Number.parseFloat(__ENV.K6_POST_CREATE_RATE || '0.35');
const ENABLE_POST_UPDATE = (__ENV.K6_ENABLE_POST_UPDATE || 'true').toLowerCase() === 'true';
const POST_UPDATE_RATE = parseNonNegativeFloat(__ENV.K6_POST_UPDATE_RATE, 0.2, 'K6_POST_UPDATE_RATE');
const POST_IMAGE_ATTACH_RATE = Number.parseFloat(__ENV.K6_POST_IMAGE_ATTACH_RATE || '0.4');
const KEEP_CREATED_POST = (__ENV.K6_KEEP_CREATED_POST || 'false').toLowerCase() === 'true';

const ENABLE_AI_CHAT = (__ENV.K6_ENABLE_AI_CHAT || 'false').toLowerCase() === 'true';
const AI_CHAT_RATE = Number.parseFloat(__ENV.K6_AI_CHAT_RATE || '0.15');
const AI_MODEL = (__ENV.K6_AI_MODEL || 'GEMINI').toUpperCase();
const KEEP_AI_CHATROOM = (__ENV.K6_KEEP_AI_CHATROOM || 'false').toLowerCase() === 'true';

// 유저 간 WebSocket 채팅 설정
const ENABLE_WS_CHAT = (__ENV.K6_ENABLE_WS_CHAT || 'false').toLowerCase() === 'true';
const WS_CHAT_RATE = parseNonNegativeFloat(__ENV.K6_WS_CHAT_RATE, 0.15, 'K6_WS_CHAT_RATE');
const WS_DURATION = parsePositiveInt(__ENV.K6_WS_DURATION, 8, 'K6_WS_DURATION');
const WS_MESSAGE_COUNT = parsePositiveInt(__ENV.K6_WS_MESSAGE_COUNT, 3, 'K6_WS_MESSAGE_COUNT');
const WS_MESSAGE_INTERVAL = parsePositiveInt(__ENV.K6_WS_MESSAGE_INTERVAL, 2, 'K6_WS_MESSAGE_INTERVAL');
const KEEP_WS_CHATROOM = ((__ENV.K6_KEEP_WS_CHATROOM || __ENV.K6_WS_KEEP_ROOM || 'false').toLowerCase() === 'true');
const WS_USER_POOL_SIZE = parsePositiveInt(__ENV.K6_WS_USER_POOL_SIZE, 10, 'K6_WS_USER_POOL_SIZE');

// Redis 캐시 검증용 핫 게시글 조회 설정
const ENABLE_HOT_POST_READ = (__ENV.K6_ENABLE_HOT_POST_READ || 'false').toLowerCase() === 'true';
const HOT_POST_ID = parseOptionalPositiveInt(__ENV.K6_HOT_POST_ID, null, 'K6_HOT_POST_ID');
const HOT_POST_READ_REPEAT = parsePositiveInt(__ENV.K6_HOT_POST_READ_REPEAT, 3, 'K6_HOT_POST_READ_REPEAT');
const HOT_POST_STICKY_USER = (__ENV.K6_HOT_POST_STICKY_USER || 'true').toLowerCase() === 'true';
const configuredHotPostReadRatio = parseNonNegativeFloat(
  __ENV.K6_HOT_POST_READ_RATIO,
  1,
  'K6_HOT_POST_READ_RATIO'
);
const fallbackColdPostReadRatio =
  __ENV.K6_COLD_POST_READ_RATIO === undefined || __ENV.K6_COLD_POST_READ_RATIO === ''
    ? Math.max(0, 1 - configuredHotPostReadRatio)
    : 0;
const configuredColdPostReadRatio = parseNonNegativeFloat(
  __ENV.K6_COLD_POST_READ_RATIO,
  fallbackColdPostReadRatio,
  'K6_COLD_POST_READ_RATIO'
);

const hotReadRatioSum = configuredHotPostReadRatio + configuredColdPostReadRatio;
const HOT_POST_READ_RATIO = hotReadRatioSum > 0 ? configuredHotPostReadRatio / hotReadRatioSum : 1;
const COLD_POST_READ_RATIO = hotReadRatioSum > 0 ? configuredColdPostReadRatio / hotReadRatioSum : 0;

if (hotReadRatioSum <= 0) {
  console.warn(
    '[loadTest] K6_HOT_POST_READ_RATIO + K6_COLD_POST_READ_RATIO 합이 0 이하라 기본값(HOT 1.0 / COLD 0.0)을 사용합니다.'
  );
}

// 트래픽 제어 설정
const REQUESTS_PER_ITERATION = parsePositiveInt(
  __ENV.K6_REQUESTS_PER_ITERATION,
  5,
  'K6_REQUESTS_PER_ITERATION'
);

const configuredGetRatio = parseNonNegativeFloat(__ENV.K6_GET_RATIO, 0.7, 'K6_GET_RATIO');
const fallbackPostRatio =
  __ENV.K6_POST_RATIO === undefined || __ENV.K6_POST_RATIO === ''
    ? Math.max(0, 1 - configuredGetRatio)
    : 0.3;
const configuredPostRatio = parseNonNegativeFloat(__ENV.K6_POST_RATIO, fallbackPostRatio, 'K6_POST_RATIO');

const ratioSum = configuredGetRatio + configuredPostRatio;
const GET_RATIO = ratioSum > 0 ? configuredGetRatio / ratioSum : 0.7;
const POST_RATIO = ratioSum > 0 ? configuredPostRatio / ratioSum : 0.3;

if (ratioSum <= 0) {
  console.warn('[loadTest] K6_GET_RATIO + K6_POST_RATIO 합이 0 이하라 기본값(GET 0.7 / POST 0.3)을 사용합니다.');
}

const GET_API_CATALOG = {
  notifications_unread: {
    weight: 1,
    run: ({ token }) => {
      group('api GET /api/notifications/unread', () => {
        getUnreadCount(token);
      });
    },
  },
  posts_list: {
    weight: 1,
    run: ({ token, postIds, rand }) => {
      group('api GET /api/posts', () => {
        const cursorId = rand() > 0.5 ? pickRandom(postIds, rand) : null;
        getPosts(token, { size: 10, lastId: cursorId });
      });
    },
  },
  post_detail: {
    weight: 1,
    run: ({ token, postIds, coldPostIds, rand, hotPostId }) => {
      const hotReadEnabled = ENABLE_HOT_POST_READ && hotPostId;
      const hasColdCandidates = Array.isArray(coldPostIds) && coldPostIds.length > 0;
      const useHotPost = hotReadEnabled && (!hasColdCandidates || rand() < HOT_POST_READ_RATIO);
      const postId = useHotPost
        ? hotPostId
        : pickRandom(hotReadEnabled ? coldPostIds : postIds, rand);

      if (!postId) {
        return;
      }

      const repeat = useHotPost ? HOT_POST_READ_REPEAT : 1;
      const groupLabel = repeat > 1
        ? 'api GET /api/posts/{postId} hot-cache'
        : 'api GET /api/posts/{postId}';

      group(groupLabel, () => {
        for (let i = 0; i < repeat; i += 1) {
          getPost(token, postId);
          if (i < repeat - 1) {
            sleep(0.03);
          }
        }
      });
    },
  },
  comments_list: {
    weight: 1,
    run: ({ token, postIds, rand }) => {
      const postId = pickRandom(postIds, rand);
      if (!postId) {
        return;
      }
      group('api GET /api/posts/{postId}/comments', () => {
        getComments(token, postId, { size: 10 });
      });
    },
  },
  users_me: {
    weight: 0.35,
    run: ({ token }) => {
      group('api GET /api/users/me', () => {
        getMe(token);
      });
    },
  },
};

const POST_API_CATALOG = {
  ...(ENABLE_REGISTER_FLOW
    ? {
      register_flow: {
        weight: Math.max(0, REGISTER_FLOW_RATE),
        run: ({ rand, postIds }) => {
          group('api POST /api/auth/google register flow', () => {
            const authCode = `k6_register_flow_${exec.vu.idInTest}_${exec.scenario.iterationInTest}_${Date.now()}_${Math.floor(rand() * 1000000)}`;
            const newToken = registerWithGoogle(authCode);
            if (!isUsableAccessToken(newToken)) {
              return;
            }

            // 회원가입 직후 기본 조회 트래픽을 붙여서 실사용 패턴에 가깝게 만든다.
            getMe(newToken);
            const postId = pickRandom(postIds, rand);
            if (postId) {
              getPost(newToken, postId);
              if (rand() < 0.3) {
                getComments(newToken, postId, { size: 5 });
              }
            }
          });
        },
      },
    }
    : {}),
  posts_like: {
    weight: 0.25,
    run: ({ token, postIds, rand }) => {
      const postId = pickRandom(postIds, rand);
      if (!postId) {
        return;
      }
      group('api POST /api/posts/{postId}/likes', () => {
        likePost(token, postId);
      });
    },
  },
  comments_create: {
    weight: 0.2,
    run: ({ token, postIds, rand }) => {
      const postId = pickRandom(postIds, rand);
      if (!postId) {
        return;
      }
      group('api POST /api/posts/{postId}/comments', () => {
        const commentId = createComment(token, postId, `k6 통합 댓글 ${Date.now()}`);
        if (commentId) {
          sleep(0.1);
          deleteComment(token, postId, commentId);
        }
      });
    },
  },
  ...(ENABLE_POST_CREATE
    ? {
      posts_create: {
        weight: Math.max(0, POST_CREATE_RATE),
        run: ({ token, rand }) => {
          group('api POST /api/posts', () => {
            let fileIds = [];
            if (rand() < POST_IMAGE_ATTACH_RATE) {
              const fileId = attachImageForPost(token);
              if (fileId) {
                fileIds = [fileId];
              }
            }

            const postId = createPost(token, {
              title: `k6 통합 게시글 ${Date.now()}`,
              content: '게시글/댓글 부하 테스트 데이터',
              tags: [],
              fileIds,
            });

            if (!postId) {
              return;
            }

            if (rand() < 0.5) {
              const commentId = createComment(token, postId, `k6 자기 게시글 댓글 ${Date.now()}`);
              if (commentId) {
                deleteComment(token, postId, commentId);
              }
            }

            if (!KEEP_CREATED_POST) {
              deletePost(token, postId);
              return;
            }

          });
        },
      },
    }
    : {}),
  ...(ENABLE_POST_UPDATE
    ? {
      posts_update: {
        weight: Math.max(0, POST_UPDATE_RATE),
        run: ({ token }) => {
          group('api PUT /api/posts/{postId}', () => {
            const postId = createPost(token, {
              title: `k6 수정 대상 게시글 ${Date.now()}`,
              content: '게시글 수정 부하 테스트 원본 데이터',
              tags: [],
              fileIds: [],
            });

            if (!postId) {
              return;
            }

            sleep(0.1);

            updatePost(token, postId, {
              title: `k6 수정 완료 게시글 ${Date.now()}`,
              content: '게시글 수정 부하 테스트 업데이트 데이터',
              tags: [],
              fileIds: [],
            });

            if (!KEEP_CREATED_POST) {
              sleep(0.1);
              deletePost(token, postId);
            }
          });
        },
      },
    }
    : {}),
  ...(ENABLE_AI_CHAT
    ? {
      ai_chat_workflow: {
        weight: Math.max(0, AI_CHAT_RATE),
        run: ({ token, rand }) => {
          group('api POST /api/ai-chatrooms workflow', () => {
            const room = createChatRoom(token);
            if (!room || !room.roomId) {
              return;
            }

            sleep(0.1);
            sendChatMessage(token, room.roomId, `k6 ai message ${Date.now()}`, AI_MODEL);

            if (rand() < 0.6) {
              sleep(0.1);
              getChatHistory(token, room.roomId, { size: 10 });
            }

            if (!KEEP_AI_CHATROOM) {
              sleep(0.1);
              deleteChatRoom(token, room.roomId);
            }
          });
        },
      },
    }
    : {}),
  ...(ENABLE_WS_CHAT
    ? {
      ws_chat_workflow: {
        weight: Math.max(0, WS_CHAT_RATE),
        run: ({ wsUsers, wsChatEnabled, rand }) => {
          if (!wsChatEnabled || !Array.isArray(wsUsers) || wsUsers.length < 2) {
            return;
          }

          group('api POST /api/chatrooms/private + websocket', () => {
            const senderIndex = Math.floor(rand() * wsUsers.length);
            let receiverIndex = Math.floor(rand() * (wsUsers.length - 1));
            if (receiverIndex >= senderIndex) {
              receiverIndex += 1;
            }

            const sender = wsUsers[senderIndex];
            const receiver = wsUsers[receiverIndex];
            if (!sender || !receiver || sender.userId === receiver.userId) {
              return;
            }

            const room = createPrivateChatRoom(sender.token, receiver.userId);
            if (!room || !room.roomId) {
              return;
            }

            sleep(0.2);

            connectWebSocketChat(sender.token, room.roomId, {
              duration: WS_DURATION,
              messageCount: WS_MESSAGE_COUNT,
              messageInterval: WS_MESSAGE_INTERVAL,
            });

            // 기존 1:1 채팅방은 여러 VU가 재사용할 수 있어 신규 생성된 방만 정리한다.
            if (!KEEP_WS_CHATROOM && room.isNew) {
              sleep(0.1);
              leaveChatRoom(sender.token, room.roomId);
            }
          });
        },
      },
    }
    : {}),
};

const enabledGetApis = buildEnabledApiEntries(GET_API_CATALOG, __ENV.K6_GET_API_LIST, 'GET');
const enabledPostApis = buildEnabledApiEntries(POST_API_CATALOG, __ENV.K6_POST_API_LIST, 'POST');

if (ENABLE_HOT_POST_READ && !enabledGetApis.some((entry) => entry.name === 'post_detail')) {
  console.warn('[loadTest] K6_ENABLE_HOT_POST_READ=true 이지만 GET API 목록에 post_detail이 없어 캐시 검증 요청이 실행되지 않습니다.');
}

if (enabledGetApis.length === 0 && enabledPostApis.length === 0) {
  throw new Error(
    '[loadTest] 실행 가능한 API가 없습니다. K6_GET_API_LIST / K6_POST_API_LIST 또는 관련 enable 옵션을 확인하세요.'
  );
}

// TPS 단계 동적 계산
const warmupTPS = Math.ceil(TPS_TARGET * 0.25); // 목표 TPS의 25%로 워밍업
const warmupDuration = Math.max(1, Math.ceil(DURATION_MINUTES * 0.15)); // 전체 시간의 15%
const rampDuration = Math.max(1, Math.ceil(DURATION_MINUTES * 0.25)); // 전체 시간의 25%
const steadyDuration = Math.max(1, DURATION_MINUTES - warmupDuration - rampDuration - 1); // 나머지 시간
const cooldownDuration = 1; // 1분 고정

export const options = {
  setupTimeout: '300s', // 5분으로 연장
  scenarios: {
    register_then_load: {
      executor: 'ramping-arrival-rate',
      startRate: TPS_START,        // 시작 TPS (환경 변수로 주입)
      timeUnit: '1s',              // rate의 시간 단위
      preAllocatedVUs: Math.ceil(TPS_TARGET * 0.5),  // 목표 TPS의 50%만큼 미리 할당
      maxVUs: Math.ceil(TPS_TARGET * 1.5),           // 목표 TPS의 150%까지 확장 가능
      stages: [
        { duration: `${warmupDuration}m`, target: warmupTPS },   // 워밍업
        { duration: `${rampDuration}m`, target: TPS_TARGET },    // 증가
        { duration: `${steadyDuration}m`, target: TPS_TARGET },  // 유지
        { duration: `${cooldownDuration}m`, target: 0 },         // 종료
      ],
    },
  },
  thresholds: {
    ...thresholds,
    custom_error_rate: ['rate<0.05'],
    custom_api_latency: ['p(95)<1500'],
  },
};

function parsePositiveInt(value, fallback, envName) {
  if (value === undefined || value === null || value === '') {
    return fallback;
  }

  const parsed = Number.parseInt(value, 10);
  if (Number.isNaN(parsed) || parsed <= 0) {
    console.warn(`[loadTest] ${envName} 값이 유효하지 않아 기본값(${fallback})을 사용합니다.`);
    return fallback;
  }

  return parsed;
}

function parseNonNegativeFloat(value, fallback, envName) {
  if (value === undefined || value === null || value === '') {
    return fallback;
  }

  const parsed = Number.parseFloat(value);
  if (Number.isNaN(parsed) || parsed < 0) {
    console.warn(`[loadTest] ${envName} 값이 유효하지 않아 기본값(${fallback})을 사용합니다.`);
    return fallback;
  }

  return parsed;
}

function parseOptionalPositiveInt(value, fallback, envName) {
  if (value === undefined || value === null || value === '') {
    return fallback;
  }

  const parsed = Number.parseInt(value, 10);
  if (Number.isNaN(parsed) || parsed <= 0) {
    console.warn(`[loadTest] ${envName} 값이 유효하지 않아 기본값(${fallback})을 사용합니다.`);
    return fallback;
  }

  return parsed;
}

function parseApiList(rawValue, defaultList) {
  if (rawValue === undefined || rawValue === null || rawValue.trim() === '') {
    return { names: [...defaultList], explicitNone: false };
  }

  const normalized = rawValue.trim().toLowerCase();
  if (normalized === 'all') {
    return { names: [...defaultList], explicitNone: false };
  }

  if (normalized === 'none') {
    return { names: [], explicitNone: true };
  }

  const names = rawValue
    .split(',')
    .map((name) => name.trim().toLowerCase())
    .filter((name) => name.length > 0);

  return { names: [...new Set(names)], explicitNone: false };
}

function buildEnabledApiEntries(catalog, rawValue, methodLabel) {
  const defaultNames = Object.keys(catalog);
  const { names: requestedNames, explicitNone } = parseApiList(rawValue, defaultNames);

  if (explicitNone) {
    return [];
  }

  const validNames = [];
  const invalidNames = [];

  for (const name of requestedNames) {
    if (catalog[name]) {
      validNames.push(name);
    } else {
      invalidNames.push(name);
    }
  }

  if (invalidNames.length > 0) {
    console.warn(
      `[loadTest] 알 수 없는 ${methodLabel} API 키를 제외합니다: ${invalidNames.join(', ')}`
    );
  }

  const baseNames = validNames.length > 0 ? validNames : defaultNames;

  if (validNames.length === 0 && requestedNames.length > 0) {
    console.warn(
      `[loadTest] 유효한 ${methodLabel} API가 없어 기본 API 목록을 사용합니다: ${defaultNames.join(', ')}`
    );
  }

  const entries = baseNames
    .map((name) => ({
      name,
      weight: catalog[name].weight,
      run: catalog[name].run,
    }))
    .filter((entry) => typeof entry.run === 'function' && entry.weight > 0);

  if (entries.length === 0 && baseNames.length > 0) {
    console.warn(
      `[loadTest] ${methodLabel} API의 weight가 모두 0 이하라 호출 대상에서 제외됩니다.`
    );
  }

  return entries;
}

function pickRandom(list, rand) {
  if (!Array.isArray(list) || list.length === 0) {
    return null;
  }
  return list[Math.floor(rand() * list.length)];
}

function pickWeighted(entries, rand) {
  if (!Array.isArray(entries) || entries.length === 0) {
    return null;
  }

  let total = 0;
  for (const entry of entries) {
    total += entry.weight;
  }

  if (total <= 0) {
    return null;
  }

  let pivot = rand() * total;
  for (const entry of entries) {
    pivot -= entry.weight;
    if (pivot <= 0) {
      return entry;
    }
  }

  return entries[entries.length - 1];
}

function pickMethod(rand) {
  const hasGet = enabledGetApis.length > 0;
  const hasPost = enabledPostApis.length > 0;

  if (hasGet && hasPost) {
    return rand() < GET_RATIO ? 'GET' : 'POST';
  }

  return hasGet ? 'GET' : 'POST';
}

function executeByMethod(method, context) {
  const entries = method === 'GET' ? enabledGetApis : enabledPostApis;
  const selected = pickWeighted(entries, context.rand);
  if (!selected) {
    return false;
  }

  selected.run(context);
  return true;
}

function extractUserIdFromToken(token) {
  if (!token || typeof token !== 'string') {
    return null;
  }

  try {
    const payload = token.split('.')[1];
    if (!payload) {
      return null;
    }

    const decoded = encoding.b64decode(payload, 'rawurl', 's');
    const parsed = JSON.parse(decoded);
    const candidate = parsed?.userId ?? parsed?.sub;
    const asNumber = Number(candidate);
    return Number.isFinite(asNumber) ? asNumber : null;
  } catch (_) {
    return null;
  }
}

function loadUserIdByMe(token) {
  const res = getMe(token);
  if (!res || res.status < 200 || res.status >= 300) {
    return null;
  }

  try {
    const parsed = JSON.parse(res.body);
    const candidate = parsed?.data?.userId ?? parsed?.data?.id ?? null;
    const asNumber = Number(candidate);
    return Number.isFinite(asNumber) ? asNumber : null;
  } catch (_) {
    return null;
  }
}

function getDistinctWsUsers(tokenPool) {
  const seen = {};
  const users = [];

  for (const token of tokenPool) {
    const decodedUserId = extractUserIdFromToken(token);
    const userId = decodedUserId == null ? loadUserIdByMe(token) : decodedUserId;
    if (userId == null || seen[userId]) {
      continue;
    }
    seen[userId] = true;
    users.push({ token, userId });
  }

  return users;
}

function isUsableAccessToken(token) {
  if (!token) {
    return false;
  }
  const me = getMe(token);
  return me.status >= 200 && me.status < 300;
}

function loadPostIds(token) {
  const result = getPosts(token, { size: 100 });
  return (result.posts || []).map((p) => p.postId).filter((id) => id != null);
}

function formatApiConfig(entries) {
  if (!entries || entries.length === 0) {
    return 'none';
  }
  return entries.map((entry) => `${entry.name}:${entry.weight}`).join(', ');
}

export function setup() {
  console.log('🔧 [loadTest] setup 시작: 회원가입 + 토큰 검증 + 채팅 유저 풀 구성');
  console.log(
    `[loadTest] env 적용값 tpsStart=${TPS_START}, tpsTarget=${TPS_TARGET}, duration=${DURATION_MINUTES}m, requests=${REQUESTS_PER_ITERATION}, getRatio=${GET_RATIO.toFixed(2)}, postRatio=${POST_RATIO.toFixed(2)}`
  );
  console.log(
    `[loadTest] env 적용값 aiChat=${ENABLE_AI_CHAT}/${AI_CHAT_RATE}, wsChat=${ENABLE_WS_CHAT}/${WS_CHAT_RATE}, wsPool=${WS_USER_POOL_SIZE}, wsMsg=${WS_MESSAGE_COUNT}@${WS_MESSAGE_INTERVAL}s`
  );
  console.log(
    `[loadTest] env 적용값 postCreate=${ENABLE_POST_CREATE}/${POST_CREATE_RATE}, postUpdate=${ENABLE_POST_UPDATE}/${POST_UPDATE_RATE}`
  );
  console.log(
    `[loadTest] env 적용값 initialRegister=${INITIAL_REGISTER_USER_COUNT}, registerFlow=${ENABLE_REGISTER_FLOW}/${REGISTER_FLOW_RATE}`
  );
  console.log(
    `[loadTest] env 적용값 hotPostRead=${ENABLE_HOT_POST_READ}, hotPostId=${HOT_POST_ID ?? 'auto'}, hotRepeat=${HOT_POST_READ_REPEAT}, hotStickyUser=${HOT_POST_STICKY_USER}, hotReadRatio=${HOT_POST_READ_RATIO.toFixed(2)}, coldReadRatio=${COLD_POST_READ_RATIO.toFixed(2)}`
  );

  const tokenPool = [];
  let registeredSuccess = 0;
  let registeredFailure = 0;
  const registerTargetCount = ENABLE_WS_CHAT
    ? Math.max(INITIAL_REGISTER_USER_COUNT, WS_USER_POOL_SIZE)
    : INITIAL_REGISTER_USER_COUNT;

  for (let i = 0; i < registerTargetCount; i += 1) {
    const authCode = `k6_integrated_auth_code_${i}_${Date.now()}`;
    const token = registerWithGoogle(authCode);

    if (isUsableAccessToken(token)) {
      tokenPool.push(token);
      registeredSuccess += 1;
    } else {
      registeredFailure += 1;
    }

    if ((i + 1) % REGISTER_PROGRESS_LOG_STEP === 0 || i === registerTargetCount - 1) {
      console.log(
        `[loadTest] register 진행 ${i + 1}/${registerTargetCount} (usable=${registeredSuccess}, failed=${registeredFailure})`
      );
    }
  }

  const fallbackToken = getToken();
  if (isUsableAccessToken(fallbackToken)) {
    tokenPool.push(fallbackToken);
    console.log('[loadTest] K6_AUTH_TOKEN을 토큰 풀에 추가했습니다.');
  }

  const dedupedTokenPool = [...new Set(tokenPool)];
  if (dedupedTokenPool.length === 0) {
    throw new Error(
      '사용 가능한 토큰이 없습니다. 기존 가입 유저 토큰(K6_AUTH_TOKEN)을 넣거나 회원가입 플로우를 점검하세요.'
    );
  }

  const wsUsers = getDistinctWsUsers(dedupedTokenPool);
  const wsChatEnabled = ENABLE_WS_CHAT && wsUsers.length >= 2;
  if (ENABLE_WS_CHAT && !wsChatEnabled) {
    console.warn(
      `[loadTest] ws_chat_workflow 비활성화: userId가 있는 유저가 부족합니다 (wsUsers=${wsUsers.length})`
    );
  }

  let postIds = loadPostIds(dedupedTokenPool[0]);
  if (postIds.length === 0) {
    console.warn('[loadTest] 기존 게시글이 없어 seed 게시글을 생성합니다.');
    for (let i = 0; i < SEED_POST_COUNT; i += 1) {
      createPost(dedupedTokenPool[0], {
        title: `k6 seed post ${Date.now()}-${i}`,
        content: '통합 부하 테스트용 seed 게시글',
        tags: [],
        fileIds: [],
      });
      sleep(0.1);
    }
    postIds = loadPostIds(dedupedTokenPool[0]);
  }

  if (postIds.length === 0) {
    throw new Error('게시글이 없어 테스트를 진행할 수 없습니다. 게시글 생성 권한/데이터를 확인하세요.');
  }

  const hotPostId = ENABLE_HOT_POST_READ
    ? (HOT_POST_ID || postIds[0])
    : null;
  if (ENABLE_HOT_POST_READ) {
    if (HOT_POST_ID && !postIds.includes(HOT_POST_ID)) {
      console.warn(`[loadTest] K6_HOT_POST_ID=${HOT_POST_ID} 가 최근 postId 목록에 없어 캐시 적중률이 낮을 수 있습니다.`);
    }
    const mode = HOT_POST_ID ? 'explicit' : 'auto';
    console.log(
      `[loadTest] hot 게시글 조회 활성화: postId=${hotPostId} (${mode}), repeat=${HOT_POST_READ_REPEAT}, hotReadRatio=${HOT_POST_READ_RATIO.toFixed(2)}, coldReadRatio=${COLD_POST_READ_RATIO.toFixed(2)}`
    );
  }

  const coldPostIds = hotPostId
    ? postIds.filter((postId) => postId !== hotPostId)
    : [...postIds];
  if (ENABLE_HOT_POST_READ && COLD_POST_READ_RATIO > 0 && coldPostIds.length === 0) {
    console.warn(
      '[loadTest] cold(post cache-miss) 대상 게시글이 없어 hot 게시글만 조회됩니다. K6_HOT_POST_ID 또는 seed 게시글 수를 확인하세요.'
    );
  }

  console.log(
    `[loadTest] traffic 설정 requests=${REQUESTS_PER_ITERATION}, getRatio=${GET_RATIO.toFixed(2)}, postRatio=${POST_RATIO.toFixed(2)}`
  );
  if (ENABLE_WS_CHAT) {
    console.log(
      `[loadTest] ws chat 설정 enabled=${wsChatEnabled}, users=${wsUsers.length}, duration=${WS_DURATION}s, messages=${WS_MESSAGE_COUNT}`
    );
  }
  console.log(`[loadTest] enabled GET APIs: ${formatApiConfig(enabledGetApis)}`);
  console.log(`[loadTest] enabled POST APIs: ${formatApiConfig(enabledPostApis)}`);

  console.log(
    `[loadTest] setup 완료 (usableTokens=${dedupedTokenPool.length}, postIds=${postIds.length})`
  );

  return { tokenPool: dedupedTokenPool, postIds, coldPostIds, wsUsers, wsChatEnabled, hotPostId };
}

export default function (data) {
  const { tokenPool, postIds, coldPostIds, wsUsers, wsChatEnabled, hotPostId } = data;
  const rand = Math.random;

  const stickyUserIndex = (exec.vu.idInTest - 1 + tokenPool.length) % tokenPool.length;
  const rotatingUserIndex = (exec.vu.idInTest + exec.scenario.iterationInTest) % tokenPool.length;
  const userIndex = ENABLE_HOT_POST_READ && HOT_POST_STICKY_USER
    ? stickyUserIndex
    : rotatingUserIndex;
  const token = tokenPool[userIndex];

  const context = { token, postIds, coldPostIds, wsUsers, wsChatEnabled, hotPostId, rand };

  for (let i = 0; i < REQUESTS_PER_ITERATION; i += 1) {
    const primaryMethod = pickMethod(rand);
    const fallbackMethod = primaryMethod === 'GET' ? 'POST' : 'GET';

    const executed = executeByMethod(primaryMethod, context) || executeByMethod(fallbackMethod, context);
    if (!executed) {
      break;
    }

    if (i < REQUESTS_PER_ITERATION - 1) {
      sleep(0.1);
    }
  }

  randomSleep(0.8, 2);
}

export function handleSummary(data) {
  return summarize(data, 'loadTest');
}
