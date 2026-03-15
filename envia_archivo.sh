#!/bin/bash

# ==============================================================================
# Machete: Cliente TCP para enviar archivos a la app Android 'PasaArchivo'
# Incorpora lectura dinámica de IP desde 'ip_android.txt' y protocolo de metadatos.
# ==============================================================================

# 1. Obtener la IP dinámicamente
# Detecta la carpeta real donde vive este script, sin importar desde dónde lo ejecutes
DIR_SCRIPT="$(dirname "$(readlink -f "$0")")"
ARCHIVO_IP="$DIR_SCRIPT/ip_android.txt"

if [ -f "$ARCHIVO_IP" ]; then
    # Lee la IP y limpia cualquier salto de línea o espacio fantasma
    IP_ANDROID=$(cat "$ARCHIVO_IP" | tr -d ' \n\r')
    echo "[*] IP cargada desde $ARCHIVO_IP: $IP_ANDROID"
else
    # Fallback: Usa el segundo parámetro si se proporciona, o la IP por defecto
    IP_ANDROID="${2:-172.30.203.106}"
    echo "[*] Usando IP (parámetro o por defecto): $IP_ANDROID"
fi

PUERTO="9000"
ARCHIVO="$1"

# 2. Validación de entrada
if [ -z "$ARCHIVO" ] || [ ! -f "$ARCHIVO" ]; then
    echo -e "\e[33mUso: $0 <archivo> [IP_ANDROID_OPCIONAL]\e[0m"
    echo -e "Nota: Se prioriza la IP escrita en '$ARCHIVO_IP'"
    exit 1
fi

# 3. Limpieza de procesos zombis
pkill -f "nc.*$PUERTO" 2>/dev/null

NOMBRE=$(basename "$ARCHIVO")
echo "[*] Empaquetando y enviando '$NOMBRE' a $IP_ANDROID:$PUERTO..."

# 4. Transferencia con Protocolo (Nombre + \n + Binario)
(echo "$NOMBRE"; cat "$ARCHIVO") | nc -w 5 "$IP_ANDROID" "$PUERTO"

# 5. Verificación
if [ $? -eq 0 ]; then
    sync
    echo -e "\e[32m[*] ¡Envío finalizado con éxito!\e[0m"
else
    echo -e "\e[31m[X] Error en la transferencia. Verifica que la IP sea correcta y la app esté abierta.\e[0m"
fi
