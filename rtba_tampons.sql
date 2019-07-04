--METHODE A-----
--Generate union and simplification from armee rtba
DROP VIEW IF EXISTS traitements.v_union_rtba_multipolygon CASCADE;
CREATE VIEW traitements.v_union_rtba_multipolygon AS

SELECT 
	1 AS ogc_fid, 
	ST_Multi(ST_Union(ST_Buffer(wkb_geometry,12)))::geometry(Multipolygon, 2154) AS wkb_geometry	
FROM contraintes_techniques.armee_rtba;
									   
GRANT SELECT ON TABLE traitements.v_union_rtba_multipolygon TO PUBLIC;
GRANT ALL ON TABLE traitements.v_union_rtba_multipolygon TO sdi_user2;										 

--Generate boundary from union armee rtba
DROP VIEW IF EXISTS traitements.v_boundary_armee_rtba CASCADE;
CREATE VIEW traitements.v_boundary_armee_rtba AS
												
SELECT 
	ogc_fid, 
	ST_Multi(ST_Boundary(wkb_geometry))::geometry(MultilineString, 2154) AS wkb_geometry
FROM traitements.v_union_rtba_multipolygon;

GRANT SELECT ON TABLE traitements.v_boundary_armee_rtba TO PUBLIC;
GRANT ALL ON TABLE traitements.v_boundary_armee_rtba TO sdi_user2;
									 
--Generate series from boundary armee rtba 	
DROP VIEW IF EXISTS traitements.v_series_boundary_armee_rtba CASCADE;
CREATE VIEW traitements.v_series_boundary_armee_rtba AS
									 
SELECT 
	row_number() over() as ogc_fid, 
	wkb_geometry::geometry(LineString, 2154) 
FROM
(									 
SELECT 
	ST_GeometryN(wkb_geometry, 
	generate_series(1, ST_NumGeometries(wkb_geometry))) as wkb_geometry
FROM traitements.v_boundary_armee_rtba) AS foo;									 

GRANT SELECT ON TABLE traitements.v_series_boundary_armee_rtba TO PUBLIC;
GRANT ALL ON TABLE traitements.v_series_boundary_armee_rtba TO sdi_user2;

--Create segments from series boundary armee rtba
DROP VIEW IF EXISTS traitements.v_segments_series_boundary_armee_rtba CASCADE;
CREATE VIEW traitements.v_segments_series_boundary_armee_rtba AS		
					
WITH segments AS (
SELECT row_number() over() as ogc_fid, ST_MakeLine(lag((pt).geom, 1, NULL) OVER (PARTITION BY ogc_fid ORDER BY ogc_fid, (pt).path), (pt).geom)::geometry(LineString, 2154) AS wkb_geometry
FROM (SELECT ogc_fid, ST_DumpPoints(wkb_geometry) AS pt FROM traitements.v_series_boundary_armee_rtba) as dumps
)
SELECT * FROM segments WHERE wkb_geometry IS NOT NULL;

GRANT SELECT ON TABLE traitements.v_segments_series_boundary_armee_rtba TO PUBLIC;
GRANT ALL ON TABLE traitements.v_segments_series_boundary_armee_rtba TO sdi_user2;

--Create buffer negative multipolygon from union armee rtba 
DROP VIEW IF EXISTS traitements.v_buffer_negative_multipolygon CASCADE;
CREATE VIEW traitements.v_buffer_negative_multipolygon AS

(SELECT 
	row_number() OVER() AS id_buffer_negative,
	ogc_fid AS id_polygon_ini,
	ST_Multi(
			ST_Buffer(wkb_geometry,-6582)                                
	)::geometry(Multipolygon, 2154) AS geom_buffer_negative
FROM traitements.v_union_rtba_multipolygon);                        

GRANT SELECT ON TABLE traitements.v_buffer_negative_multipolygon TO PUBLIC;
GRANT ALL ON TABLE traitements.v_buffer_negative_multipolygon TO sdi_user2;


