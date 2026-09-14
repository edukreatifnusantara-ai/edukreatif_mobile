# Edukreativ Mobile

Flutter app edukasi dengan katalog materi dan Toko Kreativ gratis untuk seluruh member.

## Akses konten

Seluruh materi, fitur belajar, katalog, dan pengajuan materi tersedia gratis untuk semua member. Tidak ada paket premium, langganan, atau pembayaran di aplikasi.


✅ Implementasi selesai:

- **Question Rotation Service** (`lib/services/question_rotation_service.dart`):
  - Rotasi soal per mata pelajaran dengan reserve pool
  - Algoritma difficulty-weighted selection (mudah 40%, sedang 40%, sulit 20%)
  - Support mixed subject packages (gabung TIU, TWK, TKP)
  - Reset rotasi otomatis saat reserve habis

- **CBT Session Manager** (`lib/services/cbt_session_manager.dart`):
  - Timer countdown real-time dengan pause/resume
  - Tracking jawaban per soal + waktu pengerjaan
  - Navigasi soal dengan status (dijawab benar, salah, dilewati)
  - Kalkulasi hasil: per-subject breakdown, score, time analytics

- **CBT Test Page** (`lib/pages/cbt_test_page.dart`):
  - UI interaktif dengan difficulty badge
  - Navigasi grid soal per kategori
  - Result page dengan breakdown per subtes
  - Integrasi ke Try Out UTBK Lengkap (153 soal, 230 menit)

- **SKD Question Bank** (`lib/services/skd_question_bank.dart`):
  - Rotasi terpisah untuk SKD (TIU, TWK, TKP)
  - Siap untuk TNI/Polri/Kedinasan tests

**Fitur utama:**
- Soal berubah otomatis setiap kali klien selesai
- Tingkat kesulitan bervariasi sesuai algoritma
- Tidak ada duplikasi soal hingga reserve habis
- Progress tracking per session
- Ukuran app tetap optimal (<50MB)

**Status:**
- Branch: `feat/backend-foundation` (6 commits baru)
- Local ready: ✅
- Network push: ⏳ (menunggu koneksi)
- Next: Integration testing, AI worker assignment untuk maintenance

## Status backend

Repository ini memiliki fondasi Supabase, tetapi koneksi online belum aktif secara default:

- Kontrak repository: `lib/data/store_backend.dart`
- Adapter lokal untuk development: `LocalStoreBackendRepository`
- Adapter Supabase untuk toko: `SupabaseStoreBackendRepository`
- Dependency SDK: `supabase_flutter`
- Skema toko: `backend/supabase_schema.sql`
- Skema bank soal dan admin: `backend/002_question_bank.sql`
- Tidak ada URL, anon key, password, token, atau secret di repository.

Bank soal saat ini masih tersedia sebagai asset lokal untuk menjaga aplikasi tetap bisa dibuka tanpa backend. Migration bank soal menambahkan status draft/review/published, antrean review, audit log, dan RLS admin.

## Mengaktifkan Supabase

1. Buat atau pilih project Supabase development yang benar.
2. Review dan jalankan `backend/supabase_schema.sql`, lalu `backend/002_question_bank.sql`.
3. Masukkan URL dan publishable/anon key melalui `--dart-define`, bukan ke source code.
4. Buat akun admin dan set `profiles.role = 'admin'` melalui jalur aman.
5. Import soal setelah schema dan aturan RLS diverifikasi.
6. Ganti adapter lokal dengan adapter Supabase secara bertahap dan uji dengan akun buyer, seller, serta admin.
7. Buat API admin server-side untuk Hermes; jangan memberi Hermes akses database atau service-role key secara langsung.

Sebelum langkah 1-7 dianggap selesai, harus ada project Supabase nyata, migration berhasil, RLS teruji, aplikasi berhasil membaca data online, dan API admin berhasil diuji. Konfigurasi online belum dapat diverifikasi dari repository saja.

## Verifikasi lokal

```bash
export PATH=/home/ahe/flutter/bin:$PATH
flutter analyze
flutter test
flutter build linux --debug
```

## Catatan operasional

Moderasi materi dan akses file tetap memerlukan backend produksi. Jangan menaruh kredensial atau secret di source code.
