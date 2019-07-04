CREATE OR REPLACE VIEW foncier.v_parcelles_ep_grouped AS
 SELECT parc_ep.ogc_fid,
    parc_ep.ep_id,
    parc_ep.ep_nom,
    parc_ep.list_parcelles,
    p.id AS projet_id,
    p.code AS projet_code,
    p.nom AS projet_nom,
    parc_ep.wkb_geometry
   FROM gestion_fonciere.projets p,
    ( SELECT entite_proprietaire.id AS ogc_fid,
            entite_proprietaire.id AS ep_id,
            entite_proprietaire.nom AS ep_nom,
            entite_proprietaire.id_projet AS projet_id,
            array_to_string(array_agg(parcelles.id), ','::text) AS list_parcelles,
            st_collectionextract(st_collect(parcelles.wkb_geometry), 3)::geometry(MultiPolygon,2154) AS wkb_geometry
           FROM gestion_fonciere.entite_proprietaire,
            gestion_fonciere.parcelles
          WHERE parcelles.id_entite_proprietaire = entite_proprietaire.id
          GROUP BY entite_proprietaire.id, entite_proprietaire.nom, entite_proprietaire.id_projet) parc_ep
  WHERE parc_ep.projet_id = p.id
  ORDER BY parc_ep.ep_id;

ALTER TABLE foncier.v_parcelles_ep_grouped
    OWNER TO bernd;

GRANT SELECT ON TABLE foncier.v_parcelles_ep_grouped TO scouting;
GRANT SELECT ON TABLE foncier.v_parcelles_ep_grouped TO projectmanager;
GRANT SELECT ON TABLE foncier.v_parcelles_ep_grouped TO PUBLIC;
GRANT ALL ON TABLE foncier.v_parcelles_ep_grouped TO bernd;
