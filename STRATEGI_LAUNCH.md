# Edukreativ Mobile - Strategi Launch & Produksi

## 1. Audit Fitur vs Gap (Status Saat Ini)

### ✅ Fitur Sudah Berfungsi
- **Home**: 3 jalur persiapan (Psikotest, SMA TN, Unhan), SIAP UTBK countdown, Game/Cerita/LiveClass/Camp Kreativ
- **Academy Kreativ**: Katalog SD/SMP/SMA, materi gratis/premium, bookmark, progress tracking
- **Toko Kreativ**: Katalog produk, keranjang, checkout demo, riwayat pesanan, perpustakaan e-book, seller premium
- **Profil**: Login/register, edit nama, notifikasi, langganan, progres mingguan, target UTBK harian
- **Kedinasan**: Akademi TNI, AKPOL, Sekolah Kedinasan (STIN, PKN STAN, Poltek SSN, dll)
- **UTBK**: CBT real, bank soal per paket (PU, PPU, PK, LBE, PM), tryout, hasil skor
- **Psychology Menu**: TPA, TKP, Psikotest SMA TN, Mental Ideologi

### ⚠️ Gap Produksi
| Fitur | Status | Aksi |
|-------|--------|------|
| Backend Supabase | Belum aktif | Setup project, isi env vars, RLS test |
| Data persistensi | Demo only | Ganti LocalStoreBackendRepository → SupabaseStoreBackendRepository |
| Assets (logo, emblem, media) | 1B placeholder | Download/gen real assets |
| Soal UTBK lengkap | Paket 57 only | Fetch global bank soal resmi |
| Pembayaran | Demo | Integrasi Midtrans/Xendit |
| Moderasi seller | Belum | Admin panel + review flow |
| E-book file serving | Belum | Supabase Storage + signed URLs |
| Push notification | Belum | Firebase Cloud Messaging |

---

## 2. Global Content Sourcing (Algoritma & Sumber)

### Sumber Data Resmi
| Konten | Sumber | Metode Fetch |
|--------|--------|--------------|
| Soal UTBK | LTMPT Pusat (paket resmi), Kemenristek | Scrape PDF → parse JSON, atau repo GitHub edukasi terbuka |
| Soal TNI/AKPOL | Pusdiklat TNI, Mabes Polri | PDF resmi → OCR/parse |
| Soal Kedinasan | BKN, Menpan | PDF SKD CAT → struktur JSON |
| Materi SMA/SMP/SD | Kurikulum Merdeka (Kemdikbud), Buku Paket Gratis | EPUB/PDF → ekstrak teks + gambar |
| Video pembelajaran | YouTube Edukasi (Kemdikbud, Ruangguru, Zenius) | Embed URL via `url_launcher` |
| Soal psikotest | Tes akademik terbuka, bank soal psikologi | Parse dari PDF bank soal publik |

### Algoritma Pengisian Otomatis
```dart
// Pipeline: Fetch → Parse → Validate → Store → Sync
1. Scheduled job (GitHub Actions cron weekly)
2. Download PDF sumber resmi
3. pdf-parse → extract text/tables
4. LLM/Regex classify: {type: soal/materi, mapel, tingkat, kunci}
5. Schema validation (JSON Schema)
6. Commit ke assets/ + generate index.json
7. Flutter build auto-pickup via pubspec.yaml assets
```

### Struktur Assets Target
```
assets/
├── logos/                    # Brand assets
│   ├── logo_emblem.png       # 512x512, <50KB
│   ├── logo_transparent.png  # 512x512, <30KB
│   └── splash_logo.png       # 1080x1080, <100KB
├── emblems/                  # Institusi
│   ├── satu_nusa_emblem.jpg  # <80KB
│   └── unhan_emblem.jpg      # <80KB
├── questions/                # Bank soal terstruktur
│   ├── utbk/
│   │   ├── pu.json           # 900 soal (30 x 30 paket)
│   │   ├── ppu.json          # 600 soal
│   │   ├── pk.json           # 600 soal
│   │   ├── lbe.json          # 600 soal
│   │   └── pm.json           # 600 soal
│   ├── tni/
│   │   ├── akademik.json     # 500 soal
│   │   ├── mental_ideologi.json # 300 soal
│   │   └── psikotest.json
│   ├── akpol/
│   │   ├── cat.json          # 500 soal
│   │   ├── pmk.json
│   │   ├── wawancara.json
│   │   └── psikotest.json
│   └── kedinasan/
│       ├── twk.json
│       ├── tiu.json
│       └── tkp.json
├── materials/                # Materi pembelajaran
│   ├── sd/
│   ├── smp/
│   └── sma/
└── media/                    # Video thumbnail, ilustrasi
    └── thumbnails/
```

