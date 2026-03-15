/**
 * AI/챗봇 API (긴 트랜잭션)
 *
 * 커버하는 엔드포인트:
 *   POST   /api/ai-chatrooms                    챗봇방 생성
 *   DELETE /api/ai-chatrooms/{roomId}           챗봇방 삭제
 *   GET    /api/ai-chatrooms                    챗봇방 목록 조회
 *   POST   /api/ai-chatrooms/{roomId}/messages  메시지 전송 (SSE 응답)
 *   GET    /api/ai-chatrooms/{roomId}/messages  채팅 기록 조회
 *
 * 특징:
 *   - LLM 처리로 인한 긴 응답 시간 (5~15초)
 *   - SSE(Server-Sent Events) 스트리밍 응답
 *   - 대용량 텍스트 처리
 *
 * 주의:
 *   - 메시지 전송은 SSE 응답을 반환하므로 k6에서 완전한 응답 파싱이 어렵습니다.
 *   - 부하 테스트 목적으로 요청만 보내고 응답은 제한적으로 처리합니다.
 */

import http from 'k6/http';
import { BASE_URL, headers } from '../lib/config.js';
import { record } from '../lib/helpers.js';

// ────────── 챗봇 ──────────

/**
 * POST /api/ai-chatrooms/{roomId}/messages
 * 챗봇에 메시지를 전송하고 AI 응답을 받습니다.
 * LLM 처리로 인해 응답 시간이 길 수 있습니다 (5~15초).
 *
 * 주의: SSE 스트리밍 응답을 반환하므로 k6에서 완전한 파싱이 어렵습니다.
 *
 * @param {string} token - 인증 토큰
 * @param {number} roomId - 채팅방 ID
 * @param {string} content - 사용자 메시지
 * @param {string} model - AI 모델 ("GEMINI" | "VLLM")
 * @param {number|null} interviewId - 인터뷰 ID (선택)
 * @returns {boolean} 요청 성공 여부 (SSE 응답은 제한적으로 처리)
 */
export function sendChatMessage(token, roomId, content, model = 'GEMINI', interviewId = null) {
  const normalizedModel = model === 'VLLM' ? 'VLLM' : 'GEMINI';
  const body = { content, model: normalizedModel };
  if (interviewId) body.interviewId = interviewId;
  const label = 'POST /api/ai-chatrooms/{roomId}/messages';

  const res = http.post(
    `${BASE_URL}/api/ai-chatrooms/${roomId}/messages`,
    JSON.stringify(body),
    {
      headers: {
        ...headers(true, token),
        Accept: 'text/event-stream',
      },
      tags: { name: 'ai_chat_send' },
      timeout: '30s',  // LLM 처리 시간 고려하여 타임아웃 증가
    }
  );

  // SSE 응답은 200 OK + text/event-stream content-type
  const success = record(res, label, {
    [`${label}: duration < 2s`]: (r) => r.timings.duration < 25000,
    'chat send: status 200': (r) => r.status === 200,
  });

  return success;
}

/**
 * GET /api/ai-chatrooms/{roomId}/messages
 * 채팅 기록을 조회합니다.
 *
 * @param {string} token - 인증 토큰
 * @param {number} roomId - 채팅방 ID
 * @param {object} params - { size?: number, lastId?: number }
 * @returns {{ messages: Array, lastId: number, hasNext: boolean }}
 */
export function getChatHistory(token, roomId, { size = 20, lastId = null } = {}) {
  const query = [`size=${size}`];
  if (lastId) query.push(`lastId=${lastId}`);

  const res = http.get(
    `${BASE_URL}/api/ai-chatrooms/${roomId}/messages?${query.join('&')}`,
    {
      headers: headers(true, token),
      tags: { name: 'ai_chat_history' },
    }
  );

  record(res, `GET /api/ai-chatrooms/${roomId}/messages`);

  try {
    const body = JSON.parse(res.body);
    return {
      messages: body?.data?.messages ?? [],
      lastId: body?.data?.lastId ?? null,
      hasNext: body?.data?.hasNext ?? false,
    };
  } catch (_) {
    return { messages: [], lastId: null, hasNext: false };
  }
}

/**
 * POST /api/ai-chatrooms
 * 새로운 AI 채팅방을 생성합니다.
 *
 * @param {string} token - 인증 토큰
 * @returns {{ roomId: number, roomUuid: string, title: string } | null}
 */
export function createChatRoom(token) {
  const res = http.post(
    `${BASE_URL}/api/ai-chatrooms`,
    null,  // body 없음
    {
      headers: headers(true, token),
      tags: { name: 'ai_chat_room_create' },
    }
  );

  record(res, 'POST /api/ai-chatrooms', {
    'create chat room: status 201': (r) => r.status === 201,
  });

  try {
    const body = JSON.parse(res.body);
    return {
      roomId: body?.data?.roomId ?? null,
      roomUuid: body?.data?.roomUuid ?? null,
      title: body?.data?.title ?? null,
    };
  } catch (_) {
    return null;
  }
}

/**
 * DELETE /api/ai-chatrooms/{roomId}
 * AI 채팅방을 삭제합니다.
 *
 * @param {string} token - 인증 토큰
 * @param {number} roomId - 채팅방 ID
 */
export function deleteChatRoom(token, roomId) {
  const res = http.del(`${BASE_URL}/api/ai-chatrooms/${roomId}`, null, {
    headers: headers(true, token),
    tags: { name: 'ai_chat_room_delete' },
  });

  record(res, `DELETE /api/ai-chatrooms/${roomId}`, {
    'delete chat room: status 204': (r) => r.status === 204,
  });
}

/**
 * GET /api/ai-chatrooms
 * 내 AI 채팅방 목록을 조회합니다.
 *
 * @param {string} token - 인증 토큰
 * @param {object} params - { size?: number, lastId?: number }
 * @returns {{ rooms: Array, lastId: number, hasNext: boolean }}
 */
export function getMyChatRooms(token, { size = 20, lastId = null } = {}) {
  const query = [`size=${size}`];
  if (lastId) query.push(`lastId=${lastId}`);

  const res = http.get(`${BASE_URL}/api/ai-chatrooms?${query.join('&')}`, {
    headers: headers(true, token),
    tags: { name: 'ai_chat_rooms' },
  });

  record(res, 'GET /api/ai-chatrooms');

  try {
    const body = JSON.parse(res.body);
    return {
      rooms: body?.data?.rooms ?? [],
      lastId: body?.data?.lastId ?? null,
      hasNext: body?.data?.hasNext ?? false,
    };
  } catch (_) {
    return { rooms: [], lastId: null, hasNext: false };
  }
}
