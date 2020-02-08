#!/bin/bash
show(){
        echo -e '\n\n                LISTADO DE REGISTROS ORDENADOS POR NÚM. CLIENTE\n'
	header=$(echo -e '\e[7mNombre de Usuario:, DNI:, Direccion:, Cód.Postal:, Num.Cliente:, Restringido: \e[0m') 
        sort -k 5n -t "," infoclientes_corregido | sed "1i $header" |  column  -t  -s","

}


add(){
	echo -e '\n\n\e[1;41m DB > FORMULARIO DE REGISTRO \e[0m\n'

	regex_user='^[a-zA-Z ]*$'
	regex_dni='^[0-9]{1,8}[A-Za-z]$'
	regex_client='^[0-9]{1,3}$'
	regex_restring='^[SNsn]$'

	read -p '* Nombre del Usuario: ' user
        until [[ $user =~ $regex_user ]]; do
		echo 'Valor invalido. Solo admite letras y espacios.'
		read -p '* Nombre del Usuario: ' user
	done
	read -p '* DNI: ' dni
        until [[ $dni =~ $regex_dni ]]; do
		echo 'Valor invalido. Solo admite 8 dígitos + 1 Caracter.'
     		read -p '* DNI: ' dni
	done
        read -p '* Direccion: ' address
        read -p '* Código Postal: ' codp
        read -p '* Núm Cliente: ' client
	until [[ $client =~ $regex_client ]]; do
                echo 'Valor invalido. Solo admite 3 dígitos.'
                read -p '* Núm Cliente: ' client
        done
        read -p '* Restringido: ' restring
	until [[ $restring =~ $regex_restring ]]; do
                echo 'Valor invalido. Solo admite S o N.'
                read -p '* Restringido: ' restring
        done

	dni=$(echo $dni | tr '[:lower:]' '[:upper:]') #convierte la letra del dni  en mayusculas
	restring=$(echo $restring | tr '[:lower:]' '[:upper:]') #convierte la letra s o n en mayuscula
        dni=$(zero $dni 9)
	client=$(zero $client 3)

	unique_pk $dni
	ok_dni=$?

	unique_pk $client
	ok_client=$?

	echo "$user, $dni, $address, $codp, $client, $restring"
	echo -e '\n\e[7mRESULTADO:\e[0m'
	if [[ $ok_dni -eq 1 && $ok_client -eq 1 ]];then
		validate_row "$user, $dni, $address, $codp, $client, $restring"
		if [[ $? -eq 1 ]];then
	                echo "$user, $dni, $address, $codp, $client, $restring" >> infoclientes_corregido
			echo " Se ha insertado un registro."
		fi
	else
		echo ' El DNI o Número de cliente esta duplicado.'
	fi
}
delete(){
	echo -e '\n\n\e[1;41m DB > FORMULARIO DE ELIMINACION \e[0m\n'

        read -p 'Indice el DNI o número de cliente a ELIMINAR (incluidos 0): ' pk
        aux=$( egrep ", $pk," infoclientes_corregido )

	echo -e '\n\e[7mRESULTADO:\e[0m'
	if [[ ${#aux} -eq 0 ]];then
		echo "No se ha encontrado un registro con esa clave"
	else
		dt=$( date +_%d%m%Y_%H%M%S )
	        cat infoclientes_corregido > $ruta$dt

  		aux=$(echo $aux | cut -d ',' -f 6 --output-delimiter='')
		if [[ $aux == ' N' ]]; then
		        sed -i "/, $pk,/d" infoclientes_corregido
			echo "Se ha eliminado el registro $pk"
		else
			echo "El registro se encuentra protegido. Modificalo previamente"
		fi
	fi
}


update(){
        echo -e '\n\n\e[1;41m DB > FORMULARIO DE ACTUALIZACION \e[0m\n'

        read -p  'Inserte el DNI o Num. del cliente a modificar: ' value
	unique_pk $value
	if [[ $? -eq 1 ]];then #no algun valor
		echo -e '\n\e[7mRESULTADO:\e[0m'
		echo "No se ha encontrado ningun DNI o Numero de cliente con $value"
	else
	        tupla=$(grep ", $value," infoclientes_corregido)
	        name=$(echo $tupla | cut -d ',' -f 1 --output-delimiter='')
	        address=$(echo $tupla | cut -d ',' -f 3 --output-delimiter='')
	        codp=$(echo $tupla | cut -d ',' -f 4 --output-delimiter='')
	        rest=$(echo $tupla | cut -d ',' -f 6 --output-delimiter='')
	        client=$(echo $tupla | cut -d ',' -f 5 --output-delimiter='') #no se modifica
		dni=$(echo $tupla | cut -d ',' -f 2 --output-delimiter='') #no se modifica

	        echo -e "Usuario seleccionado: $name \n"
	        echo 'Aquellos valores que no deses modificar dejelos en blanco'

	        read -p "* Nombre de usuario [${name}]: " name_new; if [ -z "$name_new" ];then name_new=$name ; fi
	        read -p "* Direccion [${address:1}]: " address_new ; if [ -z "$address_new"  ];then address_new=${address:1} ; fi
	        read -p "* Código Postal [${codp:1}]: " codp_new ; if [ -z "$codp_new"  ];then codp_new=${codp:1} ; fi
	        read -p "* Restringido(S|N) [${rest:1}]:" rest_new ; if [ -z "$rest_new"  ];then rest_new=${rest:1} ; fi


                echo -e '\n\e[7mRESULTADO:\e[0m'

		row=$(echo "$name_new, $dni, $address_new, $codp_new, $client, $rest_new" | sed  -r 's/[[:blank:]]+/ /g')
	        validate_row "$row"
        	if [[ $? -eq 1 ]];then
                	sed -i "s/$tupla/$row/g" infoclientes_corregido
			echo "Se ha modificado el registo $value exitosamente"
		else
			echo -e "Error! Formato $row \nLos datos aportados no cumplen los estandares de calidad. Reviselos"
		fi
	fi
}


unique_pk(){
        a=$(grep ", $1, " infoclientes_corregido)
        if [[ ${#a} -eq 0 ]];then
                return 1 # no hay ningun valor
        else
                return 0 #hay algun valor repetido
        fi
}
validate_row(){
	regex='^[a-zA-Z ]+, [0-9]{8}[a-zA-Z], [a-zA-Z0-9 ]*, [0-9]{0,5}, [0-9]{3}, [SN]$'
        if [[ "$1" =~ $regex ]];then
               return 1 #la fila es correcta
	else
	      # echo "La línea $1 contiene errores de formato."
	       return 0 #la fila no es correcta
        fi
}
zero(){
        dni=$1
        length=$2
        while [ ${#dni} -ne $length ]
        do
                dni='0'$dni
        done
        echo $dni
}


update_file(){
        echo -e '\n\n\e[1;41m DB > ACTUALIZACION MASIVA CLIENTES \e[0m\n'

#        read -p 'Nombre del fichero externo : ' nameFile
	nameFile='actualizacionmasivaclientes_KO'
        file=$(sudo find / -name $nameFile)
        echo -e '\n\e[7mRESULTADO:\e[0m'
        if [ -s $file ];then
		validate_file $file 'file.tmp'
		contador=0
		while read row
		do 
			row=$(echo $row | sed 's/\([0-9]\{7\}[A-Z]\)/0\1/g' ) #añade un cero al dni
			validate_row "$row"
			if [[ $? -eq 1 ]];then

				dni=$(echo $row | cut -d "," -f 2 --output-delimiter="")
				client=$(echo $row | cut -d "," -f 5 --output-delimiter="")

				unique_pk $dni
			        ok_dni=$?
			        unique_pk $client
			        ok_client=$?

				if [[ $ok_dni -eq 1 && $ok_client -eq 1 ]];then
					echo $row >> infoclientes_corregido
					contador=$(( $contador + 1 ))
				else
					echo "$row . PrimaryKey repetida"
				fi
			else
				echo "#$row# . Error de formato"
			fi
		done < file.tmp
		echo -e "\nEn total se han insertado $contador registros"

        else
                echo 'El archivo especificado no existe o esta vacio'
        fi
}
#valida un fichero, quitando duplicados y tabuladores
function validate_file(){ #ok
	corregido=$(cat $1 | tr -d '\015'  | sed  -r 's/[[:blank:]]+/ /g' | awk -F',' '!_[$2]++' | awk -F',' '!_[$5]++')
	echo "$corregido" > $2
}
validate_file "/home/server/10/actualizacionmasivaclientes_KO" file2

menu(){ #ok
while true; do
        echo -e '\nMENU DE OPCIONES:'
        select opt in 'Añadir un registro' 'Eliminar un registro' 'Modificar un registro' 'Mostrar fichero ordenado' 'Actualizar desde un fichero externo' 'Salir'
        do
           case $opt in
                'Añadir un registro')
                        clear; add
                break ;;
                'Eliminar un registro')
			clear; delete
                break ;;
                'Modificar un registro')
                       clear; update
                break ;;
                'Mostrar fichero ordenado')
                        clear; show
                break ;;
                'Actualizar desde un fichero externo')
                        clear; update_file
                break ;;
                'Salir')
   			read -p 'Desea guardar los cambios realizados (S|N):' confirm
			if [[ confirm =~ ^[Ss]$ ]];then
				cat infoclientes_corregido > $ruta
				echo "Cambios guardados"
			fi
	                exit 0
                ;;
                *) echo 'Selecciones una opción [1-6]'
           esac
        done
done
}



#main
ruta=$(sudo find /home/ -name 'infoclientes_KO')
if [ -s $ruta ];then
  	validate_file $ruta 'infoclientes_corregido'
	menu 
else
	echo 'El fichero esta vacio o no existe. Añada un registro'
	menu
fi
