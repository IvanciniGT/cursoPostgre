
# PostgreSQL

Es una BBDD Relacional.

---

# DATOS

Los vamos a querer persistir en la mayor parte de los casos.
Para persistirlos usamos ficheros/archivos.

Los SO nos ofrecen 2 formas de trabajar con ficheros:
- Fichero de acceso secuencial:
  - Muy sencillo de gestionar: Para archivos pequeños esta guay!
    - Leer un archivo de principio a fin     (Leer)
    - Escribir un archivo de principio a fin (Reescribir)
    - Añadir al final                        (Añadir)
- Fichero de acceso aleatorio
    - Esto me permite poner a agujita del HDD en la posición que me interese... para leer o para escribir.
    - **Esto es jodido de gestionar**.
    - Para trabajar con ficheros grandes, muy óptimo.
    - Voy a necesitar MUCHO más espacio de almacenamiento que cuando tengo ficheros de acceso secuencial.

Los desarrolladores cuando crean programas que necesitan lidiar con archivos huyen de los ficheros de acceso aleatorio como de la peste. Intento siempre que puedo usar archivos de acceso secuencial.

Y cuando no puedo? Me voy a una BBDD... que es lo que me dan. Las BBDD relacionales nos ofrecen una forma muy eficiente y asequible de trabajar con datos que se guardan en archivos de acceso aleatorio.

```json
{
    "usuarios": [
        {
            "nombre": "Pepe",
            "edad": 23,
            "casado": false
        },
        {
            "nombre": "Menchu",
            "edad": 34,
            "casado": true
        }
    ]
}
```

```
NOMBRE      EDAD    CASADO
Pepe        23      false
Menchu      34      true
......
Federico    45      false
```

El acceso aleatorio a datos es maravillo... tan maravilloso como complejo!
Me toca echar cuentas.
NOMBRE: 20 bytes
EDAD:    2 1byte
CASADO:  1 1byte

Sé que una fila ocupa: 20 + 2 = 23 bytes

Si quiero editar el dato de la edad de la tercera fila, tengo que colocar la aguja en:
Me salto de las filas anteriores: 23 * 2 = 46 bytes
En la actual, me voy a la edad: Me salto el nombre:  20 bytes
Coloco la aguja en la posición 46 + 20 = 66 byte... y leo o escribo 1 byte.

---

Los datos en postgresql, igual que en otras BBDD relacionales los guardaremos en tablas.
Y esas tablas irán a archivos de acceso aleatorio.

Cuánto ocupa cada dato? Va a depender del tipo de dato que sea (eso defino en el esquema asociado a la tabla)

## TIPOS DE DATOS EN POSTGRESQL

### Números

- smallint:                       2 bytes
- integer, int, int4:             4 bytes
- bigint:                         8 bytes
- real, float4:                   4 bytes
- double precision, float8:       8 bytes
- numeric, decimal:               variable. Damos 2 datos: precisión y escala. numeric(10, 2) -> 10 bytes
- smallserial:                    2 bytes
- serial:                         4 bytes
- bigserial:                      8 bytes

0000 0000 0000 0000 0000 0000 0000 0000 QUE ES ESTO? QUE REPRESETA?   0 - 2050M
                                                                [-2050M , 2050M]

Cuanto valores distintos puedo representar con 4 bytes:
1 byte: 256 ? Que significan esos valores
00000000            0           -128            a
00000001            1           -127
...
01000010            100         -10
...
11111111            255         127

### Texto

- char(n)... cuánto ocupa en el fichero? n bytes
  NPI...Depende... del JUEGO DE CARACTERES que esté usando.
  - ASCII       1 byte: solo puedo representar 256 caracteres
  - UTF-8       \
  - UTF-16       > Unicode Transform Format... El numerito es el número MINIMO de bits que ocupa un caracter.
  - UTF-32      /
  - ISO-8859-1  1 byte: solo puedo representar 256 caracteres (áéñ aê)
    Depende del juego de caracteres.... cómo interpreto los bytes que tengo en el fichero.
- varchar(n): variable. n bytes
- text (Para textos gigantes de tamaño a priori desconocido)  (lo que en Oracle sería CLOB)

### Fechas:

- date: 4 bytes
- time: 8 bytes
- timestamp: 8 bytes
- timestampz: 8 bytes
- interval: 16 bytes

### Booleanos:

