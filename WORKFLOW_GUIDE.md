# Panduan Alur Kerja Aplikasi IoT Air Quality Monitoring

## Gambaran Umum

Aplikasi IoT Air Quality Monitoring adalah aplikasi mobile berbasis Flutter yang digunakan untuk memantau kualitas udara secara real-time. Aplikasi ini terintegrasi dengan sistem sensor IoT untuk mengumpulkan data seperti kadar karbon monoksida (CO), kepadatan debu, suhu, dan kelembaban.

## Arsitektur Aplikasi

Aplikasi ini menggunakan arsitektur berbasis layanan dengan Firebase sebagai backend untuk otentikasi dan database real-time.

### Komponen Utama:
- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Authentication & Realtime Database)
- **Hardware**: Sistem sensor IoT (tidak termasuk dalam scope aplikasi mobile ini)
- **Database**: Firebase Realtime Database

## Alur Kerja Utama

### 1. Alur Login dan Otentikasi

1. **Aplikasi Dimulai**
   - Aplikasi dimulai melalui `main()` function
   - Firebase diinisialisasi
   - Aplikasi membuka `AuthWrapper` sebagai halaman pertama

2. **Pengecekan Status Login**
   - `AuthWrapper` mengecek apakah pengguna sudah login menggunakan `AuthService.isUserLoggedIn()`
   - Jika pengguna sudah login, dialihkan ke `DashboardScreen`
   - Jika pengguna belum login, dialihkan ke `LoginScreen`

3. **Proses Login/Registrasi**
   - Pengguna dapat memilih antara login atau registrasi melalui toggle
   - Form login menerima email dan password
   - Setelah validasi berhasil, `AuthService` menghubungi Firebase Authentication
   - Jika berhasil, pengguna dialihkan ke `DashboardScreen`
   - Jika gagal, pesan error ditampilkan

4. **Fitur Tambahan di Login**
   - Reset password melalui email
   - Validasi input (email valid, password minimal 6 karakter)

---

### 2. Alur Dashboard (Utama)

1. **Tampilan Dashboard**
   - Setelah login, pengguna masuk ke `DashboardScreen`
   - Dashboard menampilkan data sensor secara real-time dari Firebase
   - Menggunakan `StreamBuilder` untuk mengikuti perubahan data secara real-time

2. **Komponen Tampilan Dashboard**
   - Status kualitas udara (Baik/Peringatan) berdasarkan standar AQI
   - Waktu terakhir update data
   - Kartu-kartu data sensor:
     - Karbon Monoksida (CO) dalam PPM
     - Kepadatan Debu dalam mg/m³
     - Suhu dalam Celsius
     - Kelembaban dalam Persen

3. **Sistem Status Kualitas Udara**
   - Status "Baik": Jika CO ≤ 100 PPM dan Dust ≤ 75 mg/m³
   - Status "Peringatan": Jika CO > 100 PPM atau Dust > 75 mg/m³
   - Warna status berubah otomatis berdasarkan kondisi (hijau = baik, merah = peringatan)

4. **Menu Dashboard**
   - Tombol menu di app bar menyediakan akses ke:
     - History Screen
     - Settings Screen
     - Logout

---

### 3. Alur History Data

1. **Akses ke History**
   - Dari dashboard, pengguna dapat mengakses history melalui menu
   - Menuju `HistoryScreen` menggunakan `Navigator.push`

2. **Tampilan History**
   - Menampilkan data historis dari Firebase Realtime Database
   - Menggunakan `StreamBuilder` untuk data historis secara real-time
   - Menampilkan data dalam format kartu-kartu dengan timestamp
   - Masing-masing kartu juga menunjukkan status kualitas udara saat itu

3. **Fitur History**
   - Refresh data (pull-to-refresh)
   - Tampilan kronologis (terbaru di atas)
   - Kembali ke dashboard melalui tombol back

---

### 4. Alur Settings dan Profil

1. **Akses ke Settings**
   - Dari dashboard, pengguna dapat mengakses settings melalui menu
   - Menuju `SettingsScreen` menggunakan `Navigator.push`

2. **Komponen Settings**
   - **Profil Section**:
     - Menampilkan dan mengedit nama tampilan
     - Menggunakan `UserProfileService` untuk update data
     - Validasi input nama tampilan
   - **Akun Section**:
     - Tombol logout
     - Konfirmasi penghapusan akun (fitur belum diimplementasi penuh)
   - **Info Aplikasi**:
     - Nama aplikasi dan versi

