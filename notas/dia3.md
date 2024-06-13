1 kB -> 1000 B
1 gB -> 1000 mB -> 1000 000 kB ---> 1000 000 000 B


NO son 1000. No son 1024... DESDE HACE 25 años.

Hoy en día 1 kb = 1000 b... desde hace 25 años
Hay otra unidad de medida que se ha creado que es la que se usa hoy en día:

1kib Kibibyte = 1024 b
1mib = 1024 kib
Antiguamente 1kB = 1024 B PERO SE CAMBIO EN EL 99
Hoy 1KB = 1000B

---

# Particionado de tablas en Postgre

## Cuál es el objetivo? En conseguir tablas más pequeñas:

- Rendimiento en queries
- Mejora de los tiempos de operaciones de mnto
- Backups lógicos

En postgresql los que hacemos es crear varias tablas... 

## Cuando me interesa?

- Cuando hay muchos datos: CONDICION NECESARIA

## Tipos de particionados en postgresql

- Por rangos de una columna (para columnas cuantitativas: Cantidades, Fechas)
    Cantidad:    NUMERICOS + UD DE MEDIDA (implict o explicita)

    ```sql        
    CREATE TABLE Inscripciones {
        id SERIAL,
        fecha DATA,
        cantidad INT,
    } PARTITION BY RANGE(fecha);
    
    CREATE TABLE Inscripciones_antiguas       PARTITION OF Inscripciones FOR VALUES FROM ( MINVALUE ) TO ('01-10-2000') ;
    CREATE TABLE Inscripciones_medio_antiguas PARTITION OF Inscripciones FOR VALUES FROM ( '01-10-2000' ) TO ('01-10-2015') ;
    CREATE TABLE Inscripciones_nuevas         PARTITION OF Inscripciones FOR VALUES FROM ( '01-10-2015' ) TO ( MAXVALUE ) ;
    ```
    
- Por listas de valores (en columnas discretas: TEXTOS, CP)

    ```sql        
    CREATE TABLE Inscripciones {
        id SERIAL,
        fecha DATA,
        estado INT, -- 0 CANCELADO, 1 VIGENTE, 2 ACABADA
    } PARTITION BY LIST(estado);
    
    CREATE TABLE Inscripciones_canceladas     PARTITION OF Inscripciones FOR VALUES IN (0);
    CREATE TABLE Inscripciones_vigentes       PARTITION OF Inscripciones FOR VALUES IN (1) ;
    CREATE TABLE Inscripciones_otras          PARTITION OF Inscripciones DEFAULT ;
    ```
- Particionado por HUELLA (HASH de un campo)
    Tengo yo a priori idea del hash de un dato?
    Nos da lugar a un particionado donde las particiones van a tner más o menos la misma cantidad de datos:
    Repartir los datos uniformemente entre distintos FRAGMENTOS o PARTICIONES
    Me viene genial si:
    - Tener distintos ficheros en distintas unidades de almacenamiento
    
    ```sql        
    CREATE TABLE Inscripciones {
        id SERIAL,
        ...
    } PARTITION BY HASH(id);
    
    CREATE TABLESPACE espacio1 LOCATION 'RUTA';
    
    CREATE TABLE Inscripciones_Particion_1 TABLESPACE espacio1 PARTITION OF Inscripciones FOR VALUES WITH ( MODULUS 4, REMAINDER 0 );
    CREATE TABLE Inscripciones_Particion_2 PARTITION OF Inscripciones FOR VALUES WITH ( MODULUS 4, REMAINDER 1 );
    CREATE TABLE Inscripciones_Particion_3 PARTITION OF Inscripciones FOR VALUES WITH ( MODULUS 4, REMAINDER 2 );
    CREATE TABLE Inscripciones_Particion_4 PARTITION OF Inscripciones FOR VALUES WITH ( MODULUS 4, REMAINDER 3 );
    ```

    Llegados a este punto, yo podría hacer SELECTS en cada una de esas PARTICIONES (Tablas):
        SELECT * FROM Inscripciones_Particion_2;
    Podría hacer inserts en cada una de ellas por separado:
        INSERT INTO FROM Inscripciones_Particion_2 (...) VALUES (...);
        
    Pero, podría usar el nombre Inscrpiciones para referirme a la union de todas esas tablas:
        SELECT * FROM Inscripciones;
        
        SELECT * FROM Inscripciones_Particion_1
            UNION ALL
        SELECT * FROM Inscripciones_Particion_2
            UNION ALL
        SELECT * FROM Inscripciones_Particion_3
            UNION ALL
        SELECT * FROM Inscripciones_Particion_4;
    
    Si hago un insert en Inscripciones... se aplica la regla de particionado... y mi dato acaba en la PARTICION (TABLA) 
    que le toque.
    Puedo hacer backups de cada una... VACUUM de cada una... ANALIZE de cada una... Cada una la puedo tener en una UD de 
    almacenamiento distinta.

- Particionado múltiple

    ```sql        
    CREATE TABLE Inscripciones {
        id SERIAL,
        fecha DATA,
        estado INT, -- 0 CANCELADO, 1 VIGENTE, 2 ACABADA
    } PARTITION BY RANGE (Fecha) THEN LIST(estado);

    CREATE TABLE Inscripciones_2024 PARTITION OF Inscripciones FOR VALUES FROM ('01-01-2024') TO ( MAXVALUE ) 
        PARTITION BY LIST(estado);

    CREATE TABLE Inscripciones_2024_Canceladas PARTITION OF Inscripciones_2024 FOR VALUES IN (0);
    CREATE TABLE Inscripciones_2024_Vigentes   PARTITION OF Inscripciones_2024 FOR VALUES IN (1);
    CREATE TABLE Inscripciones_2024_Otros      PARTITION OF Inscripciones_2024 DEFAULT;
        
    CREATE TABLE Inscripciones_2023 PARTITION OF Inscripciones FOR VALUES FROM ('01-01-2023') TO ('01-01-2024')
        PARTITION BY LIST(estado);
    CREATE TABLE Inscripciones_2023_Vigentes   PARTITION OF Inscripciones_2023 FOR VALUES IN (1);
    CREATE TABLE Inscripciones_2023_Otros      PARTITION OF Inscripciones_2023 DEFAULT;
    
    ```
    
    ```sql        
    CREATE TABLE Inscripciones {
        id SERIAL,
        fecha DATA,
    } PARTITION BY RANGE(fecha);
    
    CREATE TABLE Inscripciones_2024 PARTITION OF Inscripciones FOR VALUES FROM ( '01-01-2024' ) TO ('01-01-2025') ;

    ALTER TABLE Inscripciones ATTACH PARTITION Inscripciones_2025 FOR VALUES FROM ( '01-01-2025' ) TO ('01-01-2026') ;
    ```