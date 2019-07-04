SELECT schemaname, tablename, tableowner, tablespace, hasindexes, hasrules, hastriggers, rowsecurity
	FROM pg_catalog.pg_tables WHERE tablename LIKE 'zone_%';