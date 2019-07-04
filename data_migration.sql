DROP TABLE metadata.data_migration;
CREATE TABLE metadata.data_migration AS
SELECT row_number() OVER () AS id,
    foo.schemaname,
	foo.nom,
	foo.type,
	'prospection'::text AS database
      FROM ( SELECT schemaname, 
					viewname AS nom,
					'view' AS type
                  FROM pg_catalog.pg_views
                UNION
                 SELECT schemaname, 
						tablename AS nom,
						'table' AS type
				  FROM pg_catalog.pg_tables
				UNION
			     SELECT schemaname, 
						matviewname AS nom,
						'materialized view' AS type
				FROM pg_catalog.pg_matviews) AS foo
		ORDER BY schemaname, nom ASC;

ALTER TABLE metadata.data_migration ADD COLUMN to_migrate BOOLEAN;