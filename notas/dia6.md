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

- Necesitaremos hacer un backup de la BBDD del maestro. Será un backup especial: UN BACKUP DE REPLICACION.
- Ese Backup... que será básicamente el mismo contenido de la carpeta /var/lib/postgres/data
  es lo que vamos a copiar en la segunda máquina (copia física de archivos)
- Además de los propios archivos de la BBDD del maestro, al generarse ese backup, se creará un archivo de configuración de postgres
- Ese archivo será leido por la replica... y le proporciona información acerca del primario (maestro)
- Y MAGICAMENTE SE PONEN A HABLAR ENTRE ELLOS.