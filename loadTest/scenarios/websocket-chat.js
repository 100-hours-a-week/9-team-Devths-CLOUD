/**
 * WebSocket 채팅 부하 테스트
 *
 * 목적: 실시간 채팅 시스템의 WebSocket 연결 및 메시지 처리 성능 테스트
 *
 * 테스트 시나리오:
 *   1. 동시 접속자 증가 (램핑)
 *   2. 각 사용자가 채팅방 생성 및 WebSocket 연결
 *   3. 주기적으로 메시지 송수신
 *   4. 연결 안정성 및 메시지 지연시간 측정
 *
 * 메트릭:
 *   - ws_connection_time: WebSocket 연결 시간
 *   - ws_message_send_time: 메시지 전송 시간
 *   - ws_message_receive_time: 메시지 수신 시간
 *   - ws_active_connections: 활성 연결 수
 *   - ws_error_rate: 에러 발생률
 */

import { sleep } from 'k6';
import encoding from 'k6/encoding';
import exec from 'k6/execution';
import { getToken, registerWithGoogle } from '../api/auth.js';
import { createPrivateChatRoom, leaveChatRoom } from '../api/chat.js';
import { connectWebSocketChat } from '../api/websocket.js';
import { summarize } from '../lib/helpers.js';

// 환경 변수
const WS_DURATION = parseInt(__ENV.K6_WS_DURATION || '60', 10); // WebSocket 연결 유지 시간 (초)
const WS_MESSAGE_COUNT = parseInt(__ENV.K6_WS_MESSAGE_COUNT || '10', 10); // 전송 메시지 수
const WS_MESSAGE_INTERVAL = parseInt(__ENV.K6_WS_MESSAGE_INTERVAL || '3', 10); // 메시지 간격 (초)
const WS_KEEP_ROOM = (__ENV.K6_WS_KEEP_ROOM || 'false').toLowerCase() === 'true';
const WS_REGISTER_USER_COUNT = parseInt(__ENV.K6_WS_REGISTER_USER_COUNT || '60', 10);
const WS_REGISTER_PROGRESS_LOG_STEP = parseInt(__ENV.K6_WS_REGISTER_PROGRESS_LOG_STEP || '10', 10);

function extractUserIdFromToken(token) {
  try {
    const payload = token.split('.')[1];
    if (!payload) {
      return null;
    }

    const decoded = encoding.b64decode(payload, 'rawurl', 's');
    const parsed = JSON.parse(decoded);
    const userId = parsed?.userId;

    if (typeof userId === 'number' && Number.isFinite(userId)) {
      return userId;
    }
    if (typeof userId === 'string' && userId.length > 0 && !Number.isNaN(Number(userId))) {
      return Number(userId);
    }
    return null;
  } catch (_) {
    return null;
  }
}

export const options = {
  setupTimeout: '300s',
  scenarios: {
    websocket_load: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '30s', target: 200 }, // 20명까지 증가
        { duration: '2m', target: 300 }, // 2분간 유지
        { duration: '2m', target: 500 }, // 2분간 유지
        { duration: '30s', target: 0 }, // 종료
      ],
    },
  },
  thresholds: {
    ws_connection_time: ['p(95)<3000'], // 연결 시간 95% 3초 이내
    ws_message_send_time: ['p(95)<500'], // 메시지 전송 95% 500ms 이내
    ws_message_receive_time: ['p(95)<1000'], // 메시지 수신 95% 1초 이내
    ws_error_rate: ['rate<0.05'], // 에러율 5% 이하
    http_req_failed: ['rate<0.01'], // HTTP 실패율 1% 이하 (채팅방 생성/삭제)
  },
};

