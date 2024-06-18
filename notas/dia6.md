# Instalaciones en producción

Fijo en producción quiero tener HA.. del algún tipo.

1. Necesito asegurar que en caso de problemas (SOFTWARE-PROCESO QUE SE QUEDA COLGAO- / HW) no perdemos los datos
2. Que puedo seguir ofreciendo servicio... en un tiempo breve o instantáneamente

Dentro de esto no entra el concepto backup: FALLOS NO DE HW... sino lógicos.

## Varias opciones

### Opción 1:

1. Monto un entorno con postgresql.
2. Lo configuro.. pero el almacenamiento de los datos (/var/lib/postgres/data) lo pongo en un almacenamiento independiente
    - cabina(fibra) LUN
    - iscsi
    - nfs
3. Tengo un entorno replica de ese (o lo puo crear facilmente) que en caso que el primero caiga, 
   levanto el segundo, pero tirando del mismo almacenamiento externo.
        
        MAESTRO (arrancado)
            almacenamiento ------> RED (REPLICACION - RAID, cephfs distribuido)
        OTRO MAESTRO (parada... o incluso no hay replica y la genero bajo demanda)
        
        Al caer el MAESTRO, arranco la replica con los datos que tenía el otro.

        ESTA FORMA ES LA MAS HABITUAL HOY EN DIA ! Con diferencia:
        KUBERNETES, con los contenedores.
        
        Luego en kubernetes puedo configurar autoescalado vertical. Mas CPU / RAM cuando sea necesario.
        Hoy en día, que imperan las arquitecturas orientadas a microservicios, lo que montamos ya no son MEGA BASES DE DATOS.
        Partimos un megaprograma en muchos programitas... y cada programita tiene su basecita de datos.. y ya no tengo una megabase de datos.
        
### Opción 2. MAESTRO-REPLICA

1. En este caso si habrá duplicación no solo del entorno, sino de los datos.... esto me puede venir mejor quel de arriba (OPCION 1)
   en que casos?
    - Ubicaciones diferentes geográficas... con la opción 1, puedo elegir un sistema de archivos distribuido (cephfs)
    - Separar carga de trabajo (gano solo en consulta)
        - NOTA: De hecho... habitual es hoy en día montar una instalación maestro-replica en kubernetes, donde además tengo la opción 1

### Opción 3: CLUSTER ACTIVO ACTIVO
---

# CEPHFS

Configuramos volumenes de almacenamiento lógicos.
El almacenamiento físico se realiza en distintas máquinas.
Cuando se manda un archivo, el archivo se parte en trozos.
Cada trozo se guarda varias veces en varias máquinas.
En cada máquina además podemos contar con discos de distinta naturaleza: NVME , SDD, HDD
Y usar un sistema de almacenamiento con rendimiento mejorado basado en cache.
Soy capaz de leer / escribir de muchisimos disposivos físicos simultaneamente

---

# Configuración en modo replicación
- Creamos una BBDD normalita... y le ponemos las configuraciones deseadas (MEMORIA, WORKERS...)
- Cogemos 2 ficheros para editarlos:
    - /var/lib/postgres/data/postgres.conf
        wal_level = replica         # La replicación se realiza por medio del envío de los transaccionales.log
        max_wal_senders = NUMERO    # Número de procesos para envío de esos trnsaccionales
        max_replication_slots = NUMERO # Número máximo de SERVIDORES REPLICA
        hot_standby = on            # Si la replica la quiero disponible para consultas
        hot_standby_feedback = on   # Si queremos que las replicas manden información de vuelta al 
                                    # maestro indicándole cuándo han terminado de procesar un batch de los transaccionales
                                    # Eso asegura que el maestro no va a borrar los transaccionales hasta que la replica los ha procesado.
        synchronous_commit = on		# Si el maestro debe esperar oks de loas replicas o no, antes de dar una transaccion por válida
        synchronous_standby_names   # Las replicas que deben dar el ok, para la transacción

- En el maestro (el único que hay ahora mismo) creamos un usuario de replicacion
    psql -U usuario -d db
    CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'password';
