-- View: planification.v_balance_of_plant

DROP VIEW planification.v_balance_of_plant;

CREATE OR REPLACE VIEW planification.v_balance_of_plant AS
 SELECT row_number() OVER () AS id,
    subq2.category,
    subq2.sub_category,
    subq2.total,
    subq2.unit,
    subq2.id_projet,
    proj.code,
    proj.nom
   FROM ( SELECT subq1.category,
            subq1.type AS sub_category,
            sum(subq1.mesure) AS total,
            subq1.id_projet,
            subq1.unit
           FROM ( SELECT acces.ogc_fid,
                    'Accès'::text AS category,
                    acces.type,
                    round(st_length(acces.wkb_geometry)::numeric, 2) AS mesure,
                    'm'::text AS unit,
                    acces.id_projet
                   FROM planification.acces
                UNION
                 SELECT cablage_interne.ogc_fid,
                    'Câblage interne'::text AS category,
                    'NA'::character varying AS type,
                    round(st_length(cablage_interne.wkb_geometry)::numeric, 2) AS mesure,
                    'm'::text AS unit,
                    cablage_interne.id_projet
                   FROM planification.cablage_interne
                UNION
                 SELECT cablage_externe.ogc_fid,
                    'Câblage externe'::text AS category,
                    'NA'::character varying AS type,
                    round(st_length(cablage_externe.wkb_geometry)::numeric, 2) AS mesure,
                    'm'::text AS unit,
                    cablage_externe.id_projet
                   FROM planification.cablage_externe
                UNION
                 SELECT virage_pan_coupe.ogc_fid,
                    'Virage pan coupé'::text AS category,
                    'NA'::character varying AS type,
                    round(1::numeric, 0) AS mesure,
                    ''::text AS unit,
                    virage_pan_coupe.id_projet
                   FROM planification.virage_pan_coupe
				UNION
                 SELECT poste_livraison.ogc_fid,
                    'Poste de livraison'::text AS category,
                    'NA'::character varying AS type,
                    round(1::numeric, 0) AS mesure,
                    ''::text AS unit,
                    poste_livraison.id_projet
                   FROM planification.poste_livraison
                UNION
                 SELECT deboisement.ogc_fid,
                    'Déboisement'::text AS category,
                    'NA'::character varying AS type,
                    round(st_area(deboisement.wkb_geometry)::numeric, 2) AS mesure,
                    'm2'::text AS unit,
                    deboisement.id_projet
                   FROM planification.deboisement
				UNION
                 SELECT plateformes.ogc_fid,
                    'Plateformes'::text AS category,
                    'NA'::character varying AS type,
                    round(st_area(plateformes.wkb_geometry)::numeric, 2) AS mesure,
                    'm2'::text AS unit,
                    plateformes.id_projet
                   FROM planification.plateformes) subq1
          GROUP BY subq1.category, subq1.type, subq1.id_projet, subq1.unit) subq2
     LEFT JOIN fdw_vdo1_gestion_fonciere.projets proj ON subq2.id_projet = proj.id
  ORDER BY proj.nom, subq2.category, subq2.sub_category;

ALTER TABLE planification.v_balance_of_plant
    OWNER TO sdi_user2;

GRANT ALL ON TABLE planification.v_balance_of_plant TO "lorena.posada";
GRANT SELECT ON TABLE planification.v_balance_of_plant TO PUBLIC;
GRANT ALL ON TABLE planification.v_balance_of_plant TO sdi_user2;