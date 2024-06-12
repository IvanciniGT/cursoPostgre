-- Cursos
CREATE TABLE Cursos (
    Id          SMALLSERIAL     NOT NULL    PRIMARY KEY,                -- 2
    Duración    SMALLINT        NOT NULL,                               -- 2
    Importe     NUMERIC(7,2)    NOT NULL,                -- 99999,99    -- 12
    Titulo      VARCHAR(100)    NOT NULL                                -- 100
);
-- Empresas
CREATE TABLE Empresas(
    Id          SMALLSERIAL     NOT NULL    PRIMARY KEY,
    CIF         CHAR(10)        NOT NULL,
    Nombre      VARCHAR(100)    NOT NULL
);
-- Personas
CREATE TABLE Personas(
    Id          SERIAL          NOT NULL    PRIMARY KEY,        -- 4
    EmpresaId   SMALLINT,                                       -- 2
    NUMERO_DNI  INTEGER         NOT NULL,
    LETRA_DNI   CHAR(1)         NOT NULL,
    Nombre      VARCHAR(100)    NOT NULL,
    Apellidos   VARCHAR(100)    NOT NULL,
    Email       VARCHAR(100)    NOT NULL,
    FOREIGN KEY (EmpresaId) REFERENCES Empresas(Id)
);

-- Inscripciones
CREATE TABLE Inscripciones(
    CursoId     SMALLINT        NOT NULL,       -- 2
    PersonaId   INT             NOT NULL,       -- 4
    Fecha       DATE            NOT NULL,       -- 4
    Aprobado    BOOL            NOT NULL,       -- 1
    PRIMARY KEY (CursoId,PersonaId),
    FOREIGN KEY (CursoId)   REFERENCES Cursos(Id),
    FOREIGN KEY (PersonaId) REFERENCES Personas(Id)
);

-- CURSO >- INSCRIPSIONES -< PERSONAS -< EMPRESAS

INSERT INTO Cursos (Titulo, Duración, Importe) 
            VALUES ('Curso PostgreSQL', 24, 2000.0);
INSERT INTO Cursos (Titulo, Duración, Importe) 
            VALUES ('Introducción a PostgreSQL', 20, 3000.0);
INSERT INTO Cursos (Titulo, Duración, Importe) 
            VALUES ('SQL: Introducción', 24, 2500.0);
INSERT INTO Cursos (Titulo, Duración, Importe) 
            VALUES ('PostgreSQL para expertos en Oracle', 24, 2000.0);
INSERT INTO Cursos (Titulo, Duración, Importe) 
            VALUES ('Oracle y su SQL', 30, 1000.0);
INSERT INTO Cursos (Titulo, Duración, Importe) 
            VALUES ('SQL para todos', 35, 1500.0);


INSERT INTO Empresas(CIF, Nombre) 
            VALUES ('1111111A', 'Informatica Lopez S.A.');
INSERT INTO Empresas(CIF, Nombre) 
            VALUES ('2222222A', 'Seguros Redriguez S.A.');
INSERT INTO Empresas(CIF, Nombre) 
            VALUES ('3333333A', 'Telas Manolo S.A.');
INSERT INTO Empresas(CIF, Nombre) 
            VALUES ('4444444A', 'Electrodomésticos Sáchez S.A.');
INSERT INTO Empresas(CIF, Nombre) 
            VALUES ('5555555A', 'Luis Gutierrez y asociados S.A.');


INSERT INTO Personas (EmpresaId ,NUMERO_DNI, LETRA_DNI, Nombre, Apellidos, Email)
            VALUES ( lastval() ,23000,'T','Ivan','Osuna','ivan@ivan.com');

INSERT INTO Personas (EmpresaId ,NUMERO_DNI, LETRA_DNI, Nombre, Apellidos, Email)
            VALUES ( lastval()-1 ,23000,'T','Luis','García','ivan@ivan.com');

INSERT INTO Personas (EmpresaId ,NUMERO_DNI, LETRA_DNI, Nombre, Apellidos, Email)
            VALUES ( lastval()-2 ,23000,'T','Ruth','Núñez','ivan@ivan.com');

