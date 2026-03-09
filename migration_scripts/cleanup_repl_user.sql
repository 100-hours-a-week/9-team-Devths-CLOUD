-- ==========================================
-- 마이그레이션 사후 정리: 복제 유저 완전 삭제
-- 용도: 단순 DROP USER 시 발생하는 객체 종속성(privileges/owners) 에러 방지
-- 실행 환경: V1 EC2 Postgres 관리자 계정 환경
-- ==========================================

-- 1. 테이블, 시퀀스, 스키마에 부여된 기존 권한 회수
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM repl_user;
REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM repl_user;
REVOKE ALL PRIVILEGES ON SCHEMA public FROM repl_user;

-- 2. 미래에 생성될 객체에 대한 기본 권한 회수 
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM repl_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON SEQUENCES FROM repl_user;

-- 3. 잔여 소유권을 안전한 postgres 계정으로 이관
REASSIGN OWNED BY repl_user TO postgres;
DROP OWNED BY repl_user;

-- 4. 최종 삭제 (종속성 해제 완료)
DROP USER repl_user;

\echo '✅ repl_user 복제 계정 및 권한 종속성 영구 삭제 완료.'
