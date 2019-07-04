CREATE TRIGGER plateformes_trigger
  AFTER UPDATE OR INSERT OR DELETE
  ON planification.poste_livraison
  FOR EACH ROW
  EXECUTE PROCEDURE planification.poste_livraison_history_func();
