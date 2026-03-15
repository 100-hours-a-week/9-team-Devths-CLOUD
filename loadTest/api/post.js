/**
 * 게시물 API
 *
 * 커버하는 엔드포인트:
 *   GET    /api/posts                           게시물 목록 (커서 기반)
 *   GET    /api/posts/{postId}                  게시물 상세
 *   POST   /api/posts                           게시물 생성
 *   PUT    /api/posts/{postId}                  게시물 수정
 *   DELETE /api/posts/{postId}                  게시물 삭제
 *   POST   /api/posts/{postId}/likes            좋아요
 *   DELETE /api/posts/{postId}/likes            좋아요 취소
 *   GET    /api/posts/{postId}/comments         댓글 목록 (커서 기반)
 *   POST   /api/posts/{postId}/comments         댓글 생성
 *   DELETE /api/posts/{postId}/comments/{id}    댓글 삭제
 *
 * 페이지네이션: page 없음, lastId + size 커서 방식 사용
 */

import http from 'k6/http';
import { sleep } from 'k6';
import { BASE_URL, HEALTH_PATH, headers } from '../lib/config.js';
import { record } from '../lib/helpers.js';

const ENABLE_POST_TAGS = (__ENV.K6_ENABLE_POST_TAGS || 'false').toLowerCase() === 'true';

// ────────── 헬스체크 ──────────

/**
 * GET /actuator/health
 * 서비스 정상 여부를 확인합니다.
 */
export function checkHealth() {
  const res = http.get(`${BASE_URL}${HEALTH_PATH}`, {
    headers: headers(),
    tags: { name: 'health' },
  });
  return {
    ok: res.status === 200,
    isUp: (() => { try { return JSON.parse(res.body).status === 'UP'; } catch (_) { return false; } })(),
    res,
  };
}

// ────────── 게시물 ──────────

/**
 * GET /api/posts
 * @param {string} token
 * @param {object} params - { size?: number, lastId?: number, tag?: string }
 * @returns {{ posts: Array, lastId: number|null }} 게시물 배열과 다음 커서
 */
export function getPosts(token, { size = 10, lastId = null, tag = null } = {}) {
  const query = [`size=${size}`];
  if (lastId) query.push(`lastId=${lastId}`);
  if (tag) query.push(`tag=${encodeURIComponent(tag)}`);

  const res = http.get(`${BASE_URL}/api/posts?${query.join('&')}`, {
    headers: headers(true, token),
    tags: { name: 'post_list' },
  });

  record(res, 'GET /api/posts');

  try {
    const body = JSON.parse(res.body);
    const posts = body?.data?.posts ?? [];
    return {
      posts,
      lastId: posts.length > 0 ? posts[posts.length - 1].postId : null,
    };
  } catch (_) {
    return { posts: [], lastId: null };
  }
}

/**
 * GET /api/posts/{postId}
 * @param {string} token
 * @param {number} postId
 */
export function getPost(token, postId) {
  const res = http.get(`${BASE_URL}/api/posts/${postId}`, {
    headers: headers(true, token),
    tags: { name: 'post_detail' },
  });
  record(res, `GET /api/posts/${postId}`);
  return res;
}

/**
 * POST /api/posts
 * @param {string} token
 * @param {object} params - { title, content, tags?: string[], fileIds?: number[] }
 * @returns {number|null} 생성된 postId
 */
export function createPost(token, { title, content, tags = [], fileIds = [] } = {}) {
  const body = { title, content };

  // 태그는 백엔드의 허용값 제약이 강해 INVALID_INPUT(400)을 유발할 수 있어 기본 비활성화한다.
  // 필요 시 K6_ENABLE_POST_TAGS=true 로만 전송한다.
  if (ENABLE_POST_TAGS && Array.isArray(tags) && tags.length > 0) {
    body.tags = tags;
  }

  if (fileIds.length > 0) {
    body.fileIds = fileIds;
  }

  const res = http.post(
    `${BASE_URL}/api/posts`,
    JSON.stringify(body),
    {
      headers: headers(true, token),
      tags: { name: 'post_create' },
    }
  );
  record(res, 'POST /api/posts', {
    'create post: status 201': (r) => r.status === 201,
  });

  try { return JSON.parse(res.body)?.data?.postId ?? null; } catch (_) { return null; }
}

