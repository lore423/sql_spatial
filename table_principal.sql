CREATE TABLE planification.poste_livraison (
  ogc_fid 		serial NOT NULL,
  id_projet     integer ,	
  wkb_geometry  geometry(Point,2154)

)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE planification.poste_livraison
    OWNER to sdi_user2;

GRANT ALL ON TABLE planification.poste_livraison TO "anissa.mahiddine";

GRANT ALL ON TABLE planification.poste_livraison TO "bernd.deckert";

GRANT ALL ON TABLE planification.poste_livraison TO "bjo.dec";

GRANT ALL ON TABLE planification.poste_livraison TO "julien.bequet";

GRANT ALL ON TABLE planification.poste_livraison TO "lorena.posada";

GRANT ALL ON TABLE planification.poste_livraison TO "nicolas.teyras";

GRANT SELECT ON TABLE planification.poste_livraison TO PUBLIC;

CREATE INDEX sidx_poste_livraison_wkb_geometry
    ON planification.poste_livraison USING gist
    (wkb_geometry)
    TABLESPACE pg_default;