-- View: foncier.mv_parcelles_ep_grouped_grid2d

DROP  MATERIALIZED VIEW IF EXISTS foncier.mv_parcelles_ep_grouped_grid2d ;
CREATE MATERIALIZED VIEW foncier.mv_parcelles_ep_grouped_grid2d

AS


SELECT 
	foo3.ogc_fid,
    foo3.ep_id,
	COUNT(*) OVER(PARTITION BY foo3.ep_id) AS nb_cartes, 
    foo3.ep_nom,
    foo3.projet_id,
    foo3.projet_code,
    foo3.projet_nom,
    foo3.list_parcelles,
    foo3.wkb_geometry,
	foo3.sub_num_ep_id,
	CASE
    	WHEN foo3.sub_num_ep_id = 1 THEN false
   		ELSE true
    END AS page_exclude
	   FROM
	   (
	   SELECT 
		foo2.ogc_fid,
		foo2.ep_id,
		foo2.ep_nom,
		foo2.projet_id,
		foo2.projet_code,
		foo2.projet_nom,
		foo2.list_parcelles,
		foo2.wkb_geometry,
		row_number() OVER (PARTITION BY foo2.ep_id) AS sub_num_ep_id
		FROM
		   (
			SELECT row_number() OVER () AS ogc_fid,
			foo.ep_id,
			foo.ep_nom,
			foo.projet_id,
			foo.projet_code,
			foo.projet_nom,
			foo.list_parcelles,
			foo.grid_geom AS wkb_geometry
			   FROM 
			   ( 
				   SELECT a.ep_id,
						a.ep_nom,
						a.projet_id,
						a.projet_code,
						a.projet_nom,
						a.list_parcelles,
						a.ep_geom,
						st_transform((a.grid_geom_wgs84).geom, 2154)::geometry(Polygon,2154) AS grid_geom
					   FROM 
					   ( 
						   SELECT v_parcelles_ep_grouped.ep_id,
								v_parcelles_ep_grouped.ep_nom,
								v_parcelles_ep_grouped.projet_id,
								v_parcelles_ep_grouped.projet_code,
								v_parcelles_ep_grouped.projet_nom,
								v_parcelles_ep_grouped.list_parcelles,
								v_parcelles_ep_grouped.wkb_geometry AS ep_geom,
								st_dump(makegrid_2d(st_transform(st_buffer(v_parcelles_ep_grouped.wkb_geometry, 1500::double precision), 4326), 4275, 4275)) AS grid_geom_wgs84
							   FROM foncier.v_parcelles_ep_grouped 
			) a
	) foo
  WHERE st_intersects(st_buffer(foo.ep_geom, 1::double precision), foo.grid_geom))foo2)foo3

  ORDER BY foo3.projet_id, foo3.ep_id, foo3.ogc_fid					   
  WITH DATA ;

ALTER TABLE foncier.mv_parcelles_ep_grouped_grid2d
    OWNER TO sdi_user2;

GRANT SELECT ON TABLE foncier.mv_parcelles_ep_grouped_grid2d TO PUBLIC;
GRANT ALL ON TABLE foncier.mv_parcelles_ep_grouped_grid2d TO sdi_user2;

CREATE INDEX sidx_mv_parcelles_ep_grouped_grid2d
    ON foncier.mv_parcelles_ep_grouped_grid2d USING gist
    (wkb_geometry)
    TABLESPACE pg_default;
CREATE UNIQUE INDEX uidx_mv_parcelles_ep_grouped_grid2d
    ON foncier.mv_parcelles_ep_grouped_grid2d USING btree
    (ogc_fid)
    TABLESPACE pg_default;
						  