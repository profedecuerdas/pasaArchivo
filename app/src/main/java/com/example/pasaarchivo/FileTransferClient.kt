package com.example.pasaarchivo

import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
import android.util.Log
import java.io.InputStream
import java.net.Socket
import kotlin.concurrent.thread

class FileTransferClient(private val context: Context) {
    private val TAG = "FileTransferClient"
    private val SERVER_IP = "172.30.203.102" 
    private val SEND_PORT = 9001

    fun sendFile(fileUri: Uri) {
        thread {
            try {
                // Extraer el nombre real del archivo seleccionado
                var fileName = "archivo_desde_android.dat"
                context.contentResolver.query(fileUri, null, null, null, null)?.use { cursor ->
                    val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (cursor.moveToFirst() && nameIndex != -1) {
                        fileName = cursor.getString(nameIndex)
                    }
                }

                val socket = Socket(SERVER_IP, SEND_PORT)
                val outputStream = socket.getOutputStream()
                val inputStream: InputStream? = context.contentResolver.openInputStream(fileUri)

                if (inputStream != null) {
                    Log.d(TAG, "Enviando encabezado: $fileName")
                    // Implementación del protocolo: Nombre + \n
                    outputStream.write((fileName + "\n").toByteArray(Charsets.UTF_8))
                    
                    // Enviar binario
                    inputStream.copyTo(outputStream)
                    
                    inputStream.close()
                    outputStream.flush()
                    outputStream.close()
                    socket.close()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error: ${e.message}")
            }
        }
    }
}