--Extract points from buffer negative 
DROP VIEW IF EXISTS traitements.v_extraction_points_buffer_negative CASCADE;
CREATE VIEW traitements.v_extraction_points_buffer_negative  AS

WITH
buffer_negative_multipolygon AS										 
(SELECT
	id_buffer_negative, 
	id_polygon_ini, 
 	geom_buffer_negative 
FROM traitements.v_buffer_negative_multipolygon					   
WHERE ST_IsEmpty(geom_buffer_negative) = FALSE),
buffer_negative_polygon AS 
(SELECT
 	id_polygon_ini,
	ST_GeometryN(geom_buffer_negative, 
	generate_series(1, ST_NumGeometries(geom_buffer_negative)))::geometry(Polygon, 2154) AS geom_buffer_negative_polygon    -------buffer negative polygon
FROM buffer_negative_multipolygon),
buffer_negative_linestring AS
(SELECT 
	 	id_polygon_ini,
 		ST_Boundary(geom_buffer_negative_polygon)::geometry(LineString, 2154) AS geom_buffer_negative_linestring            ---------buffer negative linestring
FROM buffer_negative_polygon
),			
buffer_negative_points AS				
(SELECT 
	id_polygon_ini,
	generate_series(1,ST_NPoints(geom_buffer_negative_linestring)-1) as point_order,
	ST_PointN(
	geom_buffer_negative_linestring,
	generate_series(1,ST_NPoints(geom_buffer_negative_linestring)-1))::geometry(Point, 2154) AS geom_buffer_negative_point      ------extraire points buffer negative
FROM buffer_negative_linestring)

SELECT 
	row_number() OVER() AS ogc_fid,
	id_polygon_ini,
	point_order,
	geom_buffer_negative_point AS wkb_geometry
FROM buffer_negative_points;

GRANT SELECT ON TABLE traitements.v_extraction_points_buffer_negative TO PUBLIC;
GRANT ALL ON TABLE traitements.v_extraction_points_buffer_negative TO sdi_user2;				

	
--Find closest points on line
DROP VIEW IF EXISTS traitements.v_closest_point_on_line CASCADE;
CREATE VIEW traitements.v_closest_point_on_line AS
		
WITH 
points_noeuds_polygone_interieur AS
(SELECT ogc_fid, wkb_geometry AS geom_point_interieur from traitements.v_extraction_points_buffer_negative),   ----(interieur)
ligne_polygone_exterieur AS
(SELECT ogc_fid, wkb_geometry AS geom_ligne_exterieure from traitements.v_boundary_armee_rtba),  ---(exterieure)
correspondance_point_int_ligne_ext AS
(SELECT * FROM points_noeuds_polygone_interieur AS inter,ligne_polygone_exterieur AS ext)	

SELECT
row_number() over() as ogc_fid,
ST_ClosestPoint(geom_ligne_exterieure,geom_point_interieur)::geometry(Point, 2154) AS wkb_geometry
FROM correspondance_point_int_ligne_ext;

GRANT SELECT ON TABLE traitements.v_closest_point_on_line TO PUBLIC;
GRANT ALL ON TABLE traitements.v_closest_point_on_line TO sdi_user2;

--Generate union from buffer negative
DROP VIEW IF EXISTS traitements.v_buffer_negative_union CASCADE;
CREATE VIEW traitements.v_buffer_negative_union AS
		
SELECT 1 AS ogc_fid, ST_Union(geom_buffer_negative) AS wkb_geometry FROM traitements.v_buffer_negative_multipolygon;
		
GRANT SELECT ON TABLE traitements.v_buffer_negative_union TO PUBLIC;
GRANT ALL ON TABLE traitements.v_buffer_negative_union TO sdi_user2;

--Extract relevant closest points
DROP VIEW IF EXISTS traitements.v_relevant_closest_points CASCADE;
CREATE VIEW traitements.v_relevant_closest_points AS
		
