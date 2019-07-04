UPDATE contraintes_techniques.armee_voltac
SET wkb_geometry=subquery.wkb_geometry,
FROM (SELECT ogc_fid, wkb_geometry
      FROM  traitements.decoupe_armee_voltac) AS subquery
WHERE armee_voltac.ogc_fid=subquery.ogc_fid;


UPDATE contraintes_techniques.armee_voltac
	WHERE armee_voltac.wkb_geometry = traitements.decoupe_armee_voltac;