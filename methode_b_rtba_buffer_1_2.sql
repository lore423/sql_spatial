--METHODE B-----
--Buffer test
DROP VIEW IF EXISTS traitements.v_buffer_test CASCADE;
CREATE VIEW traitements.v_buffer_test AS

WITH 
rtba_union AS 
(
SELECT ST_Multi(ST_Union(ST_Buffer(wkb_geometry,10)))::geometry(MultiPolygon,2154) AS wkb_geometry FROM contraintes_techniques.armee_rtba
)
,
rtba_buffer_negative AS 
(
SELECT
ST_Multi(ST_Buffer(wkb_geometry, -6492))::geometry(MultiPolygon,2154) AS wkb_geometry
FROM rtba_union
)
,
rtba_buffer_retabli AS
(
SELECT ST_Multi(ST_Union(ST_Buffer(wkb_geometry, 6505)))::geometry(MultiPolygon,2154)  AS wkb_geometry FROM rtba_buffer_negative
)
SELECT 1 AS ogc_fid,wkb_geometry  FROM rtba_buffer_retabli;
						 
GRANT SELECT ON TABLE traitements.v_buffer_test TO PUBLIC;
GRANT ALL ON TABLE traitements.v_buffer_test TO sdi_user2;	

											 					 
--Generate boundary
DROP VIEW IF EXISTS traitements.v_buffer_test_boundary CASCADE;
CREATE VIEW traitements.v_buffer_test_boundary AS						
SELECT 	ogc_fid,
		ST_Multi(ST_Boundary(wkb_geometry))::geometry(MultilineString, 2154) AS wkb_geometry				 
FROM 	traitements.v_buffer_test;	
							 
GRANT SELECT ON TABLE traitements.v_buffer_test_boundary TO PUBLIC;
GRANT ALL ON TABLE traitements.v_buffer_test_boundary TO sdi_user2;
							 
--Generate series
DROP VIEW IF EXISTS traitements.v_series_buffer_test_boundary CASCADE;
CREATE VIEW traitements.v_series_buffer_test_boundary AS
							 
SELECT 
	row_number() over() as ogc_fid, 
	wkb_geometry::geometry(LineString, 2154) 
FROM
(									 
SELECT 
	ST_GeometryN(wkb_geometry, 
	generate_series(1, ST_NumGeometries(wkb_geometry))) as wkb_geometry
FROM traitements.v_buffer_test_boundary) AS foo;									 

GRANT SELECT ON TABLE traitements.v_series_buffer_test_boundary TO PUBLIC;
GRANT ALL ON TABLE traitements.v_series_buffer_test_boundary TO sdi_user2;												
				
--segments intersectés par le buffer test (1MN)
DROP VIEW IF EXISTS traitements.v_segments_intersectes CASCADE;
CREATE VIEW traitements.v_segments_intersectes AS
					
SELECT row_number() over() as ogc_fid, 1852 AS buffer, ST_Intersection(a.wkb_geometry, b.wkb_geometry) AS wkb_geometry
FROM traitements.v_series_boundary_armee_rtba AS a, traitements.v_buffer_test AS b
WHERE ST_Intersects(a.wkb_geometry, b.wkb_geometry);
					
GRANT SELECT ON TABLE traitements.v_segments_intersectes TO PUBLIC;
GRANT ALL ON TABLE traitements.v_segments_intersectes TO sdi_user2;			

--segments non intersectés par le buffer test (2MN)
DROP VIEW IF EXISTS traitements.v_segments_non_intersectes CASCADE;
CREATE VIEW traitements.v_segments_non_intersectes AS
					
SELECT row_number() over() as ogc_fid, 3704 AS buffer, ST_Difference(a.wkb_geometry, b.wkb_geometry) AS wkb_geometry
FROM traitements.v_series_boundary_armee_rtba AS a, traitements.v_buffer_test AS b
WHERE ST_Intersects(a.wkb_geometry, b.wkb_geometry);
								
GRANT SELECT ON TABLE traitements.v_segments_non_intersectes TO PUBLIC;
GRANT ALL ON TABLE traitements.v_segments_non_intersectes TO sdi_user2;	

--correction_manuelle
DROP TABLE traitements.correction_manuelle;
CREATE TABLE traitements.correction_manuelle AS

