#!/bin/bash
PUERTO="9000"

echo -e "\e[36m[*] Escuchando en el puerto $PUERTO (A prueba de Radar)...\e[0m"

# Iniciamos un bucle infinito
while true; do
    # Limpiamos el puerto por si acaso
    fuser -k "$PUERTO/tcp" 2>/dev/null
    
    # Capturamos la salida en un archivo temporal para saber qué pasó
    nc -w 15 -l -p "$PUERTO" | {
        IFS= read -r fname
        fname=$(echo "$fname" | tr -d '\r')
        
        if [ -z "$fname" ]; then
            # Nombre vacío = Fue el Radar tocando la puerta o un timeout
            echo "RADAR"
        else
            # Archivo real, procesamos lógica anti-sobreescritura
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
    
    # Leemos la respuesta del bloque anterior
    ESTADO=$(cat .estado_transferencia)
    rm -f .estado_transferencia
    
    if [[ "$ESTADO" == ARCHIVO:* ]]; then
        echo -e "\e[32m[*] ¡Archivo recibido con éxito: ${ESTADO#ARCHIVO:}\e[0m"
        break # Salimos del bucle, el trabajo terminó
    else
        echo -e "\e[33m[*] Toque de Radar detectado. Manteniendo el puerto abierto...\e[0m"
        # Al no hacer 'break', el bucle while vuelve a iniciar 'nc' automáticamente
    fi
done
sync
