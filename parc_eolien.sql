CREATE OR REPLACE VIEW planification.parcs_eol4atlas AS
SELECT ogc_fid, nb_eol, nb_eol_securisees, pct_securisation_parc, id_projet, wkb_geometry, id, nom, code, type_projet, charge_projet, stade_avancement, insee_com, nom_com, nom_com_m, statut, nom_dep, insee_dep, nom_reg, insee_reg, code_epci, population, nom_epci, type_epci
	FROM planification.parcs_eol4atlas;
	
 gestion_fonciere.v_projets2admin_info info
  WHERE parcs.id_projet = info.id;

ALTER TABLE planification.parcs_eol4atlas
    OWNER TO "bjo.dec";

GRANT ALL ON TABLE planification.parcs_eol4atlas TO "bjo.dec";
GRANT SELECT ON TABLE planification.parcs_eol4atlas TO PUBLIC;