---

## 3. Pricing Strategy (CEO Decision)

### Tier Model: Freemium + Time-Limited Launch

| Tier | Harga | Akses | Target |
|------|-------|-------|--------|
| **Gratis (Launch)** | Rp 0 | Seluruh konten soal UTBK/TNI/AKPOL/Kedinasan, Academy SD-SMA, Progress tracking, Basic store (beli e-book per item) | Early adopters, brand awareness |
| **Premium Bulanan** | Rp 49.000/bln | Semua Gratis + Materi premium Academy, E-book unlimited library, No ads, Priority support, Offline download, LiveClass access | Siswa serious prep |
| **Premium Tahunan** | Rp 399.000/thn (33% off) | Semua Bulanan + Certificate completion, Mentor chat 1x/bln, Exclusive tryout | Power users, orang tua |
| **Seller Premium** | Rp 199.000/thn | Buka lapak, commission 15% (vs 25% gratis), Analytics dashboard, Featured placement | Kreator konten, guru |

### Launch Promo (First 90 Days)
- **Day 1-30**: 100% Gratis semua fitur Premium (no credit card)
- **Day 31-60**: 50% off Premium Tahunan (Rp 199.500)
- **Day 61-90**: 25% off Premium Tahunan (Rp 299.250)
- **Referral**: User invite → +7 hari gratis Premium each

### Revenue Projection (Year 1)
| Metric | Conservative | Realistic | Optimistic |
|--------|-------------|-----------|------------|
| MAU Month 12 | 50.000 | 150.000 | 400.000 |
| Premium Conversion | 3% | 5% | 8% |
| ARPU | Rp 15.000 | Rp 25.000 | Rp 40.000 |
| Monthly Revenue | Rp 22.5M | Rp 187.5M | Rp 1.28B |

---

## 4. Promo & Launch Strategy

### Phase 1: Pre-Launch (T-30 hari)
| Channel | Aktivitas | KPI |
|---------|-----------|-----|
| Instagram/TikTok | Teaser video "Belajar Kreativ" daily | 10k followers |
| YouTube | 3 video long-form: "Cara Belajar Efektif UTBK 2027" | 50k views |
| Telegram/Discord | Community "Keluarga Kreativ" | 5k members |
| Email | Waitlist landing page (Carrd/Notion) | 3k emails |
| SEO | Blog "Panduan UTBK/TNI/AKPOL 2027" | 10k organic visits |

### Phase 2: Launch Week (Day 1-7)
| Channel | Aktivitas | Budget |
|---------|-----------|--------|
| Play Store | ASO: "UTBK 2027", "TNI AKPOL", "Belajar SD SMP SMA" | Rp 0 |
| GitHub Pages | Web app live di `edukreatifnusantara-ai.github.io/edukreatif_mobile` | Rp 0 |
| Influencer Micro | 20 creator edukasi (10k-50k followers) | Rp 15M |
| Press Release | DetikEdu, KompasEdu, Liput6 Pendidikan | Rp 5M |
| Community Event | "UTBK Tryout Gratis Minggu Ini" via Zoom | Rp 3M |

### Phase 3: Growth (Bulan 2-6)
| Strategi | Detail |
|----------|--------|
| **Content Marketing** | Weekly blog: tips belajar, analisis soal, alumni story |
| **SEO Programmatic** | 500+ halaman: "Soal UTBK [Mapel] [Tahun] + Pembahasan" |
| **Referral Loop** | In-app share → deep link → reward coins → unlock premium |
| **School Partnership** | MOU 50 SMA/SMP: gratis Premium untuk siswa kelas 12/9 |
| **Paid Ads** | Meta/Google UAC target: orang tua SMA, calon TNI/AKPOL |
| **Email Drip** | Onboarding 7 hari → value → upsell Premium |

### Phase 4: Retention (Bulan 6+)
- Gamification: streak, badge, leaderboard mingguan
- LiveClass berkala (gratis untuk Premium)
- Alumni mentor program
- Offline event: "Camp Kreativ" di 5 kota besar

