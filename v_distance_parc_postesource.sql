CREATE OR REPLACE VIEW planification.v_distance_parc_postesource AS
 SELECT q.ogc_fid,
    q.projet_id,
    q.projet_code,
    q.projet_nom,
    q.projet_statut,
    q.postesource_code,
    q.postesource_nom,
    q.postesource_umax,
    q.postesource_umax_label,
    q.distance_parc_poste_source_km,
    q.num_parc_poste_source,
    q.wkb_geometry
   FROM ( SELECT parc_poste_dist.ogc_fid,
            parc_poste_dist.projet_id,
            parc_poste_dist.projet_code,
            parc_poste_dist.projet_nom,
            parc_poste_dist.projet_statut,
            parc_poste_dist.postesource_code,
            parc_poste_dist.postesource_nom,
            parc_poste_dist.postesource_umax,
            parc_poste_dist.postesource_umax_label,
            parc_poste_dist.distance_parc_poste_source_km,
            row_number() OVER (PARTITION BY parc_poste_dist.projet_id ORDER BY parc_poste_dist.distance_parc_poste_source_km) AS num_parc_poste_source,
            parc_poste_dist.wkb_geometry
           FROM ( SELECT row_number() OVER () AS ogc_fid,
                    projets_parcs.id_projet AS projet_id,
                    projets_parcs.code AS projet_code,
                    projets_parcs.nom AS projet_nom,
                    projets_parcs.statuts_projet AS projet_statut,
                    rte."Code" AS postesource_code,
                    rte."Nom" AS postesource_nom,
                    rte."uMax" AS postesource_umax,
                        CASE
                            WHEN rte."uMax"::text = '1'::text THEN '<45 kV'::text
                            WHEN rte."uMax"::text = '2'::text THEN '45 kV'::text
                            WHEN rte."uMax"::text = '3'::text THEN '63 kV'::text
                            WHEN rte."uMax"::text = '4'::text THEN '90 kV'::text
                            WHEN rte."uMax"::text = '5'::text THEN '150 kV'::text
                            WHEN rte."uMax"::text = '6'::text THEN '225 kV'::text
                            ELSE NULL::text
                        END AS postesource_umax_label,
                    ceil(st_distance(projets_parcs.parc_multipoint_geom, rte.wkb_geometry)) / 1000::double precision AS distance_parc_poste_source_km,
                    st_shortestline(projets_parcs.parc_multipoint_geom, rte.wkb_geometry)::geometry(LineString,2154) AS wkb_geometry
                   FROM ( SELECT subq2.id_projet,
                            p.code,
                            p.nom,
                            p.statuts_projet,
                            subq2.parc_multipoint_geom
                           FROM ( SELECT subq1.id_projet,
                                    subq1.parc_multipoint_geom
                                   FROM ( SELECT implantations_eol.id_projet,
    st_multi(st_collect(implantations_eol.wkb_geometry))::geometry(MultiPoint,2154) AS parc_multipoint_geom
   FROM planification.implantations_eol
  GROUP BY implantations_eol.id_projet) subq1
                                  WHERE subq1.id_projet > 0) subq2,
                            gestion_fonciere.projets p
                          WHERE subq2.id_projet = p.id) projets_parcs,
                    contraintes_techniques.rte_postes_sources
                  WHERE st_distance(projets_parcs.parc_multipoint_geom, rte.wkb_geometry) < 30000::double precision AND (rte."uMax"::text = ANY (ARRAY['3'::character varying::text, '4'::character varying::text]))) parc_poste_dist
          ORDER BY parc_poste_dist.projet_code, parc_poste_dist.distance_parc_poste_source_km) q
  WHERE q.num_parc_poste_source < 5;

ALTER TABLE planification.v_distance_parc_postesource
    OWNER TO "bjo.dec";

GRANT ALL ON TABLE planification.v_distance_parc_postesource TO "bjo.dec";
GRANT SELECT ON TABLE planification.v_distance_parc_postesource TO PUBLIC;