- boolean: 1 byte

### Binarios

- bytea: variable

### Campos especiales:

- json
- xml
- point
- polygon
- circle
- cidr
- inet
- macaddr

#### UNICODE 

Es un estándar internacional que recoge todos los caracteres de todos los idiomas del mundo (EMOJIS)
Ahora mismo lleva unos 150.000 caracteres.

1 bytes: 256 caracteres                 8 bits
2 bytes: 65.536 caracteres             16 bits
4 bytes: 4.294.967.296 caracteres      32 bits

UTF-32 usa independientemente del caracter que sea 4 bytes (32 bits)
UTF-16 usa 2 bytes (16 bits) para los caracteres que se pueden representar con 2 bytes y 4 bytes para los que no.
    Los caracteres más normalitos: A, j, 9, -, á -> 2 bytes
    Los caracteres más raritos: 🤣, 🤔, 🤯 å ø    -> 4 bytes
UTF-8 usa 1 byte para los caracteres más normalitos, 2 bytes para los que son menos frecuentes y 4 bytes para los que son raros.


---

# Qué tal va lo del almacenamiento.. Es caro o barato hoy en día?

CARO DE COJONES. El de buena calidad es caro...
El dato es lo más valioso.
Cuantas copias del dato hago en producción? 3 copias del dato
Para sacar 3Tbs necesito 3 HDD 3 Tbs... de los caros.

En mi casa 3Tbs 90€ 
En la empresa 3Tbs= 3x 200 = 600€

Backups: 3 tbs -> 10 tbs
Índices...


---


Cuando defino el esquema, le puedo dar a postgre los tipos de datos de cada columna... y así el PG
calcula las posiciones a las que tiene que mover la aguja del HDD para leer/escribir...

O no? NO solo con eso.

---

# Cómo postgreSQL organiza los ficheros de la BBDD

Postgre, va a guardar los datos de cada fila en el orden en el que los defina yo en el esquema.

```sql
CREATE TABLE miTabla {
    id bigserial,               -- 8 bytes
    numerito1 int,              -- 4 bytes
    casado boolean,             -- 1 bytes
    fechayhora timestamp,       -- 8 bytes
    otrafecha date,             -- 4 bytes
    texto varchar(10)           -- NPI (UTF-8)... 0-10
}
```
PREGUNTA: Cuánto ocupa cada fila de esa tabla? 25-35 bytes ... ni de coña !!!!

PostgreSQL requiere que los campos que ocupan 8 bytes comiencen en posiciones múltiplos de 8 bytes:
WELCOME BACK TO TETRIS !!!!!

|bigserial|int|boolean| |timestamp |date|varchar|
|8        |4  |1      |3| 8        |4   |10     | -> 38 bytes
                       ^
                       Espacio tirado a la basura

|boolean| |bigserial|int| |timestamp |date|varchar|
|1      |7|8        |4  |4| 8        |4   |10     | -> 50 bytes : 11 bytes tirados a la basura
        ^
        Espacio tirado a la basura

Hay datos... cuyo contenido es de tamaño variable:
- varchar

        TABLA: EMPLEADOS DE LA EMPRESA
    |2 bytes  |  1    |VC(50) | VC(50)    |
    | id      |  Edad |Nombre | Apellidos |

Ahora... cuanto ocupa la fila? Entre 8 bytes y 108 bytes
Vale...
Y la siguiente fila donde la escribo? En la posición 14x8 = 112 -> 113 (En el siguiente bloque de 8 bytes)
Claro... y si no guardo nada? Pierdo 100 bytes
De hecho lo que estamos usando son los campos varchar como si fueran campos de tipo char.
ASI NO FUNCIONA !!!! desperdicio mucho espacio... y quiero que se optimice... y POSTGRESQL lo optimiza.
El problema es que para optimizar ocurre lo siguiente:

       FILA 1                      Fila 2                                             Fila 3                
       0 bytes                     24 bytes                                           24+32 = 56 bytes
       v                           v                                                  v
      |123312|23| |Pepe| |Pérez|  |989898|45| |Juan| |García Hernandez de las Matas| |...
BYTES    2     1|5|  4 |4|   6 | 2|   2  | 1|5|  4 |4| 30                          |2|
                ^   ^    ^   ^    ^