3. **Fungsi Logout**
   - Menggunakan `AuthService.signOut()` untuk logout dari Firebase
   - Navigasi kembali ke layar login
   - Validasi dan error handling

---

### 5. Sistem Peringatan dan Status Kualitas Udara (AQI)

1. **Kriteria Penentuan Status**
   - **Karbon Monoksida (CO)**: 
     - Ambang batas > 100 PPM = Status Peringatan
   - **Kepadatan Debu**:
     - Ambang batas > 75 mg/m³ = Status Peringatan
   - Jika salah satu ambang batas terlampaui = Status Peringatan
   - Jika keduanya di bawah ambang batas = Status Baik

2. **Visualisasi Status**
   - Status Baik: Warna hijau, ikon checkmark, pesan "Air quality is safe."
   - Status Peringatan: Warna merah, ikon peringatan, pesan "Wear a mask, Avoid outdoor activities."

3. **Implementasi Teknis**
   - Fungsi `getAQIStatus()` di `AQIUtils` mengevaluasi kondisi
   - Fungsi `getStatusColor()`, `getStatusText()`, dan `getHealthMessage()` memberikan representasi visual dan teks
   - Diterapkan di Dashboard, History, dan layar-layar lainnya

---

### 6. Integrasi dengan Firebase

1. **Firebase Authentication**
   - Login/registrasi dengan email dan password
   - Otentikasi pengguna
   - Manajemen session

2. **Firebase Realtime Database**
   - Monitoring data sensor disimpan di path `/monitoring`
   - Data historis disimpan di path `/history`
   - Profil pengguna disimpan di path `/users`

3. **Struktur Data Firebase**
   ```json
   {
     "monitoring": {
       "co_ppm": 0.0,
       "dust_density": 0.0,
       "temperature": 0.0,
       "humidity": 0.0,
       "last_updated": <server_timestamp>
     },
     "history": {
       "<unique_id>": {
         "co_ppm": 0.0,
         "dust_density": 0.0,
         "temperature": 0.0,
         "humidity": 0.0,
         "timestamp": <unix_timestamp>
       }
     },
     "users": {
       "<user_id>": {
         "email": "user@example.com",
         "display_name": "User Name",
         "created_at": <timestamp>,
         "last_login": <timestamp>
       }
     }
   }
   ```

---

### 7. Alur Lengkap Penggunaan Aplikasi

1. **Pertama Kali Buka Aplikasi**
   - Aplikasi memeriksa status login
   - Jika belum login → ke `LoginScreen`
   - Jika sudah login → ke `DashboardScreen`

2. **Login/Registrasi**
   - Masukkan email dan password
   - Klik Sign In/Sign Up
   - Jika berhasil → ke `DashboardScreen`

3. **Pantau Data Real-time**
   - Di dashboard, lihat data sensor yang diperbarui secara real-time
   - Perhatikan status kualitas udara (Baik/Peringatan)

4. **Akses History**
   - Buka menu dari dashboard
   - Pilih History
   - Lihat data historis

5. **Ganti Pengaturan**
   - Buka menu dari dashboard
   - Pilih Settings
   - Ganti nama tampilan atau logout

6. **Logout**
   - Dari menu dashboard atau settings screen
   - Pilih logout
   - Kembali ke `LoginScreen`

---

## Error Handling dan Validasi

1. **Validasi Form Login**
   - Email harus valid (format email)
   - Password minimal 6 karakter

2. **Error Firebase**
   - Kesalahan network ditangani dengan snackbar
   - Kesalahan autentikasi dengan pesan spesifik

3. **Error Data Stream**
   - Jika tidak ada data dari Firebase, tampilkan pesan "No data available"
   - Jika ada error dari stream, tampilkan error message

## Teknologi dan Dependencies

- **Flutter SDK**: 3.9.2+
- **Firebase Core**: Untuk inisialisasi Firebase
- **Firebase Auth**: Untuk otentikasi pengguna
- **Firebase Realtime Database**: Untuk data sensor dan historis
- **Intl**: Untuk format tanggal dan waktu
- **Cupertino Icons**: Untuk ikon iOS jika diperlukan

---

## Catatan Penting

- Aplikasi ini dirancang untuk bekerja sama dengan sistem sensor IoT yang mengirimkan data ke Firebase Realtime Database
- Warna utama aplikasi sekarang berwarna merah untuk konsistensi tema
- Desain aplikasi responsif dan mengikuti prinsip Material Design
- Sistem peringatan otomatis berdasarkan standar kesehatan