/**
 * 환경별 설정
 *
 * 환경변수:
 *   K6_ENV          : local | dev | staging | prod  (기본: staging)
 *   K6_AUTH_TOKEN   : 미리 발급된 JWT
 *   K6_TEST_EMAIL   : 테스트 계정 이메일
 *
 *   K6_DEV_BASE_URL     : Dev 환경 Base URL (기본: https://dev.api.devths.com)
 *   K6_DEV_HEALTH_PATH  : Dev 환경 Health 경로 (기본: /actuator/health)
 *   K6_STAGING_BASE_URL : Staging 환경 Base URL (기본: https://stg.api.devths.com)
 *   K6_STAGING_HEALTH_PATH: Staging 환경 Health 경로 (기본: /actuator/health)
 *   K6_PROD_BASE_URL    : Prod 환경 Base URL (기본: https://api.devths.com)
 *   K6_PROD_HEALTH_PATH : Prod 환경 Health 경로 (기본: /actuator/health)
 */

const ENV = __ENV.K6_ENV || 'staging';

const configs = {
  local: {
    baseUrl: __ENV.K6_DEV_BASE_URL || 'http://localhost:8080',
    aiBaseUrl: __ENV.K6_DEV_AI_BASE_URL || 'http://localhost:3000',
    healthPath: __ENV.K6_DEV_HEALTH_PATH || '/actuator/health',
  },
  dev: {
    baseUrl: __ENV.K6_DEV_BASE_URL || 'https://dev.api.devths.com',
    aiBaseUrl: __ENV.K6_DEV_AI_BASE_URL || 'https://dev.ai.devths.com',
    healthPath: __ENV.K6_DEV_HEALTH_PATH || '/actuator/health',
  },
  staging: {
    baseUrl: __ENV.K6_STAGING_BASE_URL || 'https://stg.api.devths.com',
    aiBaseUrl: __ENV.K6_STAGING_AI_BASE_URL || 'https://stg.ai.devths.com',
    healthPath: __ENV.K6_STAGING_HEALTH_PATH || '/actuator/health',
  },
  prod: {
    baseUrl: __ENV.K6_PROD_BASE_URL || 'https://api.devths.com',
    aiBaseUrl: __ENV.K6_PROD_AI_BASE_URL || 'https://ai.devths.com',
    healthPath: __ENV.K6_PROD_HEALTH_PATH || '/actuator/health',
  },
};

if (!configs[ENV]) {
  throw new Error(`Unknown K6_ENV: "${ENV}". Use local | dev | staging | prod`);
}

export const BASE_URL = configs[ENV].baseUrl;
export const AI_BASE_URL = configs[ENV].aiBaseUrl;
export const HEALTH_PATH = configs[ENV].healthPath;
export const CURRENT_ENV = ENV;

/**
 * 공통 HTTP 헤더
 * @param {boolean} withAuth - Authorization 헤더 포함 여부
 * @param {string}  token    - Bearer 토큰 (withAuth=true일 때 사용)
 */
export function headers(withAuth = false, token = '') {
  const base = {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  };
  if (withAuth && token) {
    base['Authorization'] = `Bearer ${token}`;
  }
  return base;
}

/**
 * SLO 기준 thresholds
 * 각 시나리오 파일에서 spread하여 사용
 */
export const thresholds = {
  http_req_duration: ['p(95)<1000', 'p(99)<3000'],
  http_req_failed: ['rate<0.01'],
};

/**
 * 스파이크 시나리오용 완화 thresholds
 * (ALB + ASG Scale-Out 반응 시간 고려)
 */
export const spikeThresholds = {
  http_req_duration: ['p(95)<3000', 'p(99)<10000'],
  http_req_failed: ['rate<0.05'],
};
