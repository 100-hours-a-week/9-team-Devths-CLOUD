/**
 * 사용자 / 알림 / 할일 API
 *
 * 커버하는 엔드포인트:
 *   GET    /api/users/me                  내 정보
 *   GET    /api/users/{userId}            유저 프로필
 *   GET    /api/users/me/posts            내 게시물 목록
 *   GET    /api/users/me/followers        내 팔로워 목록
 *   GET    /api/users/me/followings       내 팔로잉 목록
 *   POST   /api/users/{userId}/followers  팔로우
 *   DELETE /api/users/{userId}/followers  언팔로우
 *   GET    /api/notifications             알림 목록
 *   GET    /api/notifications/unread      읽지 않은 알림 수
 *   GET    /api/todos                     할일 목록
 *   POST   /api/todos                     할일 생성
 */

import http from 'k6/http';
import { BASE_URL, headers } from '../lib/config.js';
import { record } from '../lib/helpers.js';

// ────────── 사용자 ──────────

/**
 * GET /api/users/me
 * @param {string} token
 */
export function getMe(token) {
  const res = http.get(`${BASE_URL}/api/users/me`, {
    headers: headers(true, token),
    tags: { name: 'user_me' },
  });
  record(res, 'GET /api/users/me');
  return res;
}

/**
 * GET /api/users/{userId}
 * @param {string} token
 * @param {number} userId
 */
export function getUserProfile(token, userId) {
  const res = http.get(`${BASE_URL}/api/users/${userId}`, {
    headers: headers(true, token),
    tags: { name: 'user_profile' },
  });
  record(res, `GET /api/users/${userId}`);
  return res;
}

/**
 * GET /api/users/me/posts
 * @param {string} token
 * @param {object} params - { size?: number, lastId?: number }
 */
export function getMyPosts(token, { size = 10, lastId = null } = {}) {
  const query = [`size=${size}`];
  if (lastId) query.push(`lastId=${lastId}`);

  const res = http.get(`${BASE_URL}/api/users/me/posts?${query.join('&')}`, {
    headers: headers(true, token),
    tags: { name: 'user_my_posts' },
  });
  record(res, 'GET /api/users/me/posts');
}

/**
 * GET /api/users/me/followers
 * @param {string} token
 * @param {object} params - { size?: number, lastId?: number }
 */
export function getMyFollowers(token, { size = 10, lastId = null } = {}) {
  const query = [`size=${size}`];
  if (lastId) query.push(`lastId=${lastId}`);

  const res = http.get(`${BASE_URL}/api/users/me/followers?${query.join('&')}`, {
    headers: headers(true, token),
    tags: { name: 'user_followers' },
  });
  record(res, 'GET /api/users/me/followers');
}

/**
 * GET /api/users/me/followings
 * @param {string} token
 * @param {object} params - { size?: number, lastId?: number, nickname?: string }
 */
export function getMyFollowings(token, { size = 10, lastId = null, nickname = null } = {}) {
  const query = [`size=${size}`];
  if (lastId) query.push(`lastId=${lastId}`);
  if (nickname) query.push(`nickname=${encodeURIComponent(nickname)}`);

  const res = http.get(`${BASE_URL}/api/users/me/followings?${query.join('&')}`, {
    headers: headers(true, token),
    tags: { name: 'user_followings' },
  });
  record(res, 'GET /api/users/me/followings');
}

/**
 * POST /api/users/{userId}/followers  (팔로우)
 * @param {string} token
 * @param {number} userId
 */
export function followUser(token, userId) {
  const res = http.post(`${BASE_URL}/api/users/${userId}/followers`, null, {
    headers: headers(true, token),
    tags: { name: 'user_follow' },
  });
  record(res, `POST /api/users/${userId}/followers`, {
    'follow: status 201': (r) => r.status === 201,
  });
}

/**
 * DELETE /api/users/{userId}/followers  (언팔로우)
 * @param {string} token
 * @param {number} userId
 */
export function unfollowUser(token, userId) {
  const res = http.del(`${BASE_URL}/api/users/${userId}/followers`, null, {
    headers: headers(true, token),
    tags: { name: 'user_unfollow' },
  });
  record(res, `DELETE /api/users/${userId}/followers`, {
    'unfollow: status 204': (r) => r.status === 204,
  });
}

// ────────── 알림 ──────────

/**
 * GET /api/notifications/unread
 * 읽지 않은 알림 개수 (가장 빈번히 호출되는 polling 패턴)
 * @param {string} token
 * @returns {number} unreadCount
 */
export function getUnreadCount(token) {
  const res = http.get(`${BASE_URL}/api/notifications/unread`, {
    headers: headers(true, token),
    tags: { name: 'notification_unread' },
  });
  record(res, 'GET /api/notifications/unread');

  try { return JSON.parse(res.body)?.data?.unreadCount ?? 0; } catch (_) { return 0; }
}

/**
 * GET /api/notifications
 * @param {string} token
 * @param {object} params - { size?: number, lastId?: number }
 */
export function getNotifications(token, { size = 10, lastId = null } = {}) {
  const query = [`size=${size}`];
  if (lastId) query.push(`lastId=${lastId}`);

  const res = http.get(`${BASE_URL}/api/notifications?${query.join('&')}`, {
    headers: headers(true, token),
    tags: { name: 'notification_list' },
  });
  record(res, 'GET /api/notifications');
}

// ────────── 할일 ──────────

/**
 * GET /api/todos
 * @param {string} token
 * @param {string|null} dueDate - YYYY-MM-DD 형식 (없으면 전체 조회)
 */
export function getTodos(token, dueDate = null) {
  const query = dueDate ? `?dueDate=${dueDate}` : '';
  const res = http.get(`${BASE_URL}/api/todos${query}`, {
    headers: headers(true, token),
    tags: { name: 'todo_list' },
  });
  record(res, 'GET /api/todos');
}

/**
 * POST /api/todos
 * @param {string} token
 * @param {string} title
 * @param {string} dueDate - YYYY-MM-DD 형식
 * @returns {string|null} 생성된 todoId
 */
export function createTodo(token, title, dueDate) {
  const res = http.post(
    `${BASE_URL}/api/todos`,
    JSON.stringify({ title, dueDate }),
    {
      headers: headers(true, token),
      tags: { name: 'todo_create' },
    }
  );
  record(res, 'POST /api/todos', {
    'create todo: status 201': (r) => r.status === 201,
  });

  try { return JSON.parse(res.body)?.data?.todoId ?? null; } catch (_) { return null; }
}

// ────────── 검색 ──────────

/**
 * GET /api/users/search
 * 사용자 검색 (닉네임 기반)
 * @param {string} token
 * @param {string} nickname - 검색할 닉네임
 * @param {object} params - { size?: number, lastId?: number }
 * @returns {Array<number>} userId 배열
 */
export function searchUsers(token, nickname = '', { size = 100, lastId = null } = {}) {
  const query = [`size=${size}`];
  if (nickname) query.push(`nickname=${encodeURIComponent(nickname)}`);
  if (lastId) query.push(`lastId=${lastId}`);

  const res = http.get(`${BASE_URL}/api/users/search?${query.join('&')}`, {
    headers: headers(true, token),
    tags: { name: 'user_search' },
  });
  record(res, 'GET /api/users/search');

  try {
    const body = JSON.parse(res.body);
    const users = body?.data?.users ?? [];
    return users.map(u => u.userId).filter(id => id != null);
  } catch (_) {
    return [];
  }
}
