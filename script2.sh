#!/bin/bash
read -p "Inserte el nombre de la carpeta " name
read -p "Indique la ruta de la nueva carpeta (sin ult. /) " ruta
usuario=$(whoami)

if [[ $ruta == *"/home/${usuario}"* ]];
then
 mkdir "$ruta/$name"
 cp -r "/home/server/carpeta1/" "$ruta/$name"
 comparar=$(diff "/home/server/carpeta1/*" "$ruta/$name/*")
 echo -e "Se ha echo la copia. Queda pendiente el borrado"
 if [[ "$comparar" = '' ]]
 then 
	rm -r "/home/server/carpeta1"
	echo -e "se ha eliminado el directorio correctamente. \n Tiene una copia en $ruta/$name/" 
 fi
fi
