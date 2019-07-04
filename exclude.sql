DROP MATERIALIZED VIEW foncier.mv_parcelles_ep_grouped_grid2d_exclude;
CREATE MATERIALIZED VIEW foncier.mv_parcelles_ep_grouped_grid2d_exclude AS	
SELECT
CASE
WHEN sub_num_ep_id = 1
THEN FALSE
ELSE TRUE 
END
AS page_exclude,
* 
FROM (
SELECT row_number() OVER (PARTITION BY ep_id) AS sub_num_ep_id, * FROM foncier.mv_ep_geo2af_grid2d ORDER BY projet_id, ep_id, ogc_fid
) AS foo;

GRANT SELECT ON TABLE foncier.mv_parcelles_ep_grouped_grid2d_exclude TO PUBLIC;
GRANT ALL ON TABLE foncier.mv_parcelles_ep_grouped_grid2d_exclude TO sdi_user2;	

CREATE UNIQUE INDEX uidx_mv_parcelles_ep_grouped_grid2d_exclude
    ON foncier.mv_parcelles_ep_grouped_grid2d_exclude USING btree
    (ogc_fid);
	
CREATE INDEX sidx_mv_ep_geo2af_grid2d_exclude
   	ON foncier.mv_parcelles_ep_grouped_grid2d_exclude USING gist
    (wkb_geometry);