/**
 * PUT /api/posts/{postId}
 * @param {string} token
 * @param {number} postId
 * @param {object} params - { title, content, tags?: string[], fileIds?: number[] }
 * @returns {boolean} 수정 성공 여부
 */
export function updatePost(token, postId, { title, content, tags = [], fileIds = [] } = {}) {
  const body = { title, content };

  if (ENABLE_POST_TAGS && Array.isArray(tags) && tags.length > 0) {
    body.tags = tags;
  }

  if (fileIds.length > 0) {
    body.fileIds = fileIds;
  }

  const res = http.put(
    `${BASE_URL}/api/posts/${postId}`,
    JSON.stringify(body),
    {
      headers: headers(true, token),
      tags: { name: 'post_update' },
    }
  );

  return record(res, `PUT /api/posts/${postId}`, {
    'update post: status 200 or 204': (r) => r.status === 200 || r.status === 204,
  });
}

/**
 * DELETE /api/posts/{postId}
 * @param {string} token
 * @param {number} postId
 */
export function deletePost(token, postId) {
  const res = http.del(`${BASE_URL}/api/posts/${postId}`, null, {
    headers: headers(true, token),
    tags: { name: 'post_delete' },
  });
  record(res, `DELETE /api/posts/${postId}`, {
    'delete post: status 204': (r) => r.status === 204,
  });
}

// ────────── 좋아요 ──────────

/**
 * POST /api/posts/{postId}/likes
 * @param {string} token
 * @param {number} postId
 */
export function likePost(token, postId) {
  const res = http.post(`${BASE_URL}/api/posts/${postId}/likes`, null, {
    headers: headers(true, token),
    tags: { name: 'post_like' },
  });
  record(res, `POST /api/posts/${postId}/likes`);
}

/**
 * DELETE /api/posts/{postId}/likes
 * @param {string} token
 * @param {number} postId
 */
export function unlikePost(token, postId) {
  const res = http.del(`${BASE_URL}/api/posts/${postId}/likes`, null, {
    headers: headers(true, token),
    tags: { name: 'post_unlike' },
  });
  record(res, `DELETE /api/posts/${postId}/likes`, {
    'unlike: status 204': (r) => r.status === 204,
  });
}

// ────────── 댓글 ──────────

/**
 * GET /api/posts/{postId}/comments
 * @param {string} token
 * @param {number} postId
 * @param {object} params - { size?: number, lastId?: number }
 * @returns {number|null} 다음 커서 lastId
 */
export function getComments(token, postId, { size = 10, lastId = null } = {}) {
  const query = [`size=${size}`];
  if (lastId) query.push(`lastId=${lastId}`);

  const res = http.get(`${BASE_URL}/api/posts/${postId}/comments?${query.join('&')}`, {
    headers: headers(true, token),
    tags: { name: 'comment_list' },
  });
  record(res, `GET /api/posts/${postId}/comments`);

  try {
    const body = JSON.parse(res.body);
    const comments = body?.data?.comments ?? [];
    return comments.length > 0 ? comments[comments.length - 1].commentId : null;
  } catch (_) {
    return null;
  }
}

/**
 * POST /api/posts/{postId}/comments
 * @param {string} token
 * @param {number} postId
 * @param {string} content - 1~500자
 * @param {number|null} parentId - 대댓글 시 부모 commentId
 * @returns {number|null} 생성된 commentId
 */
export function createComment(token, postId, content, parentId = null) {
  const body = { content };
  if (parentId) body.parentId = parentId;

  const res = http.post(
    `${BASE_URL}/api/posts/${postId}/comments`,
    JSON.stringify(body),
    {
      headers: headers(true, token),
      tags: { name: 'comment_create' },
    }
  );
  record(res, `POST /api/posts/${postId}/comments`, {
    'create comment: status 201': (r) => r.status === 201,
  });

  try { return JSON.parse(res.body)?.data?.commentId ?? null; } catch (_) { return null; }
}

/**
 * DELETE /api/posts/{postId}/comments/{commentId}
 * @param {string} token
 * @param {number} postId
 * @param {number} commentId
 */
export function deleteComment(token, postId, commentId) {
  const res = http.del(`${BASE_URL}/api/posts/${postId}/comments/${commentId}`, null, {
    headers: headers(true, token),
    tags: { name: 'comment_delete' },
  });
  record(res, `DELETE /api/posts/${postId}/comments/${commentId}`, {
    'delete comment: status 204': (r) => r.status === 204,
  });
}
