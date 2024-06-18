
Instalación Postgres - 2       Postgres15
    Amazon linux (REDHAT)
      v  REPLICA
    Ubuntu
    
    Crear BBDD (netflix)
    Cargar datos
---



---

Linux

Instalación: ALTA RE REPO: yum, dnf, apt
Con el mismo comando instalación: dnf install postgresql-15-server

postgresql-setup --initdb (crea todos los archivos)

Los servicios se gestionan con el demonio del sistema: systemd < systemctl

systemctl status postgresql
          start
          stop
          restart
          enable
          disable


---

Hay muchas diferencias entre Solaris y Linux
En mabos 2 encontramos más o menos las mismas carpetas... y más o menos tenemos 
los mismos comandos básicos para movernos por una terminal
Ya que Solaris es un sistema opeativo compatible con el estandar POSIX 
y Linux creemos que también.


Solaris es un Sistema Operativo Unix®... Linux NO
Antiguamente la gestión de servicios se hacía con init files (.rc)
-> service
-> systemd


Activar el servicio -> De forma que a partir del siguiente arranque de la máquina
se ejecute en automático
Iniciar el servicio

Habitualmente en los servidores tendremos varias interfaces de red:

Al menos en la práctica 3 interfaces:
Con 2 haremos un bond -> Interfaz de red -> IP
Otra interfaz 100     -> Administración  -> IP

172.31.0.71 < ethernet
127.0.0.1   < loopback (localhost)

---

Instalación:

sudo postgresql-setup --initdb
sudo -u postgres psql
ALTER USER postgres PASSWORD 'Pa$$w0rd';
CREATE USER usuario WITH PASSWORD 'Pa$$w0rd';
CREATE DATABASE bd;
GRANT ALL PRIVILEGES ON DATABASE bd TO usuario;


sudo apt purge postgresql-16 -y

SELECT version();

psql --version
postgres --version




sudo apt install curl ca-certificates
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
sudo sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
sudo apt update
sudo apt -y install postgresql-15


/var/lib/postgresql/15/main

/usr/lib/postgresql/15/bin/postgres -D /var/lib/postgresql/15/main 
                                    -c config_file=/etc/postgresql/15/main/postgresql.conf
                                    
/
    etc/    configuraciones
    var/    datos (archivos que cambian) log, ficheros de la BBDD
    opt/    < programas
    usr/