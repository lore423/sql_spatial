CREATE OR REPLACE VIEW gestion_fonciere.v_projets AS
 SELECT
	 nom, 
	 description, 
	 lien_doc, 
	 type_projet, 
	 id, 
	 statuts_projet, 
	 code, 
	 id_charge_projet, 
	 retenu, 
	 wkb_geometry, 
	 zone_etude, 
	 zone_projet, 
	 stade_avancement, 
	 x_l93, 
	 y_l93
	FROM gestion_fonciere.projets;

ALTER TABLE gestion_fonciere.v_projets
    OWNER TO sdi_user2;

GRANT ALL ON TABLE gestion_fonciere.v_projets TO bernd;
GRANT ALL ON TABLE gestion_fonciere.v_projets TO sdi_ser2;
GRANT ALL ON TABLE gestion_fonciere.v_projets TO projectmanager;
GRANT ALL ON TABLE gestion_fonciere.v_projets TO scouting;


CREATE OR REPLACE RULE v_projets_update AS
    ON UPDATE TO gestion_fonciere.v_projets
    DO INSTEAD
UPDATE gestion_fonciere.projets SET  nom = new.nom, description = new.description, lien_doc = new.lien_doc, type_projet = new.type_projet, id = new.id, statuts_projet = new.statuts_projet, code = new.code, id_charge_projet = new.id_charge_projet, retenu = new.retenu, wkb_geometry = new.wkb_geometry, zone_etude = new.zone_etude, zone_projet = new.zone_projet, stade_avancement = new.stade_avancement, x_l93 = new.x_l93, y_l93 = new.y_l93 
  WHERE projets.id = old.id;