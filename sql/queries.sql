-- CURSOS >- INSCRIPCIONES -< PERSONAS -< EMPRESAS

-- NOMBRE DE LAS PERSONAS y DE SUS EMPRESAS (SI LAS TIENE) que tienen cursos este mes

SELECT 
    Personas.Nombre,
    Personas.Apellidos,
    Empresas.Nombre
FROM
    Empresas
    RIGHT OUTER JOIN  Personas      ON Personas.EmpresaId = Empresas.Id
    INNER JOIN        Inscripciones ON Personas.Id = Inscripciones.PersonaId
WHERE
    extract('month' FROM Inscripciones.Fecha) = extract('month' FROM current_date) and
    extract('year'  FROM Inscripciones.Fecha) = extract('year'  FROM current_date) 
;

SELECT 
    Personas.Nombre,
    Personas.Apellidos,
    Empresas.Nombre
FROM
    Empresas
    RIGHT OUTER JOIN  Personas      ON Personas.EmpresaId = Empresas.Id
    INNER JOIN        Inscripciones ON Personas.Id = Inscripciones.PersonaId
WHERE
    extract('month' FROM Inscripciones.Fecha) = 1 and
    extract('year'  FROM Inscripciones.Fecha) = 2022
;

-- Si tengo una fecha para la que hay 1000 cursos... de un total de 1M de cursos.
-- a postgres le va a interesar entrar por el índice
-- Si para esa fecha hay 250.000 cursos ... de 1M... aquí se lo empezaría e pensar.
-- Entrando por el índice, llega más rápido.. a los ids... 
-- pero luego tiene que ir, leyendo en cualquier caso de la tabla gorda el resto de datos...
-- Si para esa fecha hay 900.000 cursos ... de 1M... ni de coña usaría un índice sobre fel campo fecha.
