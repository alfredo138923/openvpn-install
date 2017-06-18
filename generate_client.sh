newclient () {
	cp /etc/openvpn/client-common.txt ~/$1.ovpn
	echo "<ca>" >> ~/$1.ovpn
	cat /etc/openvpn/easy-rsa/pki/ca.crt >> ~/$1.ovpn
	echo "</ca>" >> ~/$1.ovpn
	echo "<cert>" >> ~/$1.ovpn
	cat /etc/openvpn/easy-rsa/pki/issued/$1.crt >> ~/$1.ovpn
	echo "</cert>" >> ~/$1.ovpn
	echo "<key>" >> ~/$1.ovpn
	cat /etc/openvpn/easy-rsa/pki/private/$1.key >> ~/$1.ovpn
	echo "</key>" >> ~/$1.ovpn
	echo "<tls-auth>" >> ~/$1.ovpn
	cat /etc/openvpn/ta.key >> ~/$1.ovpn
	echo "</tls-auth>" >> ~/$1.ovpn
}


if [[ -e /etc/openvpn/server.conf ]]; then
	while :
	do
	clear
		echo "Parece que OpenVPN ya está instalado"
		echo ""
		echo "   1) Agregar nuevo usuario"
		echo "   2) Revocar un usuario existente"
		echo "   3) Salir"
		read -p "Seleccione una opción [1-3]: " option
		case $option in
			1) 
			echo ""
			read -p "Nombre del cliente (Una sóla palabra sin caracteres especiales): " -e -i client CLIENT
			cd /etc/openvpn/easy-rsa/
			./easyrsa build-client-full $CLIENT nopass
			# Generates the custom client.ovpn
			newclient "$CLIENT"
			echo ""
			echo "Cliente $CLIENT agregado. El certificado está disponible en " ~/"$CLIENT.ovpn"
                        echo "Si quieres agregar más clientes, solo ejecuta este script otra vez!"
			exit
			;;
			2)

			NUMBEROFCLIENTS=$(tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep -c "^V")
			if [[ "$NUMBEROFCLIENTS" = '0' ]]; then
				echo ""
				echo "No hay clientes existentes!"
				exit 6
			fi
			echo ""
			echo "Seleccione el certificado del cliente que desea revocar"
			tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep "^V" | cut -d '=' -f 2 | nl -s ') '
			if [[ "$NUMBEROFCLIENTS" = '1' ]]; then
				read -p "Seleccione un cliente [1]: " CLIENTNUMBER
			else
				read -p "Seleccione un cliente [1-$NUMBEROFCLIENTS]: " CLIENTNUMBER
			fi
			CLIENT=$(tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep "^V" | cut -d '=' -f 2 | sed -n "$CLIENTNUMBER"p)
			cd /etc/openvpn/easy-rsa/
			./easyrsa --batch revoke $CLIENT
			./easyrsa gen-crl
			rm -rf pki/reqs/$CLIENT.req
			rm -rf pki/private/$CLIENT.key
			rm -rf pki/issued/$CLIENT.crt
			rm -rf /etc/openvpn/crl.pem
			cp /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn/crl.pem
			# CRL is read with each client connection, when OpenVPN is dropped to nobody
			chown nobody:$GROUPNAME /etc/openvpn/crl.pem
			echo ""
			echo "Certificado para el $CLIENT revocado!"
			exit
			;;
			3) exit;;
		esac
	done
else
	echo ""
	echo "OPENVPN no está instalado"
fi
