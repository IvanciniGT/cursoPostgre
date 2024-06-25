# Ayer montamos un cluster "Activo-Activo"

Postgres no tiene nada como lo que sería un Oracle RAC o un MySQL Galera.
No ofrece un cluster REAL Activo-Activo.

En el mercado, para suplir esto... y montar algo medio parecido.

Realmente en protgres, todas las soluciones ente sentido pasan por montar un cluster MULTIMAESTRO con replicación BIDIRECCIONAL!

    MAESTRO1
      ^  ^
    MAESTRO2

Y esto:
1. Era un follón conceptual .. y de trabajo (que es lo que de alguna forma me dulcifican esas Apps)
2. No ofrece HA real

# En postgres la HA la gestionamos:

- Replica (promote a maestro)... y un balanceador delante o un cambio de IPs (VIPAs)
- Reinicio/Recreación del maestro (Si estamos en entornos virtualizados: contenedores o vm)

# Para tener escalabilidad en lecturas

             (queries BI)  (Backups)
    Maestro -> Replica1 -> Replica2
      ^ v         v           v
     IN OUT      OUT         OUT

# Cómo tener escalabilidad en Escrituras (Insert, Update, Delete)

Cluster MultiMaestro de recplicación BIDIRECCIONAL

    Maestro1 <-> Maestro2
      ^  v         v  ^
     IN  OUT      IN  OUT

Por defecto NO OFRECE HA... Solo me da 2 sitios donde poder hacer IN/OUT en paralelo.
Si quiero HA, más me vale a cada una de esas máquinas:
- Montarle una replica que poder promocionar en autom. 
   ~ Tiempo de indisponilidad . Podría tenerlo muy bajo : 0.5s ~ 30 segundos
                                Pero eso nunca lo configuraré, ya que si se cae la red... 
                                o una máquina esta petada un momentito... y no me ha contestado
                                Hago promoción automática... Y FOLLONAZO ! 
                                    Me llevaré 2 horitas para reeestablecer el esclavo...
                                    + Un full backup del maestro (antiguo esclavo)
- O si estoy en entornos virtualizados reinicio/recreación del entorno 
   ~ Tiempo de indisponibilidad : Contenedores: 5 segundos/20 segundos
                                  VMs: 1-3 minutos    

Un problema es que la replicación en los custers MULTIMAESTRO no puede hacerse como nosotros aprendimos (REPLICACION FISICA)
Se copia todas las BBDD de esa máquina completas.

Y entonces necesitamos otro concepto: REPLICACION LOGICA.

Los conceptos son similares a lo que es un BACKUPS FISICO / BACKUPS LOGICO
- Backups FISICO: COPIO TODO
- Backup LOGICO: Elijo que copio... (solo muevo DATOS... no archivos)

Para conseguir esa REPLICACION LOGICA (que me permite copiar-> REPLICAR) solamente algunas BBDD o tablas sueltas
antes se usaba una extensión de postgres, llamada pg_logical

Desde PostgrSQL 16, nativamente POSTGRES permite esa replicación logica (ya no necesita de extensiones).

    CREATE PUBLICATION mi_publicacion FOR ALL TABLES;
    
Y a nivel de la replica: montar una SUBSCRIPCION

    CREATE SUBSCRIPTION mi_subscripcion 
    CONNECTION 'host=maestro port=5432 dbname=midb usuario=replicator password=Pa$$w0rd'
    PUBLICATION mi_publicacion;

Esto por si solo no me permite montar un cluster MULTIMAESTRO de recplicación bidireccional... ES MUCHO MAS FOLLON.
Decíamos que trabajamos con BBDD con tablas particionadas y con secuencias DESPLAZADAS

    Usuarios     Usuarios
         ^           ^          2 problemas: 
    Maestro1 <-> Maestro2           1. Cada una da sus IDs... y al compartirse pueden colapsar
      ^  v         v  ^             2. Si una máquina copia su tabla a la otra, machaca sus datos.
     IN  OUT      IN  OUT
    
    Usuarios: 2 particiones
    
    Maestro1 (Usuarios1). Y además, haré que en está los IDs empiezen en 1... con un paso de 10
    Maestro2 (Usuarios2). Y en esta haré que los         IDs empiezen en 2... con un paso de 10
    
    La tabla Usuarios1 -> Se replica al maestro2
    Mientras que la tabla Usuarios2 -> maestro1
    
    De esta forma, las 2 máquinas tienen todos los datos, cada una va escribiendo parte de los datos
    Y me aseguro que los IDs no colisionan.
    
    Y AHORA MULTIPLICA ESTO POR 50 tablas... o las que sean = FOLLONAZO !!!!
    