export function setup() {
  console.log('🔧 [WebSocket] setup 시작: 회원가입 + 토큰 준비');

  const tokenPool = [];
  let registeredSuccess = 0;
  let registeredFailure = 0;

  for (let i = 0; i < WS_REGISTER_USER_COUNT; i += 1) {
    const authCode = `k6_ws_auth_code_${i}_${Date.now()}`;
    const token = registerWithGoogle(authCode);

    if (token) {
      tokenPool.push(token);
      registeredSuccess += 1;
    } else {
      registeredFailure += 1;
    }

    if ((i + 1) % WS_REGISTER_PROGRESS_LOG_STEP === 0 || i === WS_REGISTER_USER_COUNT - 1) {
      console.log(
        `[WebSocket] register 진행 ${i + 1}/${WS_REGISTER_USER_COUNT} (success=${registeredSuccess}, failed=${registeredFailure})`
      );
    }
  }

  const fallbackToken = getToken();
  if (fallbackToken) {
    tokenPool.push(fallbackToken);
    console.log('[WebSocket] K6_AUTH_TOKEN을 토큰 풀에 추가했습니다.');
  }

  const dedupedTokenPool = [...new Set(tokenPool)];
  if (dedupedTokenPool.length === 0) {
    throw new Error(
      '사용 가능한 토큰이 없습니다. 회원가입 플로우를 점검하거나 K6_AUTH_TOKEN을 설정하세요.'
    );
  }

  const users = dedupedTokenPool
    .map((token) => ({ token, userId: extractUserIdFromToken(token) }))
    .filter((user) => user.userId !== null);

  if (users.length < 2) {
    throw new Error(
      '채팅 테스트에는 최소 2명의 유효한 사용자가 필요합니다. 토큰 발급/회원가입 플로우를 확인하세요.'
    );
  }

  console.log(
    `[WebSocket] setup 완료 (usableUsers=${users.length}, registerSuccess=${registeredSuccess}, registerFailed=${registeredFailure})`
  );
  return { users };
}

export default function (data) {
  const { users } = data;
  const vuId = exec.vu.idInTest;
  const iteration = exec.scenario.iterationInTest;
  const senderIndex = (vuId - 1) % users.length;
  let receiverIndex = (senderIndex + 1 + iteration) % users.length;
  if (receiverIndex === senderIndex) {
    receiverIndex = (senderIndex + 1) % users.length;
  }

  const sender = users[senderIndex];
  const receiver = users[receiverIndex];
  console.log(
    `[VU${vuId}] WebSocket 채팅 시작 (sender=${sender.userId}, receiver=${receiver.userId})`
  );

  // 1. 일반 1:1 채팅방 생성(또는 기존 방 재사용)
  const room = createPrivateChatRoom(sender.token, receiver.userId);
  if (!room || !room.roomId) {
    console.error(`[VU${vuId}] 채팅방 생성 실패 (sender=${sender.userId}, receiver=${receiver.userId})`);
    sleep(5);
    return;
  }

  console.log(`[VU${vuId}] 채팅방 준비 완료: roomId=${room.roomId}, isNew=${room.isNew}`);
  sleep(0.5);

  // 2. STOMP WebSocket 연결 및 채팅 메시지 송수신
  const result = connectWebSocketChat(sender.token, room.roomId, {
    duration: WS_DURATION,
    messageCount: WS_MESSAGE_COUNT,
    messageInterval: WS_MESSAGE_INTERVAL,
  });

  if (!result.connected) {
    console.error(
      `[VU${vuId}] WebSocket 연결 실패: status=${result.httpStatus ?? 'unknown'}, detail=${result.errors.join(' | ')}`
    );
  }

  console.log(
    `[VU${vuId}] WebSocket 테스트 완료: status=${result.httpStatus ?? 'unknown'}, sent=${result.messagesSent}, received=${result.messagesReceived}, errors=${result.errors.length}`
  );

  // 3. 채팅방 나가기 (옵션)
  if (!WS_KEEP_ROOM) {
    sleep(0.5);
    leaveChatRoom(sender.token, room.roomId);
    console.log(`[VU${vuId}] 채팅방 나가기 완료: roomId=${room.roomId}`);
  }

  sleep(2);
}

