SELECT * from pg_stat_activity;
-- Me muestra una foto de lo que actualmente está ocurriendo con mis conexiónes a la BBDD 
SELECT * from pg_stat_activity WHERE state = 'active';
-- Queries que en este momento se están ejecutando y poder analizar cuánto tiempo llevan


--- A nivel de BBDD qué tal nos va la cache
SELECT
    datname,
    blks_read,
    blks_hit,
    blks_hit * 100.0 / (blks_hit + blks_read) AS hit_ratio
FROM
    pg_stat_database
WHERE
    datname = 'postgres';
    
-- Un 70-80 hits, ya es muy aceptable
-- Si veo que este valor es bajo:
-- - Si puedo hacer un vacuum full.. compactar páginas y que las páginas estén más llenas.. De esa forma incrementaré el ratio de hits.
--   Antes de ejecuatrlo (porque es muy pesado), miro si va a aportar... Query de arriba
--   Debo identificar la (s) tablas culpables. Tendré muchas tablas pequeñas.. que estarán en RAM
SELECT
    relname,
    heap_blks_read,    -- Número de bloques de la tabla leídos desde el disco
    heap_blks_hit,     -- Número de bloques de la tabla encontrados en la cache
    heap_blks_hit * 100.0 / (heap_blks_hit + heap_blks_read) AS hit_ratio,
    idx_blks_read,     -- Número de bloques de índices leídos desde el disco
    idx_blks_hit      -- Número de bloques de índices encontrados en la cache
   ,idx_blks_hit * 100.0 / (idx_blks_hit + idx_blks_read) AS idx_hit_ratio
FROM
    pg_statio_user_tables
WHERE 
heap_blks_hit > 0
ORDER BY
    hit_ratio DESC;
--   SELECT * FROM pgstattuple('tablaX');
-- - Aumentar el tamaño de memoria para cache:
--      - shared_buffers (Lo que postgres guarda/reserva para cache de datos)
--      - La de SO (EL SO va a tratar de coger todo lo que pueda y más!)
-- $ free
--                total        used        free      shared  buff/cache   available
-- Mem:         7999100     1279256     4879204       41684     1840640     6360316
-- El SO tratará de coger para buff/cache todo lo que pueda.
-- Será memoria que me aparecerá como available(dispinible)
--      - effective_cache_size: ESTIMACION de shared_buffers+buff/cache
--        Se usa para el planificador
-- Puedo subir shared_buffers... pero como digo... es a costa de cache de Sistema
-- work_mem (a priori no está reservada, se reserva dinámicamente para cada conexión cuando se establece)
--
--    TOTAL:          8Gbs de RAM
--    SHARED_BUFFERS: 3Gbs (30-40% de la RAM global)
        -- Tamaño mínimo de cache
        -- Tamaño real de cache 80%
--    Uso SO+BBDD:    0.5 Gb
--    Mntenimiento
--    workers * # de workers
--    Cache de SO.    Con esta jugamos (FLEXIBLE-Me sirve de comodín)
--      Ésta es la que un momento dado puede entra a usarse para cache
--      O si entran muchas conexiones se librerá para atender conexiones
--      O si entran operaciones de mnto muchas... se liberá para ese trabajo
-- Si el SO se queda sin RAM:           Swap:          488Mi          0B       488Mi
-- Si free hay libre... mal asunto! Pero esto no va a pasar.. O tengo una BBDD muy pequeña... o el SO la llena

-- Pensad que en una BBDD / Gestionada meadinte un app... El nivel de uso de la CACHE es enorme
-- Estoy siempre accediendo a los mismos datos.
-- Gestión de expedientes... Pues los 2500 expedientes que tenemos abiertos.. están en cache
-- Y alguna query necesitará cargar otros.. guay!
-- Y de vez en cuando se irán metiendo datos nuevos...
-- Y otro se irán dejando de usar.

-- BBDD de tipo DATALAKE
-- Para cargas intensivas de datos. Canal isabel II
-- Cargas continuas de datos...-> ETL a otro lado

-- Quien usa la cache:
SELECT
    c.relname,
    count(*) AS buffers,
    isdirty
FROM
    pg_buffercache b
JOIN
    pg_class c ON b.relfilenode = c.relfilenode
WHERE
    b.reldatabase = (SELECT oid FROM pg_database WHERE datname = 'postgres')
GROUP BY
    c.relname, isdirty
ORDER BY
    buffers DESC;