(SELECT 
	cp.ogc_fid,
	cp.wkb_geometry
FROM traitements.v_closest_point_on_line AS cp, traitements.v_segments_series_boundary_armee_rtba AS seg
WHERE ST_Distance(cp.wkb_geometry,ST_PointN(seg.wkb_geometry, 1)) > 2 AND ST_Distance(cp.wkb_geometry,ST_PointN(seg.wkb_geometry, 2)) > 2 AND ST_DWithin(cp.wkb_geometry, seg.wkb_geometry, 0.1)
);
																						  
GRANT SELECT ON TABLE traitements.v_relevant_closest_points TO PUBLIC;
GRANT ALL ON TABLE traitements.v_relevant_closest_points TO sdi_user2;	

--Find closest point on segment
DROP VIEW IF EXISTS traitements.v_closest_points_on_segment CASCADE;
CREATE VIEW traitements.v_closest_points_on_segment AS																						  

(SELECT 
	seg.ogc_fid AS id_seg,
	cp.ogc_fid AS id_cp,
	cp.wkb_geometry AS geom_cp,
	seg.wkb_geometry AS geom_seg
FROM traitements.v_relevant_closest_points AS cp, traitements.v_segments_series_boundary_armee_rtba AS seg										   
WHERE ST_DWithin(cp.wkb_geometry, seg.wkb_geometry, 0.1) 
ORDER BY seg.ogc_fid, cp.ogc_fid
);	
																					  
GRANT SELECT ON TABLE traitements.v_closest_points_on_segment TO PUBLIC;
GRANT ALL ON TABLE traitements.v_closest_points_on_segment TO sdi_user2;			

--Generate distance segments to closest_points
DROP VIEW IF EXISTS traitements.v_distance_segments_to_closest_points CASCADE;
CREATE VIEW traitements.v_distance_segments_to_closest_points AS	
																				  
(SELECT 
 	id_seg, 
 	geom_seg,			
	round((ST_X(geom_cp)::numeric),2) ||' '|| round((ST_Y(geom_cp)::numeric),2) AS cp_x_y, 
	ST_Distance(ST_PointN(geom_seg,1),geom_cp) AS distance_segp1_cp FROM traitements.v_closest_points_on_segment 
ORDER BY id_seg, distance_segp1_cp
);
		
GRANT SELECT ON TABLE traitements.v_closest_points_on_segment TO PUBLIC;
GRANT ALL ON TABLE traitements.v_closest_points_on_segment TO sdi_user2;

																					  
--Closest points without equals
DROP VIEW IF EXISTS traitements.v_closest_points_without_equals CASCADE;
CREATE VIEW traitements.v_closest_points_without_equals AS	
(SELECT
	 row_number() over() as ogc_fid, 
	id_seg, 
	geom_seg,
	cp_x_y
FROM traitements.v_distance_segments_to_closest_points																						  
GROUP BY id_seg, geom_seg, cp_x_y
);

GRANT SELECT ON TABLE traitements.v_closest_points_without_equals TO PUBLIC;
GRANT ALL ON TABLE traitements.v_closest_points_without_equals TO sdi_user2;

--Extract coordinates from segments and closest points
DROP VIEW IF EXISTS traitements.v_coordinates_segments_closest_points CASCADE;
CREATE VIEW traitements.v_coordinates_segments_closest_points AS	
		
(SELECT
	id_seg, 
	round(ST_X(ST_PointN(geom_seg,1))::numeric,2) AS seg_start_pt_x ,
	round(ST_Y(ST_PointN(geom_seg,1))::numeric,2) AS seg_start_pt_y,
	array_to_string(array_agg(cp_x_y), ', '::text) AS cp_coords,
	round(ST_X(ST_PointN(geom_seg,2))::numeric,2) AS seg_end_pt_x,
	round(ST_Y(ST_PointN(geom_seg,2))::numeric,2) AS seg_end_pt_y
FROM traitements.v_closest_points_without_equals
GROUP BY id_seg, geom_seg
);