Con lo cuál:

        AQUI es donde POSTGRES BRILLA!
        vvv
- Si estoy en un entorno virtualizado (HA) por reinicio/recreación
    - Si tengo una BBDD con pocas actualizaciones / consultas -> 1 máquina y punto pelota (MAS HABITUAL)
    - Si tengo muchas consultas pero pocas actualizaciones    -> 1 maestro y 1 replica (consulta, sin promoción)
    - Si tengo muchas consultas y actualizaciones             -> multimaestro (sin replciación)


        AQUI es donde ECHO DE MENOS AL ORACLE y al SQL Server!
        vvv
- Si estoy con hierros físicos (HA) por promocionado de replica = FOLLON
    - Si tengo una BBDD con pocas actualizaciones / consultas -> 1 máquina y 1 replica 
    - Si tengo muchas consultas pero pocas actualizaciones    -> 1 maestro y 1 replica (consulta y promocionado)
                                                                Y CUIDADO ! que como se caiga la principal
                                                                Y entre la replica como maestro... 
                                                                se tiene que comer toda la mierda que antes se comían 
                                                                las 2 juntas.
                                                                A ver si puede
    - Si tengo muchas consultas y actualizaciones             -> multimaestro (con replicación)

---

Decíamos que la replciación bidireccional multimaestro se facilita al usar algunas apps externas:
- Distributed Postgres: DE PAGO
- Citus: Opensource y grtuito... pero muy maduro: Microsoft en AZURE, la solución que monta de Postgres es CITUS
        - Azure Cosmos DB


---

# Problemas de Rendimiento de la BBDD.. tuning al postgreSQL

En ocasiones voy a datectar (especialmente según la BBDD va siendo más usada)
tiempos de respuesta que no son aceptables... o que deseamos mejorar.

- Problema generalizado en la BBDD : AQUI NO PUEDO ECHAR BALONES FUERA . LA MIERDA ME CAE A MI!
    - Desde el principio estoy con problemas        OJO DE BUEN CUBERO !      Ver las queries de ahora mismo
        ^ Otro motivo (es que la app se empiece a usar más) 
        - Infra/HARDWARE
            - CPU:     Veo la CPU sostenida alta... me falta CPU (RARO)
            - RAM:     ME FALTA RAM (es capaz de trabajar con 3Gbs de RAM o con 300Gbs... otra cosa es el rendimiento)
                        CONSULTAS 
                        - Tengo un uso muy alto de RAM (eso está bien)
                        - No tengo un uso muy alto de RAM (configuración)
                        - Tengo mucha paginación MAL!!!
            - DISCO     CONSULTAS/"ACTUALIZACION"
                            - Volumenes más rápidos : SSD / NVME
                            - Separar volumenes en discos distintos:
                                - Separo tablas que tengan trabajo intenso (PARTICIONADO incluso)
                                - Indices
        - Configuración
            - CPU: Número de workers/conexiones
            - RAM: work_mem. ni lo miro a no ser que sea extraordinariamente bajo
                    Buffers de cache
                    Bufferes de los wal
                    Cache de SO
                    Memoria reservadada para operaciones de mnto
            - DISCO:
                    Demasiadas escrituras... las demoro en el tiempo (sacrifico datos en caso de problema)   
    - Rendimiento se degrada! general!              MONITORIZACION HISTORICO! Ver las queries de los ultimos X meses
        - Mirar el crecimiento de las tablas EN DATOS
            - Han subido
                - No Los necesito: me los llevo a un datalake
                - Si los necesito: PARTICIONADO DE DATOS FECHAS...
            - No han subido en valor absoluto
                - Fragmentación -> MEMORIA / DISCO
        - Mirar el crecimiento de las tablas EN BYTES
    