---

## 5. Optimasi Ukuran APK < 50MB

### Konfigurasi Build (`android/app/build.gradle.kts`)
```kotlin
android {
    defaultConfig {
        // ...
        ndk {
            abiFilters.addAll(listOf("arm64-v8a", "armeabi-v7a")) // Hapus x86, x86_64
        }
    }
    buildTypes {
        release {
            shrinkResources true
            minifyEnabled true
            proguardFiles(getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro')
        }
    }
    bundle {
        language {
            enableSplit = true // Split per bahasa
        }
        density {
            enableSplit = true // Split per density
        }
        abi {
            enableSplit = true // Split per ABI
        }
    }
}
```

### Asset Optimization
| Asset | Action | Target Size |
|-------|--------|-------------|
| Logo/Emblem | WebP lossless, resize max 512px | < 50KB each |
| Soal JSON | Gzip + split per mapel (lazy load) | < 5MB total |
| Images | WebP, WebP lossless untuk icon | - |
| Fonts | Subset hanya latin + latin-ext | < 100KB |
| Flutter Engine | `--no-tree-shake-icons` false, `--split-debug-info` | - |

### Expected APK Sizes
| Variant | Estimated |
|---------|-----------|
| arm64-v8a (release) | ~18 MB |
| armeabi-v7a (release) | ~20 MB |
| Universal APK | ~35 MB |
| App Bundle (Play Store) | ~15 MB download |

---

## 6. Rencana Eksekusi (Sprint 2 Minggu)

### Sprint 1: Content & Assets (Hari 1-7)
- [ ] Fetch & parse soal UTBK global (target 3.200 soal)
- [ ] Fetch soal TNI/AKPOL/Kedinasan (target 2.000 soal)
- [ ] Generate materi Academy SD/SMP/SMA dari buku paket gratis
- [ ] Create real logo/emblem assets (Canva/Figma → export WebP)
- [ ] Update pubspec.yaml assets list

### Sprint 2: Backend & Build (Hari 8-14)
- [ ] Setup Supabase project (dev + prod)
- [ ] Run schema SQL, test RLS policies
- [ ] Configure GitHub Actions secrets (SUPABASE_URL, SUPABASE_ANON_KEY)
- [ ] Switch repository adapter di main.dart
- [ ] Build APK release + test di device fisik
- [ ] Deploy web ke GitHub Pages
- [ ] Submit Play Store Internal Testing

### Sprint 3: Launch Prep (Hari 15-21)
- [ ] Landing page waitlist
- [ ] Influencer outreach
- [ ] Press kit (logo, screenshot, video demo, fact sheet)
- [ ] Play Store listing (desc, screenshot, video, privacy policy)
- [ ] Analytics: Firebase + Mixpanel/Amplitude
- [ ] Crashlytics setup

---

## 7. Tech Stack Final

| Layer | Tech |
|-------|------|
| Frontend | Flutter 3.24+, Dart 3.5+, Material 3 |
| Backend | Supabase (PostgreSQL + Auth + Storage + Realtime) |
| Auth | Supabase Auth (Email + Google + Apple) |
| Payments | Midtrans (ID) / Stripe (Global) |
| Push | Firebase Cloud Messaging |
| Analytics | Firebase Analytics + Mixpanel |
| Crash | Firebase Crashlytics |
| CI/CD | GitHub Actions (APK + Web) |
| Hosting Web | GitHub Pages (custom domain nanti) |
| Monitoring | Sentry (optional) |

---

## 8. Checklist Go/No-Go Launch

### Technical
- [ ] APK < 50MB (arm64)
- [ ] Zero crash pada 100 test run (monkey test)
- [ ] Cold start < 3s di device 4GB RAM
- [ ] Offline mode: soal + materi cached
- [ ] Web PWA score > 90 (Lighthouse)

### Content
- [ ] 3.200+ soal UTBK (5 paket x 5 mapel x 30 soal x 4 variasi)
- [ ] 2.000+ soal TNI/AKPOL/Kedinasan
- [ ] 50+ materi Academy per tingkat
- [ ] 100% assets real (no placeholder)

### Business
- [ ] Privacy Policy & ToS published
- [ ] Play Store listing approved
- [ ] Payment sandbox tested end-to-end
- [ ] Support email + FAQ live
- [ ] Launch promo calendar locked

---

*Dokumen ini living document. Update setiap sprint review.*