GRANT SELECT ON TABLE traitements.v_coordinates_segments_closest_points TO PUBLIC;
GRANT ALL ON TABLE traitements.v_coordinates_segments_closest_points TO sdi_user2;

--Create segments intersected by closest points
DROP VIEW IF EXISTS traitements.v_segments_intersected_by_closest_points CASCADE;
CREATE VIEW traitements.v_segments_intersected_by_closest_points  AS

(SELECT 
 	id_seg, ST_GeomFromText('Linestring('||seg_start_pt_x||' '||seg_start_pt_y||', '||cp_coords||', '||seg_end_pt_x||' '||seg_end_pt_y||')',2154) AS wkb_geometry
FROM traitements.v_coordinates_segments_closest_points
); 
 
GRANT SELECT ON TABLE traitements.v_segments_intersected_by_closest_points TO PUBLIC;
GRANT ALL ON TABLE traitements.v_segments_intersected_by_closest_points TO sdi_user2;

--Create segments not intersected by closest points
DROP VIEW IF EXISTS traitements.v_segments_not_intersected_by_closest_points CASCADE;
CREATE VIEW traitements.v_segments_not_intersected_by_closest_points  AS
		  
SELECT 
	ogc_fid, wkb_geometry 
FROM traitements.v_segments_series_boundary_armee_rtba 
WHERE ogc_fid NOT IN (SELECT id_seg FROM traitements.v_segments_intersected_by_closest_points
);

GRANT SELECT ON TABLE traitements.v_segments_not_intersected_by_closest_points TO PUBLIC;
GRANT ALL ON TABLE traitements.v_segments_not_intersected_by_closest_points TO sdi_user2;

--Create union from all segments
DROP VIEW IF EXISTS traitements.v_union_all_segments CASCADE;
CREATE VIEW traitements.v_union_all_segments AS	

SELECT 
	1 AS ogc_fid, 
	ST_Union(wkb_geometry) AS wkb_geometry 
FROM
	(
		SELECT * FROM traitements.v_segments_intersected_by_closest_points
		UNION
		SELECT * FROM traitements.v_segments_not_intersected_by_closest_points
		) AS foo2;

GRANT SELECT ON TABLE traitements.v_union_all_segments TO PUBLIC;
GRANT ALL ON TABLE traitements.v_union_all_segments TO sdi_user2;
		  
--Create series from union segments
DROP VIEW IF EXISTS traitements.v_series_union_all_segments CASCADE;
CREATE VIEW traitements.v_series_union_all_segments AS	

SELECT 
	row_number() over() as ogc_fid, 
	wkb_geometry::geometry(LineString, 2154) 
FROM
(									 
SELECT 
	ST_GeometryN(wkb_geometry, 
	generate_series(1, ST_NumGeometries(wkb_geometry))) as wkb_geometry
FROM traitements.v_union_all_segments) AS foo;
				 
GRANT SELECT ON TABLE traitements.v_series_union_all_segments TO PUBLIC;
GRANT ALL ON TABLE traitements.v_series_union_all_segments TO sdi_user2;		  
		  
--Generate final segments
DROP VIEW IF EXISTS traitements.v_final_segments CASCADE;
CREATE VIEW traitements.v_final_segments AS
					
SELECT 
	row_number() over() as ogc_fid, 
	wkb_geometry 
FROM (
		SELECT 
			row_number() over() as ogc_fid, 
			ST_MakeLine(lag((pt).geom, 1, NULL) OVER (PARTITION BY ogc_fid ORDER BY ogc_fid, (pt).path), (pt).geom)::geometry(LineString, 2154) AS wkb_geometry
		FROM (SELECT ogc_fid, ST_DumpPoints(wkb_geometry) AS pt FROM traitements.v_series_union_all_segments) AS dumps
		) AS foo
