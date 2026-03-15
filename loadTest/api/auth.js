/**
 * 인증 API
 *
 * 토큰 발급 방법:
 *
 *   방법) 수동 토큰 주입
 *     - 브라우저에서 로그인 후 개발자 도구 → Cookie → accessToken 복사
 *     - K6_AUTH_TOKEN 환경변수에 설정
 *
 * 실행 예시:
 *   # 수동 토큰 주입
 *   K6_ENV=dev K6_AUTH_TOKEN=eyJhbGci... k6 run scenarios/load.js
 */

import http from 'k6/http';
import { check } from 'k6';
import { BASE_URL, headers } from '../lib/config.js';

const REFRESH_PATH = '/api/auth/tokens';
const LOGOUT_PATH = '/api/auth/logout';
const GOOGLE_LOGIN_PATH = '/api/auth/google';
const USER_SIGNUP_PATH = '/api/users';

function parseJsonSafely(raw) {
  try {
    return JSON.parse(raw);
  } catch (_) {
    return null;
  }
}

function getHeaderValue(res, headerName) {
  if (!res || !res.headers) {
    return null;
  }

  const target = headerName.toLowerCase();
  for (const key of Object.keys(res.headers)) {
    if (key.toLowerCase() !== target) {
      continue;
    }

    const value = res.headers[key];
    if (Array.isArray(value)) {
      return value.length > 0 ? value[0] : null;
    }
    return value;
  }

  return null;
}

function extractBearerToken(res) {
  const authHeader = getHeaderValue(res, 'Authorization');
  if (!authHeader || typeof authHeader !== 'string') {
    return null;
  }

  return authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
}

function buildSignupNickname() {
  const prefix = (__ENV.K6_SIGNUP_NICKNAME_PREFIX || 'k6').replace(/[^a-zA-Z0-9가-힣]/g, '') || 'k6';
  const suffix = `${Date.now()}`.slice(-6) + `${Math.floor(Math.random() * 1000)}`.padStart(3, '0');
  const maxPrefixLength = Math.max(0, 10 - suffix.length);
  let nickname = `${prefix.slice(0, maxPrefixLength)}${suffix}`;

  if (nickname.length < 2) {
    nickname = `k6${suffix}`.slice(0, 10);
  }

  return nickname;
}

function getSignupInterests() {
  const raw = __ENV.K6_SIGNUP_INTERESTS;
  if (!raw) {
    return ['BACKEND'];
  }

  const interests = raw
    .split(',')
    .map((value) => value.trim())
    .filter((value) => value.length > 0);

  return interests.length > 0 ? interests : ['BACKEND'];
}

function completeSignupWithTempToken(email, tempToken) {
  const interests = getSignupInterests();
  const maxRetry = Number.parseInt(__ENV.K6_SIGNUP_MAX_RETRY || '3', 10);
  const retryCount = Number.isFinite(maxRetry) && maxRetry > 0 ? maxRetry : 3;
  let lastResponse = null;

  for (let attempt = 1; attempt <= retryCount; attempt += 1) {
    const payload = JSON.stringify({
      email,
      nickname: buildSignupNickname(),
      interests,
      tempToken,
    });

    const signupResponse = http.post(`${BASE_URL}${USER_SIGNUP_PATH}`, payload, {
      headers: {
        'Content-Type': 'application/json',
      },
      tags: { name: 'auth_signup_google' },
    });

    lastResponse = signupResponse;
    const accessToken = extractBearerToken(signupResponse);
    if (signupResponse.status === 201 && accessToken) {
      return accessToken;
    }
  }

  if (lastResponse) {
    console.error(
      `[auth] ❌ Google 신규회원 JWT 발급 실패: ${lastResponse.status} - ${lastResponse.body}`
    );
  }

  return null;
}

/**
 * 토큰을 반환합니다.
 * 우선순위: 1) K6_AUTH_TOKEN 환경변수
 *
 * @returns {string|null}
 */
export function getToken() {
  const manualToken = __ENV.K6_AUTH_TOKEN;
  if (manualToken) {
    return manualToken;
  }

  console.warn('[auth] K6_AUTH_TOKEN이 없습니다. .env에 토큰을 설정하세요.');
  return null;
}

/**
 * 토큰 갱신 (POST /api/auth/tokens)
 * 쿠키 기반 refresh token을 사용합니다.
 *
 * @returns {boolean} 성공 여부
 */
export function refreshToken() {
  const res = http.post(`${BASE_URL}${REFRESH_PATH}`, null, {
    headers: headers(),
    tags: { name: 'auth_refresh' },
  });

  return check(res, { 'refresh: status 200': (r) => r.status === 200 });
}

/**
 * 로그아웃 (POST /api/auth/logout)
 *
 * @param {string} token
 */
export function logout(token) {
  const res = http.post(`${BASE_URL}${LOGOUT_PATH}`, null, {
    headers: headers(true, token),
    tags: { name: 'auth_logout' },
  });

  check(res, { 'logout: status 204': (r) => r.status === 204 });
}

/**
 * 구글 OAuth2 회원가입/로그인 (POST /api/auth/google)
 *
 * Backend는 이 Authorization Code를 받아서:
 * 1. WireMock(구글 Token Endpoint)에 요청 → Access Token 받기
 * 2. WireMock(구글 UserInfo API)에 요청 → 사용자 정보 받기
 * 3. 회원가입 또는 로그인 처리 → 자체 JWT 토큰 반환
 *
 * @param {string} authCode - 구글 Authorization Code (모킹용이므로 임의의 값)
 * @returns {string|null} Backend JWT 토큰 또는 null
 */
export function registerWithGoogle(authCode) {
  const payload = JSON.stringify({
    authCode: authCode,
  });

  const res = http.post(`${BASE_URL}${GOOGLE_LOGIN_PATH}`, payload, {
    headers: {
      'Content-Type': 'application/json',
    },
    tags: { name: 'auth_register_google' },
  });

  const body = parseJsonSafely(res.body);
  let token =
    extractBearerToken(res) ||
    body?.token ||
    body?.accessToken ||
    body?.data?.token ||
    body?.data?.accessToken;

  // 신규 유저는 tempToken만 내려오므로 회원가입 완료 API(/api/users)로 최종 JWT를 발급받는다.
  if (!token && body?.data?.isRegistered === false && body?.data?.tempToken && body?.data?.email) {
    token = completeSignupWithTempToken(body.data.email, body.data.tempToken);
  }

  const success = check(res, {
    'google register: status 200 or 201': (r) => r.status === 200 || r.status === 201,
    'google register: has token': () => token !== undefined && token !== null && token !== '',
  });

  if (success) {
    console.log(`[auth] ✅ 구글 OAuth2 회원가입/로그인 성공 (token: ${token.slice(0, 20)}...)`);
    return token;
  } else {
    console.error(`[auth] ❌ 구글 OAuth2 회원가입/로그인 실패: ${res.status} - ${res.body}`);
    return null;
  }
}
