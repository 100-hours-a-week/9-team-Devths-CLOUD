import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
    stages: [
        { duration: '2m', target: 5 },
        { duration: '5m', target: 20 },
        { duration: '999m', target: 20 },
    ],
    thresholds: {
        http_req_failed: ['rate<0.01'],
    },
};

const BASE_URL = __ENV.BASE_URL || 'https://api.devths.com';
const TOKEN = __ENV.TOKEN || '';

export default function () {
    const params = {
        headers: {
            Authorization: `Bearer ${TOKEN}`,
            'Content-Type': 'application/json',
        },
    };

    // 1. GET 요청 검증
    const getRes = http.get(`${BASE_URL}/api/posts?size=10`, params);
    check(getRes, {
        'GET status is 200': (r) => r.status === 200,
    });

    const payload = JSON.stringify({
        title: `마이그레이션 부하 테스트 VU${__VU}-#${__ITER}`,
        content: `무중단 마이그레이션 중 WRITE 요청 유실 및 시퀀스 충돌 여부 확인 [VU:${__VU}, ITER:${__ITER}, TIME:${Date.now()}]`,
    });

    const postRes = http.post(`${BASE_URL}/api/posts`, payload, params);
    check(postRes, {
        'POST status is 201': (r) => r.status === 201,
    });

    sleep(1);
}
