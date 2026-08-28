# Edukreativ Mobile

Flutter app edukasi dengan Toko Kreativ untuk katalog materi, seller premium, keranjang, checkout demo, riwayat pesanan, dan perpustakaan e-book.

## Status backend

Milestone 7 menyiapkan fondasi backend tanpa mengaktifkan koneksi jaringan:

- Kontrak repository: `lib/data/store_backend.dart`
- Adapter lokal untuk development: `LocalStoreBackendRepository`
- Adapter Supabase siap pakai: `SupabaseStoreBackendRepository`
- Dependency SDK: `supabase_flutter`
- Skema Supabase: `backend/supabase_schema.sql`
- Tidak ada URL, anon key, password, token, atau secret yang disimpan di repository.

Aplikasi saat ini tetap berjalan menggunakan data demo lokal. Status premium, produk, order, dan perpustakaan belum persisten setelah aplikasi ditutup.

## Mengaktifkan Supabase nanti

1. Buat project Supabase terpisah untuk development dan production.
2. Review lalu jalankan `backend/supabase_schema.sql` di project yang benar.
3. Tambahkan dependency `supabase_flutter` setelah URL project dan anon key resmi tersedia.
4. Simpan konfigurasi melalui environment/build config, bukan hard-code atau commit ke repository.
5. Implementasikan adapter `StoreBackendRepository` berbasis Supabase.
6. Uji Row Level Security dengan akun buyer, seller premium, dan admin sebelum mengganti adapter lokal.

## Verifikasi lokal

```bash
export PATH=/home/ahe/flutter/bin:$PATH
flutter analyze
flutter test
flutter build linux --debug
```

## Catatan keamanan

Pembayaran, webhook, moderasi admin, komisi, dan akses file e-book belum menjadi sistem produksi. Jangan menaruh kredensial atau secret di source code.
