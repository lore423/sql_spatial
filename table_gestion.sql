--DROP TABLE metadata.data_migration;

CREATE TABLE metadata.data_migration
(
    id serial,
    schemaname name,
    nom name,
    type text COLLATE pg_catalog."default",
    database text COLLATE pg_catalog."default",
    to_migrate boolean,
	migrated boolean,
    comments text COLLATE pg_catalog."default"
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE metadata.data_migration
    OWNER to sdi_user2;

GRANT ALL ON TABLE metadata.data_migration TO "lorena.posada";

GRANT ALL ON TABLE metadata.data_migration TO sdi_user2;