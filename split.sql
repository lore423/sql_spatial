/*
-------SPLIT LINES WITH POINTS-------

CREATE OR REPLACE FUNCTION ST_AsMultiPoint(geometry) RETURNS geometry AS
'SELECT ST_Union((d).geom) FROM ST_DumpPoints($1) AS d;'
LANGUAGE sql IMMUTABLE STRICT COST 10;

--input points on nearest place over lines segments---
DROP VIEW IF EXISTS traitements.v_pointsoverlines CASCADE;
CREATE VIEW traitements.v_pointsoverlines AS
SELECT row_number() OVER () AS ogc_fid, wkb_geometry 
FROM (
SELECT a.ogc_fid,ST_ClosestPoint(ST_Union(b.wkb_geometry), a.wkb_geometry)::geometry(POINT,2154) AS wkb_geometry
FROM traitements.v_closest_point_on_line a, traitements.v_segments_series_boundary_armee_rtba b
WHERE ST_DWithin(a.wkb_geometry, b.wkb_geometry, 10000) 
GROUP BY a.ogc_fid, a.wkb_geometry
) AS foo
GROUP BY wkb_geometry;

GRANT SELECT ON TABLE traitements.v_pointsoverlines TO PUBLIC;
GRANT ALL ON TABLE traitements.v_pointsoverlines TO sdi_user2;


--densify lines and extract nodes as 1 unique multipoint geometry avec segments---
DROP VIEW IF EXISTS traitements.v_lines_nodes_densified CASCADE;
CREATE VIEW traitements.v_lines_nodes_densified AS
SELECT ogc_fid, ST_Union(ST_AsMultiPoint(st_segmentize(wkb_geometry,10)))::geometry(MULTIPOINT,2154) AS wkb_geometry 
FROM traitements.v_segments_series_boundary_armee_rtba
GROUP BY v_segments_series_boundary_armee_rtba.ogc_fid
ORDER BY v_segments_series_boundary_armee_rtba.ogc_fid ASC;
													   
GRANT SELECT ON TABLE traitements.v_lines_nodes_densified TO PUBLIC;
GRANT ALL ON TABLE traitements.v_lines_nodes_densified TO sdi_user2;
											

---snap points over lines nodes/vertexes-----													
DROP VIEW IF EXISTS traitements.v_points_snapped CASCADE;
CREATE VIEW traitements.v_points_snapped AS
SELECT row_number() OVER () AS ogcfid, b.ogc_fid, ST_snap(ST_Union(b.wkb_geometry),a.wkb_geometry, ST_Distance(a.wkb_geometry,b.wkb_geometry)*1.01)::geometry(POINT,2154) AS wkb_geometry 
--SELECT b.ogc_fid, ST_snap(b.wkb_geometry, a.wkb_geometry, ST_Distance(b.wkb_geometry, a.wkb_geometry)*1.01)::geometry(POINT,2154) AS wkb_geometry
FROM traitements.v_lines_nodes_densified a, traitements.v_pointsoverlines b  -----couche ligne union
WHERE ST_DWithin(a.wkb_geometry, b.wkb_geometry, 1) 	---1 metre												   
GROUP BY a.wkb_geometry, b.wkb_geometry, b.ogc_fid
ORDER BY b.ogc_fid ASC;

GRANT SELECT ON TABLE traitements.v_points_snapped TO PUBLIC;
GRANT ALL ON TABLE traitements.v_points_snapped TO sdi_user2;
															
----intersect O/N----
SELECT row_number() OVER () AS ogc_fid
FROM traitements.v_lines_nodes_densified  a, traitements.v_points_snapped p
--WHERE ST_Intersects(ST_Buffer(p.wkb_geometry,1), a.wkb_geometry) = TRUE;

WHERE ST_Intersects(p.wkb_geometry, a.wkb_geometry) = TRUE;



----split lines------
DROP VIEW IF EXISTS traitements.v_lines_split CASCADE;
CREATE VIEW traitements.v_lines_split AS
--SELECT a.ogc_fid, (ST_Dump(ST_split(st_segmentize(a.wkb_geometry,1),ST_Union(b.wkb_geometry)))).geom::geometry(LINESTRING,2154) AS wkb_geometry
SELECT row_number() OVER () AS ogc_fid, wkb_geometry::geometry(LineString,2154) FROM
(
	SELECT
	(ST_Dump(ST_split(a.wkb_geometry,(ST_Multi(ST_Union(b.wkb_geometry)))::geometry(Multipoint,2154)
					 )
											  ::geometry(GeometryCollection,2154))).geom AS wkb_geometry

FROM traitements.v_segments_series_boundary_armee_rtba a, traitements.v_points_snapped b
GROUP BY a.wkb_geometry, b.wkb_geometry
) AS foo;														 

GRANT SELECT ON TABLE traitements.v_lines_split TO PUBLIC;
GRANT ALL ON TABLE traitements.v_lines_split TO sdi_user2;	

											   
--ST_MakeLine between closest point and segments 
DROP VIEW IF EXISTS traitements.v_make_line_cp_segments CASCADE;
CREATE VIEW traitements.v_make_line_cp_segments AS

SELECT row_number() OVER() AS ogc_fid, ST_MakeLine(t2.wkb_geometry, t1.wkb_geometry)::geometry(lineString, 2154) AS wkb_geometry
FROM traitements.v_closest_point_on_line AS t1, traitements.v_segments_series_boundary_armee_rtba AS t2
WHERE t1.ogc_fid = t2.ogc_fid;

GRANT SELECT ON TABLE traitements.v_make_line_cp_segments TO PUBLIC;
GRANT ALL ON TABLE traitements.v_make_line_cp_segments TO sdi_user2;
											   
											   
SELECT * FROM 
(										   
SELECT seg.ogc_fid, ST_MakeLine(ST_PointN(seg.wkb_geometry, 1), cp.wkb_geometry)::geometry(lineString, 2154)AS wkb_geometry
FROM traitements.v_closest_point_on_line AS cp, traitements.v_segments_series_boundary_armee_rtba AS seg										   
WHERE ST_DWithin(cp.wkb_geometry, seg.wkb_geometry, 1) 		
UNION
SELECT seg.ogc_fid, ST_MakeLine(ST_PointN(seg.wkb_geometry, 2), cp.wkb_geometry)::geometry(lineString, 2154)AS wkb_geometry
FROM traitements.v_closest_point_on_line AS cp, traitements.v_segments_series_boundary_armee_rtba AS seg										   
WHERE ST_DWithin(cp.wkb_geometry, seg.wkb_geometry, 1) 											   
) AS foo
*/

