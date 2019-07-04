INSERT INTO contraintes_techniques.armee_voltac
(name, type, altitude_min_ft, altitude_min_m, altitude_min_type, altitude_max_ft, altitude_max_m, altitude_max_type, night_only, wkb_geometry)
--	VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
SELECT name, type, 
NULL AS altitude_min_ft, NULL AS altitude_min_m, NULL AS altitude_min_type, 
NULL AS altitude_max_ft, NULL AS altitude_max_m, NULL AS altitude_max_type, NULL AS night_only, wkb_geometry
	FROM traitements.decoupe_armee_voltac;
	
--SELECT ogc_fid, wkb_geometry, name, type, altitude_m, altitude_1, altitude_2, altitude_3, altitude_4, altitude_5, night_only
	-- FROM traitements.decoupe_armee_voltac;