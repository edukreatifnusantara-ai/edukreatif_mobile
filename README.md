# Edukreativ Mobile

Flutter app edukasi dengan Toko Kreativ untuk katalog materi, seller premium, keranjang, checkout demo, riwayat pesanan, dan perpustakaan e-book.

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

## Catatan keamanan

Pembayaran, webhook, moderasi admin, komisi, dan akses file e-book belum menjadi sistem produksi. Jangan menaruh kredensial atau secret di source code.