SELECT row_number() over() as ogc_fid, wkb_geometry, buffer, NULL::boolean AS correction_manuelle
					FROM (
					SELECT * FROM traitements.v_segments_non_intersectes
					UNION
					SELECT * FROM  traitements.v_segments_intersectes
					) as foo;

GRANT SELECT ON TABLE traitements.correction_manuelle TO PUBLIC;
GRANT ALL ON TABLE traitements.correction_manuelle TO sdi_user2;


---segments correction manuelle
DROP TABLE IF EXISTS traitements.segments_correction_manuelle;
CREATE TABLE traitements.segments_correction_manuelle AS
					
SELECT 
	row_number() over() as ogc_fid, buffer,NULL::boolean AS correction_manuelle,
	wkb_geometry::geometry(LineString, 2154)
FROM
(									 
SELECT 
	buffer, ST_GeometryN(wkb_geometry,
	generate_series(1, ST_NumGeometries(wkb_geometry))) as wkb_geometry
FROM traitements.correction_manuelle) AS foo;											

ALTER TABLE traitements.segments_correction_manuelle
    ADD CONSTRAINT pk_segments_correction_manuelle PRIMARY KEY (ogc_fid);
					
GRANT ALL ON TABLE traitements.segments_correction_manuelle TO PUBLIC;
GRANT ALL ON TABLE traitements.segments_correction_manuelle TO sdi_user2;			

				
--Generate buffer 
DROP VIEW IF EXISTS traitements.v_buffer_segments_correction_manuelle CASCADE;
CREATE VIEW traitements.v_buffer_segments_correction_manuelle AS

SELECT 1 as ogc_fid, ST_Multi(ST_Union(ST_Buffer(wkb_geometry,buffer)))::geometry(MultiPolygon,2154) AS wkb_geometry FROM traitements.segments_correction_manuelle;						
				
GRANT SELECT ON TABLE traitements.v_buffer_segments_correction_manuelle TO PUBLIC;
GRANT ALL ON TABLE traitements.v_buffer_segments_correction_manuelle TO sdi_user2;								   
									   
--Difference buffer union with union armee rtba
DROP VIEW IF EXISTS traitements.v_difference_buffer_union CASCADE;
CREATE VIEW traitements.v_difference_buffer_union AS
				
SELECT 
	1 as ogc_fid,
	ST_Difference(a.wkb_geometry, b.wkb_geometry)::geometry(MultiPolygon,2154) as wkb_geometry 
FROM traitements.v_buffer_segments_correction_manuelle a, traitements.v_union_rtba_multipolygon b;
							   
GRANT SELECT ON TABLE traitements.v_difference_buffer_union TO PUBLIC;
GRANT ALL ON TABLE traitements.v_difference_buffer_union TO sdi_user2;		

--Create la view materialisée buffer 1 et 2mn
CREATE MATERIALIZED VIEW contraintes_techniques.mv_armee_rtba_buffer_1_2mn
AS
	SELECT * FROM traitements.v_difference_buffer_union	
WITH DATA;

CREATE UNIQUE INDEX uidx_mv_armee_rtba_buffer_1_2mn
    ON contraintes_techniques.mv_armee_rtba_buffer_1_2mn USING btree
    (ogc_fid);
												 
REFRESH MATERIALIZED VIEW CONCURRENTLY contraintes_techniques.mv_armee_rtba_buffer_1_2mn;										
												 
GRANT ALL ON TABLE contraintes_techniques.mv_armee_rtba_buffer_1_2mn TO PUBLIC;
GRANT SELECT ON TABLE contraintes_techniques.mv_armee_rtba_buffer_1_2mn TO PUBLIC;	
												 
-- Create la view materialisée du buffer union (methode A)
CREATE MATERIALIZED VIEW contraintes_techniques.mv_armee_rtba_buffer_negative
AS
	SELECT * FROM traitements.v_buffer_negative_union
WITH DATA;

CREATE UNIQUE INDEX uidx_mv_armee_rtba_buffer_negative
    ON contraintes_techniques.mv_armee_rtba_buffer_negative USING btree
    (ogc_fid);
												 
REFRESH MATERIALIZED VIEW CONCURRENTLY contraintes_techniques.mv_armee_rtba_buffer_negative;										
												 
GRANT ALL ON TABLE contraintes_techniques.mv_armee_rtba_buffer_negative TO PUBLIC;
GRANT SELECT ON TABLE contraintes_techniques.mv_armee_rtba_buffer_negative TO PUBLIC;													 