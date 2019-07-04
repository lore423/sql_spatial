CREATE TABLE public.count_tables AS
SELECT
    table_schema as schema,
	table_name as table
FROM
    information_schema.tables
WHERE
    table_type = 'BASE TABLE'
AND
    table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY table_schema ASC;