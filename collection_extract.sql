/*
--ST_CollectionExtract segments_series_boundary_armee_rtba
DROP VIEW IF EXISTS traitements.v_collection_extract_segments_series_boundary_armee CASCADE;
CREATE VIEW traitements.v_collection_extract_segments_series_boundary_armee AS
SELECT row_number() over() as ogc_fid, wkb_geometry::geometry(LineString, 2154)	FROM			
(SELECT ST_CollectionExtract(wkb_geometry,2) as wkb_geometry
FROM traitements.v_segments_series_boundary_armee_rtba) AS foo;

GRANT SELECT ON TABLE traitements.v_collection_extract_segments_series_boundary_armee TO PUBLIC;
GRANT ALL ON TABLE traitements.v_collection_extract_segments_series_boundary_armee TO sdi_user2;


--ST_CollectionExtract extract v_closest_point_on_line
DROP VIEW IF EXISTS traitements.v_collection_extract_closest_point_on_line CASCADE;
CREATE VIEW traitements.v_collection_extract_closest_point_on_line AS
SELECT row_number() over() as ogc_fid, wkb_geometry::geometry(Point, 2154)	FROM			
(SELECT ST_CollectionExtract(wkb_geometry,1) as wkb_geometry
FROM traitements.v_closest_point_on_line) AS foo;

GRANT SELECT ON TABLE traitements.v_collection_extract_closest_point_on_line TO PUBLIC;
GRANT ALL ON TABLE traitements.v_collection_extract_closest_point_on_line TO sdi_user2;


-- ST_CollectionExtract v_split_points_boundary (Pasar de geometrycollection a multilinestring)
DROP VIEW IF EXISTS traitements.v_collection_extract_split_points_boundary CASCADE;
CREATE VIEW traitements.v_collection_extract_split_points_boundary AS
SELECT row_number() over() as ogc_fid, wkb_geometry::geometry(MultilineString, 2154)	FROM			
(SELECT ST_CollectionExtract(wkb_geometry,2) as wkb_geometry
FROM traitements.v_split_points_boundary) AS foo;

GRANT SELECT ON TABLE traitements.v_collection_extract_split_points_boundary TO PUBLIC;
GRANT ALL ON TABLE traitements.v_collection_extract_split_points_boundary TO sdi_user2;


--Generate series v_collection_extract_split_points_boundary (pasar de multilinestring a lignestring)
DROP VIEW IF EXISTS traitements.v_series_collection_extract_split_points_boundary CASCADE;
CREATE VIEW traitements.v_series_collection_extract_split_points_boundary AS
SELECT row_number() over() as ogc_fid, wkb_geometry::geometry(LineString, 2154) FROM
(									 
SELECT ST_GeometryN(wkb_geometry, 
	generate_series(1, ST_NumGeometries(wkb_geometry))) as wkb_geometry
FROM traitements.v_collection_extract_split_points_boundary) AS foo;									 

GRANT SELECT ON TABLE traitements.v_series_collection_extract_split_points_boundary TO PUBLIC;
GRANT ALL ON TABLE traitements.v_series_collection_extract_split_points_boundary TO sdi_user2;


--ST_Dump from collection extract segments_series_boundary_armee_rtba
DROP VIEW IF EXISTS traitements.v_dump_collection_extract_segments_series_boundary_armee_rtba CASCADE;
CREATE VIEW traitements.v_dump_collection_extract_segments_series_boundary_armee_rtba AS
SELECT row_number() over() as ogc_fid, (gdump).geom::geometry(LineString,2154) AS wkb_geometry FROM (
SELECT ogc_fid, ST_Dump(wkb_geometry) AS gdump
FROM traitements.v_collection_extract_segments_series_boundary_armee) AS g;

GRANT SELECT ON TABLE traitements.v_dump_collection_extract_segments_series_boundary_armee_rtba TO PUBLIC;
GRANT ALL ON TABLE traitements.v_dump_collection_extract_segments_series_boundary_armee_rtba TO sdi_user2;

--ST_DumpPoints from collection extract closest points on line
DROP VIEW IF EXISTS traitements.v_dump_collection_extract_closest_point_on_line CASCADE;
CREATE VIEW traitements.v_dump_collection_extract_closest_point_on_line AS
SELECT row_number() over() as ogc_fid, (gdump).geom::geometry(Point,2154) AS wkb_geometry FROM (
SELECT ogc_fid, ST_DumpPoints(wkb_geometry) AS gdump
FROM traitements.v_collection_extract_closest_point_on_line) AS g;

GRANT SELECT ON TABLE traitements.v_dump_collection_extract_closest_point_on_line TO PUBLIC;
GRANT ALL ON TABLE traitements.v_dump_collection_extract_closest_point_on_line TO sdi_user2;									 

*/


