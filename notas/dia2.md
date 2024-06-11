
# Procesos en un SO.

Cuando ejecutamos un programa, el SO levanta un proceso asociado a ese programa.

Ahí se ejecutarán unos trabajos... y para ello necesitaremos CPU, memoria, E/S, etc.
Mi proceso (programa) le va pidiendo recursos al SO.

## Para qué usa un programa la memoria RAM?

- Guardar datos de trabajo (datos temporales, ordenaciones...)
- Cache
- Propio código del programa
- Guardar la pila de ejecución de hilos.

Quien lleva la carga de trabajo a la CPU es un hilo de ejecución.
Asociado a un proceso puedo tener un huevo de hilos de ejecución.
Si tengo muchos hilos, puedo ejecutar tareas en paralelo.

## Para que usa la RAM el SO?

- Para su uso por programas
- Para sus propios datos/programas
- Control de interrupciones por los recursos de HW:
  - Cuando llega un paquete de red -> Moverlo a la memoria
  - Cuando escriben en teclado -> Moverlo a la memoria
  - Cuando quiero pintar en la pantalla -> Moverlo a la memoria
  - Cuando quiero escribir a disco -> Buffers
- Caches lectura a disco

## Tengo mi BBDD (proceso, corriendo en un servidor) y quiero hacer una consulta a la BBDD.

Lo primero que necesito hacer es: TENER UNA CONEXION con la BBDD

### Qué implica abrir una conexión con una BBDD a nivel de SO? 

Generar un nuevo proceso.
De hecho.. intentamos hacerlo lo menos posible, porque es caro (computacionalmente hablando).

WEBLOGIC, donde tengo unas apps JAVA.
Cada vez que la app JAVA quiere hacer una consulta, abre una conexión? NO

En las app usamos pools de conexiones... son mucho más eficientes.

Oye... vete abriendo 10... y cuando tenga que hacer una consulta pues usa una de esas... la que esté libre.

    +--------------------------+------------------------------+
    |   Cache                  |                              |
    |      Datos del disco     |                              |
    |        (páginas)         |                              |
    |    MEMORIA  COMPARTIDA   |                              |
    |                          |                              |
    |                          |                              |
    |                          |                              |
    |                          |                              |
    |                          |                              |
    +--------------------------+------------------------------+
    | POSTGRESQL    1 GORDO     Cada conexión x n             |
    +---------------------------------------------------------+
    | SOLARIS                                                 |
    +---------------------------------------------------------+
        SERVIDOR FISICO

# Mi BBDD Empezará a usar la RAM.... para qué?

- Guardar datos de trabajo (datos temporales, ordenaciones...)
  - Un área para hacer ordenaciones, recuperar información      Lo menos que pueda siempre y cuando sea capaz de procesar el trabajo de todas las conexiones que se abran... LO QUE VOY A CAPAR ES LAS CONEXIONES.
  - Para operaciones de mnto.                                   Cuanto más... más rápido
  - Buffers de escritura a disco de los WAL (write ahead log)   POCO... y fijo
- Cache
  - Datos de las páginas    99%                                 Todo lo que pueda
  - Compilaciones de las queries... y los planes de ejecución.  La BBDD empieza y no para....

Al final en mi sistema tengo una RAM finita... y tengo que decidir a qué la dedico.
Los valores más adecuados para mi instalación solo los saco de MONITORIZACION !

Operaciones de mnto de la BBDD:
- VACUUM : Compactar las tablas
- STATES: ANALYZE
- REBUILD INDEXES
- BACKUPS

---

Este es el charco en el que me quiero meter...
En eso.. y luego también mediante monitorización:
- Ir mirando las queries que se tiran... 
- Ver los índices... y si usan en los planes de ejecución o no...
- Si hacen falta más índices
- O si sobran

---

Esto es lo que no hacen AWS, GPC, AZURE, ORACLE CLOUD

Ahí detrás no hay nadie... hay programas... a día de hoy no muy listos... aunque aprenden rápido (IA)
Y claro... no es lo mismo comprar una camiseta en el primark que me la hagan a medida.

---

# Entornos de producción:

Qué características tiene un entorno de producción que lo diferencia de el resto?
- Alta disponibilidad
  Tratar de garantizar un determinado tiempo de servicio (pactado contractualmente) 90% 99% 99.9% 99.99%
  Los 9... no es que mos tome al pie de la letra... básicamente me hablan de la criticidad del entorno:
    90% RUINA !!! -> 36 días al año offline (1 mes)     |   €
    99% RUINA     -> 3.6 días al año offline            |   €€
    99.9%         -> 8 horas al año offline             |   €€€€€€
    99.99%        -> 1 hora al año offline              v   €€€€€€€€€€€€€€€€€€€€
  Tratar de garantizar que no voy a perder información
    Esos escenarios los paliamos con replicación:
        - Infraestructura
        - Datos
        - Procesos
- Escalabilidad
  Ajustar la capacidad de la infraestructura a la demanda de cada momento.
  En las BBDD lo que solemos hacer es crecer hacia arriba en recursos.

        Escalado vertical       MAS MAQUINA
        Escalado horizontal     MAS MAQUINAS

    Web telepi:
        00:00 -> 0
        06:00 -> 0
        10:00 -> 0
        13:00 -> 10
        15:00 -> 200
        17:00 -> 50
        20:30 -> 10000000
        23:00 -> 0

Tenemos en los entornos de producción más rendimiento que un entorno de desarrollo? NO SIEMPRE
Qué prima en un entorno de producción: HA... y eso come... y mucho.


