#include <WiFi.h>
#include <FirebaseESP32.h> // Pastikan install "Firebase ESP32 Client" by Mobizt
#include <DHT.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <time.h>

// ================= KONFIGURASI WIFI & FIREBASE =================
#define WIFI_SSID "hiqaffyed"
#define WIFI_PASSWORD "12345678"

// Project ID dari firebase_options.dart Anda: 'airquality-tubes'
#define FIREBASE_HOST "https://airquality-tubes-default-rtdb.asia-southeast1.firebasedatabase.app/"
// Database Secret (Didapat dari Project Settings > Service Accounts > Database Secrets)
#define FIREBASE_AUTH "FF3tDyPeasdJcDHxooKWbyIVoi3scAPvBszGTNDd"

// ================= PIN MAPPING (ESP32 DEVKIT V1) =================
// I2C LCD: SDA = GPIO 21, SCL = GPIO 22 (Default Wire)
#define DHTPIN 4
#define DHTTYPE DHT22
#define MQ2_PIN 34       // Analog ADC1
#define DUST_VO_PIN 35   // Analog ADC1
#define DUST_LED_PIN 27  // Digital Output

DHT dht(DHTPIN, DHTTYPE);
LiquidCrystal_I2C lcd(0x27, 16, 2); // Cek alamat I2C, bisa 0x27 atau 0x3F

FirebaseData firebaseData;
FirebaseConfig config;
FirebaseAuth auth;

unsigned long sendDataPrevMillis = 0;
// Sampling debu butuh timing presisi
int samplingTime = 280;
int deltaTime = 40;
int sleepTime = 9680;

void setup() {
  Serial.begin(115200);
  
  // --- Init LCD ---
  // Jika LCD tidak nyala, cek kabel SDA/SCL (SDA ke D21, SCL ke D22)
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("Booting System...");

  // --- Init Sensor ---
  dht.begin();
  pinMode(MQ2_PIN, INPUT);
  pinMode(DUST_VO_PIN, INPUT);
  pinMode(DUST_LED_PIN, OUTPUT);
  
  // ESP32 ADC resolution is 12-bit (0-4095) by default,
  // tapi kode perhitungan Anda menggunakan 1023.0 (10-bit).
  // Kita set ke 10-bit agar rumus Anda tetap valid.
  analogReadResolution(10); 

  // --- WiFi ---
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  Serial.println("\nConnected!");

  // --- Sync Time ---
  configTime(7 * 3600, 0, "pool.ntp.org", "time.nist.gov"); // UTC+7 untuk WIB

  // --- Firebase Config ---
  config.database_url = FIREBASE_HOST;
  config.signer.tokens.legacy_token = FIREBASE_AUTH;
  
  // Opsi reconnect
  Firebase.reconnectWiFi(true);
  
  // Init Firebase
  Firebase.begin(&config, &auth);
  
  lcd.clear();
  lcd.print("Firebase OK!");
  delay(2000);
}

void loop() {
  // Kirim data setiap 5 detik (sesuai kode lama)
  if (millis() - sendDataPrevMillis > 5000 || sendDataPrevMillis == 0) {
    sendDataPrevMillis = millis();

    // 1. BACA DHT22
    float h = dht.readHumidity();
    float t = dht.readTemperature();

    // 2. BACA MQ2 (CO)
    int mq2_raw = analogRead(MQ2_PIN);
    // Konversi sederhana ke PPM (Perlu kalibrasi ulang untuk akurasi tinggi)
    float vrl = (float)mq2_raw * (3.3 / 1023.0); 
    // Rumus pendekatan CO
    float co_ppm = 3.027 * exp(1.0698 * vrl); 

    // 3. BACA DUST SENSOR (Sharp GP2Y1010AU0F)
    digitalWrite(DUST_LED_PIN, LOW); // Nyalakan IR LED
    delayMicroseconds(samplingTime);
    int dust_raw = analogRead(DUST_VO_PIN); // Baca nilai debu
    delayMicroseconds(deltaTime);
    digitalWrite(DUST_LED_PIN, HIGH); // Matikan IR LED
    delayMicroseconds(sleepTime);

    // Konversi Voltase ke Density
    float calcVoltage = dust_raw * (3.3 / 1023.0);
    float dust_density = (0.17 * calcVoltage) - 0.1; // mg/m3
    if (dust_density < 0) dust_density = 0;

    // Validasi bacaan DHT
    if (isnan(h) || isnan(t)) {
      Serial.println(F("Gagal baca DHT!"));
      lcd.setCursor(0,0); lcd.print("Err Sensor DHT");
      return;
    }

    // --- Serial Debug ---
    Serial.printf("Temp: %.1f C, Hum: %.1f %%, CO: %.1f PPM, Dust: %.2f\n", t, h, co_ppm, dust_density);

    // --- Tampilan LCD ---
    lcd.clear();
    lcd.setCursor(0, 0);
    // Menampilkan T (Suhu) dan H (Lembab)
    lcd.print("T:"); lcd.print(t, 1); 
    lcd.print(" H:"); lcd.print(h, 0); lcd.print("%");
    
    lcd.setCursor(0, 1);
    // Menampilkan C (CO) dan D (Debu)
    lcd.print("C:"); lcd.print((int)co_ppm);
    lcd.print(" D:"); lcd.print(dust_density, 2);

    // --- Kirim ke Firebase ---
    if (Firebase.ready()) {
      // Menggunakan objek JSON untuk efisiensi pengiriman
      FirebaseJson json;
      json.set("temperature", t);
      json.set("humidity", h);
      json.set("co_ppm", co_ppm);
      json.set("dust_density", dust_density);
      // Mengambil waktu epoch sekarang
      time_t now;
      time(&now);
      json.set("last_updated", (int)now); 

      // Kirim ke path "/monitoring"
      // Path ini COCOK dengan MonitoringService.dart di Flutter Anda
      if (Firebase.setJSON(firebaseData, "/monitoring", json)) {
        Serial.println("Upload Berhasil ✅");
      } else {
        Serial.print("Upload Gagal ❌: ");
        Serial.println(firebaseData.errorReason());
      }
    }
  }
}