-- Personas
-- Esta tabla es de mentira... No existe
-- Es un alias con el que referirme a las 3 tablas que hay por debajo
CREATE TABLE personas2 (
    id              SERIAL          NOT NULL, 
    estado          SMALLINT        NOT NULL,
    otros_datos     VARCHAR(100)    NOT NULL,
    PRIMARY KEY (id, estado)
)   PARTITION BY LIST(estado);
-- LIST: Una serie de valores predefinidos sobre los que particionar

CREATE TABLE personas_alta PARTITION OF personas2 FOR VALUES IN (1);
CREATE TABLE personas_baja PARTITION OF personas2 FOR VALUES IN (2);
CREATE TABLE personas_otros PARTITION OF personas2 DEFAULT; -- el resto

INSERT INTO personas2 (estado,otros_datos) VALUES (1,'Ivan');
INSERT INTO personas2 (estado,otros_datos) VALUES (1,'Carlos');
INSERT INTO personas2 (estado,otros_datos) VALUES (2,'Emiliano');
INSERT INTO personas2 (estado,otros_datos) VALUES (2,'Gustavo');
INSERT INTO personas2 (estado,otros_datos) VALUES (3,'Ramon');
INSERT INTO personas2 (estado,otros_datos) VALUES (4,'Jose Luis');




CREATE TABLE personas3 (
    id              SERIAL          NOT NULL, 
    edad            SMALLINT        NOT NULL,
    otros_datos     VARCHAR(100)    NOT NULL,
    PRIMARY KEY (id, edad)
)   PARTITION BY RANGE(edad);
-- RANGE: Rangos de valores sobre los que particionar
                                                                                -- no se incluye
CREATE TABLE personas_jovenes  PARTITION OF personas3 FOR VALUES FROM (MINVALUE) TO(20);
CREATE TABLE personas_adultas  PARTITION OF personas3 FOR VALUES FROM (20) TO (65);
CREATE TABLE personas_ancianas PARTITION OF personas3 FOR VALUES FROM (65) TO (MAXVALUE);


-- - Particionado cuando lo que quiero conseguir es que los datos se repartan homogeneamente en varias tablas
-- - sin criterio ninguno... de forma aleatoria
-- - No tengo criterio de particionado... y tengo tablas con una cantidad de actualizaciones /inserciones y borrados enorme

-- - Ventajas en operaciones de mantenimiento de la BBDD:
-- - PostgreSQL decida cuando hacer un REINDEX, VACUUM, ANALIZE
CREATE TABLE personas4 (
    id              SERIAL          NOT NULL, 
    edad            SMALLINT        NOT NULL,
    otros_datos     VARCHAR(100)    NOT NULL,
    PRIMARY KEY (id)
)   PARTITION BY HASH(id);
-- RANGE: Rangos de valores sobre los que particionar
                                                                                -- no se incluye
CREATE TABLE personas_1  PARTITION OF personas3 FOR VALUES WITH (modulus 3, remainder 0);
CREATE TABLE personas_2  PARTITION OF personas3 FOR VALUES WITH (modulus 3, remainder 1);
CREATE TABLE personas_3  PARTITION OF personas3 FOR VALUES WITH (modulus 3, remainder 2);



-- Saca donde está el dato
SELECT tableoid::regclass, * from personas2  order by id;

-- Ambas tienen el mismo plan de ejecución
EXPLAIN SELECT * from personas2;
EXPLAIN (
    select * from personas_alta
    UNION ALL 
    select * from personas_baja
    UNION ALL
    select * from personas_otros
);
-- Se ataca solo a una de las particiones (tablas de nivel inferior)
EXPLAIN SELECT * from personas2 where estado=2;