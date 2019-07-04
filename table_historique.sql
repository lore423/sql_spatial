CREATE TABLE planification.poste_livraison_history (
  ogc_fid 		serial NOT NULL,
  id_projet     integer ,	
  wkb_geometry  geometry(Point,2154),
  created_date  timestamp with time zone,
  created_by    varchar(50),
  deleted_date  timestamp with time zone,
  deleted_by    varchar(50),
  hid           serial NOT NULL
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE planification.poste_livraison_history
    OWNER to sdi_user2;

GRANT ALL ON TABLE planification.poste_livraison_history TO "anissa.mahiddine";

GRANT ALL ON TABLE planification.poste_livraison_history TO "bernd.deckert";

GRANT ALL ON TABLE planification.poste_livraison_history TO "bjo.dec";

GRANT ALL ON TABLE planification.poste_livraison_history TO "julien.bequet";

GRANT ALL ON TABLE planification.poste_livraison_history TO "lorena.posada";

GRANT ALL ON TABLE planification.poste_livraison_history TO "nicolas.teyras";

GRANT SELECT ON TABLE planification.poste_livraison_history TO PUBLIC;

CREATE INDEX sidx_poste_livraison_history_wkb_geometry
    ON planification.poste_livraison_history USING gist
    (wkb_geometry)
    TABLESPACE pg_default;