# 1. Generar el README.md actualizado para la v1.1.0
cat << 'EOF' > README.md
# pasaArchivo 📱↔️🐧 (v1.1.0)

Una herramienta minimalista de transferencia de archivos bidireccional sobre TCP, construida bajo la filosofía UNIX. Diseñada para mover archivos rápidamente entre un dispositivo Android y una máquina Linux (o entre dos Androids) utilizando *sockets* crudos en la red local.

## ✨ Novedades en la v1.1.0
* **Puerto Universal (9000):** Se eliminó la asimetría. Todo el ecosistema (envío y recepción en cualquier dispositivo) opera exclusivamente sobre el puerto TCP 9000.
* **Radar de Red Integrado:** Escáner concurrente (TCP Ping Sweep) que lanza 254 hilos para encontrar dispositivos activos en el puerto 9000 en menos de 1 segundo.
* **Autocompletado Inteligente:** Al usar el Radar, la aplicación extrae la IP detectada y la escribe automáticamente en el campo de destino.
* **Scripts Blindados:** El receptor en Linux ahora es "a prueba de radares"; ignora los escaneos de red vacíos y mantiene la escucha activa hasta que llega un archivo real.

## 🏗️ Arquitectura y Panel de Control
La interfaz actúa como un **Panel de Control de Red**:
* Muestra en tiempo real la IP del dispositivo Android y el puerto de operación.
* Un servidor TCP en segundo plano escucha silenciosamente. Al recibir, guarda en **Descargas** y emite un Toast.
* Un campo de destino editable (que recuerda la última IP mediante `SharedPreferences`) para empujar archivos hacia otras máquinas.

## 🛡️ Características Principales
* **Protocolo de Metadatos:** Preserva el nombre y extensión original del archivo.
* **Protección Anti-Sobreescritura:** Si un archivo ya existe, se renombra automáticamente (ej: `archivo (1).txt`).
* **Resistente a Rotaciones y Timeouts:** Preparada para transferir archivos pesados sin cortes por inactividad.

## 🚀 Uso y Scripts en Linux (Los "Machetes")

Para interactuar con la app desde Linux, se utilizan scripts en Bash que envuelven `nc` (netcat).

### 1. Enviar desde Linux a Android (`envia_archivo.sh`)
Lee dinámicamente la IP desde un archivo `ip_android.txt` si existe en la misma carpeta.
```bash
#!/bin/bash
DIR_SCRIPT="$(dirname "$(readlink -f "$0")")"
ARCHIVO_IP="$DIR_SCRIPT/ip_android.txt"

[ -f "$ARCHIVO_IP" ] && IP_ANDROID=$(cat "$ARCHIVO_IP" | tr -d ' \n\r') || IP_ANDROID="${2:-172.30.203.106}"

PUERTO="9000"; ARCHIVO="$1"
[ -z "$ARCHIVO" ] || [ ! -f "$ARCHIVO" ] && exit 1

pkill -f "nc.*$PUERTO" 2>/dev/null
NOMBRE=$(basename "$ARCHIVO")
(echo "$NOMBRE"; cat "$ARCHIVO") | nc -w 5 "$IP_ANDROID" "$PUERTO" && sync

2. Recibir en Linux desde Android (recibe_archivo.sh)

Incluye un bucle infinito para ignorar los toques del "Radar" de Android y esperar el archivo real.
Bash

#!/bin/bash
PUERTO="9000"
echo -e "\e[36m[*] Escuchando en el puerto $PUERTO (A prueba de Radar)...\e[0m"

while true; do
    fuser -k "$PUERTO/tcp" 2>/dev/null
    nc -w 15 -l -p "$PUERTO" | {
        IFS= read -r fname
        fname=$(echo "$fname" | tr -d '\r')
        if [ -z "$fname" ]; then
            echo "RADAR"
        else
            base="${fname%.*}"; ext="${fname##*.}"
            [[ "$base" == "$fname" ]] && ext="" || ext=".$ext"
            nuevo_nombre="$fname"; contador=1
            while [[ -f "$nuevo_nombre" ]]; do
                nuevo_nombre="${base}(${contador})${ext}"
                ((contador++))
            done
            cat > "$nuevo_nombre"
            echo "ARCHIVO:$nuevo_nombre"
        fi
    } > .estado_transferencia
    
    ESTADO=$(cat .estado_transferencia)
    rm -f .estado_transferencia
    
    if [[ "$ESTADO" == ARCHIVO:* ]]; then
        echo -e "\e[32m[*] ¡Archivo recibido con éxito: ${ESTADO#ARCHIVO:}\e[0m"
        break
    else
        echo -e "\e[33m[*] Toque de Radar detectado. Manteniendo escucha...\e[0m"
    fi
done
sync

EOF

echo "[*] README.md actualizado con la documentación de la v1.1.0."
