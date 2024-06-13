# Indices

- btree
- hash
- gin
 
## INDICE BTREE

CREATE INDEX Incripciones_Fecha_Idx ON Inscripciones(Fecha);

Me vale para : 
- EQUAL / NOT EQUAL = <>
- > < >= <= RANGE
- LIKE "patron%"

## INDICES HASH

CREATE INDEX Empresas_Cif_Hash_Idx ON Empresas USING hash(Cif);

Me vale para : 
- EQUAL / NOT EQUAL = <>
A cambio:
- Ocupaba menos espacio
- Mejor rendimiento

## INDICES GIN
CREATE INDEX Cursos_Titulo_Gin_Idx ON Cursos USING gin(to_tsvector('spanish',Titulo));

---

Tengo una aplicación que se está diseñando. WEB.
Hay un formulario de captura de datos: Personas (DNI)

FORMULARIO HTML   ---> SERVIDOR     ----->  BBDD
DNI [   ]               Proceso             Personas(DNI) << CONSULTAS BI
                                                ^^ 
                                                SQL INSERTS

> PREGUNTA: Si solo dispusiera de un sitio para validar el DNI, cuál sería el sitio donde validaría?

- FORMULARIO    
- SERVIDOR
- BBDD<<<<

La BBDD es la garante del DATO.
No puedo permitir que la BBDD contenga un dato ERRONEO.

Otro tema es que por cortesía, en el formulario validaré (interactividad... y no cargar Servidor y BBDD innecesariamente)

EL CAMPO ES FECHA DE NACIMIENTO... va a validar la BBDD que lo que meta sea una fecha? "DIA / MES / AÑO"

DNI: Secuencia de 1 a 8 dígitos seguido de una letra que tiene que cuadrar con el número.

---

Hoy en día, los desarrolladores usan frameworks (librerías) que les generan en autom. todo el SQL.