export function teardown(data) {
  console.log('✅ WebSocket 채팅 부하 테스트 완료!');
}

export function handleSummary(data) {
  // 기본 HTTP 메트릭 요약
  const httpSummary = summarize(data, 'websocket-chat');

  // WebSocket 커스텀 메트릭 추가 출력
  const wsConnectionTime = data.metrics.ws_connection_time?.values || {};
  const wsMsgSendTime = data.metrics.ws_message_send_time?.values || {};
  const wsMsgReceiveTime = data.metrics.ws_message_receive_time?.values || {};
  const wsErrorRate = data.metrics.ws_error_rate?.values?.rate ?? 0;
  const wsMsgsSent = data.metrics.ws_messages_sent?.values?.count ?? 0;
  const wsMsgsReceived = data.metrics.ws_messages_received?.values?.count ?? 0;

  let wsOutput = '\n';
  wsOutput += '🔌 WebSocket 전용 메트릭\n';
  wsOutput += '──────────────────────────────────────────────────────────\n';
  wsOutput += '  연결 시간 (Connection Time)\n';
  wsOutput += `    평균(avg)   : ${(wsConnectionTime.avg ?? 0).toFixed(2)}ms\n`;
  wsOutput += `    중앙값(med) : ${(wsConnectionTime.med ?? 0).toFixed(2)}ms\n`;
  wsOutput += `    p90         : ${(wsConnectionTime['p(90)'] ?? 0).toFixed(2)}ms\n`;
  wsOutput += `    p95         : ${(wsConnectionTime['p(95)'] ?? 0).toFixed(2)}ms\n`;
  wsOutput += `    p99         : ${(wsConnectionTime['p(99)'] ?? 0).toFixed(2)}ms\n`;
  wsOutput += '\n';
  wsOutput += '  메시지 전송 시간 (Send Time)\n';
  wsOutput += `    평균(avg)   : ${(wsMsgSendTime.avg ?? 0).toFixed(2)}ms\n`;
  wsOutput += `    중앙값(med) : ${(wsMsgSendTime.med ?? 0).toFixed(2)}ms\n`;
  wsOutput += `    p90         : ${(wsMsgSendTime['p(90)'] ?? 0).toFixed(2)}ms\n`;
  wsOutput += `    p95         : ${(wsMsgSendTime['p(95)'] ?? 0).toFixed(2)}ms\n`;
  wsOutput += `    p99         : ${(wsMsgSendTime['p(99)'] ?? 0).toFixed(2)}ms\n`;
  wsOutput += '\n';
  wsOutput += '  메시지 수신 시간 (Receive Time)\n';
  wsOutput += `    평균(avg)   : ${(wsMsgReceiveTime.avg ?? 0).toFixed(2)}ms\n`;
  wsOutput += `    중앙값(med) : ${(wsMsgReceiveTime.med ?? 0).toFixed(2)}ms\n`;
  wsOutput += `    p90         : ${(wsMsgReceiveTime['p(90)'] ?? 0).toFixed(2)}ms\n`;
  wsOutput += `    p95         : ${(wsMsgReceiveTime['p(95)'] ?? 0).toFixed(2)}ms\n`;
  wsOutput += `    p99         : ${(wsMsgReceiveTime['p(99)'] ?? 0).toFixed(2)}ms\n`;
  wsOutput += '\n';
  wsOutput += '  메시지 통계\n';
  wsOutput += `    전송 메시지 : ${wsMsgsSent.toLocaleString()}\n`;
  wsOutput += `    수신 메시지 : ${wsMsgsReceived.toLocaleString()}\n`;
  wsOutput += `    에러율      : ${(wsErrorRate * 100).toFixed(2)}%\n`;
  wsOutput += '──────────────────────────────────────────────────────────\n\n';

  return { stdout: httpSummary.stdout + wsOutput };
}
