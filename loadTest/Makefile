.PHONY: help health smoke load load-test stress spike soak write-heavy dms-stress

# .env 파일에서 환경 변수 읽기
ifneq (,$(wildcard .env))
    include .env
    export
endif

# K6 실행 명령어 빌드 함수
define build_k6_cmd
	@set -a; \
	[ -f .env ] && . ./.env; \
	set +a; \
	k6 run \
		--quiet \
		$${K6_PROMETHEUS_RW_SERVER_URL:+--out experimental-prometheus-rw} \
		-e K6_ENV=$${K6_ENV:-staging} \
		$${K6_AUTH_TOKEN:+-e K6_AUTH_TOKEN=$$K6_AUTH_TOKEN} \
		$${K6_TEST_EMAIL:+-e K6_TEST_EMAIL=$$K6_TEST_EMAIL} \
		$${K6_TEST_PASSWORD:+-e K6_TEST_PASSWORD=$$K6_TEST_PASSWORD} \
		$${K6_TPS_START:+-e K6_TPS_START=$$K6_TPS_START} \
		$${K6_TPS_TARGET:+-e K6_TPS_TARGET=$$K6_TPS_TARGET} \
		$${K6_DURATION_MINUTES:+-e K6_DURATION_MINUTES=$$K6_DURATION_MINUTES} \
		$${K6_INITIAL_REGISTER_USER_COUNT:+-e K6_INITIAL_REGISTER_USER_COUNT=$$K6_INITIAL_REGISTER_USER_COUNT} \
		$${K6_REGISTER_USER_COUNT:+-e K6_REGISTER_USER_COUNT=$$K6_REGISTER_USER_COUNT} \
		$${K6_REGISTER_PROGRESS_LOG_STEP:+-e K6_REGISTER_PROGRESS_LOG_STEP=$$K6_REGISTER_PROGRESS_LOG_STEP} \
		$${K6_ENABLE_REGISTER_FLOW:+-e K6_ENABLE_REGISTER_FLOW=$$K6_ENABLE_REGISTER_FLOW} \
		$${K6_REGISTER_FLOW_RATE:+-e K6_REGISTER_FLOW_RATE=$$K6_REGISTER_FLOW_RATE} \
		$${K6_SEED_POST_COUNT:+-e K6_SEED_POST_COUNT=$$K6_SEED_POST_COUNT} \
		$${K6_ENABLE_POST_CREATE:+-e K6_ENABLE_POST_CREATE=$$K6_ENABLE_POST_CREATE} \
		$${K6_POST_CREATE_RATE:+-e K6_POST_CREATE_RATE=$$K6_POST_CREATE_RATE} \
		$${K6_ENABLE_POST_UPDATE:+-e K6_ENABLE_POST_UPDATE=$$K6_ENABLE_POST_UPDATE} \
		$${K6_POST_UPDATE_RATE:+-e K6_POST_UPDATE_RATE=$$K6_POST_UPDATE_RATE} \
		$${K6_POST_IMAGE_ATTACH_RATE:+-e K6_POST_IMAGE_ATTACH_RATE=$$K6_POST_IMAGE_ATTACH_RATE} \
		$${K6_KEEP_CREATED_POST:+-e K6_KEEP_CREATED_POST=$$K6_KEEP_CREATED_POST} \
		$${K6_ENABLE_HOT_POST_READ:+-e K6_ENABLE_HOT_POST_READ=$$K6_ENABLE_HOT_POST_READ} \
		$${K6_HOT_POST_ID:+-e K6_HOT_POST_ID=$$K6_HOT_POST_ID} \
		$${K6_HOT_POST_READ_REPEAT:+-e K6_HOT_POST_READ_REPEAT=$$K6_HOT_POST_READ_REPEAT} \
		$${K6_HOT_POST_STICKY_USER:+-e K6_HOT_POST_STICKY_USER=$$K6_HOT_POST_STICKY_USER} \
		$${K6_HOT_POST_READ_RATIO:+-e K6_HOT_POST_READ_RATIO=$$K6_HOT_POST_READ_RATIO} \
		$${K6_COLD_POST_READ_RATIO:+-e K6_COLD_POST_READ_RATIO=$$K6_COLD_POST_READ_RATIO} \
		$${K6_REQUESTS_PER_ITERATION:+-e K6_REQUESTS_PER_ITERATION=$$K6_REQUESTS_PER_ITERATION} \
		$${K6_GET_RATIO:+-e K6_GET_RATIO=$$K6_GET_RATIO} \
		$${K6_POST_RATIO:+-e K6_POST_RATIO=$$K6_POST_RATIO} \
		$${K6_GET_API_LIST:+-e K6_GET_API_LIST=$$K6_GET_API_LIST} \
		$${K6_POST_API_LIST:+-e K6_POST_API_LIST=$$K6_POST_API_LIST} \
		$${K6_ENABLE_POST_TAGS:+-e K6_ENABLE_POST_TAGS=$$K6_ENABLE_POST_TAGS} \
		$${K6_ENABLE_AI_CHAT:+-e K6_ENABLE_AI_CHAT=$$K6_ENABLE_AI_CHAT} \
		$${K6_AI_CHAT_RATE:+-e K6_AI_CHAT_RATE=$$K6_AI_CHAT_RATE} \
		$${K6_AI_MODEL:+-e K6_AI_MODEL=$$K6_AI_MODEL} \
		$${K6_KEEP_AI_CHATROOM:+-e K6_KEEP_AI_CHATROOM=$$K6_KEEP_AI_CHATROOM} \
		$${K6_ENABLE_WS_CHAT:+-e K6_ENABLE_WS_CHAT=$$K6_ENABLE_WS_CHAT} \
		$${K6_WS_CHAT_RATE:+-e K6_WS_CHAT_RATE=$$K6_WS_CHAT_RATE} \
		$${K6_WS_DURATION:+-e K6_WS_DURATION=$$K6_WS_DURATION} \
		$${K6_WS_MESSAGE_COUNT:+-e K6_WS_MESSAGE_COUNT=$$K6_WS_MESSAGE_COUNT} \
		$${K6_WS_MESSAGE_INTERVAL:+-e K6_WS_MESSAGE_INTERVAL=$$K6_WS_MESSAGE_INTERVAL} \
		$${K6_KEEP_WS_CHATROOM:+-e K6_KEEP_WS_CHATROOM=$$K6_KEEP_WS_CHATROOM} \
		$${K6_WS_USER_POOL_SIZE:+-e K6_WS_USER_POOL_SIZE=$$K6_WS_USER_POOL_SIZE} \
		$${K6_WS_CONNECT_TIMEOUT_MS:+-e K6_WS_CONNECT_TIMEOUT_MS=$$K6_WS_CONNECT_TIMEOUT_MS} \
		$${K6_WS_USE_SOCKJS:+-e K6_WS_USE_SOCKJS=$$K6_WS_USE_SOCKJS} \
		$${K6_DEV_BASE_URL:+-e K6_DEV_BASE_URL=$$K6_DEV_BASE_URL} \
		$${K6_DEV_AI_BASE_URL:+-e K6_DEV_AI_BASE_URL=$$K6_DEV_AI_BASE_URL} \
		$${K6_DEV_HEALTH_PATH:+-e K6_DEV_HEALTH_PATH=$$K6_DEV_HEALTH_PATH} \
		$${K6_STAGING_BASE_URL:+-e K6_STAGING_BASE_URL=$$K6_STAGING_BASE_URL} \
		$${K6_STAGING_AI_BASE_URL:+-e K6_STAGING_AI_BASE_URL=$$K6_STAGING_AI_BASE_URL} \
		$${K6_STAGING_HEALTH_PATH:+-e K6_STAGING_HEALTH_PATH=$$K6_STAGING_HEALTH_PATH} \
		$${K6_PROD_BASE_URL:+-e K6_PROD_BASE_URL=$$K6_PROD_BASE_URL} \
		$${K6_PROD_AI_BASE_URL:+-e K6_PROD_AI_BASE_URL=$$K6_PROD_AI_BASE_URL} \
		$${K6_PROD_HEALTH_PATH:+-e K6_PROD_HEALTH_PATH=$$K6_PROD_HEALTH_PATH} \
		$(1)
