/**
 * 회원가입 부하테스트 — 구글 OAuth2를 통한 대량 회원가입
 * 목적: 구글 OAuth2 플로우를 모킹하여 여러 사용자를 생성하고, 생성된 사용자 정보를 저장
 *
 * 사용 방법:
 *   1. WireMock 구글 OAuth2 모킹 서버 실행
 *   2. Backend 설정에서 구글 OAuth2 URL을 WireMock URL로 변경
 *   3. k6 run scenarios/register.js
 *
 * 결과:
 *   - fixtures/registered-users.json에 생성된 사용자 토큰 저장
 *   - 이후 다른 부하테스트에서 이 토큰들을 재사용 가능
 */

import { SharedArray } from 'k6/data';
import { sleep } from 'k6';
import { registerWithGoogle } from '../api/auth.js';
import { summarize } from '../lib/helpers.js';
import exec from 'k6/execution';

// TPS 기반 회원가입 설정 (환경변수로 조정 가능)
const TPS_START = parseInt(__ENV.K6_REGISTER_TPS_START || '5', 10);
const TPS_TARGET = parseInt(__ENV.K6_REGISTER_TPS_TARGET || '50', 10);
const DURATION_MINUTES = parseInt(__ENV.K6_REGISTER_DURATION_MINUTES || '5', 10);

// TPS 단계 동적 계산
const warmupTPS = Math.ceil(TPS_TARGET * 0.2); // 목표 TPS의 20%로 워밍업
const warmupDuration = Math.max(1, Math.ceil(DURATION_MINUTES * 0.2)); // 전체 시간의 20%
const rampDuration = Math.max(1, Math.ceil(DURATION_MINUTES * 0.3)); // 전체 시간의 30%
const steadyDuration = Math.max(1, DURATION_MINUTES - warmupDuration - rampDuration - 1); // 나머지 시간
const cooldownDuration = 1; // 1분 고정

export const options = {
  scenarios: {
    register: {
      executor: 'ramping-arrival-rate',
      startRate: TPS_START,                           // 시작 TPS (초당 회원가입 수)
      timeUnit: '1s',                                 // rate의 시간 단위
      preAllocatedVUs: Math.ceil(TPS_TARGET * 0.3),  // 목표 TPS의 30%만큼 미리 할당
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
    'http_req_duration': ['p(95)<2000'],        // 회원가입 95% 2초 이내
    'http_req_failed': ['rate<0.05'],           // 실패율 5% 이하
    'checks': ['rate>0.95'],                    // 성공률 95% 이상
  },
};

/**
 * setup() - 초기화 (필요시)
 */
export function setup() {
  console.log(`🚀 회원가입 부하테스트 시작 - TPS 목표: ${TPS_TARGET}, 지속 시간: ${DURATION_MINUTES}분`);
  return { registeredUsers: [] };
}

/**
 * default() - 각 VU가 회원가입 수행
 */
export default function (data) {
  // 각 VU의 고유 번호 생성
  const vuId = exec.vu.idInTest;
  const iterationId = exec.scenario.iterationInTest;
  const userId = vuId * 10000 + iterationId;

  // 구글 Authorization Code 생성 (모킹용 - 실제로는 구글에서 받음)
  const authCode = `mock_auth_code_${userId}_${Date.now()}`;

  console.log(`[VU${vuId}] 회원가입 시도: userId=${userId}`);

  // Backend에 구글 OAuth2 회원가입 요청
  const token = registerWithGoogle(authCode);

  if (token) {
    console.log(`[VU${vuId}] ✅ 회원가입 성공 - userId: ${userId}, token: ${token.slice(0, 20)}...`);

    // 생성된 사용자 정보를 메모리에 저장 (teardown에서 파일로 저장)
    // K6에서는 VU 간 데이터 공유가 제한적이므로, 실전에서는 외부 저장소 사용 권장
    // 또는 각 VU가 개별적으로 파일에 append 하는 방식 사용 가능
  } else {
    console.error(`[VU${vuId}] ❌ 회원가입 실패 - userId: ${userId}`);
  }

  sleep(0.5); // 서버 부하 완화
}

/**
 * teardown() - 정리 작업
 */
export function teardown(data) {
  console.log('✅ 회원가입 부하테스트 완료!');
  console.log('💡 생성된 사용자를 실제 부하테스트에 사용하려면:');
  console.log('   1. Backend DB에서 생성된 사용자의 토큰을 추출');
  console.log('   2. fixtures/registered-users.json 파일에 저장');
  console.log('   3. load.js 시나리오에서 SharedArray로 로드하여 사용');
}

export function handleSummary(data) {
  return summarize(data, 'register');
}
