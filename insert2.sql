--INSERT INTO contraintes_techniques.armee_voltac_zones_favorables(
	--ogc_fid, name, type, wkb_geometry)
	--VALUES (?, ?, ?, ?);
	
--SELECT ogc_fid, name, type, wkb_geometry
	--FROM contraintes_techniques.armee_voltac_zones_favorables;
	
SELECT ogc_fid, wkb_geometry, name, type
	FROM traitements.decoupe_voltac_zones_favorables;