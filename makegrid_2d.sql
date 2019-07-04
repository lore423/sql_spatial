--Fonction makegrid_2d
CREATE OR REPLACE FUNCTION public.makegrid_2d (
  bound_polygon public.geometry,
  width_step integer,
  height_step integer
)
RETURNS public.geometry AS
$body$
DECLARE
  Xmin DOUBLE PRECISION;
  Xmax DOUBLE PRECISION;
  Ymax DOUBLE PRECISION;
  X DOUBLE PRECISION;
  Y DOUBLE PRECISION;
  NextX DOUBLE PRECISION;
  NextY DOUBLE PRECISION;
  CPoint public.geometry;
  sectors public.geometry[];
  i INTEGER;
  SRID INTEGER;
BEGIN
  Xmin := ST_XMin(bound_polygon);
  Xmax := ST_XMax(bound_polygon);
  Ymax := ST_YMax(bound_polygon);
  SRID := ST_SRID(bound_polygon);

  Y := ST_YMin(bound_polygon); --current sector's corner coordinate
  i := -1;
  <<yloop>>
  LOOP
    IF (Y > Ymax) THEN  
        EXIT;
    END IF;

    X := Xmin;
    <<xloop>>
    LOOP
      IF (X > Xmax) THEN
          EXIT;
      END IF;

      CPoint := ST_SetSRID(ST_MakePoint(X, Y), SRID);
      NextX := ST_X(ST_Project(CPoint, $2, radians(90))::geometry);
      NextY := ST_Y(ST_Project(CPoint, $3, radians(0))::geometry);

      i := i + 1;
      sectors[i] := ST_MakeEnvelope(X, Y, NextX, NextY, SRID);

      X := NextX;
    END LOOP xloop;
    CPoint := ST_SetSRID(ST_MakePoint(X, Y), SRID);
    NextY := ST_Y(ST_Project(CPoint, $3, radians(0))::geometry);
    Y := NextY;
  END LOOP yloop;

  RETURN ST_Collect(sectors);
END;
$body$
LANGUAGE 'plpgsql';						 

							
-- Subdivide le polygone dans un grille de 3000 x 3000 - couche: entités propietaires:ensemble de parcelles
DROP MATERIALIZED VIEW foncier.mv_parcelles_ep_grouped_grid2d;
CREATE MATERIALIZED VIEW foncier.mv_parcelles_ep_grouped_grid2d AS	
SELECT row_number() OVER () as ogc_fid, ep_id, ep_nom, projet_id, projet_code, projet_nom, list_parcelles, grid_geom AS wkb_geometry FROM 
	(					 
	SELECT  ep_id, ep_nom, projet_id, projet_code, projet_nom, list_parcelles, ep_geom, ST_Transform((a.grid_geom_wgs84).geom, 2154)::geometry(Polygon,2154) AS grid_geom FROM
		( 
			SELECT 
			ep_id, ep_nom, projet_id, projet_code, projet_nom, list_parcelles, 
			wkb_geometry AS ep_geom,
			ST_Dump(makegrid_2d(ST_Transform(ST_Buffer(wkb_geometry,1500),4326), 4275, 4275)) AS grid_geom_wgs84 
			FROM foncier.v_parcelles_ep_grouped
		) AS a					 
) AS foo
WHERE ST_Intersects(ST_Buffer(ep_geom,1), grid_geom);
									   
GRANT SELECT ON TABLE foncier.mv_parcelles_ep_grouped_grid2d TO PUBLIC;
GRANT ALL ON TABLE foncier.mv_parcelles_ep_grouped_grid2d TO sdi_user2;					 


CREATE UNIQUE INDEX uidx_mv_parcelles_ep_grouped_grid2d
    ON foncier.mv_parcelles_ep_grouped_grid2d USING btree
    (ogc_fid);
												 
--REFRESH MATERIALIZED VIEW CONCURRENTLY foncier.mv_parcelles_ep_grouped_grid2d;																					 
			
CREATE INDEX sidx_mv_parcelles_ep_grouped_grid2d
    ON foncier.mv_parcelles_ep_grouped_grid2d USING gist
    (wkb_geometry);
			
			
-- Subdivide le polygone dans un grille de 3000 x 3000 - couche: accords fonciers:écheances		
DROP MATERIALIZED VIEW foncier.mv_ep_geo2af_grid2d;
CREATE MATERIALIZED VIEW foncier.mv_ep_geo2af_grid2d AS	
SELECT row_number() OVER () as ogc_fid, ep_id, ep_nom, nb_parcelles_signees, list_parcelles_signees, projet_id, projet_nom, projet_statut, id_af, nom_fichier, bail_de_fermage, type_accord, type_redevance, conditions_particulieres, date_effet, 
			date_enregistrement,redevance, jours_restants_avant_prorog, statut_action, af_date_validite, nombre_avenant, date_validite, date_limite_envoi_prorog, prorogation, prorog_date_fin, prorog_nom_fichier,
			jours_restants, lib_action, grid_geom AS wkb_geometry FROM 
	(					 
	SELECT  ep_id, ep_nom, nb_parcelles_signees, list_parcelles_signees, projet_id, projet_nom, projet_statut, id_af, nom_fichier, bail_de_fermage, type_accord, type_redevance, conditions_particulieres, date_effet, 
			date_enregistrement,redevance, jours_restants_avant_prorog, statut_action, af_date_validite, nombre_avenant, date_validite, date_limite_envoi_prorog, prorogation, prorog_date_fin, prorog_nom_fichier,
			jours_restants, lib_action, ep_geom, ST_Transform((a.grid_geom_wgs84).geom, 2154)::geometry(Polygon,2154) AS grid_geom FROM
		( 
			SELECT 
			ep_id, ep_nom, nb_parcelles_signees, list_parcelles_signees, projet_id, projet_nom, projet_statut, id_af, nom_fichier, bail_de_fermage, type_accord, type_redevance, conditions_particulieres, date_effet, 
			date_enregistrement,redevance, jours_restants_avant_prorog, statut_action, af_date_validite, nombre_avenant, date_validite, date_limite_envoi_prorog, prorogation, prorog_date_fin, prorog_nom_fichier,
			jours_restants, lib_action,
			wkb_geometry AS ep_geom,
			ST_Dump(makegrid_2d(ST_Transform(ST_Buffer(wkb_geometry,1500),4326), 4275, 4275)) AS grid_geom_wgs84 
			FROM foncier.v_ep_geo2af
		) AS a					 
) AS foo
WHERE ST_Intersects(ST_Buffer(ep_geom,1), grid_geom);

GRANT SELECT ON TABLE foncier.mv_ep_geo2af_grid2d TO PUBLIC;
GRANT ALL ON TABLE foncier.mv_ep_geo2af_grid2d TO sdi_user2;	

CREATE UNIQUE INDEX uidx_mv_ep_geo2af_grid2d
    ON foncier.mv_ep_geo2af_grid2d USING btree
    (ogc_fid);
			
CREATE INDEX sidx_mv_ep_geo2af_grid2d
    ON foncier.mv_ep_geo2af_grid2d USING gist
    (wkb_geometry);
			