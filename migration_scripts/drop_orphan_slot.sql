-- ==========================================
-- 논리 복제 고아 슬롯(Orphan Slot) 수동 파기
-- 용도: V2 Subscription 삭제 후 V1 Publisher에 남은 슬롯으로 인한
--       WAL 디스크 급증 및 새로운 복제 채널 방해 해결용
-- ==========================================

-- 1. 활성화되지 않은 (active = false) 복제 슬롯 현황 조회
SELECT slot_name, plugin, slot_type, active 
FROM pg_replication_slots 
WHERE active = false;

-- 2. 대상 슬롯명(예: devths_sub_old)을 파기하여 WAL 누적 해제
-- 아래 줄의 'devths_sub_old' 문자열을 실제 pg_replication_slots 에 남은 slot_name으로 교체
SELECT pg_drop_replication_slot('devths_sub_old');

\echo '✅ 고아 복제 슬롯 해제 요청이 전송되었습니다.'
