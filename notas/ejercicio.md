
NETFLIX

Usuarios        1M
id
estado
email           ***
nombre
alta

Visualizaciones     1M x 200 = 200M
usuario
pelicula
fecha               Peliculas que están teniendo éxito ahora mismo. TOP 10 (*)

    HASH -> usuario
    HASH -> pelicula
    HASH -> fecha
    RANGO -> fecha (*)
        Cerrado año... ni vacuum, ni analyze... ni backups

Peliculas       5000
id
nombre          ****
tematica
director
duracion
fecha           **** NOVEDADES
edad_minima

Tematica        20
id
nombre          **** < - TRIGRAMAS

Director
id
nombre