En entornos de producción tiramos de clusters. para las BBDD:

- Standalone
- Replicación
  - Maestro: Toda la carga de trabado en actualización, inserción, eliminación y consulta
  - Replica: Sin hacer ni la hueva... a la espera de si la otra se cae
             Para consultas <<< BI
- Cluster:
  Múltiples nodos compartiendo la carga de trabajo 

### Tolerancia a fallas catastróficas

Qué pasa si hay un problema con la consistencia/integridad de los datos?
    TRUNCATE TABLE mi_tabla;

BACKUPS
    - Completo          MUCHO TIEMPO        OCUPA MUCHO         DOMINGOS, PRIMER DOMINGO DE MES   RECUPERACION SENCILLA
    - Incremental       MENOS TIEMPO        OCUPA MENOS         TODAS LAS NOCHES                  RECUPERACION MAS LENTA Y LABORIOSA
    - Transaccionales:
      - ArchiveLog
      - WAL (write ahead log)
        Cada operación que se hace sobre la BBDD que la cambia (INSERT, UPDATE, DELETE) se guarda en un fichero de log.

# Comunicación de procesos en un SO

A veces necesito que 2 o más procesos que estoy ejecutando en mi máquina puedan compartir información.
Los SO me ofrecen mecanismos para ello:
- Portapapeles de Windows
- Sockets de conexión
- Puertos de comunicación
- En un SO a priori, 2 procesos diferentes pueden acceder a las mismas zonas de la RAM?
  NO... a priori... hay un mecanismo que me ofrecen los SO para habilitar eso: SHARED MEMORY
  Es el procedimiento de comunicación de información más rápido que tengo en un SO.


---

# cuando llega una query a una BBDD

Qué debe hacer la BBDD para ejecutarla?

1º PARSEARLA (Analizarla sintacticamente... ver que no hay errores, y entender que es lo que pide)
2º ANALIZAR LOS DATOS CON LOS QUE SE ESTA TRABAJANDO... que sea consistente
  - Que las tablas existan
  - Que los campos existan
  - Que los campos sean del tipo correcto 
3º PLAN DE EJECUCION
  Determinar la forma más óptima de buscar esa información en los datos
-------^
Y todo esto... va rápido?
Depende de la query... en general es curro.


---

# Palabras prohibidas en SQL

- LIKE '%...'
- DISTINCT ->
  Ordenar por TODOS LOS CAMPOS... y después un FULLSCAN para quitar los duplicados
- UNION -> DISTINCT
- ORDER BY (sin indices... RUINA)

---

# Zonas de RAM de PostgreSQL

## Shared Buffers

Es donde se guardan las páginas de datos que se van a usar.
Parámetro de configuración: shared_buffers

## Work Memory

La memoria que necesitan las conexiones para hacer sus trabajos: ordenaciones, joins, etc.
Parámetro de configuración: work_mem
Es por conexión...

## Maintenance Work Memory

La memoria que necesita la BBDD para hacer operaciones de mantenimiento.
Parámetro de configuración: maintenance_work_mem

## Effective Cache Size: Tamaño de cache efectivo

Esto no configura una mierda!
No es un valor real que la BBDD vaya a reservar... 
Es una estimación del tamaño de RAM a nivel del HIERRO que se usa para cachear datos.
Y cuidado...
Lo que le indicamos al PostgreSQL es cuánta RAM tiene disponible el SO para cachear páginas de datos.
Esa información la usa el planificador de ejecución.
Parámetro de configuración: effective_cache_size

## WAL Buffers

El tamaño de los buffers de escritura a disco de los WAL.
Parámetro de configuración: wal_buffers

## Temp Buffers

Si creo por ejemplo tablas temporales en consultas... se guardan en esta zona de la RAM.
Parámetro de configuración: temp_buffers

---

# CONTENEDORES

1º Instalación de postgresql con contenedores

## Qué es un contenedor?

Es un entorno aislado dentro de un SO con Kernel Linux donde ejecuto procesos.
Aislado?
- El contenedor (entorno) tiene su propia conf de red -> Su propia IP
- El contenedor tiene sus propias variables de entorno
- El contenedor tiene su propio sistema de ficheros
- Puede tener restricciones de acceso al HIERRO

Por lo que estoy describiendo se parece a una Máquina virtual.. Pero con una diferencia GIGANTE:
Diferencia que hace que hoy en día sea la forma preferida de desplegar aplicaciones.
Con un hypervisor (VMWare, KVM, VirtualBox) genero MV... que a todos los efectos trato como un hierro físico:
- Tengo que instalarles un SO.
Cuando trabajo con un gestor de contenedores(Docker, Podman, CRIO, ContainerD) genero contenedores:
Y los contenedores no tienen, ni pueden tener un SO... no los trato como un hierro.. SON SOLO un entorno aislado dentro del Sistema operativo del HOST -> Zonas de Solaris

El mundo de los contenedores está muy estandarizado... y eso es una ventaja.
Una imagen de contenedor (los contenedores se crean desde imágenes) creada con Docker funciona en Podman, CRIO, ContainerD...y al revés.

Kubernetes es un gestor de gestores de contenedores apto para entornos de producción:
Cluster :
    Kubernetes
    Maquina 1
        ContainerD | Crio
    Maquina 2
        ContainerD | Crio
    Maquina 3
        ContainerD | Crio

De kubernetes hay varias DISTRIBUCIONES:
    - La más común se llama K8S
    - La vainilla K3S
    - OpenShift (distro de RedHat)
    - Tamzú (distro de VMWare)
    - Karbon (distro de Nutanix)
    
---