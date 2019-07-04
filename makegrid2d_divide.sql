-- makegrid_2d with

drop function public.makegrid_2d;
CREATE OR REPLACE FUNCTION public.makegrid_2d (
 bound_polygon public.geometry
)
RETURNS public.geometry AS
$body$
DECLARE
 Xmin DOUBLE PRECISION;
 Xmax DOUBLE PRECISION;
 Xdis DOUBLE PRECISION;
 Ymin DOUBLE PRECISION;
 Ymax DOUBLE PRECISION;
 Ydis DOUBLE PRECISION;
 X DOUBLE PRECISION;
 Y DOUBLE PRECISION;
 NextX DOUBLE PRECISION;
 NextY DOUBLE PRECISION;
 CPoint public.geometry;
 sectors public.geometry[];
 i INTEGER;
 SRID INTEGER;
BEGIN
 Xmin := ST_XMin(bound_polygon);
 Xmax := ST_XMax(bound_polygon);
 Ymin := ST_YMin(bound_polygon);
 Ymax := ST_YMax(bound_polygon);
 SRID := ST_SRID(bound_polygon);
 Xdis := ((ST_XMax(bound_polygon)+ST_XMin(bound_polygon))/2 - ST_XMin(bound_polygon));
 Ydis := ((ST_YMax(bound_polygon)+ST_YMin(bound_polygon))/2 - ST_YMin(bound_polygon)); 

 Y := ST_YMin(bound_polygon); --current sector's corner coordinate
 i := -1;
 <<yloop>>
 LOOP
   IF (Y > ((Ymax+Ymin)/2)) THEN  
       EXIT;
   END IF;

   X := Xmin;
   <<xloop>>
   LOOP
     IF (X > ((Xmax+Xmin)/2)) THEN
         EXIT;
     END IF;

     CPoint := ST_SetSRID(ST_MakePoint(X, Y), SRID);
     NextX := (X+Xdis);
     NextY := (Y+Ydis);

     i := i + 1;
     sectors[i] := ST_MakeEnvelope(X, Y, NextX, NextY, SRID);

     X := NextX;
   END LOOP xloop;
   CPoint := ST_SetSRID(ST_MakePoint(X, Y), SRID);
   NextY := (Y+Ydis);
   Y := NextY;
 END LOOP yloop;

 RETURN ST_Collect(sectors);
END;
$body$
LANGUAGE 'plpgsql';

-- Subdivide le polygone en quatre carrés																	  
SELECT (
  ST_Dump(
    makegrid_2d(wkb_geometry
     ) )
) .geom FROM foncier.v_projet_ep_parcelles_grouped_envelope
																	  
																	  