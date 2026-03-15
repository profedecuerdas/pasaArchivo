# pasaArchivo 📱↔️🐧

Una herramienta minimalista de transferencia de archivos bidireccional sobre TCP, construida bajo la filosofía UNIX. Diseñada para mover archivos rápidamente entre un dispositivo Android (actuando como Hotspot) y una máquina Linux, utilizando *sockets* crudos en lugar de depender de cables, ADB o servicios en la nube.

Ideal para transferir firmware (ESP32/Arduino), scripts de Python, audios o documentos directamente desde la terminal hacia el teléfono y viceversa.

## 🏗️ Arquitectura y Panel de Control

La aplicación funciona como una navaja suiza de doble vía, gestionada desde una interfaz que actúa como un **Panel de Control de Red**:

* **Android recibe (Puerto 9000):** La app detecta y muestra su propia IP en pantalla. Un servidor TCP en segundo plano escucha silenciosamente. Al recibir un archivo desde Linux, lo guarda en la carpeta pública de **Descargas** y emite un Toast.
* **Android envía (Puerto 9001):** La app cuenta con un campo de texto que recuerda la última IP de tu máquina Linux (usando `SharedPreferences`). Al seleccionar un archivo, abre una conexión hacia esa IP y empuja los datos.

## 🛡️ Características Principales
* **Protocolo de Metadatos:** Preserva el nombre y extensión original del archivo en ambas direcciones (envía el nombre seguido de un `\n` antes de los bytes binarios).
* **Protección Anti-Sobreescritura:** Si un archivo con el mismo nombre ya existe, se renombra automáticamente añadiendo un sufijo numérico, ej: `archivo (1).txt`.
* **IPs Dinámicas a Prueba de Reinicios:** Adiós a las IPs *hardcodeadas*. En Android modificas el destino desde la interfaz. En Linux, el script lee un archivo de texto plano (`ip_android.txt`), permitiendo actualizar las rutas en un segundo sin tocar el código.

## 🚀 Uso y Scripts en Linux (Los "Machetes")

Para interactuar con la app, se utilizan scripts en Bash que envuelven el comando `nc` (netcat). Estos scripts garantizan la limpieza de procesos zombies (`fuser`), timeouts de inactividad (`-w 5` / `-w 15`) e integridad de disco (`sync`).

### 1. Preparación (Gestión de IP)
En la misma carpeta donde guardes tus scripts en Linux, crea un archivo llamado `ip_android.txt` y escribe allí la IP que muestra la pantalla de la app PasaArchivo:
```bash
echo "172.30.203.106" > ip_android.txt


2. Enviar desde Linux a Android (envia_archivo.sh)
Bash

#!/bin/bash
# Detecta la ruta del script y lee la IP automáticamente
DIR_SCRIPT="$(dirname "$(readlink -f "$0")")"
ARCHIVO_IP="$DIR_SCRIPT/ip_android.txt"

[ -f "$ARCHIVO_IP" ] && IP_ANDROID=$(cat "$ARCHIVO_IP" | tr -d ' \n\r') || IP_ANDROID="${2:-172.30.203.106}"

PUERTO="9000"; ARCHIVO="$1"
[ -z "$ARCHIVO" ] || [ ! -f "$ARCHIVO" ] && exit 1

pkill -f "nc.*$PUERTO" 2>/dev/null
NOMBRE=$(basename "$ARCHIVO")
(echo "$NOMBRE"; cat "$ARCHIVO") | nc -w 5 "$IP_ANDROID" "$PUERTO" && sync

3. Recibir en Linux desde Android (recibe_archivo.sh)
Bash

#!/bin/bash
PUERTO="9001"
fuser -k "$PUERTO/tcp" 2>/dev/null
nc -w 15 -l -p "$PUERTO" | {
    IFS= read -r fname
    fname=$(echo "$fname" | tr -d '\r')
    [ -z "$fname" ] && fname="archivo_sin_nombre.dat"
    
    base="${fname%.*}"; ext="${fname##*.}"
    [[ "$base" == "$fname" ]] && ext="" || ext=".$ext"
    nuevo_nombre="$fname"; contador=1
    while [[ -f "$nuevo_nombre" ]]; do
        nuevo_nombre="${base}(${contador})${ext}"
        ((contador++))
    done
    cat > "$nuevo_nombre"
} && sync

🛠️ Compilación

Para compilar el APK directamente desde la terminal:
./gradlew assembleDebug
