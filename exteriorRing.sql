/*
--ST_Buffer Negative
DROP  VIEW IF EXISTS traitements.v_buffer_negative CASCADE;
CREATE VIEW traitements.v_buffer_negative AS
SELECT row_number() OVER() AS ogc_fid, ogc_fid AS ogc_fid_armee_rtba, ST_Buffer(armee_rtba.wkb_geometry,-6582) AS wkb_geometry -- (7nm/2)*1852
FROM contraintes_techniques.armee_rtba;

GRANT SELECT ON TABLE traitements.v_buffer_negative TO PUBLIC;
GRANT ALL ON TABLE traitements.v_buffer_negative TO sdi_user2;
*/
--ST_Exterior Ring Armee rtba
DROP VIEW IF EXISTS traitements.v_exterior_ring_armee_rtba CASCADE;
CREATE VIEW traitements.v_exterior_ring_armee_rtba AS
SELECT ogc_fid, ogc_fid AS ogc_fid_armee_rtba, ST_ExteriorRing(wkb_geometry)::geometry(LineString, 2154) AS wkb_geometry
FROM contraintes_techniques.armee_rtba;

GRANT SELECT ON TABLE traitements.v_exterior_ring_armee_rtba TO PUBLIC;
GRANT ALL ON TABLE traitements.v_exterior_ring_armee_rtba TO sdi_user2;
/*
--ST_Exterior Ring Buffer Negative
DROP VIEW IF EXISTS traitements.v_exterior_ring_buffer_negative CASCADE;
CREATE VIEW traitements.v_exterior_ring_buffer_negative AS
SELECT ogc_fid, ogc_fid AS ogc_fid_armee_rtba, ST_ExteriorRing(wkb_geometry)AS wkb_geometry
FROM traitements.v_buffer_negative;

GRANT SELECT ON TABLE traitements.v_exterior_ring_buffer_negative TO PUBLIC;
GRANT ALL ON TABLE traitements.v_exterior_ring_buffer_negative TO sdi_user2;
																																										 																					
--ST_DumpPoints() Extraire noeuds du buffer_negative
DROP VIEW IF EXISTS traitements.v_extraire_noeuds_buffer_negative CASCADE;
CREATE VIEW traitements.v_extraire_noeuds_buffer_negative AS
SELECT row_number() over() as ogc_fid, ogc_fid_armee_rtba, (gdump).geom::geometry(Point,2154) AS wkb_geometry FROM (
SELECT ogc_fid_armee_rtba, ST_DumpPoints(wkb_geometry) AS gdump
FROM traitements.v_buffer_negative) AS g;

GRANT SELECT ON TABLE traitements.v_extraire_noeuds_buffer_negative TO PUBLIC;
GRANT ALL ON TABLE traitements.v_extraire_noeuds_buffer_negative TO sdi_user2;

*/
--Extraire points polygon contraintes_techniques.armee_rtba
DROP VIEW IF EXISTS traitements.v_buffer_negative_points CASCADE;
CREATE VIEW traitements.v_buffer_negative_points AS
WITH buffer_negative AS 
(SELECT 
	row_number() OVER() AS id_buffer_negative,
	armee_rtba.ogc_fid AS id_polygon_ini,
	ST_Multi(
		ST_Buffer(
			ST_Buffer(armee_rtba.wkb_geometry,-6582)
		,10, 'quad_segs=2')
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
	generate_series(1, ST_NumGeometries(geom_buffer_negative)))::geometry(Polygon, 2154) AS geom_buffer_negative_polygon
FROM buffer_negative_multipolygon),
buffer_negative_linestring AS
(SELECT 
	 	id_polygon_ini,
 		ST_Boundary(geom_buffer_negative_polygon)::geometry(LineString, 2154) AS geom_buffer_negative_linestring
FROM buffer_negative_polygon
),			
buffer_negative_points AS				
(SELECT 
	id_polygon_ini,
	generate_series(1,ST_NPoints(geom_buffer_negative_linestring)-1) as point_order,
	ST_PointN(
	geom_buffer_negative_linestring,
	generate_series(1,ST_NPoints(geom_buffer_negative_linestring)-1))::geometry(Point, 2154) AS geom_buffer_negative_point
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
(SELECT ogc_fid AS id_point_buffer_negative, id_polygon_ini, wkb_geometry AS geom_point_interieur from traitements.v_buffer_negative_points),
ligne_polygone_exterieur AS
(SELECT ogc_fid_armee_rtba, wkb_geometry AS geom_ligne_exterieure from traitements.v_exterior_ring_armee_rtba),
correspondance_point_int_ligne_ext AS
(SELECT * FROM points_noeuds_polygone_interieur AS inter,ligne_polygone_exterieur AS ext	
WHERE inter.id_polygon_ini = ext.ogc_fid_armee_rtba
GROUP BY inter.id_polygon_ini, ext.ogc_fid_armee_rtba, id_point_buffer_negative, geom_point_interieur, geom_ligne_exterieure ORDER BY id_point_buffer_negative)

SELECT
row_number() over() as ogc_fid,
id_polygon_ini,
id_point_buffer_negative,
--ST_AsText(ST_ClosestPoint(geom_ligne_exterieure,geom_point_interieur)),
ST_ClosestPoint(geom_ligne_exterieure,geom_point_interieur)::geometry(Point, 2154) AS wkb_geometry
FROM correspondance_point_int_ligne_ext;

GRANT SELECT ON TABLE traitements.v_closest_point_on_line TO PUBLIC;
GRANT ALL ON TABLE traitements.v_closest_point_on_line TO sdi_user2;
																		 
--ST_MakeLine()
DROP VIEW IF EXISTS traitements.v_make_line CASCADE;
CREATE VIEW traitements.v_make_line AS

SELECT row_number() OVER() AS ogc_fid, ST_MakeLine(t2.wkb_geometry, t1.wkb_geometry)::geometry(Linestring, 2154) AS wkb_geometry
FROM traitements.v_closest_point_on_line AS t1, traitements.v_buffer_negative_points AS t2
WHERE t1.id_point_buffer_negative = t2.ogc_fid;

GRANT SELECT ON TABLE traitements.v_make_line TO PUBLIC;
GRANT ALL ON TABLE traitements.v_make_line TO sdi_user2;

						 
						 
						 