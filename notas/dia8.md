# Alta disponibilidad en PostgreSQL

## Trabajo con máquinas físicas

### Tengo limitaciones de hierros? SIGHUP

2 Hierros
- HIERRO 1: POSTGRES MAESTRO
- HIERRO 2: POSTGRES REPLICA

En este escenario me interesa que ambas tengan la misma configuración.
Si se cae el primario, tendré que promocionar la réplica y EMPIEZAN LOS PROBLEMAS !

PROBLEMAS A PARTIR DE ESTE PUNTO:
- Veter preparando un nuevo hierro:
    - COPIA DE SEGURIDAD COMPLETA DE LA REPLICA (que ahora es maestro)
    - Me la llevo al hierro nuevo
    - Y parriba!
- Reconfiguro la replica como nuevo maestro
- De alguna forma restauro un nuevo maestro (desde la replcia que estaba actuando como nuevo maestro)
- Y desde ese mestro reconfiguro el antiguo replica (que ahora es maestro) para que vuelva a ser réplica)

PREGUNTA: En este escenario, me sirve la réplica como BBDD secundaria de QUERIES? CONSULTA?
BUENO... 
Mientras esté el maestro arriba, si...
Si se cae el maestro... y me quedo solo con la replcia (que ahora es maestro) ya no.
Es decir... el nuevo maestro (antigua replica) ahora tendrá que lidiar con las queries
con las que antes lidiaba el maestro + nuvas que le llegan como replica.
A VER SI ME DA LA MAQUINA !

HIERRO 1
    IP PROPIA 1
    VIPA MAESTRO
HIERRO 2
    IP PROPIA 2
    VIPA REPLICA < Caso que quiera tirar queries a la replica
        SELECT pg_promote(); DARLE ENTER tiene unas implicaciones DE COJONES !!!!!
        SELECT pg_is_in_recovery(); -- Si ya está promocionado    
    Si se cae la replica, me llevaré la VIPA de replica  al HIERRO 1 (o no... que se jodan)
    Si se cae el maestro, me llevaré la VIPA del maestro al HIERRO 2

## Entornos virtualizados

VIRTUAL 1
    IP PROPIA 1
        2 volumenes -> SISTEMA
                    -> DATOS.   /var/lib/pgsql/data
VIRTUAL 2
    IP PROPIA 2
    Y el almacenamiento de los datos no está en la máquina VIRTUAL... está externalizado (cabina...)
En este caso, si se cae la VM 1 (Maestro)
    Lo úinico que debo hacer es levantar otra VM1, con los mismo datos que tenía la antigua!
Y esto me funcionaría en TODOS LOS ESCNARIOS... SALVO corrupción de datos... 
    Pero en ese caso, la replica los va atener igual de jodidos.
    