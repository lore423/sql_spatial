CREATE OR REPLACE VIEW referentiel_national.v_admin_info AS
 SELECT a.ogc_fid,
    a.wkb_geometry,
    a.insee_com,
    a.nom_com,
    a.insee_dep,
    a.nom_dep,
    a.insee_reg,
    a.nom_reg,
    a.nom_com_m,
    b.code_epci,
    b.nom_epci,
    b.type_epci
   FROM referentiel_national.ign_admin_express__communes a
     LEFT JOIN referentiel_national.ign_admin_express__epci b ON a.code_epci::text = b.code_epci::text;

ALTER TABLE referentiel_national.v_admin_info
    OWNER TO sdi_user2;

GRANT ALL ON TABLE referentiel_national.v_admin_info TO PUBLIC;
GRANT ALL ON TABLE referentiel_national.v_admin_info TO sdi_user2;