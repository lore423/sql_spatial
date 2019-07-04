
--ST_Union rtba multipolygon avec simplify
DROP VIEW IF EXISTS traitements.v_union_rtba_multipolygon CASCADE;
CREATE VIEW traitements.v_union_rtba_multipolygon AS
SELECT 1 AS ogc_fid, ST_Multi(ST_Union(ST_Buffer(wkb_geometry,12)))::geometry(Multipolygon, 2154) AS wkb_geometry	
--SELECT 1 AS ogc_fid, ST_Multi(ST_Simplify(ST_Buffer(ST_Union(ST_Buffer(wkb_geometry,1)),-1),10))::geometry(Multipolygon, 2154) AS wkb_geometry	
FROM contraintes_techniques.armee_rtba;
									   
GRANT SELECT ON TABLE traitements.v_union_rtba_multipolygon TO PUBLIC;
GRANT ALL ON TABLE traitements.v_union_rtba_multipolygon TO sdi_user2;										 


--ST_Boundary armee rtba
DROP VIEW IF EXISTS traitements.v_boundary_armee_rtba CASCADE;
CREATE VIEW traitements.v_boundary_armee_rtba AS
SELECT ogc_fid, ST_Multi(ST_Boundary(wkb_geometry))::geometry(MultilineString, 2154) AS wkb_geometry
FROM traitements.v_union_rtba_multipolygon;

GRANT SELECT ON TABLE traitements.v_boundary_armee_rtba TO PUBLIC;
GRANT ALL ON TABLE traitements.v_boundary_armee_rtba TO sdi_user2;

--Generate series boundary armee rtba		
DROP VIEW IF EXISTS traitements.v_series_boundary_armee_rtba CASCADE;
CREATE VIEW traitements.v_series_boundary_armee_rtba AS
SELECT row_number() over() as ogc_fid, wkb_geometry::geometry(LineString, 2154) FROM
(									 
SELECT ST_GeometryN(wkb_geometry, 
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

/*
--ST_DumpPoints from boundary armee rtba
DROP VIEW IF EXISTS traitements.v_extraire_noeuds_boundary_armee CASCADE;
CREATE VIEW traitements.v_extraire_noeuds_boundary_armee AS
SELECT row_number() over() as ogc_fid, (gdump).geom::geometry(Point,2154) AS wkb_geometry FROM (
SELECT ogc_fid, ST_DumpPoints(wkb_geometry) AS gdump
FROM traitements.v_series_boundary_armee_rtba) AS g;

GRANT SELECT ON TABLE traitements.v_extraire_noeuds_boundary_armee TO PUBLIC;
GRANT ALL ON TABLE traitements.v_extraire_noeuds_boundary_armee TO sdi_user2;									 
*/
	
--Extraire points polygon contraintes_techniques.armee_rtba
DROP VIEW IF EXISTS traitements.v_buffer_negative_points CASCADE;
CREATE VIEW traitements.v_buffer_negative_points AS
WITH buffer_negative AS 
(SELECT 
	row_number() OVER() AS id_buffer_negative,
	armee_rtba.ogc_fid AS id_polygon_ini,
	ST_Multi(
		--ST_Buffer(
			ST_Buffer(armee_rtba.wkb_geometry,-6582)           --- buffer negative multipolygon
		--,1,'join=mitre mitre_limit=5.0')                        ---,10, 'quad_segs=2'
	)::geometry(Multipolygon, 2154) AS geom_buffer_negative
FROM contraintes_techniques.armee_rtba),
buffer_negative_multipolygon AS										 
(SELECT
	id_buffer_negative, 
	id_polygon_ini, 
 	geom_buffer_negative 
FROM buffer_negative					   
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

GRANT SELECT ON TABLE traitements.v_buffer_negative_points TO PUBLIC;
GRANT ALL ON TABLE traitements.v_buffer_negative_points TO sdi_user2;		


-- ST_ClosestPoint() 
DROP VIEW IF EXISTS traitements.v_closest_point_on_line CASCADE;
CREATE VIEW traitements.v_closest_point_on_line AS
		
WITH 
points_noeuds_polygone_interieur AS
(SELECT ogc_fid, wkb_geometry AS geom_point_interieur from traitements.v_buffer_negative_points),   ----(interieur)
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

		
--ST_MakeLine between closest point and buffer negative points 
DROP VIEW IF EXISTS traitements.v_make_line CASCADE;
CREATE VIEW traitements.v_make_line AS

SELECT row_number() OVER() AS ogc_fid, ST_MakeLine(t2.wkb_geometry, t1.wkb_geometry)::geometry(lineString, 2154) AS wkb_geometry
FROM traitements.v_closest_point_on_line AS t1, traitements.v_buffer_negative_points AS t2
WHERE t1.ogc_fid = t2.ogc_fid;

GRANT SELECT ON TABLE traitements.v_make_line TO PUBLIC;
GRANT ALL ON TABLE traitements.v_make_line TO sdi_user2;

/*
--ST_Split closest point on line and segments boundary armee rtba
DROP VIEW IF EXISTS traitements.v_split_points_boundary CASCADE;
CREATE VIEW traitements.v_split_points_boundary AS
		
SELECT row_number() over() as ogc_fid, ST_Split(a.wkb_geometry, b.wkb_geometry)::geometry(GeometryCollection, 2154) as wkb_geometry1 
FROM traitements.opcion2 as b, traitements.v_segments_series_boundary_armee_rtba as a
GROUP BY wkb_geometry1;

GRANT SELECT ON TABLE traitements.v_split_points_boundary TO PUBLIC;
GRANT ALL ON TABLE traitements.v_split_points_boundary TO sdi_user2;	

		
--ST_Centroid split boundary armee rtba		---------------------------------------					
DROP VIEW IF EXISTS traitements.v_centroid_split_boundary CASCADE;
CREATE VIEW traitements.v_centroid_split_boundary  AS
		
SELECT row_number() over() as ogc_fid,(ST_Centroid(wkb_geometry))::geometry(point, 2154) as wkb_geometry  
FROM traitements.v_segments_series_boundary_armee_rtba;

GRANT SELECT ON TABLE traitements.v_centroid_split_boundary  TO PUBLIC;
GRANT ALL ON TABLE traitements.v_centroid_split_boundary TO sdi_user2;	

		
SELECT ST_AsText(wkb_geometry) FROM traitements.v_segments_series_boundary_armee_rtba;		
SELECT ST_AsText(wkb_geometry) FROM traitements.v_closest_point_on_line;
SELECT ST_GeometryType(wkb_geometry)FROM traitements.v_segments_series_boundary_armee_rtba;
SELECT ST_GeometryType(wkb_geometry)FROM traitements.v_closest_point_on_line;	
SELECT ST_GeometryType(wkb_geometry)FROM traitements.v_segments_series_boundary_armee_rtba;
*/	