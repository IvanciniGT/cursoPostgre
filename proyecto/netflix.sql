-- Crear una BBDD 
CREATE DATABASE netflix;
-- Las tablas voy a montar 2 tablespaces
-- 1 para las tablas de datos
CREATE TABLESPACE datos LOCATION '/var/lib/postgresql/data/netflix_datos';
-- 2 para los índices
CREATE TABLESPACE indices LOCATION '/var/lib/postgresql/data/netflix_indices';

-- Usuario
CREATE USER netflix WITH ENCRYPTED PASSWORD 'netflix';
GRANT ALL PRIVILEGES ON DATABASE netflix TO netflix;

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

ALTER TABLE usuarios ADD CONSTRAINT usuarios_pk PRIMARY KEY (id) TABLESPACE indices;
ALTER TABLE usuarios ADD CONSTRAINT usuarios_email_uq UNIQUE (email) TABLESPACE indices;

-- Directores
CREATE TABLE directores (
    id     SMALLSERIAL,
    nombre VARCHAR(100) NOT NULL

) TABLESPACE datos;

ALTER TABLE directores ADD CONSTRAINT directores_pk PRIMARY KEY (id) TABLESPACE indices;
ALTER TABLE directores ADD CONSTRAINT directores_nombre_uq UNIQUE (nombre) TABLESPACE indices;

-- Tematicas
CREATE TABLE tematicas (
    id     SMALLSERIAL,
    nombre VARCHAR(100) NOT NULL --- TODO: PLANTEAR INDICE. Si la app ofrece la lista de temáticas, no es necesario

) TABLESPACE datos;

ALTER TABLE tematicas ADD CONSTRAINT tematicas_pk PRIMARY KEY (id) TABLESPACE indices;
ALTER TABLE tematicas ADD CONSTRAINT tematicas_nombre_uq UNIQUE (nombre) TABLESPACE indices;

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
                                       -- Los collate no me resuelven la papeleta: No permiten hacer búsquedas por palabras parciales
                                       --    Si puedo hacer un LIKE'palabra%' pero no un LIKE'%palabra%'
                                       -- Los gin con ts_vector no me resuelven la papeleta: No permiten hacer búsquedas por palabras parciales
                                       -- Necesito un índice gin de trigramas
                                       -- Pero los trigramas son sensibles a mayúsculas y minúsculas y acentos
    CONSTRAINT peliculas_fecha_check CHECK (fecha <= CURRENT_DATE),
    CONSTRAINT peliculas_edad_minima_check CHECK (edad_minima >= 0),
    CONSTRAINT peliculas_duracion_minima_check CHECK (duracion > 0),

) TABLESPACE datos;

ALTER TABLE peliculas ADD CONSTRAINT peliculas_pk PRIMARY KEY (id) TABLESPACE indices;
ALTER TABLE peliculas ADD CONSTRAINT peliculas_tematica_fk FOREIGN KEY (tematica) REFERENCES tematicas (id) TABLESPACE indices;
ALTER TABLE peliculas ADD CONSTRAINT peliculas_director_fk FOREIGN KEY (director) REFERENCES directores (id) TABLESPACE indices;
-- Indice fecha
CREATE INDEX peliculas_fecha_idx ON peliculas (fecha) TABLESPACE indices;
-- Visualizaciones

CREATE TABLE visualizaciones (
    usuario  INTEGER    NOT NULL,
    pelicula INTEGER    NOT NULL,
    fecha    TIMESTAMP  NOT NULL  DEFAULT CURRENT_TIMESTAMP

) TABLESPACE datos 
PARTITION BY RANGE (fecha);
;

ALTER TABLE visualizaciones ADD CONSTRAINT visualizaciones_usuario_pelicula_fecha_uq PRIMARY KEY (usuario, pelicula, fecha) TABLESPACE indices;
ALTER TABLE visualizaciones ADD CONSTRAINT visualizaciones_usuario_fk FOREIGN KEY (usuario) REFERENCES usuarios (id) TABLESPACE indices;
ALTER TABLE visualizaciones ADD CONSTRAINT visualizaciones_pelicula_fk FOREIGN KEY (pelicula) REFERENCES peliculas (id) TABLESPACE indices;

CREATE TABLE visualizaciones_2024 PARTITION OF visualizaciones
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01') TABLESPACE datos;
-- El año que viene, crear otra tabla
ALTER TABLE visualizaciones ATTACH PARTITION visualizaciones_2025 FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