endef

help:
	@echo "Devths K6 Load Test Commands"
	@echo ""
	@echo "사용법: make <command>"
	@echo ""
	@echo "Commands:"
	@echo "  health      - 헬스체크 테스트 (인증 불필요)"
	@echo "  smoke       - 스모크 테스트 (1 VU, 1분)"
	@echo "  load        - 부하 테스트 (평균 부하)"
	@echo "  load-test   - 통합 테스트 (회원가입 + 게시글/댓글 + AI채팅 부하)"
	@echo "  stress      - 스트레스 테스트 (한계 테스트)"
	@echo "  spike       - 스파이크 테스트 (급격한 증가)"
	@echo "  soak        - 장시간 안정성 테스트"
	@echo "  write-heavy - 쓰기 집중 부하 테스트 (게시글/댓글 생성 중심)"
	@echo "  dms-stress  - DMS 스트레스 테스트 (쓰기+LLM 혼합, DB 안정성 검증)"
	@echo "  websocket   - WebSocket 채팅 부하 테스트 (실시간 연결 및 메시지 송수신)"
	@echo ""
	@echo "환경 설정: .env 파일 편집"

health:
	@echo "🚀 헬스체크 테스트..."
	$(call build_k6_cmd,scenarios/health-only.js)

smoke:
	@echo "🚀 스모크 테스트..."
	$(call build_k6_cmd,scenarios/smoke.js)

load:
	@echo "🚀 부하 테스트..."
	$(call build_k6_cmd,scenarios/load.js)

load-test:
	@echo "🚀 통합 테스트 (회원가입 + 게시글/댓글 + AI채팅 부하)..."
	$(call build_k6_cmd,scenarios/loadTest.js)

stress:
	@echo "🚀 스트레스 테스트..."
	$(call build_k6_cmd,scenarios/stress.js)

spike:
	@echo "🚀 스파이크 테스트..."
	$(call build_k6_cmd,scenarios/spike.js)

soak:
	@echo "🚀 장시간 안정성 테스트..."
	$(call build_k6_cmd,scenarios/soak.js)

write-heavy:
	@echo "🚀 쓰기 집중 부하 테스트..."
	$(call build_k6_cmd,scenarios/write-heavy.js)

dms-stress:
	@echo "🚀 DMS 스트레스 테스트..."
	$(call build_k6_cmd,scenarios/dms-stress.js)

websocket:
	@echo "🚀 WebSocket 채팅 부하 테스트..."
	$(call build_k6_cmd,scenarios/websocket-chat.js)
