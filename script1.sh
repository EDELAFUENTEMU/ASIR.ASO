#!/bin/bash
#ejercicio 6 de ASO  19/11/19

mkdir -p /home/server/carpeta1
for aux in 1 2 3 4
do 
	touch /home/server/carpeta1/fichero0$aux
done
	touch /home/server/carpeta1/textoA
