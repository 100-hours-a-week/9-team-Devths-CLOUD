/**
 * 공통 헬퍼 함수
 * - HTTP 결과 체크 & 메트릭 기록
 * - 테스트 완료 요약 출력
 */

import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';
import { CURRENT_ENV } from './config.js';

// ─── 커스텀 메트릭 (전역 싱글톤) ────────────────────────────────
export const metrics = {
  errorRate: new Rate('custom_error_rate'),
  apiLatency: new Trend('custom_api_latency', true),
  totalRequests: new Counter('custom_total_requests'),
};

/**
 * HTTP 응답 결과를 체크하고 커스텀 메트릭에 기록합니다.
 *
 * @param {object} res        - k6 http 응답 객체
 * @param {string} label      - 로그 및 check 이름
 * @param {object} [checks]   - 추가 체크 조건 ({ 'label': (r) => boolean })
 */
export function record(res, label, checks = {}) {
  metrics.totalRequests.add(1);
  metrics.apiLatency.add(res.timings.duration);

  const defaultChecks = {
    [`${label}: status 2xx`]: (r) => r.status >= 200 && r.status < 300,
    [`${label}: duration < 2s`]: (r) => r.timings.duration < 2000,
  };

  const ok = check(res, { ...defaultChecks, ...checks });
  metrics.errorRate.add(!ok);

  if (!ok) {
    const bodyPreview = typeof res.body === 'string'
      ? res.body.slice(0, 240).replace(/\s+/g, ' ')
      : '';

    console.error(
      `[FAIL] ${label} | status=${res.status} | ${res.timings.duration.toFixed(0)}ms | ${res.url} | body=${bodyPreview}`
    );
  }

  return ok;
}

/**
 * handleSummary 전용 요약 출력 함수
 * 각 시나리오에서 export function handleSummary(data) { return summarize(data); } 로 사용
 *
 * @param {object} data     - k6 summary data
 * @param {string} scenario - 시나리오 이름
 */
export function summarize(data, scenario) {
  const httpDuration = data.metrics.http_req_duration?.values || {};
  const failRate = data.metrics.http_req_failed?.values?.rate ?? 0;
  const totalReqs = data.metrics.http_reqs?.values?.count ?? 0;
  const reqRate = data.metrics.http_reqs?.values?.rate ?? 0;

  // TPS (Transactions Per Second) 메트릭
  const iterations = data.metrics.iterations?.values || {};
  const totalIterations = iterations.count ?? 0;
  const avgTPS = iterations.rate ?? 0;

  // VU 메트릭
  const vus = data.metrics.vus?.values || {};
  const vusMax = vus.max ?? 0;

  const passed = failRate < 0.01;

  let output = '\n';
  output += '══════════════════════════════════════════════════════════\n';
  output += '  📊 Devths Backend TPS 기반 부하 테스트 결과\n';
  output += '══════════════════════════════════════════════════════════\n';
  output += `  환경           : ${CURRENT_ENV}\n`;
  output += `  시나리오       : ${scenario}\n`;
  output += `  총 트랜잭션 수 : ${totalIterations.toLocaleString()}\n`;
  output += `  평균 TPS       : ${avgTPS.toFixed(2)}\n`;
  output += `  총 요청 수     : ${totalReqs.toLocaleString()}\n`;
  output += `  평균 RPS       : ${reqRate.toFixed(2)}\n`;
  output += `  최대 VU 수     : ${vusMax}\n`;
  output += `  에러율         : ${(failRate * 100).toFixed(2)}%\n`;
  output += `  결과           : ${passed ? '✅ 성공' : '❌ 실패'}\n`;
  output += '══════════════════════════════════════════════════════════\n\n';

  // HTTP 전체 통계
  output += '🌐 HTTP 전체 통계\n';
  output += '──────────────────────────────────────────────────────────\n';
  output += `  평균(avg)   : ${(httpDuration.avg ?? 0).toFixed(2)}ms\n`;
  output += `  중앙값(med) : ${(httpDuration.med ?? 0).toFixed(2)}ms\n`;
  output += `  최소(min)   : ${(httpDuration.min ?? 0).toFixed(2)}ms\n`;
  output += `  최대(max)   : ${(httpDuration.max ?? 0).toFixed(2)}ms\n`;
  output += `  p90         : ${(httpDuration['p(90)'] ?? 0).toFixed(2)}ms\n`;
  output += `  p95         : ${(httpDuration['p(95)'] ?? 0).toFixed(2)}ms\n`;
  output += `  p99         : ${(httpDuration['p(99)'] ?? 0).toFixed(2)}ms\n`;
  output += '──────────────────────────────────────────────────────────\n\n';

  // 그룹별 통계
  const groups = {};
  for (const [metricName, metricData] of Object.entries(data.metrics)) {
    const groupMatch = metricName.match(/^group_duration\{group::(.+)\}$/);
    if (groupMatch && metricData.values) {
      groups[groupMatch[1]] = metricData.values;
    }
  }

  if (Object.keys(groups).length > 0) {
    output += '📦 API 그룹별 응답시간 (Duration)\n';
    output += '──────────────────────────────────────────────────────────\n';
    for (const [groupName, values] of Object.entries(groups)) {
      output += `\n  ${groupName}\n`;
      output += `    평균(avg)   : ${(values.avg ?? 0).toFixed(2)}ms\n`;
      output += `    중앙값(med) : ${(values.med ?? 0).toFixed(2)}ms\n`;
      output += `    p90         : ${(values['p(90)'] ?? 0).toFixed(2)}ms\n`;
      output += `    p95         : ${(values['p(95)'] ?? 0).toFixed(2)}ms\n`;
      output += `    p99         : ${(values['p(99)'] ?? 0).toFixed(2)}ms\n`;
    }
    output += '\n──────────────────────────────────────────────────────────\n\n';
  }

  // 커스텀 메트릭
  const customApiLatency = data.metrics.custom_api_latency?.values;
  const customErrorRate = data.metrics.custom_error_rate?.values?.rate;
  if (customApiLatency || customErrorRate != null) {
    output += '📈 커스텀 메트릭\n';
    output += '──────────────────────────────────────────────────────────\n';
    if (customApiLatency) {
      output += `  API 레이턴시 p95: ${(customApiLatency['p(95)'] ?? 0).toFixed(2)}ms\n`;
      output += `  API 레이턴시 p99: ${(customApiLatency['p(99)'] ?? 0).toFixed(2)}ms\n`;
    }
    if (customErrorRate != null) {
      output += `  커스텀 에러율   : ${(customErrorRate * 100).toFixed(2)}%\n`;
    }
    output += '──────────────────────────────────────────────────────────\n\n';
  }

  return { stdout: output };
}

/**
 * VU 간 랜덤 지연 (사용자 행동 패턴 모사)
 * @param {number} min - 최소 초 (기본 1)
 * @param {number} max - 최대 초 (기본 3)
 */
export function randomSleep(min = 1, max = 3) {
  sleep(min + Math.random() * (max - min));
}
