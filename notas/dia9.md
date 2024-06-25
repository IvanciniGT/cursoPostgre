# Clusters Activo - Activo

En días anteriores hemos montado HA en Postgres mediante modo espejo: 
- primario / activo
- replica / activa (standby) para consultas
- replica / no activo

Y que si el primario cae, podemos hacer un 
    SELECT pg_promote()
Puede ser que queramos configurar en automático el pg_promote! 
Sobre todo si trabajo con hierros físicos.
Y entonces echamos mano de otras herrameintas:
- KeepAlive
- Patroni

ESTA ES LA GRAN ESTRATEGIA que usamos en PostgreSQL.
Siempre que podamos tirar por aquí: MAESTRO / REPLICA es lo mejor!
La escritura no escala... la lectura si.. el tirar queries SI!
Puedo hacer las queries en las replicas.

De hecho es la ÚNICA SOPORTADA NATIVAMENTE por postgres para HA.
Postgres NO TIENE NADA per se como lo que encontramos en un Oracle (oracle RAC) 
o en mysql/mariadb(galera)

PostgreSQL no permite montar un cluster Activo/Activo!
Eso es un problema:
- No tenemos escalabilidad en escritura
- Si se cae un servidor, hay que promocionar otro... y eso es un follón!

Hay alternativas... pero fuera de postgresql.

Todas esas alternativas al final lo que van orientadas es a montar una Replicación MultiMaestro: Replicación Bidireccional!

    Maestro -- replica -->  Otro maestro
            <-- replica --

El problema gordo aquí cuál es? de esta forma de trabajo? BRAIN SPLITTING
Que pasa si el maestro 1 hace un insert.. y genera un ID... y lo replica al otro... 
pero ese otro ha hecho entre tanto un insert... y ha asignado el mismo ID!
OSTION ! Irrecuperable automaticamente. Me tocaría cambiar a mano ids... Y todas las referencias a esos Id...

Lo que vamos a es buscar estrategias para evitar eso = CHAPUZA.. A mi si... pero es lo que hay... 
y está institucionalizado por postgres.

- pglogical.. Se usaba mucho... pero ha quedado bastante muerto... por buen motivo.
- postgres-xl: De pago . Absorbido por EBD
- EDB: postgres distributed ... De pago
- Citus: opensource y gratis... De hecho es la más guay!

Pero como decía, todas esas soluciones se basan en el concepto de REPLICACION BIDIRECCIONAL.
Replicaciones que hacemos de una forma diferente a como las hemos hecho nosotros cuando montamos el Maestro/Replica.

De hecho , la funcionalidad que era necesaria para montar ese tipo de replicación, es desde postgresv16 parte de postgres.
Es lo que antes nos daba el pg_logical

Nosotros, la replicación que hemos montado ha sido una replicación FISICA !
Lo que significa que se replica la instancia de postgres entera (con todas sus BBDD con todas sus tablas).
Y eso está genial... si quiero Maestro/Replica. Ese es el camino.

Pero cuando quiero una replicación BIDIRECCIONAL, eso no sirve.
No quiero replicar toda la BBDD... se machacarían entre si.
Necesitamos otro tipo de replicación: REPLICACION LOGICA !
La replicación LOGICA me permite decidir qué BBDD / TABLAS quiero replicar.
Básicamente, lo que hacemos es en la máquina maestra activar una "publicación": PUBLICATION

    CREATE PUBLICATION mi_publicacion FOR ALL TABLES;
    
Y a nivel de la replica: montar una SUBSCRIPCION

    CREATE SUBSCRIPTION mi_subscripcion 
    CONNECTION 'host=maestro port=5432 dbname=midb usuario=replicator password=Pa$$w0rd'
    PUBLICATION mi_publicacion;
    
Básicamente la publicación es una tabla que se crea, de foprma que para cada subscriptor, anota dónde se ha quedado.

Y la subscripción es un trabajo en segundo plano que se configura en las replicas, que van pidiendo datos al maestro
y van actualizando la tabla de Publicacion en consecuencia, para saber por donde van.
    
Desde postgres16 está nativamente soportada ese tipo de replciación (antiguamente ofrecido por pg_logical).

Vamos a necesitar volvernos muy muy creativos. Montar un cluster de PosgreSQL Activo-Activo 
(que en realidad ya estamos descubriendo que no es tal) es tan solo montar 2 o más maestros replciando datos entre si.
Pero si los 2 permiten que se inserten datos en la TABLA_A... podemos encontrar conflictos en los IDs.
Además que al replicarse, si yo te paso mi tabla TABLA_A... machaco tu tabla TABLA_A. PROBLEMONES! GORDOS!

El montar un cluster de este tipo, que vamos a dejar de llamarlo Activo/Activo 
es una combinación de infraestructura y desarrollo.

Lo que vamos a hacer es usar el particionado de tablas, con secuencias desplazadas para los ID.

Imaginad una tabla... que no se actualiza en ningún caso (solo desde desarrollo). 
La típica tabla para normalizar X datos.

    Expedientes > Estados
                    1 Alta
                    2 Cancelado
                    3 Finalizado
                    
                    ^ Esta tabla no cambia dinámicamente.. Puede cambiar en desarrollo.
                      Con estas tablas no hay problema. Ninguno. Las meto en un nodo... y las replico al resto de nodos.
    
Qué pasa con la tabla Expedientes?
Esa si cambia... estamos dando de alta expedientes de continuo.
Quiero tener la posibilidad de poder dar de alta expedientes en las 2 máquinas... 
Quiero este tinglao para escalabilidad en escritura.
Si solo quiero HA, Maestro/Replica con promoción ... 
y si es posible directamente REINICIO/RECREACION DEL MAESTRO (VM/contenedores)
    