/*
---segments_buffer_1mn_2mn----
DROP VIEW IF EXISTS traitements.v_buffer_rtba CASCADE;
CREATE VIEW traitements.v_buffer_rtba AS

WITH
segments_buffer_1mn AS										   
(SELECT row_number() OVER () AS ogc_fid, 1852 AS buffer_value, ST_GeomFromText('Linestring('||x1||' '||y1||','||x2||' '||y2||','||x3||' '||y3||')',2154) AS wkb_geometry	
FROM (
SELECT ST_X(start_pt) AS x1, ST_Y(start_pt) AS y1, ST_X(closest_pt) AS x2, ST_Y(closest_pt) AS y2, ST_X(end_pt) AS x3, ST_Y(end_pt) AS y3 FROM									   
(
SELECT 
ST_PointN(seg.wkb_geometry, 1) AS start_pt,
cp.wkb_geometry AS closest_pt, 
ST_PointN(seg.wkb_geometry, 2)	AS end_pt									   
FROM traitements.v_closest_point_on_line AS cp, traitements.v_segments_series_boundary_armee_rtba AS seg										   
WHERE ST_DWithin(cp.wkb_geometry, seg.wkb_geometry, 1)
) AS foo
) AS foo2
),

segments_buffer_2mn	AS
(SELECT row_number() OVER () AS ogc_fid, 3704 AS buffer_value, wkb_geometry	
FROM											   
(SELECT * FROM											   
traitements.v_segments_series_boundary_armee_rtba
WHERE ogc_fid NOT IN
(SELECT seg.ogc_fid FROM traitements.v_closest_point_on_line AS cp, traitements.v_segments_series_boundary_armee_rtba AS seg										   
WHERE ST_DWithin(cp.wkb_geometry, seg.wkb_geometry, 1)) 
) AS foo3)
 
 
SELECT 1 AS ogc_fid, ST_Union(wkb_geometry) AS wkb_geometry FROM
(
SELECT row_number() over() as ogc_fid, 
 ST_Buffer(wkb_geometry,buffer_value) AS wkb_geometry FROM 
(
SELECT * FROM segments_buffer_1mn
UNION
SELECT * FROM segments_buffer_2mn
) AS foo
) AS foo2;

GRANT SELECT ON TABLE traitements.v_buffer_rtba TO PUBLIC;
GRANT ALL ON TABLE traitements.v_buffer_rtba TO sdi_user2; 
 
 /*
---ST_Difference between v_buffer_rtba and v_union_rtb_multipolygon
SELECT 1 AS ogc_fid, ST_Difference(a.wkb_geometry, b.wkb_geometry) AS wkb_geometry
FROM traitements.v_buffer_rtba as a, traitements.v_union_rtba_multipolygon as b

									 

----ST_CollectionExtract lines_split --
DROP VIEW IF EXISTS traitements.v_collection_extract_lines_split CASCADE;
CREATE VIEW traitements.v_collection_extract_lines_split AS
SELECT row_number() over() as ogc_fid, wkb_geometry::geometry(MultilineString, 2154)	FROM			
(SELECT ST_CollectionExtract(wkb_geometry,2) as wkb_geometry
FROM traitements.v_lines_split) AS foo;

GRANT SELECT ON TABLE traitements.v_series_collection_extract_v_lines_split TO PUBLIC;
GRANT ALL ON TABLE traitements.v_series_collection_extract_v_lines_split TO sdi_user2;										 

																		 /*
---generate series 	v_collection_extract_v_lines_split(pasar de multilinestring a lignestring)
DROP VIEW IF EXISTS traitements.v_series_collection_extract_split_points_boundary CASCADE;
CREATE VIEW traitements.v_series_collection_extract_split_points_boundary AS
SELECT row_number() over() as ogc_fid, wkb_geometry::geometry(LineString, 2154) FROM
(									 
SELECT ST_GeometryN(wkb_geometry, 
	generate_series(1, ST_NumGeometries(wkb_geometry))) as wkb_geometry
FROM traitements.v_collection_extract_v_lines_split) AS foo;									 

GRANT SELECT ON TABLE traitements.v_series_collection_extract_split_points_boundary TO PUBLIC;
GRANT ALL ON TABLE traitements.v_series_collection_extract_split_points_boundary TO sdi_user2;																	 																																																			 
																		 
----CREATE TABLE lines_split AS-----
WITH 
temp_table1 AS (SELECT a.ogc_fid,ST_ClosestPoint(ST_Union(b.wkb_geometry), a.wkb_geometry)::geometry(POINT,3763) AS wkb_geometry FROM traitements.v_closest_point_on_line a, traitements.v_segments_series_boundary_armee_rtba b GROUP BY a.wkb_geometry,a.ogc_fid),
temp_table2 AS (SELECT 1 AS id, ST_Union(ST_AsMultiPoint(st_segmentize(wkb_geometry,1)))::geometry(MULTIPOINT,3763) AS wkb_geometry FROM traitements.v_segments_series_boundary_armee_rtba),
temp_table3 AS (SELECT b.ogc_fid, ST_snap(ST_Union(b.wkb_geometry),a.wkb_geometry, ST_Distance(a.wkb_geometry,b.wkb_geometry)*1.01)::geometry(POINT,3763) AS wkb_geometry
FROM temp_table2 a, temp_table1 b
GROUP BY a.wkb_geometry, b.wkb_geometry, b.ogc_fid)
SELECT a.ogc_fid, (ST_Dump(ST_split(st_segmentize(a.wkb_geometry,1),ST_Union(b.wkb_geometry)))).geom::geometry(LINESTRING,3763) AS wkb_geometry FROM traitements.v_segments_series_boundary_armee_rtba a, temp_table3 b
GROUP BY a.ogc_fid, a.wkb_geometry;																			 
*/																			 
																			 
																			 