La primera fila empieza en la posición 0, la segunda fila empieza en la posición 24... y la tercera fila empieza en la posición 56. Hay forma a priori (sin más datos) de saber en que posición empieza una linea / fila de la tabla? NO... IMPOSIBLE
Las filas se guardan en PAGINAS DE DATOS (BLOQUES) de 8Kb (8192 bytes)
En cada bloque, lo primero que tengo es un listado de todas las filas que hay guardadas (ROWID) con la posición en la que empieza cada fila.
Y si ahora Pepe... que esto me han dicho que hoy en día se hace... se va al juzgado y pide que le llamen Menchu! QUE PASA?      "UPDATE"
Entra sin problema? En este caso, entra... gracias al PADDING (4) sin que afectase al resto de la página
Pero... y si en lugar de Menchu, quiere llamarse Margarita (9 bytes)
Entra Margarita donde estaba guardado Pepe??? ni contando los 4 espacios de padding que se habían dejado.
Con lo que esa fila queda muerta en la página... y se reescribe la fila en la misma página si es que hay hueco... o en otra página si es que no lo hay.
Cada fila, además de ocupar lo que ocupen sus datos.. va a llevar METADATOS: 24 bytes
Entre ellos por ejemplo si la fila está vigente o no... Si no está vigente podrá ser eliminada al realizar una 
compactación del fichero de la BBDD (tabla): VACUUM

Si tengo tablas sujetas a muchas actualizaciones... este comportamiento es bueno? NO TANTO... puede generar demasiada basura en los ficheros.

Y aquí tenemos una opción... que se usa por otras bbdd (especialmente en los índices)... FILLFACTOR
Porcentaje de espacio que se deja libre en cada fila/página para que se puedan hacer actualizaciones sin tener que reescribir la fila.
|123312|23| |Pepe| |Pérez|  |
  2     1 |5|  4 |4|   6 | 2|  -> 24 bytes
  Pero quiero un 25% libre... por si las moscas.
|123312|23| |Pepe| |Pérez|  | |
  2     1 |5|  4 |4|   6 | 2|8   -> 32 bytes
De forma que si hay una actualización que afecta a la fila... no haya que reescribir la fila entera... sino que se pueda hacer en el espacio libre que se ha dejado.    

---

Para cada columna podemos especificar distintos tipos de almacenamiento:

- PLAIN: Almacena una columna tal cual... dentro del bloque de datos.
- EXTERNAL: Almacena una columna fuera del bloque de datos.
- EXTENDED: Como el external... pero con compresión.
- MAIN: Almacena una columna en el bloque de datos... si entra... incluso lo comprime si lo necesita.
        Y si no entra, lo llevas a otro fichero 

---

# Índices

Un problema es almacenar al información... de forma eficiente, sobre todo si luego quiero actualizarla... que no me ocupe mucho espacio.

Acceder rápidamente a la información.

Por defecto, si tengo una tabla con datos... y quiero buscar las filas (o columas de esas filas) que cumplan con unas determinadas condiciones, la BBDD va a hacer lo que llamamos un FULL SCAN DE LA TABLA:
- Leer todas las filas de la tabla.... con suerte, tendré muchas de ellas en RAM(CACHE) y no tendrá que ir al HDD. Para las que no tenga en cache, me tocará ir al HDD.

Hay alguna forma de optimizar esto? INDICES?

## Qué es un índice?

Y salgamos de las BBDD... es una copia ordenada de TODOS los datos por los que quiero hacer una búsqueda rápida.

En qué forma, qué procedimiento puedo usar para hacer una búsqueda más efectiva? ALGORITMO DE BÚSQUEDA BINARIA.
Cada vez que buscamos una palabra en un diccionario, estamos usando un algoritmo de búsqueda binaria.
Es un algoritmo de búsqueda muy eficiente, comparado con un FULLSCAN.
El fullscan me obliga a ir dato a dato.

Si tengo 1.000.000 de faturas...y quiero 1... en total puede ser que necesite hacer 1M de comparaciones.
Si los datos están ordenados por el número de factura.

1.000.000
  500.000
  250.000
  125.000
   62.500
   31.250
   15.625
    7.812
    3.906
    1.953
    1.000
      500
      250
      125
       62
       31
       15
        7
        3
        1
En 20 operaciones, en el peor de los casos he encontrado la factura que buscaba.

Comparad 20 ~ 1.000.000 LA DIFERENCIA ES ABERRANTE !!!!

