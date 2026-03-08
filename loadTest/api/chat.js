/**
 * 일반 채팅(Chat) API
 *
 * 커버하는 엔드포인트:
 *   POST   /api/chatrooms/private  1:1 채팅방 생성(또는 기존 방 반환)
 *   DELETE /api/chatrooms/{roomId} 채팅방 나가기
 */

import http from 'k6/http';
import { BASE_URL, headers } from '../lib/config.js';
import { record } from '../lib/helpers.js';

/**
 * POST /api/chatrooms/private
 * @param {string} token
 * @param {number} targetUserId
 * @returns {{roomId: number, isNew: boolean}|null}
 */
export function createPrivateChatRoom(token, targetUserId) {
  const res = http.post(
    `${BASE_URL}/api/chatrooms/private`,
    JSON.stringify({ userId: targetUserId }),
    {
      headers: headers(true, token),
      tags: { name: 'chat_room_private_create' },
    }
  );

  const ok = record(res, 'POST /api/chatrooms/private', {
    'create private chat room: status 201 or 200': (r) => r.status === 201 || r.status === 200,
  });

  if (!ok) {
    return null;
  }

  try {
    const data = JSON.parse(res.body)?.data;
    if (!data || data.roomId == null) {
      return null;
    }

    return {
      roomId: data.roomId,
      isNew: data.isNew === true,
    };
  } catch (_) {
    return null;
  }
}

/**
 * DELETE /api/chatrooms/{roomId}
 * @param {string} token
 * @param {number} roomId
 */
export function leaveChatRoom(token, roomId) {
  const res = http.del(`${BASE_URL}/api/chatrooms/${roomId}`, null, {
    headers: headers(true, token),
    tags: { name: 'chat_room_leave' },
  });

  record(res, `DELETE /api/chatrooms/${roomId}`, {
    'leave chat room: status 204': (r) => r.status === 204,
  });
}
