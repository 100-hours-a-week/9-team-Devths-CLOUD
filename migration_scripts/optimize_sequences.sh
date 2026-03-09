#!/bin/bash
# ==========================================
# Phase 6: 시퀀스 갭 최적화 자동화 스크립트
# 용도: 마이그레이션(Lag 0 및 컷오버 스위칭) 완료 직후, 
# 빈 테이블(0건)을 예외 처리하며 현재 데이터 MAX(id) 값에 
# 맞게 RDS 내의 모든 시퀀스를 정확히 1차이로 당겨줌.
# ==========================================

RDS_ENDPOINT="${RDS_ENDPOINT:-devths-v2-prod-rds.c304wce485et.ap-northeast-2.rds.amazonaws.com}"
DB_USER="${DB_USER:-devths}"
DB_NAME="${DB_NAME:-devths}"

echo "🚀 시퀀스 갭 2차 최적화 시작 (RDS: $RDS_ENDPOINT)"

PGPASSWORD=$PGPASSWORD psql -h "$RDS_ENDPOINT" -U "$DB_USER" -d "$DB_NAME" << 'EOF'

DO $$
DECLARE
    seq_record RECORD; max_val BIGINT; seq_query TEXT;
BEGIN
    FOR seq_record IN
        SELECT n.nspname AS schema_name, s.relname AS seq_name,
               t.relname AS table_name, a.attname AS col_name
        FROM pg_class s JOIN pg_namespace n ON n.oid = s.relnamespace
        JOIN pg_depend d ON d.objid = s.oid JOIN pg_class t ON t.oid = d.refobjid
        JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = d.refobjsubid
        WHERE s.relkind = 'S'
    LOOP
        seq_query := format('SELECT COALESCE(MAX(%I), 0) FROM %I.%I',
            seq_record.col_name, seq_record.schema_name, seq_record.table_name);
        EXECUTE seq_query INTO max_val;

        IF max_val = 0 THEN
            PERFORM setval(format('%I.%I', seq_record.schema_name, seq_record.seq_name), 1, false);
            RAISE NOTICE '✅ 빈 테이블 시퀀스 1로 초기화: %.%', seq_record.table_name, seq_record.col_name;
        ELSE
            PERFORM setval(format('%I.%I', seq_record.schema_name, seq_record.seq_name), max_val);
            RAISE NOTICE '✅ 시퀀스 갭 최적화 완료: %.% → %', seq_record.table_name, seq_record.col_name, max_val;
        END IF;
    END LOOP;
END $$;
EOF

echo "✨ 시퀀스 최적화 작업이 모두 완료되었습니다."