Solo tenemos un problemilla... Los algoritmos de búsqueda binaria obligan a trabajar sobre conjuntos de datos ordenados de antemano...

Pero un conjunto de datos, en su almacenamiento los puedo tener ordenados solamente por un campo.
Podría cada vez que tengo que hacer una búsqueda ordenadr primero los datos... por el campo de búsqueda... de esta forma la búsqueda sería muy eficiente... 
El problema es : Qué tal se le da a los ORDENADORES ordenar datos? COMO EL PUTO CULO !
Es de las peores cosas que se le da a un ordenador... ordenar datos.

De hecho tarda más un ordenador / computadora en hacer una ordenación que en hacer el fullscan.
Ahí es donde entran los INDICES.

Antes de entrar en el concepto de INDICE... 
Si vosotros tuvierais que buscar en el diccionario la palabra "zapato"... abriríais el diccionario por la mitad? Casi al final... verdad? POR QUE?
Porque conocéis la DISTRIBUCIÓN de los datos... más o menos...

Pregunta... la BBDD al hacer una búsqueda binaria... corta por la mitad? TAMPOCO
La BBDD va aprendiendo la DISTRIBUCIÓN DE LOS DATOS...
    Número de factura:
        Facturas que empiecen por 1: 500.000    \
        Facturas que empiecen por 2: 250.000     | ESTADÍSTICAS DE LA TABLA
        Facturas que empiecen por 3:   1.000     |
        Facturas que empiecen por 4: 249.000    /
    Y en base a esa distribución de los datos dentro de la columna, optimiza el primer/segundo/tercero cortecito que hace en la búsqueda binaria.
        Y en lugar de 20 operaciones.. quizás con 16-17... 15 me sirve


### Volvamos a los índices

Es una copia preordenada de parte de los datos de una tabla (de ciertas columnas) (hay opción también de quitar filas...) + Una ubicación en la tabla original.

| RECETAS |
| id | nombre               | dificultad | tiempo | ingrediente principal | tipo_de_plato | tipo2              |
| 1  | Paella               | 3          | 60     | Arroz                 | Arroces       | plato principal    |
| 2  | Tortilla             | 2          | 30     | Patatas               | Huevos        | aperitivo          |
| 3  | Cocido               | 4          | 120    | Garbanzos             | Cocidos       | comida completa    |
| 4  | Corderito al horno   | 5          | 180    | Cordero               | Asados        | plato principal    |
| 5  | Ensalada de pasta    | 1          | 10     | pasta                 | Pastas        | segundo plato      |
    1000000 filas                                                                           200 valores diferentes
       980000 filas

INDICE tipo2
    aperitivo         2
    comida completa   3
    plato principal   1, 4
    segundo plato     5

Ahora si me piden una búsqueda por tipo2 como la siguiente:
    SELECT * FROM RECETAS WHERE tipo2 = 'plato principal';
, puedo hacer una búsqueda binaria en el índice y encontrar la fila en la tabla original.

Ahora bien... si me piden la búsqueda:
    SELECT * FROM RECETAS WHERE tipo2 LIKE 'plato%';
Puedo hacer búsqueda binaria? También

Y si... me piden la búsqueda:
    SELECT * FROM RECETAS WHERE tipo2 LIKE '%plato%';
Puedo hacer búsqueda binaria? Nasti de plasti... No cuela la búsqueda binaria.. necesito un fullscan... de qué?
    - de la tabla
    - del índice <- En el índice tengo menos datos que en la tabla... tardo menos.              ORACLE TEXT
                                                                                                     ^
    SELECT * FROM RECETAS WHERE lower(tipo2) LIKE '%plato%'; ---> COLLATE (intercalaciones) + INDICES INVERTIDOS -> Búsqueda FULL_TEXT
        Los collates configuran cómo la BBDD debe comparar u ordenar determinadas columnas al trabajar.
        Hay collates que no distinguen entre acentos y mayúsculas y minúsculas... y otros que sí.

---

| RECETAS |
| id | nombre               | dificultad | tiempo | ingrediente principal | tipo_de_plato | tipo2              |
| 1  | Paella               | 3          | 60     | Arroz                 | Arroces       | plato principal    |
| 2  | Tortilla             | 2          | 30     | Patatas               | Huevos        | aperitivo          |
| 3  | Cocido               | 4          | 120    | Garbanzos             | Cocidos       | comida completa    |
| 4  | Corderito al horno   | 5          | 180    | Cordero               | Asados        | plato principal    |
| 5  | Ensalada de pasta    | 1          | 10     | pasta                 | Pastas        | segundo plato      |

