-- ==========================================
-- 마이그레이션 V2 RDS 스키마 복원 후 앱 유저 권한 인가 
-- 용도: V1 덤프(schema-only) 복원 시 이전 계정 소유권이 따라와서
--       V2 백엔드가 INSERT/UPDATE 시 권한 에러 방지 목적 
-- 실행 환경: V2 RDS rds_superuser 로그인
-- ==========================================

-- 스키마 사용 권한 부여
GRANT USAGE ON SCHEMA public TO devths;

-- 현재 존재하는 모든 테이블에 대해 DML(SELECT, INSERT, UPDATE, DELETE) 부여
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO devths;

-- 현재 존재하는 모든 시퀀스에 대해 USAGE, SELECT 부여 
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO devths;

-- 향후 새로 생성될 테이블/시퀀스에 대해서도 devths 계정 기본 권한 자동 부여
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO devths;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO devths;

\echo '✅ V2 DEVTHS 서비스 계정(devths) 테이블/시퀀스 접근 권한 인가 완료.'