WHERE wkb_geometry IS NOT NULL;
					
GRANT SELECT ON TABLE traitements.v_final_segments TO PUBLIC;
GRANT ALL ON TABLE traitements.v_final_segments TO sdi_user2;					
					
--Generate final segments distance and shortest line
DROP VIEW IF EXISTS traitements.v_final_segments_distance CASCADE;
CREATE VIEW traitements.v_final_segments_distance  AS
	
SELECT  
	v_final_segments.ogc_fid, 
	round(ST_Distance(ST_Centroid(v_final_segments.wkb_geometry),v_buffer_negative_union.wkb_geometry)::numeric,2) AS distance_seg_buffer_negative, 
	ST_Shortestline(ST_Centroid(v_final_segments.wkb_geometry),v_buffer_negative_union.wkb_geometry)::geometry(LineString, 2154) AS geom_shortest_line,
	v_final_segments.wkb_geometry AS wkb_geometry
FROM traitements.v_final_segments, traitements.v_buffer_negative_union;
	
GRANT SELECT ON TABLE traitements.v_final_segments_distance  TO PUBLIC;
GRANT ALL ON TABLE traitements.v_final_segments_distance TO sdi_user2;

--Generate final segments distance buffer
DROP VIEW IF EXISTS traitements.v_final_segments_distance_buffer CASCADE;
CREATE VIEW traitements.v_final_segments_distance_buffer  AS	
	
SELECT
 ogc_fid,
 CASE 
	WHEN distance_seg_buffer_negative < 8000 THEN 1852    --1mn
	ELSE 3704    --2mn
 END AS buffer,
 wkb_geometry
 FROM traitements.v_final_segments_distance;
		
GRANT SELECT ON TABLE traitements.v_final_segments_distance_buffer TO PUBLIC;
GRANT ALL ON TABLE traitements.v_final_segments_distance_buffer TO sdi_user2;
	
--Create buffer from final segments distance buffer
DROP VIEW IF EXISTS traitements.v_buffer_final_segments_distance_buffer CASCADE;
CREATE VIEW traitements.v_buffer_final_segments_distance_buffer  AS	
	
SELECT 
	ST_Buffer(wkb_geometry,buffer) AS  wkb_geometry
FROM traitements.v_final_segments_distance_buffer;
	
GRANT SELECT ON TABLE traitements.v_buffer_final_segments_distance_buffer TO PUBLIC;
GRANT ALL ON TABLE traitements.v_buffer_final_segments_distance_buffer TO sdi_user2;	
		
--Generate buffer union 
DROP VIEW IF EXISTS traitements.v_union_buffer_final_segments_distance_buffer CASCADE;
CREATE VIEW traitements.v_union_buffer_final_segments_distance_buffer AS	
	
SELECT 
	1 as ogc_fid,
	ST_Union(wkb_geometry)::geometry(Multipolygon, 2154) as wkb_geometry 
FROM traitements.v_buffer_final_segments_distance_buffer;

GRANT SELECT ON TABLE traitements.v_union_buffer_final_segments_distance_buffer TO PUBLIC;
GRANT ALL ON TABLE traitements.v_union_buffer_final_segments_distance_buffer TO sdi_user2;

--Difference buffer union with union armee rtba
DROP VIEW IF EXISTS traitements.v_difference_buffer_union_with_union_rtba CASCADE;
CREATE VIEW traitements.v_difference_buffer_union_with_union_rtba AS	

SELECT 
	1 as ogc_fid,
	ST_Difference(a.wkb_geometry, b.wkb_geometry) as wkb_geometry 
FROM traitements.v_union_buffer_final_segments_distance_buffer a, traitements.v_union_rtba_multipolygon b;

GRANT SELECT ON TABLE traitements.v_difference_buffer_union_with_union_rtba TO PUBLIC;
GRANT ALL ON TABLE traitements.v_difference_buffer_union_with_union_rtba TO sdi_user2;

					