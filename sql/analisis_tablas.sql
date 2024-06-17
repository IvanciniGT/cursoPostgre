CREATE EXTENSION IF NOT EXISTS pgstattuple;


SELECT 
  pg_relation_size('visualizaciones_2024') as tamaño_tabla_crudo,
  pg_size_pretty(pg_relation_size('visualizaciones_2024')) as tamaño_tabla,
  pg_size_pretty(pg_total_relation_size('visualizaciones_2024')) as tamaño_con_indices
;
SELECT 
  relname AS nombre_tabla,
  n_live_tup AS filas
FROM 
  pg_stat_all_tables
WHERE 
  relname = 'visualizaciones_2024';
SELECT * FROM pgstattuple('visualizaciones_2024');





DELETE FROM VISUALIZACIONES WHERE MOD(usuario,100) = 0; -- Borro 1 de cada 100 filas... borro el 1% de los datos



SELECT 
  pg_relation_size('visualizaciones_2024') as tamaño_tabla_crudo,
  pg_size_pretty(pg_relation_size('visualizaciones_2024')) as tamaño_tabla,
  pg_size_pretty(pg_total_relation_size('visualizaciones_2024')) as tamaño_con_indices
;
SELECT 
  relname AS nombre_tabla,
  n_live_tup AS filas
FROM 
  pg_stat_all_tables
WHERE 
  relname = 'visualizaciones_2024';
SELECT * FROM pgstattuple('visualizaciones_2024');