- Vamos a crear un slot de replicación por cada replica que quiera tener. En nuestro caso de momento 1.
    SELECT * FROM pg_create_physical_replication_slot('NOMBRE DE SLOT');
    SELECT * FROM pg_create_physical_replication_slot('replica1');
- Ahora el otro fichero
    - /var/lib/postgres/data/pg_hba.conf
            host    replication     replicator      172.21.0.3/32           trust
            host    replication     replicator      172.21.0.2/32           trust
            Añadimos la forma de autenticacion de ese usuario especial
- REINICIO PARA COGER TODOS LOS CAMBIOS
- Necesitaremos hacer un backup de la BBDD del maestro. Será un backup especial: UN BACKUP DE REPLICACION.
- Ese Backup... que será básicamente el mismo contenido de la carpeta /var/lib/postgres/data
  es lo que vamos a copiar en la segunda máquina (copia física de archivos)
- Además de los propios archivos de la BBDD del maestro, al generarse ese backup, se creará un archivo de configuración de postgres

    pg_basebackup -h 172.25.0.2  -D /var/lib/postgresql/backup -S replica1 -X stream -P -U replicator -Fp -R
        -h IP del Maestro
        -D directorio donde se deja el Backup
        -S slot de replicación 
        -X stream INCLUYE LOS WAL
        -P Mostrar el progreso
        -U replicator Usuario que usamos para el backup
        -Fp Formato del backup: PLANO: Una carpeta tal y como es la carpeta normal de los datos de cualquier BBDD postgresql
        -R Genera un archivo de configuración para el nodo replica (que sepa que es el slot de replicacion1, y que su maestro está en tal IP)

    Al hacer esto ^^^^^ se ha generado una carpeta identica a la de la BBDD maestra.
    Pero... adicionalmente, se ha creado (ha rellenado) un archivo postgresql.auto.conf 
    
        # Do not edit this file manually!
        # It will be overwritten by the ALTER SYSTEM command.
        primary_conninfo = 'user=replicator passfile=''/var/lib/postgresql/.pgpass'' channel_binding=prefer host=172.25.0.2 port=5432 sslmode=prefer sslcompression=0 sslcertmode=allow sslsni=1 ssl_min_protocol_version=TLSv1.2 gssencmode=prefer krbsrvname=postgres gssdelegation=0 target_session_attrs=any load_balance_hosts=disable'
        primary_slot_name = 'replica1'
        

- Ese archivo será leido por la replica... y le proporciona información acerca del primario (maestro)
- Y MAGICAMENTE SE PONEN A HABLAR ENTRE ELLOS.


---

Aqui faltarían cositas que tener en cuenta!

Lo que tenemos es:
 - Un maestro
 - Un replica que va recibiendo datos del maestro
    - En el mejor de los casos, podré tirar queries de consulta sobre la replica
    - Y puedo configurar si quiero que el maestro espere a la replica antes de cerrar la transacción

Qué pasa si se cae el maestro? VOY JODIDO!
La replica no va a pasar a ser maestro y a aceptar peticiones (INSERTS, DELETES y UPDATE)

Quiero que ocurra eso?
- BUFFF !
    - Lo ideal sería tener un entorno replicado del maestro que pueda levantar tirando de los mismos archivos que el maestro.
        - Con contenedores es automático (me lo regala kubernetes)
        - Con máquinas virtuales (VMWare). Me creo una máquina virtual clon de la otra (o con una plantilla) o mejor aún, 
          la tengo precreada... y levanto

Hay que pensar de donde me pueden venir los problemas.
- MAQUINA PROCESO COLGAO -> RESTART 
- MAQUINA FISICO -> QUIERO OTRA MAQUINA, con la misma configuración
- PROBLEMA CON LOS DATOS FISICO (Rotura de HDD) Esto no pasa en la vida!
    Los datos los montaré en RAID, distribuidos... lo que sea, pero los datos no se pierden.
- SI TENGO UN PROBLEMA LOGICO DE DATOS: RESTORE !
    Si alguien ha hecho un truncate... date por jodido... que esta replicado en TRUNCATE !!   

