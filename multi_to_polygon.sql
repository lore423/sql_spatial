--ALTER TABLE traitements.decoupe_armee_voltac ALTER COLUMN wkb_geometry type geometry(Polygon, 2154) using ST_Multi(wkb_geometry);

CREATE TABLE traitements.decoupe_armee_voltac3 AS 
   SELECT ogc_fid, name, type, (ST_DUMP(wkb_geometry)).geom::geometry(Polygon,2154) AS wkb_geometry FROM traitements.decoupe_armee_voltac;
  