Añadir un dato: INSERT INTO RECETAS VALUES (6, 'Pulpo a la gallega', 3, 45, 'Pulpo', 'Mariscos', 'aperitivo');
        Al final esto es escribir en un fichero ese dato... RAPIDO de narices!

INDICE nombre
    Cocido               3
    HUECO PRERESERVADO
    HUECO PRERESERVADO
    Corderito al horno   4
    HUECO PRERESERVADO
    HUECO PRERESERVADO
    Ensalada de pasta    5
    HUECO PRERESERVADO
    HUECO PRERESERVADO
    Paella               1
    HUECO PRERESERVADO
        <<< Pulpo a la gallega   6       Para meter eso ahí, necesito que haya hueco... Si no hay hueco? ***
    HUECO PRERESERVADO
    Tortilla             2
    HUECO PRERESERVADO

En cuantito configuro un índice, además de añadir en la tabla lso 50 bytes de marras, que hay que hacer?
Actualizar el índice:
- Buscar la posición en la que tengo que añadir el dato

*** El índice comienza a fragmentarse... Necesito guardar ese bloque de datos (pulpo a la gallega) en otro bloque de datos... y al leer el índice, tendré que consolidar en RAM los datos de los distintos bloques de datos... y eso es más lento.

Y para evitar esto, las BBDD dejan mogollón de espacios en blanco en los ficheros de los índices.
Y el día que se acaben los huecos? REGENERAR EL INDICE: ESCRIBIR DE NUEVO TODO EL FICHERO DEL INDICE... dejando nuevos huecos.

Nosotros vamos a poder configurar cuántos huecos queremos en el índice ... en cada índice: FILL_FACTOR

Si tengo 1M de datos... de 50 bytes: 50M
Si dejo un 50% de huecos: 100M -> 3 copias... y backups...

---

# Índices en PostgreSQL

- B-Tree... éste es el que os he contado por arriba!
  - Me soporta igual, mayor, menor, igual o mayor, igual o menor, entre... , LIKE, distinto
- Hash
  La diferencia con los B-Tree es que en lugar de copiar a un fichero los datos originales de la(s) columna(s) que quiero tener preordenadas, lo que copiamos es un HASH (Huella) de esos datos. Los algoritmos de HASH que usamos en computación lo que devuelven es un número... que es único para cada dato.

    INDICE nombre
        1020119211               3
        HUECO PRERESERVADO
        HUECO PRERESERVADO
        1932874628               4
        HUECO PRERESERVADO
        HUECO PRERESERVADO
        2837498287               5
        HUECO PRERESERVADO
        HUECO PRERESERVADO
        5203947212               1
        HUECO PRERESERVADO
            <<< 821726736        6       Para meter eso ahí, necesito que haya hueco... Si no hay hueco? ***
        HUECO PRERESERVADO
        91827837418              2
        HUECO PRERESERVADO
    Ventajas de usar un índice de tipo HASH:
    - Tamaño fijo
    - Es más fácil comprar un número con otro... o comparar textos?
    - Va a ocupar menos espacio en disco
      - Pulpo a la gallega -> 18 bytes
      - 8 bytes -> 2^64 = 18.446.744.073.709.551.616
    Limitaciones: 
        - No puedo hacer likes
        - No puedo hacer RANGOS (> <)
        - De hecho lo único que puedo hacer con estos índices es: IGUAL y DISTINTO

- GIN: Generalized Inverted Index: Me permiten hacer búsquedas de tipo FULLTEXT

| Nombre de la receta                |
|------------------------------------|
| Paella de marisco                  |
| Paella de verduras                 |
| Mariscada                          |
| Tortilla de patatas                |
| Patatitas al horno                 |
| Patatas fritas                     |
| Tortilla de camarones              |

Quiero un índice... para poder acelerar búsquedas de tipo : LIKE %patata%
- El hash no me sirve
- El BTree... como mucho me permitiría hacer un FULLSCAN


