#include <WiFi.h>
#include <WebServer.h>
#include <Wire.h>

#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>

// =====================================================
// I2C PINS
// =====================================================

#define SDA_PIN 8
#define SCL_PIN 9

// =====================================================
// WIFI SETTINGS
// =====================================================

const char* ssid = "ESP32-MPU6050";
const char* password = "12345678";

// =====================================================
// OBJECTS
// =====================================================

Adafruit_MPU6050 mpu;
WebServer server(80);

// =====================================================
// WEB PAGE
// =====================================================

const char webpage[] PROGMEM = R"rawliteral(

<!DOCTYPE html>

<html>

<head>

<meta name="viewport" content="width=device-width, initial-scale=1">

<title>ESP32-S3 MPU6050</title>

<style>

body {
    font-family: Arial, sans-serif;
    text-align: center;
    background: #eeeeee;
    margin: 0;
    padding: 20px;
}

h1 {
    margin-bottom: 5px;
}

h2 {
    margin-bottom: 15px;
}

.container {
    max-width: 500px;
    margin: auto;
}

.card {
    background: white;
    padding: 20px;
    margin: 15px 0;
    border-radius: 15px;
    box-shadow: 0px 3px 10px rgba(0,0,0,0.2);
}

.value {
    font-size: 22px;
    margin: 12px;
}

.status {
    font-size: 18px;
    margin-bottom: 20px;
}

</style>

</head>


<body>

<div class="container">

<h1>ESP32-S3 + MPU6050</h1>

<div class="status">
Wi-Fi Connected ✅
</div>


<div class="card">

<h2>Acceleration</h2>

<div class="value">
X = <span id="ax">0</span> m/s²
</div>

<div class="value">
Y = <span id="ay">0</span> m/s²
</div>

<div class="value">
Z = <span id="az">0</span> m/s²
</div>

</div>


<div class="card">

<h2>Gyroscope</h2>

<div class="value">
X = <span id="gx">0</span> rad/s
</div>

<div class="value">
Y = <span id="gy">0</span> rad/s
</div>

<div class="value">
Z = <span id="gz">0</span> rad/s
</div>

</div>


<div class="card">

<h2>Temperature</h2>

<div class="value">
<span id="temp">0</span> °C
</div>

</div>

</div>


<script>

function getData()
{

    fetch("/data")

    .then(response => response.json())

    .then(data =>
    {

        document.getElementById("ax").innerHTML =
        data.ax.toFixed(3);

        document.getElementById("ay").innerHTML =
        data.ay.toFixed(3);

        document.getElementById("az").innerHTML =
        data.az.toFixed(3);


        document.getElementById("gx").innerHTML =
        data.gx.toFixed(3);

        document.getElementById("gy").innerHTML =
        data.gy.toFixed(3);

        document.getElementById("gz").innerHTML =
        data.gz.toFixed(3);


        document.getElementById("temp").innerHTML =
        data.temp.toFixed(2);

    })

    .catch(error =>
    {
        console.log(error);
    });

}


// Update every 100 milliseconds

setInterval(getData, 100);

// Get data immediately

getData();

</script>

</body>

</html>

)rawliteral";


// =====================================================
// HOME PAGE
// =====================================================

void handleRoot()
{

    server.send(
        200,
        "text/html",
        webpage
    );

}


// =====================================================
// MPU6050 DATA
// =====================================================

void handleData()
{

    sensors_event_t acceleration;
    sensors_event_t gyro;
    sensors_event_t temperature;


    // Read MPU6050

    mpu.getEvent(
        &acceleration,
        &gyro,
        &temperature
    );


    // Create JSON

    String json = "{";


    json += "\"ax\":";
    json += String(
        acceleration.acceleration.x,
        3
    );

    json += ",";


    json += "\"ay\":";
    json += String(
        acceleration.acceleration.y,
        3
    );

    json += ",";


    json += "\"az\":";
    json += String(
        acceleration.acceleration.z,
        3
    );

    json += ",";


    json += "\"gx\":";
    json += String(
        gyro.gyro.x,
        3
    );

    json += ",";


    json += "\"gy\":";
    json += String(
        gyro.gyro.y,
        3
    );

    json += ",";


    json += "\"gz\":";
    json += String(
        gyro.gyro.z,
        3
    );

    json += ",";


    json += "\"temp\":";
    json += String(
        temperature.temperature,
        2
    );


    json += "}";


    // Send JSON to phone

    server.send(
        200,
        "application/json",
        json
    );

}


// =====================================================
// SETUP
// =====================================================

void setup()
{

    // Start Serial
    // Only for debugging

    Serial.begin(115200);

    delay(1000);


    Serial.println();
    Serial.println("==============================");
    Serial.println("ESP32-S3 MPU6050 Wi-Fi");
    Serial.println("==============================");


    // =================================================
    // START I2C
    // =================================================

    Wire.begin(
        SDA_PIN,
        SCL_PIN
    );


    Serial.println("Starting I2C...");


    // =================================================
    // START MPU6050
    // =================================================

    if (!mpu.begin())
    {

        Serial.println(
            "ERROR: MPU6050 NOT FOUND!"
        );

        while (true)
        {
            delay(1000);
        }

    }


    Serial.println(
        "MPU6050 detected!"
    );


    // =================================================
    // MPU6050 SETTINGS
    // =================================================

    mpu.setAccelerometerRange(
        MPU6050_RANGE_8_G
    );


    mpu.setGyroRange(
        MPU6050_RANGE_500_DEG
    );


    mpu.setFilterBandwidth(
        MPU6050_BAND_21_HZ
    );


    // =================================================
    // START ESP32-S3 WIFI ACCESS POINT
    // =================================================

    Serial.println();
    Serial.println("Starting Wi-Fi...");


    WiFi.mode(WIFI_AP);


    bool wifiStarted =
        WiFi.softAP(
            ssid,
            password
        );


    if (wifiStarted)
    {

        Serial.println(
            "Wi-Fi AP started!"
        );

        Serial.print(
            "Wi-Fi name: "
        );

        Serial.println(ssid);


        Serial.print(
            "Wi-Fi password: "
        );

        Serial.println(password);


        Serial.print(
            "IP address: "
        );

        Serial.println(
            WiFi.softAPIP()
        );

    }

    else
    {

        Serial.println(
            "ERROR: Wi-Fi AP failed!"
        );

    }


    // =================================================
    // WEB SERVER
    // =================================================

    server.on(
        "/",
        handleRoot
    );


    server.on(
        "/data",
        handleData
    );


    server.begin();


    Serial.println(
        "Web server started!"
    );


    Serial.println();
    Serial.println(
        "Connect your phone to:"
    );

    Serial.println(
        "ESP32-MPU6050"
    );

    Serial.println();
    Serial.println(
        "Then open:"
    );

    Serial.println(
        "http://192.168.4.1"
    );

}


// =====================================================
// LOOP
// =====================================================

void loop()
{

    // Handle web requests

    server.handleClient();

}