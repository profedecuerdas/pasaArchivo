package com.example.pasaarchivo

import android.os.Bundle
import android.util.Log
import android.widget.Button
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {
    private val TAG = "MainActivity"

    // Registramos el lanzador para el selector de archivos de Android
    private val filePickerLauncher = registerForActivityResult(ActivityResultContracts.GetContent()) { uri ->
        if (uri != null) {
            Log.d(TAG, "Archivo seleccionado: $uri")
            // Llamamos a nuestro cliente para enviar el archivo a Linux (172.30.203.102)
            FileTransferClient(this).sendFile(uri)
        } else {
            Log.d(TAG, "Selección de archivo cancelada.")
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // 1. Iniciamos el servidor para RECIBIR archivos (Puerto 9000)
        Log.d(TAG, "Iniciando servidor TCP en puerto 9000...")
        FileTransferServer(this).startServer()

        // 2. Configuramos el botón para ENVIAR archivos
        val btnEnviar = findViewById<Button>(R.id.btn_enviar)
        btnEnviar.setOnClickListener {
            // Abre el explorador de archivos nativo filtrando por cualquier tipo (*/*)
            filePickerLauncher.launch("*/*")
        }
    }
}
