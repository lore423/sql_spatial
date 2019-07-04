-- View: foncier.v_ep_geo2af_full_info

DROP VIEW foncier.v_ep_geo2af_full_info CASCADE;

CREATE OR REPLACE VIEW foncier.v_ep_geo2af_full_info AS
 SELECT 
    row_number() OVER() AS ogc_fid, 
    a.ogc_fid AS ogc_fid_v_parcelles_signees_ep_grouped,
    a.ep_id,
    a.ep_nom,
    a.nb_parcelles AS nb_parcelles_signees,
    a.list_parcelles AS list_parcelles_signees,
    a.projet_id,
    a.projet_code,
    a.projet_nom,
    a.projet_statut,
    a.wkb_geometry,
    b.id AS id_af,
    b.nom_fichier,
    b.bail_de_fermage,
    b.type_accord,
    b.type_redevance,
    b.conditions_particulieres,
    b.date_effet,
    b.date_enregistrement,
    b.redevance,
    b.id_ep,
    b.id_projets,
    b.jours_restants_avant_prorog,
    b.statut_action,
    b.af_date_validite,
    b.nombre_avenant,
    b.avenant_fichiers,
    b.date_validite,
    b.date_limite_envoi_prorog,
    b.prorogation,
    b.prorog_date_fin,
    b.prorog_nom_fichier,
    b.jours_restants,
    b.lib_action
   FROM foncier.v_parcelles_signees_ep_grouped a
     LEFT JOIN gestion_fonciere.v_af_full_info b ON a.ep_id::text = b.id_ep::text;

ALTER TABLE foncier.v_ep_geo2af_full_info
    OWNER TO sdi_user2;

GRANT SELECT ON TABLE foncier.v_ep_geo2af_full_info TO PUBLIC;
GRANT ALL ON TABLE foncier.v_ep_geo2af_full_info TO sdi_user2;
