--Polygon to lines
CREATE OR REPLACE VIEW planification.v_plateformes_mesures_lignes AS
SELECT row_number() OVER () AS id,
id_projet,
ST_MakeLine(sp,ep) 
FROM
   -- extract the endpoints for every 2-point line segment for each linestring
   (SELECT
	  id_projet,
      ST_PointN(geom, generate_series(1, ST_NPoints(geom)-1)) as sp,
      ST_PointN(geom, generate_series(2, ST_NPoints(geom)  )) as ep
    FROM
       -- extract the individual linestrings
      (SELECT 
	   id_projet,
	   (ST_Dump(ST_Boundary(wkb_geometry))).geom
       FROM planification.plateformes
       ) AS linestrings
    ) AS wkb_geometry;
			   
	