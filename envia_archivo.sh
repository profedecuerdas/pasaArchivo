#!/bin/bash
IP_ANDROID="${2:-172.30.203.106}"
PUERTO="9000"
ARCHIVO="$1"

if [ -z "$ARCHIVO" ] || [ ! -f "$ARCHIVO" ]; then
    echo -e "\e[31m[X] Uso: $0 <archivo> [IP_ANDROID]\e[0m"
    exit 1
fi

pkill -f "nc.*$PUERTO" 2>/dev/null

NOMBRE=$(basename "$ARCHIVO")
echo "[*] Empaquetando y enviando '$NOMBRE' a $IP_ANDROID:$PUERTO..."

# El protocolo: Escribimos el nombre, un salto de línea (implícito en echo) y el binario.
(echo "$NOMBRE"; cat "$ARCHIVO") | nc -w 5 "$IP_ANDROID" "$PUERTO"

if [ $? -eq 0 ]; then
    sync
    echo -e "\e[32m[*] ¡Envío finalizado con éxito!\e[0m"
else
    echo -e "\e[31m[X] Error en la transferencia.\e[0m"
fi
