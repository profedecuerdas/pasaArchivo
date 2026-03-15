#!/bin/bash

# --- Configuración ---
PKG_NAME="com.example.pasaarchivo"
PKG_PATH="app/src/main/java/$(echo $PKG_NAME | tr '.' '/')"
MANIFEST="app/src/main/AndroidManifest.xml"

echo "[*] Iniciando el andamiaje del FileServer..."

# 1. Parcheo del AndroidManifest.xml usando sed
echo "[*] Parcheando AndroidManifest.xml con permisos de red..."
sed -i '/<application/i \
    \
    <uses-permission android:name="android.permission.INTERNET" />\
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />\
' "$MANIFEST"

# 2. Creación del archivo de lógica del Servidor TCP
echo "[*] Generando FileTransferServer.kt..."
cat << 'EOF' > "$PKG_PATH/FileTransferServer.kt"
package $PKG_NAME

import android.content.Context
import android.util.Log
import java.io.File
import java.io.FileOutputStream
import java.net.ServerSocket
import kotlin.concurrent.thread

class FileTransferServer(private val context: Context) {
    private val TAG = "FileTransferServer"
    private val RECEIVE_PORT = 9000
    private var isRunning = false

    fun startServer() {
        if (isRunning) return
        isRunning = true

        thread {
            try {
                val serverSocket = ServerSocket(RECEIVE_PORT)
                Log.d(TAG, "Servidor escuchando en el puerto $RECEIVE_PORT")

                while (isRunning) {
                    val client = serverSocket.accept()
                    Log.d(TAG, "Cliente conectado desde: ${client.inetAddress.hostAddress}")
                    
                    thread {
                        try {
                            val inputStream = client.getInputStream()
                            val outputFile = File(context.filesDir, "archivo_recibido_${System.currentTimeMillis()}.dat")
                            val outputStream = FileOutputStream(outputFile)
                            
                            inputStream.copyTo(outputStream)
                            
                            outputStream.close()
                            inputStream.close()
                            client.close()
                            Log.d(TAG, "Archivo guardado en: ${outputFile.absolutePath}")
                        } catch (e: Exception) {
                            Log.e(TAG, "Error al recibir archivo: ${e.message}")
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error en el servidor: ${e.message}")
            }
        }
    }

    fun stopServer() {
        isRunning = false
    }
}
EOF

# Parcheamos la variable del paquete dentro del archivo recién creado
sed -i "s/\$PKG_NAME/$PKG_NAME/g" "$PKG_PATH/FileTransferServer.kt"

echo "[*] Estructura generada en $PKG_PATH. ¡Listo!"
