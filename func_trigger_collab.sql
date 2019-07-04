CREATE OR REPLACE FUNCTION planification.poste_livraison_history_func()
RETURNS trigger AS
$$
BEGIN
	CASE TG_OP
		WHEN 'INSERT' THEN
			INSERT INTO planification.poste_livraison_history
				VALUES (NEW.*, current_timestamp::timestamp with time zone, current_user);
			RETURN NEW;
		WHEN 'DELETE' THEN
			UPDATE planification.poste_livraison_history
				SET deleted_date = current_timestamp::timestamp with time zone,
					deleted_by = current_user
				WHERE deleted_date IS NULL AND ogc_fid = OLD.ogc_fid;
			RETURN NULL;
		WHEN 'UPDATE' THEN
			UPDATE planification.poste_livraison_history
				SET deleted_date = current_timestamp::timestamp with time zone,
					deleted_by = current_user
				WHERE deleted_date IS NULL AND ogc_fid = OLD.ogc_fid;
			INSERT INTO planification.poste_livraison_history
				VALUES (NEW.*, current_timestamp::timestamp with time zone, current_user);
			RETURN NEW;
	END CASE;
END;
$$
LANGUAGE 'plpgsql';
