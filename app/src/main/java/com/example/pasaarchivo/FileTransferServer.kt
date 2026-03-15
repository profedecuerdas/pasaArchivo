package com.example.pasaarchivo

import android.content.ContentValues
import android.content.Context
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.util.Log
import android.widget.Toast
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
                while (isRunning) {
                    val client = serverSocket.accept()
                    thread {
                        try {
                            val inputStream = client.getInputStream()
                            
                            // Protocolo: Leer el nombre hasta el salto de línea
                            val nameBytes = mutableListOf<Byte>()
                            var currentByte = inputStream.read()
                            while (currentByte != -1 && currentByte != '\n'.code) {
                                nameBytes.add(currentByte.toByte())
                                currentByte = inputStream.read()
                            }
                            
                            val receivedName = String(nameBytes.toByteArray(), Charsets.UTF_8).trim()
                            val requestedName = if (receivedName.isNotEmpty()) receivedName else "archivo_linux.dat"

                            val values = ContentValues().apply {
                                put(MediaStore.MediaColumns.DISPLAY_NAME, requestedName)
                                put(MediaStore.MediaColumns.MIME_TYPE, "application/octet-stream")
                                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                            }
                            
                            val uri = context.contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                            
                            if (uri != null) {
                                val outputStream = context.contentResolver.openOutputStream(uri)
                                if (outputStream != null) {
                                    // Guardamos el binario
                                    inputStream.copyTo(outputStream)
                                    outputStream.close()
                                    
                                    // --- LA MAGIA ESTÁ AQUÍ ---
                                    // Consultamos a Android cuál fue el nombre final que le dio (por si le puso un (1), (2), etc.)
                                    var actualName = requestedName
                                    context.contentResolver.query(uri, arrayOf(MediaStore.MediaColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
                                        if (cursor.moveToFirst()) {
                                            actualName = cursor.getString(0)
                                        }
                                    }

                                    // Mostramos el Toast con el nombre REAL
                                    Handler(Looper.getMainLooper()).post {
                                        Toast.makeText(context, "Guardado: $actualName", Toast.LENGTH_LONG).show()
                                    }
                                }
                            }
                            inputStream.close()
                            client.close()
                        } catch (e: Exception) {
                            Log.e(TAG, "Error: ${e.message}")
                        }
                    }
                }
            } catch (e: Exception) {}
        }
    }
    fun stopServer() { isRunning = false }
}
