CREATE INDEX Incripciones_Fecha_Idx ON Inscripciones(Fecha);

SELECT 
    * 
FROM 
    Inscripciones
WHERE 
    Fecha < TO_DATE('01-03-2022','dd-MM-YYYY');
    
-- Indices aplicando filtros
-- En postgre no podemos particionar un índice

CREATE INDEX Incripciones_Fecha_Idx ON Inscripciones(Fecha) WHERE Aprobado=true

-- también podemos crear índices para funciones o expresiones

-- Tengo un formulario de autocompletar: 
-- B1029%
-- WHERE lower(CIF) LIKE 'dato%'
-- quizas en este caso, no quiero discriminar MAYUSCULAS de MINUSCULAS

CREATE INDEX Empresas_Cif_Idx ON Empresas(lower(Cif));

SELECT * FROM EMPRESAS
WHERE lower(Cif) LIKE '3333%';

SELECT to_tsvector('spanish','Introducción a PostgreSQL');
SELECT to_tsquery('spanish','Introducción a PostgreSQL');

CREATE INDEX Cursos_Titulo_Gin_Idx ON Cursos USING gin(to_tsvector('spanish',Titulo));

SET enable_seqscan = off;
EXPLAIN SELECT id
FROM Cursos
WHERE
  to_tsvector('spanish',Titulo) @@ to_tsquery('spanish','SQL');