En este caso un GIN nos viene que ni pintado.
1º Tokenizar el texto:  (tengo que separar tokens por : espacios, comas, puntos, guiones, barras, etc)
    "Paella de marisco" -> "Paella", "de", "marisco"
    Paella de verduras -> Paella, de, verduras
    Mariscada -> Mariscada
    Tortilla de patatas -> Tortilla, de, patatas
    Patatitas al horno -> Patatitas, al, horno
    Patatas fritas -> Patatas, fritas
    Tortilla de camarones -> Tortilla, de, camarones
2º Eliminar las palabras vacías de significado (dependiendo del idioma, las palabras vacías de significado pueden ser distintas)
    "Paella", *,  "marisco"
    "Paella", *, "verduras"
    "Mariscada"
    "Tortilla", * , "patatas"
    "Patatitas", *, "horno"
    "Patatas", "fritas"
    "Tortilla", *, "camarones"
3º Normalizar los tokens: Pasarlos a minúsculas... quitar acentos si los hay
    "paella", "*", "marisco"
    "paella", "*", "verduras"
    "mariscada"
    "tortilla", "*", "patatas"
    "patatitas", "*", "horno"
    "patatas", "fritas"
    "tortilla", "*", "camarones"
3.5º Quedarme con la raiz etimológica de las palabras
    "paella" -> "paell"
    "marisco" -> "marisc"
    "verduras" -> "verdur"
    "mariscada" -> "marisc"
    "tortilla" -> "tortill"
    "patatas" -> "patat"
    "patatitas" -> "patat"
    "horno" -> "horn"
    "fritas" -> "frit"
    "camarones" -> "camaron"
4º Indexar los tokens con su posición original dentro del dato
    "paella" -> 1(1), 2(1)
    "marisco" -> 1(3)
    "verduras" -> 2(3)
    "mariscada" -> 3(1)
    "tortilla" -> 4(1), 7(1)
    "patatas" -> 4(3), 6(2)
    "patatitas" -> 5(1)
    "horno" -> 5(3)
    "fritas" -> 6(3)
    "camarones" -> 7(3)
5º Esos tokens son los que ordeno: GIN
    "camaron" -> 7(3)
    "frit" -> 6(3)
    "horn" -> 5(3)
    "marisc" -> 1(3), 3(1)
    "paell" -> 1(1), 2(1)
    "patat" -> 4(3), 6(2)
    "tortill" -> 4(1), 7(1)
    "verdur" -> 2(3)

---
Cuando se hace una búsqueda del tipo: LIKE %Patata%... se aplica sobre el término de búsqueda el mismo proceso que se ha aplicado a los datos... y se busca en el índice.
    -> Patata -> patat
                  ^ Y con esto hago la búsqueda binaria en el índice
Me permite hacer búsquedas fulltext de forma muy eficiente.
A costa de un tiempo grande en indexado (que normalmente se hace de forma ASINCRONA... para evitar retrasos en los commits)

Si quiero realmente mucha potencia en este tipo de búsquedas me interesa más montar un MOTOR DE INDEXACION: ElasticSearch, Solr, Sphinx, Lucene


| Nombre de la receta                |
|------------------------------------|
| Paella de marisco                  |
| Paella de verduras                 |
| Mariscada                          |
| Tortilla de patatas                |
| Patatitas al horno                 |
| Patatas fritas                     |
| Tortilla de camarones              |








---

# Algoritmos de HASH (HUELLA) MD5, SHA-1, SHA-256, SHA-512

Los usáis de nuevo desde que tenéis 8-15 años.

DNI España: 12345678-LETRA
La letra es un hash (huella) del número.

Un algoritmo de tipo HASH es una función que dado un valor:
- Siempre devuelve el mismo resultado
- Hay una probabilidad lo "suficientemente" baja de que dos valores distintos de entrada devuelvan el mismo resultado de salida
  Qué probabilidad hay que 2 DNI compartan letra: 1/24 ~= 4% (1/24)  -> COLISION
- Desde el dato resultado es impossible obtener el dato original(el dato resultado es un RESUMEN del dato original)

Letra del DNI:
- Se toma el número y se divide entre 23
    23.000.007 | 23
               +----------
             7   1.000.000
             ^
             RESTO: 0-22
             Al 7 le corresponde la letra F

Los algoritmos de hash que usamos normalmente tienen una probabilidad de colisión muy baja... casí nula.
MD5 -> Probabilidad de colisión: 1/2^128
SHA-512 -> Probabilidad de colisión: 1/2^512
