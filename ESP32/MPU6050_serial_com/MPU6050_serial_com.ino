#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>

Adafruit_MPU6050 mpu;

#define SDA_PIN 8
#define SCL_PIN 9

void setup() {
  Serial.begin(115200);

  Wire.begin(SDA_PIN, SCL_PIN);

  Serial.println("Initializing MPU6050...");

  if (!mpu.begin()) {
    Serial.println("MPU6050 not found!");
    while (1) {
      delay(100);
    }
  }

  Serial.println("MPU6050 Connected Successfully!");
  Serial.println("--------------------------------");
}

void loop() {

  sensors_event_t a, g, temp;

  mpu.getEvent(&a, &g, &temp);

  Serial.print("Accel X: ");
  Serial.print(a.acceleration.x);
  Serial.print(" m/s^2\t");

  Serial.print("Y: ");
  Serial.print(a.acceleration.y);
  Serial.print(" m/s^2\t");

  Serial.print("Z: ");
  Serial.print(a.acceleration.z);
  Serial.println(" m/s^2");

  Serial.print("Gyro X: ");
  Serial.print(g.gyro.x);
  Serial.print(" rad/s\t");

  Serial.print("Y: ");
  Serial.print(g.gyro.y);
  Serial.print(" rad/s\t");

  Serial.print("Z: ");
  Serial.print(g.gyro.z);
  Serial.println(" rad/s");

  Serial.print("Temperature: ");
  Serial.print(temp.temperature);
  Serial.println(" °C");

  Serial.println("--------------------------------");

  delay(1000);
}