- Problemas con queries u operaciones puntuales en la BBDD
    - QUERIES: Necesito identificar la query y mirar el plan de ejecución EXPLAIN ANALIZE
                Si los datos de estimación de costos no concuerdan con los datos reales:
                    Opción razonable:
                    - Work_mem: Neceito incrementarla o se tira de HDD
                    Estas posibles causas, darían la cara no solo con una query... sino de forma más generalizada
                    - ESTADISTICAS no están actualizadas
                    - Con queries que devuelven muchos datos: Compactación de la BBDD (VACUUM FULL): ETL
                    - Fragmentación de los índices (no debería de afectar tanto aquí)
                        En RAM el índice se cachea consolidado...   
                    EL PROBLEMA NO ESTABA EN EL PLAN DE EJECUCION... SINO EN LA EJECUCION DEL PLAN ! 
                Si los datos concuerdan, tiramos por otro:
                    FIJO no está en la ejecución del plan.
                    EL PROBLEMA ESTA EN EL PLAN DE EJECUCION... Pero quizás no se podía hacer mejor.
                    - En el plan ver que se están haciendo FULLScans en lugar de entrar por índices:
                        - ** Necesitamos índices o replantear los que tenemos **
                        - Replantear la QUERY
                        - Soluciones conjntas: Replantear la query y crear índices para ello
                        - Desnormalizar tablas
        - Problemas en la configuración de memoria del POSTGRES? 
            - WORK_MEM: La parte de la memoria que se asigna para las conexiones... para que ejecuten las queries
                Si el trabajador no tiene suficiente memoria configurada... Empezará a tirar de HDD (sort, filter, joins)
                    En este caso me interesa subir la memoria workers (CON CUIDADO de no pasarme)
            - AREA DE CACHES? Nop
        - Modelo de datos: CAMBIO desnormalizar (DESARROLLO)
    - MNTO de la BBDD
        - Los workers que usamos para esto y mas memoria de los workers de mnto (Muy raro).
        - VACUUM    \                                                                                       |
        - ANALIZE   / Bloquean tabla... AUMENTAR FRECUENCIA... Más veces... pero más cortas en el tiempos   |
                        VACUUM Normal... evitar los FULL                                                    | PARTICIONADO DE TABLAS
                        Controlar muy bien los ANALYZE (en muchos casos los relanzamos sin necesidad)       | (divide y vencerás)
                        MUY POCAS COLUMNAS se van a beneficiar de ANALIZE (fechas... ids...)                |
        - REINDEX                                                                                           |
                Aquí hay poca poesia. De vez en cuando hay que hacerlos.. y tardan lo que tardan            |
        - BACKUP: Nos joden mucho 
           - CALIENTE / FISICOS pgbasebackup (Hacen que los datos no se escriban en ficheros... para poder tener consistenciaen la copia)
             El problema viene cuando la BBDD Acabael backup... de repente tenemos que aplicar todo lo que se ha quedado en los WAL. 
                POCA SOLUCION!
                Si es un problema gordo... deberíamos pensar en replantear la estrategia de backup.
                    - Pasar a backup logicos incrementales (PS no lo soporta nativamente)
            - El propio backup tarde mucho... más de lo que considero aceptable.
                Se ha degradado mucho (con un volumen de datos similar ql que tenía)
                    1M datos -> 30 segundos     
                    1M datos -> 2 minutos       -> Si está no compactado, la tabla a lo mejor me ocupa el doble
                    2M datos -> 3 minutos       -> Si está no compactado, la tabla a lo mejor me ocupa el cuadruple
                Asegurar que el backups, SI ES FISICO, se haga sobre las tablas compactadas
                Me va a interesar lanzar un VACUUM FULL antes del backup
            - No hay huevos a aceptar los tiempos de backup (REPLICA y sobre la replica BACKUP)
                A esta máquina le pondría una configuración MUY DISTINTA de memoria.
                No necesito casi cache... ni work_men
                Necesito mucha memoria para operaciones de mnto.

            Puedo convivir sin problemas en la máquina maestra con VACUUM normales.
                Con un VACUUM normal, se marcan trozos de archivo(páginas) como libres.. reutilizables
                Y las rellenaré... Tendré un 20%-40% más de espacio en disco de lo que apriori sería necesario (en picos)
            Lo que me interesa es eso en la máquina de la hago los backups.
                Necesito un VACUUM FULL..sino voy generando Backups GIGANTES (que ocupan 1.5 veces más)

- Caídas de rendimiento que se presentan de forma discreta (a veces)
    - Me quede sin memoria -> HDD           \
        - Muchas queries muy complejas       > Demasiadas conexiones / trabajos muy pesados (BI) 
    - Me quede sin CPU                      / 
        
    SOLUCIONES:
        - REPLICA para ciertas queries
        - Limito conexiones (Tiempos de respuesta a nivel de la app se disparan): POCO PODRE TOMAR ESTA DECISION

        Hoy en día, los frameworks de desarrollo, que se usan para montar app, permiten TODOS trabajar con BBDD en espejo
        Y esos frameworks auto. reparten el trabajo: 
            - INSERT, UPDATE, DELETE -> MAESTRO
            - SELECT                 -> REPLICA
            
    MONITORIZAR CONEXIONES: REPLICA o bajar conexiones
    Si no se corresponde el uso disparado en un momento de CPU/RAM con un pico de conexiones,
        MIRAR Queries que se hayan ejecutado en ese momento: Llegado 4 de BI a tirar sus queries