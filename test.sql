--test---
DROP VIEW IF EXISTS traitements.v_test CASCADE;
CREATE VIEW traitements.v_test AS

WITH
buffer_negative AS 
(SELECT 
	row_number() OVER() AS id_buffer_negative,
	ogc_fid AS id_polygon_ini,
	ST_Multi(
		--ST_Buffer(
			ST_Buffer(wkb_geometry,-6582)           --- buffer negative multipolygon
		--,1,'join=mitre mitre_limit=5.0')                        ---,10, 'quad_segs=2'
	)::geometry(Multipolygon, 2154) AS geom_buffer_negative
FROM traitements.v_union_rtba_multipolygon
),

buffer_negative_union AS (
SELECT 1 AS ogc_fid, ST_Union(geom_buffer_negative) AS wkb_geometry FROM buffer_negative
),

relevant_closest_points AS 
(
SELECT 
	cp.ogc_fid,
	cp.wkb_geometry
	FROM traitements.v_closest_point_on_line AS cp, traitements.v_segments_series_boundary_armee_rtba AS seg
	WHERE ST_Distance(cp.wkb_geometry,ST_PointN(seg.wkb_geometry, 1)) > 2 AND ST_Distance(cp.wkb_geometry,ST_PointN(seg.wkb_geometry, 2)) > 2 AND ST_DWithin(cp.wkb_geometry, seg.wkb_geometry, 0.1)
),
																					 
closest_point_on_segment AS
(
	
		SELECT 
	    seg.ogc_fid AS id_seg,
	    cp.ogc_fid AS id_cp,
	    cp.wkb_geometry AS geom_cp,
		seg.wkb_geometry AS geom_seg
		FROM relevant_closest_points AS cp, traitements.v_segments_series_boundary_armee_rtba AS seg										   
		WHERE ST_DWithin(cp.wkb_geometry, seg.wkb_geometry, 0.1) 
	 	ORDER BY seg.ogc_fid, cp.ogc_fid
),
																						  
distance_segpoints_cp AS
(																						  
		SELECT id_seg, geom_seg,			
		round((ST_X(geom_cp)::numeric),2) ||' '|| round((ST_Y(geom_cp)::numeric),2) AS cp_x_y, 
		ST_Distance(ST_PointN(geom_seg,1),geom_cp) AS distance_segp1_cp FROM closest_point_on_segment   
		ORDER BY id_seg, distance_segp1_cp
),	

segpoints_cp_without_equals AS 
(
		SELECT
		id_seg, 
		geom_seg,
		cp_x_y
		FROM distance_segpoints_cp																						  
		GROUP BY id_seg, geom_seg, cp_x_y
),

coordinates_seg_cp AS
(
		SELECT
		id_seg, 
		round(ST_X(ST_PointN(geom_seg,1))::numeric,2) AS seg_start_pt_x ,
		round(ST_Y(ST_PointN(geom_seg,1))::numeric,2) AS seg_start_pt_y,
		array_to_string(array_agg(cp_x_y), ', '::text) AS cp_coords,
		round(ST_X(ST_PointN(geom_seg,2))::numeric,2) AS seg_end_pt_x,
		round(ST_Y(ST_PointN(geom_seg,2))::numeric,2) AS seg_end_pt_y
		FROM
		segpoints_cp_without_equals
		GROUP BY id_seg, geom_seg
),

segments_intersect_cp AS
(			  
		SELECT id_seg, ST_GeomFromText('Linestring('||seg_start_pt_x||' '||seg_start_pt_y||', '||cp_coords||', '||seg_end_pt_x||' '||seg_end_pt_y||')',2154) AS wkb_geometry
		FROM coordinates_seg_cp 
),
segments_not_intersect_cp AS
(
 		SELECT ogc_fid, wkb_geometry FROM
		traitements.v_segments_series_boundary_armee_rtba 
		WHERE ogc_fid NOT IN (SELECT id_seg FROM segments_intersect_cp)
)	  
,
			 
union_segments AS
(			  
		SELECT 1 AS ogc_fid, ST_Union(wkb_geometry) AS wkb_geometry FROM
		(
		SELECT * FROM segments_intersect_cp
		UNION
		SELECT * FROM segments_not_intersect_cp
		) AS foo2		  
),	

series_union_segments AS
(
SELECT row_number() over() as ogc_fid, wkb_geometry::geometry(LineString, 2154) FROM
(									 
SELECT ST_GeometryN(wkb_geometry, 
	generate_series(1, ST_NumGeometries(wkb_geometry))) as wkb_geometry
FROM union_segments) AS foo			  
),
					
final_segments AS 	
(		
	    SELECT row_number() over() as ogc_fid, wkb_geometry FROM (
		SELECT row_number() over() as ogc_fid, ST_MakeLine(lag((pt).geom, 1, NULL) OVER (PARTITION BY ogc_fid ORDER BY ogc_fid, (pt).path), (pt).geom)::geometry(LineString, 2154) AS wkb_geometry
		FROM (SELECT ogc_fid, ST_DumpPoints(wkb_geometry) AS pt FROM series_union_segments) AS dumps
		) AS foo
	WHERE wkb_geometry IS NOT NULL
),

final_segments_distance AS 
(
SELECT  final_segments.ogc_fid, 
	round(ST_Distance(ST_Centroid(final_segments.wkb_geometry),buffer_negative_union.wkb_geometry)::numeric,2) AS distance_seg_buffer_negative, 
	ST_Shortestline(ST_Centroid(final_segments.wkb_geometry),buffer_negative_union.wkb_geometry)::geometry(LineString, 2154) AS geom_shortest_line, 
	final_segments.wkb_geometry
 FROM final_segments, buffer_negative_union
),
	
--SELECT * FROM final_segments_distance; -- WHERE distance_seg_buffer_negative; < 6590

final_segments_distance_buffer AS
(
SELECT
 ogc_fid,
 CASE 
	WHEN distance_seg_buffer_negative < 6582 THEN 3704
	ELSE 1852
 END AS buffer,
 wkb_geometry
 FROM final_segments_distance
),

final_segments_buffer AS
(SELECT 
ST_Buffer(wkb_geometry,buffer) AS  wkb_geometry
FROM final_segments_distance_buffer
),
	
final_segments_buffer_union AS
(SELECT 1 as ogc_fid,
ST_Union(wkb_geometry) as wkb_geometry 
 FROM final_segments_buffer)

SELECT * FROM final_segments_buffer_union;
	*/
GRANT ALL ON TABLE traitements.v_test TO PUBLIC;
GRANT ALL ON TABLE traitements.v_test TO sdi_user2;