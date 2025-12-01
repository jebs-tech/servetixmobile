# 🎟️ **ServeTix – Mobile App Pembelian Tiket Pertandingan Voli**

ServeTix adalah aplikasi mobile yang dirancang untuk memudahkan penggemar olahraga voli dalam membeli tiket pertandingan secara cepat, aman, dan terintegrasi dengan sistem web service yang sudah dibangun pada Proyek Tengah Semester.

Aplikasi ini menawarkan pengalaman pemesanan tiket yang modern, mulai dari melihat jadwal pertandingan, memilih kursi, melakukan pembayaran multi-metode, hingga mendapatkan e-ticket dalam bentuk QR Code.

## 👥 **Anggota Kelompok**

| Nama                          | NPM        |
| ----------------------------- | ---------- |
| Firos Aqilla Zufa             | 2406412972 |
| Jenisa Bunga                  | 2406431334 |
| Priyanggara Zuhaynanda Zavana | 2406359241 |
| Hafiz Nathan Vesaputra        | 2406432406 |
| Ghiyas Fazle Mawla Rahmat     | 2406354303 |
| Jonathan Immanuel             | 2406395695 |

## 📱 **Deskripsi Aplikasi**

ServeTix memberikan solusi digital untuk pembelian tiket pertandingan voli. Dengan aplikasi ini, pengguna dapat:

* Melihat jadwal pertandingan voli terbaru.
* Memilih kursi di layout stadion interaktif.
* Membeli tiket menggunakan metode pembayaran yang beragam (Bank Transfer, E-Wallet, QRIS).
* Mendapatkan e-ticket berbasis QR Code.
* Mengakses riwayat pembelian dan tiket aktif.
* Mengikuti forum diskusi dan menerima notifikasi pengingat pertandingan.

Aplikasi ini dibuat menggunakan **Flutter** dan terhubung dengan **Django REST API**.

## 🧩 **Daftar Modul yang Diimplementasikan**

### **Modul Utama**

1. **Homepage & Daftar Pertandingan**
   Menampilkan jadwal pertandingan, venue, dan kategori tiket.
2. **Detail Pertandingan & Pilih Kursi**
   Menampilkan detail pertandingan + seat map interaktif.
3. **Pembayaran (Multi-payment)**
   Bank, e-wallet, dan QRIS.
4. **E-Ticket (QR Code)**
   Tiket digital otomatis dibuat setelah pembayaran berhasil.
5. **Akun Pengguna**
   Profil, riwayat pembelian, tiket aktif.
6. **Promo**
   Diskon dan bundle tiket.
7. **Forum & Notifikasi**
   Forum diskusi & pengingat pertandingan.

### **1. Pengguna Umum (Customer/Fans)**

* Registrasi & login
* Melihat jadwal pertandingan
* Memilih kursi dan membeli tiket
* Mengakses tiket (QR)
* Memberi ulasan venue
* Mengikuti diskusi di forum

### **2. Admin / Penyelenggara**

* Menambah pertandingan baru
* Mengatur kategori kursi & harga tiket
* Memantau penjualan tiket
* Mengelola laporan dan transaksi

## 🌐 **Alur Pengintegrasian Data Flutter ↔ Django (PWS)**

Aplikasi mobile ServeTix berkomunikasi dengan Django REST API melalui HTTP request. Alurnya:

1. **Flutter → Django: Authentication**

   * User mengirim username & password ke endpoint `/auth/login/`.
   * Django mengembalikan token (JWT/Access Token).
   * Flutter menyimpan token secara lokal (Secure Storage).

2. **Flutter → Django: Fetch Data**

   * Flutter melakukan `GET /matches/` untuk daftar pertandingan.
   * Token dikirim melalui header (Authorization).

3. **Flutter → Django: Seat Selection**

   * Saat memilih kursi, Flutter mengirim request `POST /ticket/select-seat/`.

4. **Pembayaran**

   * Flutter → Django: `POST /payment/checkout/`
   * Django menghasilkan QRIS atau kode pembayaran.
   * Flutter menampilkan UI pembayaran.

5. **E-Ticket**

   * Django membuat tiket setelah pembayaran diverifikasi.
   * Flutter mengambil tiket via `GET /ticket/<id>/qr`.

6. **Forum & Notifikasi**

   * Forum: `GET/POST /forum/`
   * Notifikasi: menggunakan local notification atau push (jika sempat).

Seluruh data berpindah menggunakan format **JSON**.

## 🎨 **Link Design (Figma)**


## 📱 **Tautan APK (Release)**


# 📅 **Rencana Kerja Per Pekan (17 Nov – 21 Des 2025)**

## **Pekan 1 — 17 s.d. 24 November 2025**

### Fokus: Setup proyek, fondasi desain, API dasar

* **Firos Aqilla Zufa** — Membuat design system
* **Jenisa Bunga** — Inisiasi Flutter project + folder structure
* **Priyanggara Zuhaynanda Zavana** — Membuat deskripsi README awal
* **Hafiz Nathan Vesaputra** — Implementasi API Authentication
* **Ghiyas Fazle Mawla Rahmat** — Implementasi API Fitur 1 (Daftar Pertandingan)
* **Jonathan Immanuel** — Setup integrasi API dasar Flutter ↔ Django

#### Kelompok:

* Setup repository GitHub
* Menentukan arsitektur aplikasi
* Menentukan navigasi utama

## **Pekan 2 — 24 November s.d. 1 Desember 2025**

### Fokus: API lanjutan & UI Fundamental

* **Firos** — API Fitur 2 (Detail Pertandingan & Seat Map)
* **Jenisa** — API Fitur 3 (Pembayaran)
* **Priyanggara** — API Fitur 4 (E-ticket)
* **Hafiz** — Halaman Authentication Flutter
* **Ghiyas** — Halaman Fitur 1 Flutter
* **Jonathan** — Halaman Fitur 2 Flutter

#### Kelompok:

* Integrasi seluruh API
* Menyusun alur integrasi data
* Build pipeline awal di Bitrise

## **Pekan 3 — 1 s.d. 8 Desember 2025**

### Fokus: Halaman lanjutan & data handling

* **Firos** — Halaman pembayaran Flutter
* **Jenisa** — Fitur QR Code e-ticket
* **Priyanggara** — Modul Akun Pengguna
* **Hafiz** — Token refresh & interceptor
* **Ghiyas** — Seat map interaktif
* **Jonathan** — Modul Promo

#### Kelompok:

* Testing API end-to-end
* Dokumentasi API final
* Review & revisi UI/UX

## **Pekan 4 — 8 s.d. 15 Desember 2025**

### Fokus: Forum, Notifikasi, Integrasi lanjutan

* **Firos** — Forum Diskusi
* **Jenisa** — Notifikasi pertandingan
* **Priyanggara** — Admin basic panel
* **Hafiz** — Data caching
* **Ghiyas** — Unit test API Django
* **Jonathan** — Unit test Flutter

#### Kelompok:

* Integrasi final seluruh fitur
* Build APK untuk uji internal

## **Pekan 5 — 15 s.d. 21 Desember 2025** (FINAL)

### Fokus: Deployment & Polishing Akhir

* **Firos** — Polishing UI/UX
* **Jenisa** — Integrasi Bitrise
* **Priyanggara** — Dokumentasi final
* **Hafiz** — Bug fixing backend
* **Ghiyas** — Bug fixing mobile
* **Jonathan** — Final testing

#### Kelompok:

* Publish APK Release ke GitHub & Bitrise
* Upload laporan integrasi ke Scele
* Final demo
