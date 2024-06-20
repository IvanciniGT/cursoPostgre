import psycopg2
from psycopg2 import sql
from faker import Faker

# Configuración de la conexión
db_config = {
    'dbname': 'bd',
    'user': 'postgres',
    'password': 'Pa$$w0rd',
    'host': '172.31.0.71',
    'port': '5432'
}

# Constantes para el número de registros
NUM_USERS = 10
NUM_DIRECTORS = 5
NUM_TEMATICS = 2
NUM_MOVIES = 1
NUM_VISUALIZATIONS = 2

# Conexión a la base de datos
try:
    conn = psycopg2.connect(**db_config)
    cur = conn.cursor()
    print("Conexión a la base de datos exitosa")
except Exception as e:
    print(f"Error al conectar a la base de datos: {e}")
    exit()

# Generador de datos de prueba
fake = Faker()

# Función para ejecutar una consulta con manejo de errores
def execute_query(query, params):
    try:
        cur.execute(query, params)
    except Exception as e:
        print(f"Error al ejecutar la consulta: {e}")
        conn.rollback()  # Revertir la transacción en caso de error
        return False
    return True

# Inserción de datos en la tabla usuarios
def insert_users(num_users):
    emails = set()
    for _ in range(num_users):
        email = fake.email()
        while email in emails:
            email = fake.email()
        emails.add(email)
        
        nombre = fake.name()
        if not execute_query(
            sql.SQL("INSERT INTO usuarios (email, nombre) VALUES (%s, %s)"),
            [email, nombre]
        ):
            break
    conn.commit()
    print(f'{num_users} usuarios insertados.')

# Inserción de datos en la tabla directores
def insert_directors(num_directors):
    nombres = set()
    for _ in range(num_directors):
        nombre = fake.name()
        while nombre in nombres:
            nombre = fake.name()
        nombres.add(nombre)
        
        if not execute_query(
            sql.SQL("INSERT INTO directores (nombre) VALUES (%s)"),
            [nombre]
        ):
            break
    conn.commit()
    print(f'{num_directors} directores insertados.')

# Inserción de datos en la tabla tematicas
def insert_tematics(num_tematics):
    nombres = set()
    for _ in range(num_tematics):
        nombre = fake.word()
        while nombre in nombres:
            nombre = fake.word()
        nombres.add(nombre)
        
        if not execute_query(
            sql.SQL("INSERT INTO tematicas (nombre) VALUES (%s)"),
            [nombre]
        ):
            break
    conn.commit()
    print(f'{num_tematics} temáticas insertadas.')

# Inserción de datos en la tabla peliculas
def insert_movies(num_movies):
    for _ in range(num_movies):
        tematica = fake.random_int(min=1, max=NUM_TEMATICS)
        director = fake.random_int(min=1, max=NUM_DIRECTORS)
        duracion = fake.random_int(min=60, max=180)
        fecha = fake.date_between(start_date='-30y', end_date='today')
        edad_minima = fake.random_int(min=0, max=18)
        nombre = fake.sentence(nb_words=3)
        
        if not execute_query(
            sql.SQL("INSERT INTO peliculas (tematica, director, duracion, fecha, edad_minima, nombre) VALUES (%s, %s, %s, %s, %s, %s)"),
            [tematica, director, duracion, fecha, edad_minima, nombre]
        ):
            break
    conn.commit()
    print(f'{num_movies} películas insertadas.')

# Inserción de datos en la tabla visualizaciones
def insert_visualizations(num_visualizations):
    for _ in range(num_visualizations):
        usuario = fake.random_int(min=1, max=NUM_USERS)
        pelicula = fake.random_int(min=1, max=NUM_MOVIES)
        fecha = fake.date_time_this_year()
        
        if not execute_query(
            sql.SQL("INSERT INTO visualizaciones (usuario, pelicula, fecha) VALUES (%s, %s, %s)"),
            [usuario, pelicula, fecha]
        ):
            break
    conn.commit()
    print(f'{num_visualizations} visualizaciones insertadas.')

# Ejecución de las funciones de inserción
try:
    insert_users(NUM_USERS)           # Insertar usuarios
    insert_directors(NUM_DIRECTORS)        # Insertar directores
    insert_tematics(NUM_TEMATICS)         # Insertar temáticas
    insert_movies(NUM_MOVIES)          # Insertar películas
    insert_visualizations(NUM_VISUALIZATIONS)  # Insertar visualizaciones
finally:
    # Cerrar la conexión
    cur.close()
    conn.close()
