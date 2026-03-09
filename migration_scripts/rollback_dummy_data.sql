-- ==========================================
-- 부하 테스트 더미 데이터 순차 롤백 (FK 제약 고려)
-- 용도: K6 부하 테스트로 삽입된 데이터를 롤백 시, 부모 참조(posts)
--       삭제 에러(Foreign Key Violation)를 피하기 위한 자식 테이블 선행 삭제 쿼리
-- 실행 대상: V1 또는 V2 DB 환경 (부하 테스트 종료 후)
-- ==========================================

-- 식별자: '마이그레이션 부하 테스트%' (LIKE 매칭)

BEGIN;

-- 1. 자식 테이블 (comments, likes, post_tags) 행부터 삭제
DELETE FROM comments WHERE post_id IN (SELECT id FROM posts WHERE title LIKE '마이그레이션 부하 테스트%');
DELETE FROM likes WHERE post_id IN (SELECT id FROM posts WHERE title LIKE '마이그레이션 부하 테스트%');
DELETE FROM post_tags WHERE post_id IN (SELECT id FROM posts WHERE title LIKE '마이그레이션 부하 테스트%');

-- 2. 최상단 부모 테이블 (posts) 행 삭제
DELETE FROM posts WHERE title LIKE '마이그레이션 부하 테스트%';

COMMIT;

\echo '✅ 부하 테스트 더미 데이터 롤백 완료 (FK 관계 우회)'