INSERT INTO Personas (EmpresaId ,NUMERO_DNI, LETRA_DNI, Nombre, Apellidos, Email)
            VALUES ( lastval()-2 ,23000,'T','Fernán','Esteban','ivan@ivan.com');


INSERT INTO INSCRIPCIONES ( CursoId, PersonaId, Fecha, Aprobado)
            VALUES ( currval('cursos_id_seq') , currval('personas_id_seq') ,'03-10-2022',false);

INSERT INTO INSCRIPCIONES ( CursoId, PersonaId, Fecha, Aprobado)
            VALUES ( currval('cursos_id_seq') -1, currval('personas_id_seq') -1,'03-08-2022',false);

INSERT INTO INSCRIPCIONES ( CursoId, PersonaId, Fecha, Aprobado)
            VALUES ( currval('cursos_id_seq') -1, currval('personas_id_seq')-2 ,'03-20-2022',false);

INSERT INTO INSCRIPCIONES ( CursoId, PersonaId, Fecha, Aprobado)
            VALUES ( currval('cursos_id_seq') -2, currval('personas_id_seq') -2,'03-22-2022',false);

INSERT INTO INSCRIPCIONES ( CursoId, PersonaId, Fecha, Aprobado)
            VALUES ( currval('cursos_id_seq') -2, currval('personas_id_seq') -3,'02-01-2022',true);

INSERT INTO INSCRIPCIONES ( CursoId, PersonaId, Fecha, Aprobado)
            VALUES ( currval('cursos_id_seq') -3, currval('personas_id_seq') -3,'01-10-2022',true);


INSERT INTO INSCRIPCIONES ( CursoId, PersonaId, Fecha, Aprobado)
            VALUES ( currval('cursos_id_seq') -3, currval('personas_id_seq') -3,'03-10-2022',true);


CREATE TABLE LETRAS_DNI (
    RESTO SMALLINT NOT NULL PRIMARY KEY,
    LETRA CHAR(1)    
);
INSERT INTO LETRAS_DNI (RESTO,LETRA) VALUES (0,'T');
INSERT INTO LETRAS_DNI (RESTO,LETRA) VALUES (1,'R');
INSERT INTO LETRAS_DNI (RESTO,LETRA) VALUES (2,'W');
INSERT INTO LETRAS_DNI (RESTO,LETRA) VALUES (3,'A');
INSERT INTO LETRAS_DNI (RESTO,LETRA) VALUES (4,'G');
INSERT INTO LETRAS_DNI (RESTO,LETRA) VALUES (5,'M');
INSERT INTO LETRAS_DNI (RESTO,LETRA) VALUES (6,'Y');
INSERT INTO LETRAS_DNI (RESTO,LETRA) VALUES (7,'F');
INSERT INTO LETRAS_DNI (RESTO,LETRA) VALUES (8,'P');
INSERT INTO LETRAS_DNI (RESTO,LETRA) VALUES (9,'D');
INSERT INTO LETRAS_DNI (RESTO,LETRA) VALUES (10,'X');
INSERT INTO LETRAS_DNI (RESTO,LETRA) VALUES (11,'B');
INSERT INTO LETRAS_DNI (RESTO,LETRA) VALUES (12,'N');
INSERT INTO LETRAS_DNI (RESTO,LETRA) VALUES (13,'J');
INSERT INTO LETRAS_DNI (RESTO,LETRA) VALUES (14,'Z');
INSERT INTO LETRAS_DNI (RESTO,LETRA) VALUES (15,'S');
INSERT INTO LETRAS_DNI (RESTO,LETRA) VALUES (16,'Q');
INSERT INTO LETRAS_DNI (RESTO,LETRA) VALUES (17,'V');
INSERT INTO LETRAS_DNI (RESTO,LETRA) VALUES (18,'H');
INSERT INTO LETRAS_DNI (RESTO,LETRA) VALUES (19,'L');
INSERT INTO LETRAS_DNI (RESTO,LETRA) VALUES (20,'C');
INSERT INTO LETRAS_DNI (RESTO,LETRA) VALUES (21,'K');
INSERT INTO LETRAS_DNI (RESTO,LETRA) VALUES (22,'E');