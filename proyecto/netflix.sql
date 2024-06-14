-- Crear una BBDD 
CREATE DATABASE netflix;

-- Usuario
CREATE USER netflix WITH ENCRYPTED PASSWORD 'netflix';
GRANT ALL PRIVILEGES ON DATABASE netflix TO netflix;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO netflix;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO netflix;

-- Las tablas voy a montar 2 tablespaces
-- 1 para las tablas de datos
CREATE TABLESPACE datos LOCATION '/var/lib/postgresql/data/netflix_datos';
-- 2 para los índices
CREATE TABLESPACE indices LOCATION '/var/lib/postgresql/data/netflix_indices';

DROP TABLE IF EXISTS visualizaciones_2024;
DROP TABLE IF EXISTS visualizaciones_2025;

DROP TABLE IF EXISTS visualizaciones;
DROP TABLE IF EXISTS peliculas;
DROP INDEX IF EXISTS peliculas_nombre_idx;
DROP INDEX IF EXISTS peliculas_director_idx;
DROP TABLE IF EXISTS tematicas;
DROP TABLE IF EXISTS directores;
DROP TABLE IF EXISTS usuarios;

-- Tablas

-- Usuarios
-- El campo el email debería validarlo... que lo que metan sea un email
-- Regexp: ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$
CREATE TABLE usuarios (
    id      SERIAL,
    estado  BOOLEAN      NOT NULL   DEFAULT TRUE,
    alta    TIMESTAMP    NOT NULL   DEFAULT CURRENT_TIMESTAMP,
    email   VARCHAR(100) NOT NULL,
    nombre  VARCHAR(100) NOT NULL,

    CONSTRAINT usuarios_email_check CHECK (email ~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')

) TABLESPACE datos;

ALTER TABLE usuarios ADD CONSTRAINT usuarios_pk       PRIMARY KEY (id)  USING INDEX TABLESPACE indices;
ALTER TABLE usuarios ADD CONSTRAINT usuarios_email_uq UNIQUE (email)    USING INDEX TABLESPACE indices;

-- Directores
CREATE TABLE directores (
    id     SMALLSERIAL,
    nombre VARCHAR(100) NOT NULL

) TABLESPACE datos;

ALTER TABLE directores ADD CONSTRAINT directores_pk        PRIMARY KEY (id) USING INDEX TABLESPACE indices;
ALTER TABLE directores ADD CONSTRAINT directores_nombre_uq UNIQUE (nombre)  USING INDEX TABLESPACE indices;

-- Tematicas
CREATE TABLE tematicas (
    id     SMALLSERIAL,
    nombre VARCHAR(100) NOT NULL --- TODO: PLANTEAR INDICE. Si la app ofrece la lista de temáticas, no es necesario

) TABLESPACE datos;

ALTER TABLE tematicas ADD CONSTRAINT tematicas_pk        PRIMARY KEY (id) USING INDEX TABLESPACE indices;
ALTER TABLE tematicas ADD CONSTRAINT tematicas_nombre_uq UNIQUE (nombre)  USING INDEX TABLESPACE indices;

-- Peliculas
CREATE TABLE peliculas (
    id          SERIAL,
    tematica    SMALLINT     NOT NULL,
    director    SMALLINT     NOT NULL,
    duracion    SMALLINT     NOT NULL,
    fecha       DATE         NOT NULL,
    edad_minima SMALLINT     NOT NULL,
    nombre      VARCHAR(100) NOT NULL, -- TODO: PLANTEAR INDICE
                                       -- Quiero que me puedan hacer búsquedas por nombres.. pero sin importar mayusculas, minusculas, acentos, etc
                                       -- Y que me puedan poner los primeros caracteres de una de las palabras del nombre
                                       -- "LEO" -> "El rey león"
                                       -- Los collate no me resuelven la papeleta: No permiten hacer búsquedas por palabras parciales, ni por palabras
                                       --    Si puedo hacer un LIKE 'palabra%' pero no un LIKE'%palabra%'
                                       -- Los gin con ts_vector no me resuelven la papeleta: No permiten hacer búsquedas por palabras parciales
                                       -- Necesito un índice gin de trigramas
                                       -- Pero los trigramas son sensibles a mayúsculas y minúsculas y acentos
    CONSTRAINT peliculas_fecha_check           CHECK (fecha <= CURRENT_DATE),
    CONSTRAINT peliculas_edad_minima_check     CHECK (edad_minima >= 0),
    CONSTRAINT peliculas_duracion_minima_check CHECK (duracion > 0)

) TABLESPACE datos;

ALTER TABLE peliculas ADD CONSTRAINT peliculas_pk          PRIMARY KEY (id)         USING INDEX TABLESPACE indices;
ALTER TABLE peliculas ADD CONSTRAINT peliculas_tematica_fk FOREIGN KEY (tematica)   REFERENCES tematicas (id);
ALTER TABLE peliculas ADD CONSTRAINT peliculas_director_fk FOREIGN KEY (director)   REFERENCES directores (id);

-- Índices
CREATE INDEX peliculas_nombre_idx ON peliculas (tematica) ;
CREATE INDEX peliculas_director_idx ON peliculas (director) ;
ALTER INDEX peliculas_nombre_idx SET TABLESPACE indices;
ALTER INDEX peliculas_director_idx SET TABLESPACE indices;
-- Índice de trigramas
CREATE EXTENSION IF NOT EXISTS unaccent;

ALTER TABLE peliculas ADD COLUMN nombre_normalizado VARCHAR(100);

-- Crear la función del trigger para actualizar la columna normalizada
CREATE OR REPLACE FUNCTION actualizar_nombre_normalizado()
RETURNS TRIGGER AS $$
BEGIN
    NEW.nombre_normalizado := unaccent(lower(NEW.nombre));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear el trigger
CREATE TRIGGER trg_actualizar_nombre_normalizado
BEFORE INSERT OR UPDATE ON peliculas
FOR EACH ROW
EXECUTE FUNCTION actualizar_nombre_normalizado();




CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX peliculas_nombre_trgm_idx ON peliculas USING gin (nombre_normalizado gin_trgm_ops) TABLESPACE indices;

-- Indice fecha
CREATE INDEX peliculas_fecha_idx ON peliculas (fecha) TABLESPACE indices;
-- Visualizaciones

CREATE TABLE visualizaciones (
    usuario  INTEGER    NOT NULL,
    pelicula INTEGER    NOT NULL,
    fecha    TIMESTAMP  NOT NULL  DEFAULT CURRENT_TIMESTAMP

) PARTITION BY RANGE (fecha);

ALTER TABLE visualizaciones ADD CONSTRAINT visualizaciones_usuario_pelicula_fecha_uq 
    PRIMARY KEY (fecha, usuario, pelicula) USING INDEX TABLESPACE indices;
-- Order de las columnas en el PRIMARY KEY... No es irrelevante... Al contrario... es bien importante
-- PostgreSQL ya dijimos que en autom. nos genera un INDICE de los PK
-- Ese índice se puede usar para búsquedas...
-- Pero en el índice, la primera ordenación se hace por fecha
-- SOLO se usará ese índice para búquedas en la tabla que filtren por fecha.

-- Dado que va a ser la tabla más grande con diferencia, si se plantease la necesidad de hacer búsquedas en ella
-- por otros campos: USUARIO: Dame las peliculas que ya ha visto este usuario
--  DEBERIAMOS plantear el crear un índice para esa columna
    
    
ALTER TABLE visualizaciones ADD CONSTRAINT visualizaciones_usuario_fk                FOREIGN KEY (usuario)  REFERENCES usuarios (id);
ALTER TABLE visualizaciones ADD CONSTRAINT visualizaciones_peliculas_fk              FOREIGN KEY (pelicula) REFERENCES peliculas (id);


CREATE TABLE visualizaciones_2024 PARTITION OF visualizaciones
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01') TABLESPACE datos;
-- El año que viene, crear otra tabla
CREATE TABLE visualizaciones_2025 PARTITION OF visualizaciones
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01') TABLESPACE datos;