Qué me toca hacer:

Particionar la tabla Expedientes en 2... por HASH (aleatorio)

Máquina 1: 
    CREATE TABLE Expedientes (
        ID INT,
        ...    
    ) PARTITION BY HASH(campo);
    CREATE SEQUENCE maquina1_expedientes_secuencia START WITH 1 INCREMENT BY 10;
    CREATE TABLE Expedientes1 (
        ID INT DEFAULT nextval('maquina1_expedientes_secuencia'),
        ...
    )
    -- La tabla maquina1_expedientes_secuencia -> Se replique a la máquina 2
Máquina 2: 
    CREATE TABLE Expedientes (
        ID INT,
        ...    
    ) PARTITION BY HASH(campo);
    CREATE SEQUENCE maquina2_expedientes_secuencia START WITH 2 INCREMENT BY 10;
    CREATE TABLE Expedientes2 (
        ID INT DEFAULT nextval('maquina2_expedientes_secuencia'),
        ...
    )
    -- La tabla maquina2_expedientes_secuencia -> Se replique a la máquina 1
    
Cuando en cualquiera de las máquinas se haga una consulta, las 2 tendrán toda la información para devolverla.
Pero cada una va a ser responsable de las inserciones en una de las tablas particionadas.

Esto hoy en día es posible gracias a el particionado LOGICO de los datos, disponible desde POSTGRES16
Antes con pg_logical.
Y es en lo que se basan todas las soluciones de cluster MULTIMAESTRO de postgres: CITUS, EDB: postgres distributed

Cómo veis montar esa aventura?
Esto es complicao... y mucho curro!
Y es precisamente en lo que me ayudan CITUS, EDB.
Yo le doy las tablas ... le indico las que van a cambiar... y en base a qué me puede interesar particionar...
Y ellas se encargan de montar todo ese entramado de secuencias desplazadas, tablas particionadas, subscripciones, publicaciones y balanceo!
Porque si la máquina2 recibe la orden de insertar en la tabla de la particion1, no debe procesarlo... debe redirigirlo a la otra.

Y ahora de nuevo, vemos más claro que:
- Si lo que quiero es solo HA, no me meto en este charco.. Porque no es solo montar unas instancias de postgres en Cluster (como ocurre en un Oracle RAC o en un MySQL galera)
  Aquí hay cambios en la estructura de los datos profundos.
- De hecho... esta forma de trabajar (MULTIMAESTRO) me ofrece HA? NO. 
  Si se cae el maestro1, quién puede meter datos en la particion: Expedientes1: NADIE.
    La máquina 2 podra seuir recibiendo peticiones de inserción en la partición suya: Expedientes2
    Lo que había en maestro1, está disponible (por replicación lógica) en maestro2.
    Pero nadie hay ahora para hacer actualizaciones en la particion Expedientes1 
    (que estaba vinculada a la máquina maestro1)
    Si quiero HA con un cluster MultiMaestro, necesito:
        - Que cada uno tenga su replica dísica que pueda ser promocionada en caso de que su maestro caiga
        - Optar por una estrategia de reinicio / recreación de un contenedor/vm
    Esta solución solo me da: Escalabilidad en ESCRITURA. Tengo 2 sitios paralelos donde poder ir escribiendo los datos.
Si tengo una BBDD muy animal, llena de operaciones de actualización, me tendré que ir a esto! sin remedio...
O montar una máquina más gorda (Escalo en vertical)... y distintos dispositivos de almacenamiento, 
con tablas particionadas también... 
pero si el follón de los IDs y la replicación.

Nos pensamos muy y mucho el montar un cluster MULTIMAESTRO en POSTGRESQL... las ventajas no están nada claras!

Y sigue cogiendo más fuerza el planteamiento de montar una instancia de PG para cada BBDD / Aplicación

Iré a maestro/replica si necesito más performance en queries.
Si no... y tengo la suerte de trabajar en entorno virtualizado, iré a un reinicio/recreación del maestro.

En la medida de mis posibilidades voy a huir de servidores físicos para pg. No tienen sentido.
No es un Oracle en un exadata!

No trateis de llevar Oracle y las formas de trabajo que tengo en Oracle a postgreSQL. Es otra herramienta. No encaja!

HA:
- promoción de una replica (de lo cual también trato de huir, por las implicaciones) segundos.
- recreación/reinicio del maestro = GUAY ! Puedo tener una indisponibilidad de segundos/1-2minuto

-- Esto en cada máquina del cluster
sudo apt update
curl https://install.citusdata.com/community/deb.sh | sudo bash
sudo apt-get -y install postgresql-16-citus-12.1
sudo pg_conftool 16 main set shared_preload_libraries citus
sudo pg_conftool 16 main set listen_addresses '*'
echo "host all all 0.0.0.0/0 trust"| sudo tee -a /etc/postgresql/16/main/pg_hba.conf
sudo systemctl restart postgresql
sudo systemctl enable postgresql
sudo -i -u postgres psql -c "CREATE EXTENSION citus;"

-- En una máquina: COORDINADORA
sudo -i -u postgres psql -c "SELECT citus_set_coordinator_host('172.31.39.41', 5432);"
sudo -i -u postgres psql -c "SELECT * from citus_add_node('172.31.27.172', 5432);"


sudo -i -u postgres psql -h 172.31.27.172 -c "SELECT 1;"

--- El instalar el cluster ha sido fácil ^

Ahora... Hay que hacer cambios en Modelo de datos:
Por suerte CITUS nos regala algunos procedimientos para que se hagan en automático.


