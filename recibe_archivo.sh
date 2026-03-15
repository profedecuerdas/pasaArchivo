#!/bin/bash

# ==============================================================================
# Machete: Servidor TCP (Receptor) con Protocolo de Metadatos
# Extrae el nombre del archivo de la primera línea y protege contra sobreescritura.
# ==============================================================================

PUERTO="9001"

echo "[*] Limpiando procesos colgados en el puerto $PUERTO..."
fuser -k "$PUERTO/tcp" 2>/dev/null

echo -e "\e[34m[*] Escuchando en el puerto $PUERTO...\e[0m"
echo "[*] -> Ve a la app en Android, toca 'Enviar archivo a Linux' y selecciona algo."

# Usamos un bloque para procesar el flujo de entrada que entrega netcat
nc -w 15 -l -p "$PUERTO" | {
    
    # 1. Leer hasta el primer salto de línea para atrapar el nombre
    IFS= read -r fname
    
    # Limpiar retornos de carro (\r) que a veces se cuelan en las transmisiones
    fname=$(echo "$fname" | tr -d '\r')
    
    # Si la conexión se cortó o llegó vacío, asignamos un nombre de rescate
    if [ -z "$fname" ]; then
        fname="archivo_sin_nombre.dat"
    fi

    # 2. Lógica de protección anti-sobreescritura
    # Separamos el nombre base y la extensión
    base="${fname%.*}"
    ext="${fname##*.}"
    
    # Si el archivo no tiene extensión (ej. un binario puro), ajustamos
    if [[ "$base" == "$fname" ]]; then
        ext=""
    else
        ext=".$ext"
    fi

    nuevo_nombre="$fname"
    contador=1
    
    # Si el archivo ya existe, iteramos agregando (1), (2)...
    while [[ -f "$nuevo_nombre" ]]; do
        nuevo_nombre="${base}(${contador})${ext}"
        ((contador++))
    done

    echo "[*] Entrando archivo... Guardando como: $nuevo_nombre"

    # 3. Volcar todo el resto del flujo binario al archivo final
    cat > "$nuevo_nombre"
}

# Verificamos que todo el pipeline anterior haya terminado bien
if [ $? -eq 0 ]; then
    sync
    echo -e "\e[32m[*] ¡Éxito! Transferencia completada y sincronizada en disco.\e[0m"
else
    echo -e "\e[31m[X] Error: La conexión se interrumpió o expiró el tiempo.\e[0m"
fi
