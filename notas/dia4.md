# VACUUM

Postgre, al hacer un vacuum de una tabla:
- Las filas que estaban muertas (dead_tuple) son eliminados de cada bloque
  de forma que en cada bloque ahora tengo espacio libre para escribir nuevos datos. 
  Pero los bloques (páginas siguen estando ahí... prereservadas... ocupando espacio).

El VACUUM está pensado para poder ejecutarse MUY RAPIDO

- VACUUM FULL visualizaciones_2024;
Este reescribe los datos que me quedan para compactarlos.

También podemos ejecutar solamente:
> VACUUM;                   -- APLICA A TODAS LAS TABLAS
> VACUUM FULL;
> VACUUM tabla;
> VACUUM FULL tabla;


Si tengo una sola tabla de visualizaciones, cada noche podría ejecutar
una ETL que me lleve las visualizaciones de más de 3 meses a un datalake.
Dejo muchos huecos -> Cada noche, despues de la ETL lanzo un `VACUUM visualizaciones`;

-- 
En otros escenarios, donde tengo tablas que si van borrando datos dinámicamente.
Me puede interesar dejar el AUTOVACUUM.
Si tengo periodos de inactividad... lo desactivo y lo lanzo en esos periodos.
    Si el fin de semana no trabaja la BBDD -> VACUUM
    Si las noches no trabaja -> VACUUM
Pero si tengo una BBDD 24x7, dejo el AUTOVACUUM

SET autovacuum_vacuum_scale_factor= 0.01

Define el % de filas que deben haber sido borradas antes de que se ejecute un AUTOVACUUM.

SET autovacuum_vacuum_threshold= 1000

Define el número mínimo de filas que deben haber sido borradas antes de que se ejecute un AUTOVACUUM.

EL VACUUM deja la tabla bloqueada. (incluso el normal.. por supuesto el FULL también)

Si tengo 20000 datos y borro 5000 datos...
siguen estando ocupadas 20000 filas de la tabla... Esos 5000 que he borrado siguen ocupando
hasta el VACUUM.
Otra cosa es el VACUUM FULL... que además, empaqueta las 15000 que me han quedao 
para que ocupen menos espacio en disco.


---

ANALYZE - Recolección de estadísticas

> ANALYZE;
> ANALYZE TABLA;
> ANALYZE TABLA(columna1, columna2);

Lo normal es que haya muchas muchas muchas columnas que sus estadísticas no cambian,
por más inserts que se hagan o updates!

COLUMNA: DNI
         CIF
         NOMBRE
         
         Cargaré más datos...
         Pero la proporción de DNIS que empiecen por 5: 10%
         o de CIF que empiecen por A1
         o de Nombres de empresa que empiecen por la letra a no cambia

Tengo la edad de los clientes
    Tendré un perfil de edad de clientes:
    Irán entrando y saliendo clientes... pero el perfil de edad no cambia mucho.

Hay columnas que lo necesitan de continuo: FECHAS !
    PEDIDOS (PRODUCTO) y van saliendo nuevos productos al mercado
BLOQUEA TABLA

El momento de lanzar un ANALYZE es cuando hago vacuum... 
> VACUUM ANALYZE tabla;
---

REBUILD -> SI CONCURRENTLY

SELECT * FROM pgstattuple('visualizaciones_usuario_idx')

    table_len	tuple_count	tuple_len	tuple_percent	dead_tuple_count	dead_tuple_len	dead_tuple_percent	free_space	free_percent
    65839104	1979883	31678128	48.11	0	0	0	25871520	39.3

    INDICE OCUPA: 65839104
    FILAS         31678128
    LIBRE         25871520       DISPONIBLE PARA FILAS NUEVAS (*)
    RESTO ->       8289456       METADATOS

    (*) Que los indices no son como las tablas... necesitan espacio prereservado (huecos entre medias)

    CREATE INDEX nombre ON tabla(columna) TABLESPACE tablespace WITH (fillfactor = 50)
    REINDEX INDEX indice

---


BBDD medida automatizadas
    TABLA por minutos

BBDD medidas manuales

    ME TEMO... espero ... confío... que se hagan pocas consultas.
    
