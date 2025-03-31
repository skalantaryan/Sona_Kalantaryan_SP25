--2
CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1,(10^7)::int) x;


SELECT *, pg_size_pretty(total_bytes) AS total,
                 pg_size_pretty(index_bytes) AS INDEX,
                 pg_size_pretty(toast_bytes) AS toast,
                 pg_size_pretty(table_bytes) AS TABLE
FROM ( 
        SELECT *, total_bytes - index_bytes - COALESCE(toast_bytes, 0) AS table_bytes
        FROM (
            SELECT c.oid, nspname AS table_schema, relname AS TABLE_NAME,
                   c.reltuples AS row_estimate,
                   pg_total_relation_size(c.oid) AS total_bytes,
                   pg_indexes_size(c.oid) AS index_bytes,
                   pg_total_relation_size(reltoastrelid) AS toast_bytes
            FROM pg_class c
            LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE relkind = 'r'
        ) a
) a
WHERE table_name LIKE '%table_to_delete%';


DELETE FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0;


EXPLAIN ANALYZE
DELETE FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0;


SELECT *, pg_size_pretty(total_bytes) AS total,
                 pg_size_pretty(index_bytes) AS INDEX,
                 pg_size_pretty(toast_bytes) AS toast,
                 pg_size_pretty(table_bytes) AS TABLE
FROM ( 
        SELECT *, total_bytes - index_bytes - COALESCE(toast_bytes, 0) AS table_bytes
        FROM (
            SELECT c.oid, nspname AS table_schema, relname AS TABLE_NAME,
                   c.reltuples AS row_estimate,
                   pg_total_relation_size(c.oid) AS total_bytes,
                   pg_indexes_size(c.oid) AS index_bytes,
                   pg_total_relation_size(reltoastrelid) AS toast_bytes
            FROM pg_class c
            LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE relkind = 'r'
        ) a
) a
WHERE table_name LIKE '%table_to_delete%';


VACUUM FULL VERBOSE table_to_delete;


SELECT *, pg_size_pretty(total_bytes) AS total,
                 pg_size_pretty(index_bytes) AS INDEX,
                 pg_size_pretty(toast_bytes) AS toast,
                 pg_size_pretty(table_bytes) AS TABLE
FROM ( 
        SELECT *, total_bytes - index_bytes - COALESCE(toast_bytes, 0) AS table_bytes
        FROM (
            SELECT c.oid, nspname AS table_schema, relname AS TABLE_NAME,
                   c.reltuples AS row_estimate,
                   pg_total_relation_size(c.oid) AS total_bytes,
                   pg_indexes_size(c.oid) AS index_bytes,
                   pg_total_relation_size(reltoastrelid) AS toast_bytes
            FROM pg_class c
            LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE relkind = 'r'
        ) a
) a
WHERE table_name LIKE '%table_to_delete%';


DROP TABLE table_to_delete;
CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1,(10^7)::int) x;



TRUNCATE table_to_delete;


SELECT *, pg_size_pretty(total_bytes) AS total,
                 pg_size_pretty(index_bytes) AS INDEX,
                 pg_size_pretty(toast_bytes) AS toast,
                 pg_size_pretty(table_bytes) AS TABLE
FROM ( 
        SELECT *, total_bytes - index_bytes - COALESCE(toast_bytes, 0) AS table_bytes
        FROM (
            SELECT c.oid, nspname AS table_schema, relname AS TABLE_NAME,
                   c.reltuples AS row_estimate,
                   pg_total_relation_size(c.oid) AS total_bytes,
                   pg_indexes_size(c.oid) AS index_bytes,
                   pg_total_relation_size(reltoastrelid) AS toast_bytes
            FROM pg_class c
            LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE relkind = 'r'
        ) a
) a
WHERE table_name LIKE '%table_to_delete%';



/*
Before DELETE Operation:
Table size: 8192 bytes (8KB)
No indexes or TOAST data.

After DELETE Operation:
Table size: 8192 bytes (8 KB)
Index size: 0 bytes
TOAST size: 0 bytes

After VACUUM FULL
Table size: 8192 bytes (8 KB)
Index size: 0 bytes
TOAST size: 0 bytes

After TRUNCATE 
Table size: 8192 bytes (8 KB)
Index size: 0 bytes (No indexes)
TOAST size: 0 bytes (No TOAST data)
*/