PODRIA promocionar la réplica como maestro. ES ALGO FACIL DE HACER
    SELET * FROM pg_promote();
EL PROBLEMA ES QUE ESA MAQUINA DE AHORA EN ADELANTE ES MAESTRA.
Me tocaría configurar un nuevo servidor de replicacion.
Ni aunque recupere la máquina maestra tengo remedio.
Si la recuperase tendría que:
    PARAR SECUNDARIA
    BACKUP DE LA SECUNDARIA (copiar ficheros)
        ME LOS LLEVO AL PRIMARIO
    VUELVO A ARRANCAR EL PRIMARIO
        LE HAGO NUEVO BACKUP DE REPLICACION
        ME LO LLEVO AL SECUNDARIO
    Y LEVANTO EL SECUNDARIO
    
    Resumiendo. Vuelvo a configurar TODO desde un recovery que haga en el primario(maestro) de la replica
    
En cuantito la replica empieza a funcionar como maestro. Ella empieza a dar ids... a controlar transacciones... 
Y eso ya no se puede casar de nuevo con otro que quiera venir a hacer de nuevo (o nuevo) de maestro

LA UNICA MINIMA VENTAJA: El tiempo de indisponibilidad es infimo (a lo que quiera configurar)
OJO... como configure algo muy pequeño, al mínimo problema de conexión de red entre las máquinas FOLLONAZO !
PERO.. de entrada me he quedado sin replica... y el conseguirla a sudar !

# CONSULTAS SOBRE LAS REPLICAS:

pg_replication_slots -> Muestra los slots de replicacion configurados para una BBDD

pg_stat_replication -> ES EN EL MAESTRO
pg_stat_wal_receiver -> EN LAS REPLICAS

# CADA DIA MAS no monto megaservidores de BBDD
Esto no es un oracle.

Puedo hacer replciacion de una sola BBDD o de 2... pero entonces es otro proceso.
El proceso que os he enseñado es REPLICACION FISICA, aplica a todas las BBDD de la instancia.
Para bbdd discreats dentro de la instancia: REPLICACION LOGICA

PARA MI lo más lógico es una Instancia por proyecto/Aplicativo
Mi aplicativo puede tener varias BBDD:
Quizas tengo un paquete de microservicios que necesitan 4 BBDD y van juntos -> 1 INSTANCIA

---

# BACKUPS & RECOVERY

El más rápido, seguro FISICO EN FRIO

---


En las replicaciones lógicas:
MAESTRO:
CREATE DATABASE...
CREATE TABLE...

y opero (INSERTS... updates...)

CREATE PUBLICACION replicacion_bbdd_1 FOR ALL TABLES;
                                      FOR TABLE tabla1, tabla2;
                                      
                                      
REPLICA:

CREATE DATABASE....
CREATE SUBSCRIPTION replicacion_bbdd_1 
CONNECTION   'user=replicator password='' host=172.25.0.2 dbname=BASEDEDATOS'
PUBLICATION replicacion_bbdd_1;


Si uso el PG para un datawarehouse, donde tengo ETLS nocturnas, ni de coña necesito WAL en una un volumen físico distinto
Si tengo una BBDD de producción, donde no paran de hacer INSERTS y UPDATES y deletes... y EN PARALELO BIEN DE CONSULTAS

La replicacion: Si el maestro debe esperar el commit de la replica los tiempos see multiplican
Si no uso la replica como HA... para que quiero esto?

Variará mucho la calidad confianza que tenga en el volumen de almacenamiento.
Si mi volumen para los WAL es un NVME (tendré un rendimiento DPM)... pero una seguridad mínima!
EL WAL lo momto en raid en el host o en un volumen externo... pero... RED!

POSTGRESS

    BBDD PRODUCCION (TRANSACCIONES OLTP)
        v
       ETL
        v
    DATALAKE (dejo la info en bruto)
        v    v
       ETL  STREAMING
        v    v
    DATAWAREHOUSE (tengo la información preparada para un uso concreto: BI: Modelo:  SNOWFLAKE)
    