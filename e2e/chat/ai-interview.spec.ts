import { test, expect } from '@playwright/test';

test.describe('AI Mock Interview Process (Real API)', () => {
    // 실제 API 통신과 AI 생성이 포함되므로 타임아웃을 넉넉하게 설정 (5분)
    test.setTimeout(300 * 1000);

    test('should allow user to create interview, analyze, and complete session with real data', async ({ page }) => {
        // =========================================================================
        // 1. 로그인 및 페이지 이동
        // =========================================================================
        // 전제: Playwright 설정(auth.json 등)을 통해 이미 로그인이 되어 있거나,
        // 테스트 실행 전 로그인 세션이 주입되어야 합니다.
        // 로그인 로직이 필요하다면 여기에 추가해야 합니다.

        await page.goto('/llm');

        // =========================================================================
        // 2. 새 면접 시작 및 정보 입력
        // =========================================================================
        // LlmRoomCreateCard 컴포넌트의 텍스트는 "새 대화 시작" 임
        // Link 컴포넌트(next/link)는 a 태그로 렌더링되므로 role="link" 사용 가능
        await page.getByRole('link', { name: '새 대화 시작' }).click();

        // 실제 테스트 데이터 입력
        const resumeText = `
        [이력서]
        이름: 홍길동
        직무: 백엔드 개발자
        기술 스택: Java, Spring Boot, MySQL, AWS, Docker
        경력:
        - ABC 테크 (2022.01 ~ 현재): 백엔드 엔지니어
          - MSA 기반 쇼핑몰 프로젝트 구축
          - Kafka를 이용한 이벤트 기반 아키텍처 도입
        - XYZ 솔루션 (2020.01 ~ 2021.12): 웹 개발자
          - 사내 ERP 시스템 유지보수
        `;

        const jobPostingText = `
        [채용 공고]
        포지션: 백엔드 개발자 (3년 이상)
        주요 업무:
        - 대규모 트래픽 처리를 위한 서버 설계 및 개발
        - AWS 기반 인프라 운영
        자격 요건:
        - Java, Spring Boot 숙련자
        - RDBMS 및 NoSQL 경험자
        - RESTful API 설계 역량 보유
        우대 사항:
        - MSA 및 Event-Driven Architecture 경험
        `;

        await page.getByPlaceholder('이력서/포트폴리오 내용을 붙여 넣거나 직접 입력하세요.').fill(resumeText);
        await page.getByPlaceholder('채용 공고 내용을 붙여 넣거나 직접 입력하세요.').fill(jobPostingText);

        // =========================================================================
        // 3. 종합 분석 요청 및 대기
        // =========================================================================
        const analyzeButton = page.getByRole('button', { name: '종합 분석하기' });
        await expect(analyzeButton).toBeEnabled();
        await analyzeButton.click();

        // 201 Created 응답 확인 (채팅방 생성)
        // const roomResponse = await page.waitForResponse(response => 
        //     response.url().includes('/api/ai-chatrooms') && response.status() === 201
        // );

        // 분석 시작 확인 (UI 로딩 상태)
        await expect(page.getByText('분석이 진행 중입니다')).toBeVisible();

        // Task Polling 완료 대기
        // 실제 API가 호출되는 것을 기다림 (완료될 때까지)
        // 200 OK 응답이 오면 분석이 완료된 것으로 간주 (taskId polling)
        await page.waitForResponse(async response => {
            // URL이 task polling API이고, status가 200(완료)이면서 body에 COMPLETED가 있는지 체크
            if (response.url().includes('/api/ai/tasks/') && response.status() === 200) {
                const body = await response.json();
                return body.status === 'COMPLETED';
            }
            return false;
        }, { timeout: 180000 }); // 최대 3분 대기

        console.log('Analysis task completed.');

        // 채팅 목록 페이지로 리다이렉트 확인
        await page.waitForURL(/\/llm$/, { timeout: 30000 });

        // =========================================================================
        // 4. 알림 확인 및 입장
        // =========================================================================
        // 알림 API 호출 확인 (선택 사항)
        // await page.waitForResponse(response => response.url().includes('/api/notifications/unread') && response.status() === 200);

        // 목록에서 방금 생성된 채팅방 클릭 (최상단) -> TestId 또는 role로 더 구체적으로 선택
        // 단순히 href로 찾으면 네비게이션바의 링크 등 엉뚱한 곳을 클릭할 수 있음.
        // 여기서는 가장 최근 생성된(최상단) 리스트 아이템 내부의 버튼/링크를 클릭하도록 수정
        // 만약 LlmRoomListItem 컴포넌트가 <button>이나 <a>로 구현되어 있다면,
        // 리스트 컨테이너(LlmRoomList) 내부의 첫 번째 요소를 찾는 것이 안전함.

        // 예: 텍스트로 찾거나, 특정 class/testid 사용
        // 여기서는 'AI 분석' 이라는 텍스트가 포함된 요소를 찾되, 리스트 영역 내에서 찾음.
        const roomList = page.locator('main .flex.flex-col.gap-4'); // LlmRoomList 컨테이너 추정 클래스
        await roomList.locator('button, a').first().click();

        // 분석 완료 메시지 확인
        // 실제 FE 코드(Server to UI message mapping)를 보면, 
        // 시스템 메시지나 첫 AI 메시지를 기다려야 함.
        // 현재 V1 기준 '이력서 및 포트폴리오 분석 결과' 텍스트가 뜸.
        await expect(page.getByText(/이력서 및 포트폴리오 분석 결과/)).toBeVisible({ timeout: 20000 });

        // =========================================================================
        // 5. 면접 모드 진행 (기술 면접)
        // =========================================================================
        await page.getByRole('button', { name: '면접 모드 시작' }).click();
        await page.getByRole('button', { name: '기술 면접' }).click();

        // 총 5회 질문 답변 반복
        for (let i = 1; i <= 5; i++) {
            console.log(`Round ${i}: Waiting for question...`);

            // 질문 생성 완료 대기 (AI 메시지가 스트리밍으로 옴)
            // UI 상 "질문 N/5" 뱃지가 업데이트 되는 것을 기다림 (가장 확실)
            // LlmChatPage.tsx: 질문 {interviewSession.questionCount}/{MAX_QUESTIONS}
            await expect(page.getByText(`질문 ${i}/5`)).toBeVisible({ timeout: 120000 });

            // 답변 입력
            const answer = `이것은 ${i}번째 답변입니다. 실제 AI 면접 테스트 중입니다.`;
            await page.getByPlaceholder('메시지를 입력하세요').fill(answer);
            await page.getByLabel('전송').click(); // aria-label="전송" 사용

            // 내 메시지가 전송 완료될 때까지 대기
            // (전송 중 상태가 사라지는지 확인)
            await expect(page.getByText(answer)).toBeVisible();
        }

        // =========================================================================
        // 6. 면접 종료 및 평가
        // =========================================================================
        console.log('Interview loop finished. Waiting for completion notice...');

        // 5회 답변 후 자동 종료 로직이 있음 (LlmChatPage.tsx: setTimeout -> handleEndInterview)
        // "면접이 종료되었습니다. 답변 평가를 시작합니다." 텍스트 대기
        await expect(page.getByText('면접이 종료되었습니다.')).toBeVisible({ timeout: 60000 });

        console.log('Waiting for evaluation report...');

        // 평가 리포트 대기 (스트리밍)
        // 평가 완료 시 "면접 종료" 상태로 바뀜
        // 평가 텍스트가 올라오는 것을 확인
        await expect(page.locator('div', { hasText: /평가|피드백|강점|약점/ }).last()).toBeVisible({ timeout: 180000 });

        console.log('E2E Test Passed with Real API interactions.');
    });
});
