# Crea un repo de git
git init
# Creo un archivo .gitignore, para decir cuales son los archivos que no quiero controlar
# Lo usamos a la inversa: PARA DECIRLE LOS QUE SI

    *.* # Excluyo todos los archivos
    *   # Excluyo todas las carpeta
    !*.conf # Menos los archivos .conf que si me interesan
    
echo "*.*"      > .gitignore
echo "*"        >> .gitignore
echo '!*.conf'  >> .gitignore

git status # VEr los archivos que va a controlar
git add :/ && git commit -m 'Originales'

# toco archivos
# Cuando toque y deje algo guay
git add :/
git commit -m 'Activo las reglas de autenticacion para el usuario replicator'

# Si un dia quiero ver todas las versiones del archivos:
git log --oneline

# Lo que he tocao
git diff

# Si un dia quiero ver la diferencia del archivo actual con una version pasada
         # v El que salga en el git log
git diff ID

# Si quiero anular los cambios actuales
git reset --hard

# Si quiero volver a una version vieja
             # Version a la que quiero volver
git checkout ID ARCHIVO