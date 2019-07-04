drop table if exists traitements.voltac_sans_zones_propices ;
create table traitements.voltac_sans_zones_propices as
(
	select t1.ogc_fid, 
		t1.name,
	ST_Buffer(ST_Buffer(St_difference(t1.wkb_geometry, t2.wkb_geometry), -50),50)::geometry('Polygon',2154)
as wkb_geometry
from
traitements.decoupe_armee_voltac as t1, 
(select ST_Union(wkb_geometry) AS wkb_geometry FROM traitements.decoupe_voltac_zones_favorables) as t2
);

ALTER TABLE traitements.voltac_sans_zones_propices
    ADD CONSTRAINT pk_voltac_sans_zones_propices PRIMARY KEY (ogc_fid);

GRANT SELECT ON TABLE traitements.voltac_sans_zones_propices TO projectmanager;
GRANT SELECT ON TABLE traitements.voltac_sans_zones_propices TO scouting;

