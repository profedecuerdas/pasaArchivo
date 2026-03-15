package com.example.pasaarchivo

import android.content.Context
import android.content.pm.PackageManager
import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import java.net.Inet4Address
import java.net.InetSocketAddress
import java.net.NetworkInterface
import java.net.Socket
import kotlin.concurrent.thread

class MainActivity : AppCompatActivity() {
    private lateinit var etIpLinux: EditText
    private lateinit var tvMiIp: TextView
    private lateinit var tvResultadosRed: TextView
    private lateinit var tvVersionPuerto: TextView

    private val filePickerLauncher = registerForActivityResult(ActivityResultContracts.GetContent()) { uri ->
        if (uri != null) {
            val ipDestino = etIpLinux.text.toString().trim()
            if (ipDestino.isNotEmpty()) {
                getSharedPreferences("PasaArchivoPrefs", Context.MODE_PRIVATE)
                    .edit().putString("ULTIMA_IP", ipDestino).apply()
                FileTransferClient(this, ipDestino).sendFile(uri)
            } else {
                Toast.makeText(this, "Por favor ingresa la IP destino", Toast.LENGTH_SHORT).show()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        etIpLinux = findViewById(R.id.et_ip_linux)
        tvMiIp = findViewById(R.id.tv_mi_ip)
        tvResultadosRed = findViewById(R.id.tv_resultados_red)
        tvVersionPuerto = findViewById(R.id.tv_version_puerto)
        val btnEnviar = findViewById<Button>(R.id.btn_enviar)
        val btnEscanear = findViewById<Button>(R.id.btn_escanear)

        // Obtener versión dinámica
        try {
            val pInfo = packageManager.getPackageInfo(packageName, 0)
            tvVersionPuerto.text = "PasaArchivo v${pInfo.versionName} | Puerto TCP: 9000"
        } catch (e: PackageManager.NameNotFoundException) { e.printStackTrace() }

        tvMiIp.text = getLocalIpAddress()

        val prefs = getSharedPreferences("PasaArchivoPrefs", Context.MODE_PRIVATE)
        etIpLinux.setText(prefs.getString("ULTIMA_IP", "172.30.203.102"))

        FileTransferServer(this).startServer()

        btnEscanear.setOnClickListener { escaneoRadar() }
        btnEnviar.setOnClickListener { filePickerLauncher.launch("*/*") }
    }

    private fun escaneoRadar() {
        tvResultadosRed.text = "Escaneando la subred (Puerto 9000)..."
        tvResultadosRed.setTextColor(android.graphics.Color.BLUE)
        val myIp = getLocalIpAddress()
        
        if (myIp == "No detectada") {
            tvResultadosRed.text = "Error: No estás conectado a una red."
            return
        }

        val prefix = myIp.substringBeforeLast(".") + "."
        val activeIps = mutableListOf<String>()

        // Disparamos un hilo maestro para no congelar la pantalla
        thread {
            val threads = mutableListOf<Thread>()
            // Escaneamos desde la IP .1 hasta la .254 de tu red
            for (i in 1..254) {
                val targetIp = prefix + i
                if (targetIp == myIp) continue
                
                val t = thread(start = false) {
                    try {
                        val socket = Socket()
                        // Timeout de 500ms, muy agresivo para hacerlo rápido
                        socket.connect(InetSocketAddress(targetIp, 9000), 500)
                        socket.close()
                        synchronized(activeIps) { activeIps.add(targetIp) }
                    } catch (e: Exception) { } // Silencio si la IP no responde
                }
                t.start()
                threads.add(t)
            }
            
            // Esperamos a que los 254 hilos terminen
            threads.forEach { it.join() }

            // Actualizamos la pantalla con los resultados
            runOnUiThread {
                if (activeIps.isEmpty()) {
                    tvResultadosRed.text = "Nadie detectado. (Abre la app en el otro equipo o ejecuta recibe_archivo.sh)"
                    tvResultadosRed.setTextColor(android.graphics.Color.RED)
                } else {
                    tvResultadosRed.text = "¡Detectados!\n" + activeIps.joinToString("\n")
                    tvResultadosRed.setTextColor(android.graphics.Color.parseColor("#2E7D32")) // Verde
                    // Autocompleta el campo con la primera IP que encontró
                    etIpLinux.setText(activeIps.first())
                }
            }
        }
    }

    private fun getLocalIpAddress(): String {
        try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val networkInterface = interfaces.nextElement()
                val addresses = networkInterface.inetAddresses
                while (addresses.hasMoreElements()) {
                    val address = addresses.nextElement()
                    if (!address.isLoopbackAddress && address is Inet4Address) {
                        return address.hostAddress ?: "Desconocida"
                    }
                }
            }
        } catch (e: Exception) { e.printStackTrace() }
        return "No detectada"
    }
}
