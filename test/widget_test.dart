import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edukreativ_mobile/akpol_cat_data.dart';
import 'package:edukreativ_mobile/akpol_interview_data.dart';
import 'package:edukreativ_mobile/kedinasan_tiu_data.dart';
import 'package:edukreativ_mobile/kedinasan_tkp_data.dart';
import 'package:edukreativ_mobile/kedinasan_twk_data.dart';
import 'package:edukreativ_mobile/mental_ideology_data.dart';
import 'package:edukreativ_mobile/main.dart';
import 'package:edukreativ_mobile/tni_academic_data.dart';

void main() {
  test('batas soal UTBK mengikuti jumlah paket, bukan seluruh bank', () {
    expect(UtbkRealCbtPage.limitFor('PU'), 30);
    expect(UtbkRealCbtPage.limitFor('PPU'), 20);
    expect(UtbkRealCbtPage.limitFor('PK'), 20);
    expect(UtbkRealCbtPage.limitFor('LBE'), 20);
    expect(UtbkRealCbtPage.limitFor('PM'), 20);
  });

  testWidgets('hasil UTBK menampilkan skor dan jumlah soal', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: UtbkCbtResultPage(
          subject: 'Pengetahuan Kuantitatif',
          correct: 15,
          answered: 20,
          total: 20,
        ),
      ),
    );

    expect(find.text('Try Out selesai!'), findsOneWidget);
    expect(find.text('75'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('20/20'), findsOneWidget);
  });

  test('bank soal Mental Ideologi dan Akademik Siber tervalidasi', () {
    expect(mentalIdeologyQuestions, hasLength(30));
    expect(
      mentalIdeologyQuestions.where((item) => !item.interview),
      hasLength(20),
    );
    expect(
      mentalIdeologyQuestions.where((item) => item.interview),
      hasLength(10),
    );
    expect(tniAcademicQuestions, hasLength(50));
    expect(akpolCatQuestions, hasLength(50));
    expect(akpolCatQuestions.every((item) => item.options.length == 5), isTrue);
    expect(akpolInterviewQuestions, hasLength(50));
    expect(
      akpolInterviewQuestions.every((item) => item.exampleAnswer.isNotEmpty),
      isTrue,
    );
    expect(STINTwkQuestions, hasLength(30));
    expect(PKNSTANTwkQuestions, hasLength(30));
    expect(PoltekSSNTwkQuestions, hasLength(30));
    expect(IPDNTwkQuestions, hasLength(30));
    expect(STMKGTwkQuestions, hasLength(30));
    expect(PoltekipTwkQuestions, hasLength(30));
    expect(PoltekimTwkQuestions, hasLength(30));
    expect(STINTiuQuestions, hasLength(35));
    expect(PKNSTANTiuQuestions, hasLength(35));
    expect(PoltekSSNTiuQuestions, hasLength(35));
    expect(IPDNTiuQuestions, hasLength(35));
    expect(STMKGTiuQuestions, hasLength(35));
    expect(PoltekipTiuQuestions, hasLength(35));
    expect(PoltekimTiuQuestions, hasLength(35));
    expect(STINTkpQuestions, hasLength(45));
    expect(PKNSTANTkpQuestions, hasLength(45));
    expect(PoltekSSNTkpQuestions, hasLength(45));
    expect(IPDNTkpQuestions, hasLength(45));
    expect(STMKGTkpQuestions, hasLength(45));
    expect(PoltekipTkpQuestions, hasLength(45));
    expect(PoltekimTkpQuestions, hasLength(45));
    expect(
      tniAcademicQuestions.map((item) => item.category).toSet(),
      containsAll([
        'Matematika',
        'Bahasa Indonesia',
        'Bahasa Inggris',
        'Pengetahuan Umum',
        'Siber',
      ]),
    );
    for (final item in tniAcademicQuestions) {
      expect(item.options, hasLength(5));
      expect(item.answer, isNotNull);
    }
    for (final item in mentalIdeologyQuestions.where(
      (item) => !item.interview,
    )) {
      expect(item.options, hasLength(5));
      expect(item.answer, isNotNull);
    }
  });

  testWidgets('guest melihat splash lalu katalog publik', (tester) async {
    await tester.pumpWidget(const EduKreativApp());
    expect(find.text('Belajar dengan cara kreatif'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pump();
    expect(find.text('Mau belajar apa hari ini?'), findsOneWidget);
    expect(find.text('Ruang Kreativ'), findsOneWidget);
  });

  testWidgets('Ruang Kreativ membuka tiga submenu', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomePage())),
    );

    await tester.scrollUntilVisible(
      find.text('Ruang Kreativ'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Ruang Kreativ'));
    await tester.pumpAndSettle();

    expect(find.text('Karya Kreativ'), findsOneWidget);
    expect(find.text('Inspirasi Kreativ'), findsOneWidget);
    expect(find.text('Jurnal Kreativ'), findsOneWidget);
  });

  testWidgets('halaman Ruang Kreativ berisi karya inspirasi dan jurnal', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CreativeWorksPage()));
    expect(find.text('Karya nyata dari ide yang diwujudkan.'), findsOneWidget);
    expect(find.text('Poster Hemat Air'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(home: CreativeInspirationPage()),
    );
    expect(find.text('Temukan ide, lalu kembangkan dengan caramu.'), findsOneWidget);
    expect(find.text('Ubah masalah menjadi ide'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: CreativeJournalPage()));
    expect(find.text('Catatan hari ini'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      'Hari ini saya menemukan ide baru.',
    );
    await tester.tap(find.text('Simpan jurnal'));
    await tester.pump();
    expect(find.text('Hari ini saya menemukan ide baru.'), findsOneWidget);
  });

  testWidgets('materi premium menampilkan paywall sebelum login', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CatalogPage())),
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Sains di Sekitar Kita'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Sains di Sekitar Kita'));
    await tester.pumpAndSettle();
    expect(find.text('Lihat pilihan akses'), findsOneWidget);
    await tester.tap(find.text('Lihat pilihan akses'));
    await tester.pumpAndSettle();
    expect(find.text('Materi premium'), findsNWidgets(2));
    expect(find.text('Lanjut ke login / daftar'), findsOneWidget);
  });

  testWidgets('materi gratis dapat menandai lesson dan memperbarui progres', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CourseDetailPage(title: 'Matematika Dasar', free: true),
      ),
    );

    expect(find.text('0/4 selesai'), findsOneWidget);
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pump();

    expect(find.text('1/4 selesai'), findsOneWidget);
    expect(
      tester
          .widget<CheckboxListTile>(find.byType(CheckboxListTile).first)
          .value,
      isTrue,
    );
  });

  testWidgets('materi dapat disimpan melalui tombol bookmark', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CourseDetailPage(title: 'Matematika Dasar', free: true),
      ),
    );

    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    await tester.tap(find.byTooltip('Simpan materi'));
    await tester.pump();
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
  });

  testWidgets('filter SMA menampilkan materi SMA lengkap', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CatalogPage())),
    );

    await tester.tap(find.text('SMA'));
    await tester.pump();

    expect(find.text('Bahasa Indonesia'), findsOneWidget);
    expect(find.text('Matematika Tingkat Lanjut'), findsOneWidget);
    expect(find.text('Fisika'), findsOneWidget);
    expect(find.text('Kimia'), findsOneWidget);
    expect(find.text('Biologi'), findsOneWidget);
    expect(find.text('Ekonomi'), findsOneWidget);
    expect(find.text('Sosiologi'), findsOneWidget);
    expect(find.text('Geografi'), findsOneWidget);
    expect(find.text('Bahasa Inggris Tingkat Lanjut'), findsOneWidget);
    expect(find.text('Informatika'), findsOneWidget);
    expect(find.text('Koding dan Kecerdasan Artifisial'), findsOneWidget);
    expect(find.text('Matematika Dasar'), findsNothing);
    expect(find.text('Sains di Sekitar Kita'), findsNothing);
  });

  testWidgets('filter SMP menampilkan mapel Kurikulum Merdeka', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CatalogPage())),
    );

    await tester.tap(find.text('SMP'));
    await tester.pump();

    expect(find.text('Sains di Sekitar Kita'), findsOneWidget);
    expect(find.text('Eksperimen Energi'), findsOneWidget);
    expect(find.text('Matematika SMP'), findsOneWidget);
    expect(find.text('Bahasa Inggris SMP'), findsOneWidget);
    expect(find.text('IPS Terpadu'), findsOneWidget);
    expect(find.text('Pendidikan Pancasila'), findsOneWidget);
    expect(find.text('Informatika SMP'), findsOneWidget);
    expect(find.text('Seni Budaya'), findsOneWidget);
    expect(find.text('PJOK'), findsOneWidget);
    expect(find.text('Bahasa Indonesia'), findsNothing);
    expect(find.text('Matematika Dasar'), findsNothing);
  });

  testWidgets('filter SD menampilkan mapel dasar Kurikulum Merdeka', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CatalogPage())),
    );

    await tester.tap(find.text('SD'));
    await tester.pump();

    expect(find.text('Matematika Dasar'), findsOneWidget);
    expect(find.text('Petualangan Pecahan'), findsOneWidget);
    expect(find.text('Bahasa Indonesia SD'), findsOneWidget);
    expect(find.text('IPAS'), findsOneWidget);
    expect(find.text('Pendidikan Pancasila SD'), findsOneWidget);
    expect(find.text('Bahasa Inggris Dasar'), findsOneWidget);
    expect(find.text('Seni Budaya SD'), findsOneWidget);
    expect(find.text('PJOK SD'), findsOneWidget);
    expect(find.text('Pendidikan Agama dan Budi Pekerti'), findsOneWidget);
    expect(find.text('Sains di Sekitar Kita'), findsNothing);
    expect(find.text('Bahasa Indonesia'), findsNothing);
  });

  testWidgets('profil dapat mengubah nama pengguna', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ProfilePage())),
    );

    await tester.tap(find.byTooltip('Edit profil'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Alya Kreativ');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Alya Kreativ'), findsOneWidget);
    expect(find.text('Profil berhasil diperbarui.'), findsOneWidget);
  });

  test('riwayat hasil menyimpan hasil terbaru', () {
    TniTryoutHistory.results.clear();
    final first = TniTryoutResult(
      score: 20,
      total: 50,
      completedAt: DateTime(2026, 8, 26, 10),
      timedOut: false,
    );
    final second = TniTryoutResult(
      score: 35,
      total: 50,
      completedAt: DateTime(2026, 8, 26, 11),
      timedOut: true,
    );

    TniTryoutHistory.add(first);
    TniTryoutHistory.add(second);

    expect(TniTryoutHistory.results, hasLength(2));
    expect(TniTryoutHistory.results.first.score, 35);
    expect(TniTryoutHistory.results.first.timedOut, isTrue);
    TniTryoutHistory.results.clear();
  });

  testWidgets('akun yang didaftarkan dapat digunakan untuk login', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    await tester.tap(find.widgetWithText(OutlinedButton, 'Buat akun baru'));
    await tester.pumpAndSettle();
    final registerFields = find.byType(TextField);
    await tester.enterText(registerFields.at(0), 'Alya Kreativ');
    await tester.enterText(registerFields.at(1), 'alya@kreativ.test');
    await tester.enterText(registerFields.at(2), 'rahasia123');
    await tester.enterText(registerFields.at(3), 'rahasia123');
    await tester.tap(find.widgetWithText(FilledButton, 'Buat akun'));
    await tester.pumpAndSettle();
    expect(find.text('Akun berhasil dibuat'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Mulai Kreativ'));
    await tester.pumpAndSettle();
    expect(find.text('Masuk'), findsOneWidget);

    final loginFields = find.byType(TextField);
    await tester.enterText(loginFields.at(0), 'alya@kreativ.test');
    await tester.enterText(loginFields.at(1), 'rahasia123');
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk ke akun'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsNothing);
  });
  testWidgets('tombol inti beranda berfungsi', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomePage())),
    );

    await tester.tap(find.byTooltip('Notifikasi'));
    await tester.pumpAndSettle();
    expect(find.text('Notifikasi Kreativ'), findsOneWidget);
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ActionChip, 'Mulai jelajah'));
    await tester.pumpAndSettle();
    expect(find.text('Temukan cara belajar'), findsOneWidget);
    await tester.tap(find.text('Belajar dengan Misi'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih target belajar'), findsOneWidget);
    Navigator.of(tester.element(find.text('Pilih target belajar'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Mulai jelajah'), findsOneWidget);
    await tester.tap(find.text('Game Kreativ'));
    await tester.pumpAndSettle();
    expect(
      find.text('Kumpulan game edukasi Kreativ sedang disiapkan.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cerita Kreativ'));
    await tester.pumpAndSettle();
    expect(find.text('Cerita pendek Nusantara'), findsOneWidget);
    expect(find.text('Timun Mas'), findsOneWidget);
    Navigator.of(tester.element(find.text('Cerita pendek Nusantara'))).pop();
    await tester.pumpAndSettle();

    for (final title in ['Promo Kreativ', 'Camp Kreativ']) {
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      expect(find.text(title), findsAtLeastNWidgets(1));
      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('pilihan belajar beranda membuka fitur masing-masing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomePage())),
    );

    await tester.scrollUntilVisible(
      find.text('Game Kreativ'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Game Kreativ'));
    await tester.pumpAndSettle();
    expect(
      find.text('Kumpulan game edukasi Kreativ sedang disiapkan.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cerita Kreativ'));
    await tester.pumpAndSettle();
    expect(find.text('Cerita pendek Nusantara'), findsOneWidget);
    Navigator.of(tester.element(find.text('Cerita pendek Nusantara'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('LiveClass'));
    await tester.pumpAndSettle();
    expect(find.text('Jadwal kelas'), findsOneWidget);
  });

  testWidgets('LiveClass dipendekkan dan Guru Kreativ membuka ajakan guru', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomePage())),
    );

    await tester.scrollUntilVisible(
      find.text('LiveClass'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final liveClassCard = find
        .ancestor(of: find.text('LiveClass'), matching: find.byType(Card))
        .first;
    expect(
      tester.getSize(liveClassCard).width,
      lessThan(tester.getSize(find.byType(Scaffold).first).width),
    );

    await tester.scrollUntilVisible(
      find.text('GURU KREATIV JOIN US'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('GURU KREATIV JOIN US'));
    await tester.pumpAndSettle();
    expect(find.byType(CreativeTeacherJoinPage), findsOneWidget);
    expect(find.text('Mengapa bergabung?'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Saya tertarik bergabung'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Saya tertarik bergabung'));
    await tester.pumpAndSettle();
    expect(find.text('Minat bergabung'), findsOneWidget);
    expect(find.text('Tutup'), findsOneWidget);
  });
  testWidgets('beranda menampilkan tiga jalur persiapan baru', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomePage())),
    );

    await tester.scrollUntilVisible(
      find.text('Psikotest'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Psikotest'), findsOneWidget);
    expect(find.text('SMA Taruna Nusantara'), findsOneWidget);
    expect(find.text('Universitas Pertahanan'), findsOneWidget);
    expect(find.text('Target UTBK hari ini'), findsNothing);

    await tester.tap(find.text('Psikotest'));
    await tester.pumpAndSettle();
    expect(find.text('Materi dan latihan untuk menu ini sedang disiapkan.'), findsOneWidget);
  });

  testWidgets('SIAP UTBK menampilkan countdown pelaksanaan', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomePage())),
    );

    await tester.scrollUntilVisible(
      find.text('SIAP UTBK'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('SIAP UTBK'), findsOneWidget);
    await tester.tap(find.text('SIAP UTBK'));
    await tester.pumpAndSettle();

    expect(find.text('SIAP UTBK'), findsOneWidget);
    expect(find.text('HITUNG MUNDUR UTBK 2027'), findsOneWidget);
    expect(find.text('Senin, 1 Maret 2027'), findsOneWidget);
    expect(find.text('hari'), findsOneWidget);
    expect(find.text('minggu'), findsOneWidget);
    expect(find.text('bulan'), findsOneWidget);
  });
  testWidgets('layout soal memisahkan area scroll dan tombol tetap', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: UtbkQuestionPage()),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(Scrollable), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Selesai'),
        matching: find.byType(Scrollable),
      ),
      findsNothing,
    );
  });
  testWidgets('target UTBK berpindah ke progress profil', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ProfilePage())),
    );

    expect(find.text('Target UTBK hari ini'), findsOneWidget);
    await tester.tap(find.text('Target UTBK hari ini'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Fokus hari ini: TPS, Literasi, dan Penalaran Matematika.'),
      findsOneWidget,
    );
  });

  testWidgets('menu KEDINASAN membuka tiga jalur persiapan', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomePage())),
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('menu-kedinasan')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('menu-kedinasan')));
    await tester.pumpAndSettle();

    expect(find.text('KEDINASAN'), findsOneWidget);
    expect(find.text('Akademi TNI'), findsOneWidget);
    expect(find.text('AKPOL'), findsOneWidget);
    expect(find.text('Sekolah Kedinasan'), findsOneWidget);

    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('kedinasan-track-title')), findsOneWidget);
    expect(find.text('Materi persiapan'), findsOneWidget);

    await tester.tap(find.text('Materi persiapan'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tni-materials-title')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Kesamaptaan jasmani'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Kesamaptaan jasmani'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Latihan dan tryout'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tni-tryout-menu-title')), findsOneWidget);
    expect(find.byKey(const Key('tryout-tka-akademi-tni')), findsOneWidget);
    expect(find.byKey(const Key('tryout-mental-ideologi')), findsOneWidget);
    expect(find.byKey(const Key('tryout-akademik-siber')), findsOneWidget);
    expect(find.byKey(const Key('tryout-psikotest')), findsOneWidget);

    await tester.tap(find.byKey(const Key('tryout-tka-akademi-tni')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tni-tryout-title')), findsOneWidget);
    expect(find.text('Soal 1 dari 50 · Matematika'), findsOneWidget);
    expect(find.text('Sumber soal: TB XI'), findsOneWidget);
    expect(find.text('60:00'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tryout-mental-ideologi')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tni-bank-title')), findsOneWidget);
    expect(find.text('Try Out Mental Ideologi'), findsWidgets);
    expect(find.text('Soal 1 dari 30 · Nilai Kebangsaan'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tryout-akademik-siber')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tni-bank-title')), findsOneWidget);
    expect(find.text('Try Out Akademik dan Siber'), findsWidgets);
    expect(find.text('Soal 1 dari 50 · Matematika'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    Navigator.of(tester.element(find.byKey(const Key('kedinasan-track-title'))))
        .pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('AKPOL'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('kedinasan-track-title')), findsOneWidget);
    expect(find.text('AKPOL'), findsWidgets);
    await tester.tap(find.text('Materi persiapan'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('akpol-materials-title')), findsOneWidget);
    expect(find.text('Tes Akademik CAT'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('PMK — Penelusuran Mental Kepribadian'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('PMK — Penelusuran Mental Kepribadian'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Antropometri'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Antropometri'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Latihan dan tryout'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('akpol-tryout-menu-title')), findsOneWidget);
    expect(find.byKey(const Key('akpol-tryout-akademik-cat')), findsOneWidget);
    await tester.tap(find.byKey(const Key('akpol-tryout-akademik-cat')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tni-bank-title')), findsOneWidget);
    expect(find.text('Try Out Tes Akademik CAT AKPOL'), findsWidgets);
    expect(find.text('Soal 1 dari 50 · TPA Verbal'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('akpol-tryout-pmk')), findsOneWidget);
    expect(find.byKey(const Key('akpol-tryout-wawancara')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('akpol-tryout-psikotest')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('akpol-tryout-psikotest')), findsOneWidget);
    await tester.tap(find.byKey(const Key('akpol-tryout-pmk')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('akpol-pmk-title')), findsOneWidget);
    expect(find.byKey(const Key('akpol-pmk-question-1')), findsOneWidget);
    expect(find.textContaining('Ceritakan identitas'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('akpol-tryout-wawancara')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('akpol-tryout-wawancara')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('akpol-interview-title')), findsOneWidget);
    expect(find.byKey(const Key('akpol-interview-question-1')), findsOneWidget);
    expect(find.textContaining('Ceritakan identitas'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byKey(const Key('kedinasan-track-title'))))
        .pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sekolah Kedinasan'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('kedinasan-track-title')), findsOneWidget);
    expect(find.text('Sekolah Kedinasan'), findsWidgets);

    await tester.tap(find.text('Materi persiapan'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('skd-materials-title')), findsOneWidget);
    expect(find.byKey(const Key('skd-school-STIN')), findsOneWidget);
    expect(find.byKey(const Key('skd-school-PKN STAN')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('skd-school-Poltek SSN')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('skd-school-Poltek SSN')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('skd-school-STIN')));
    await tester.tap(find.byKey(const Key('skd-school-STIN')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('skd-school-detail-title')), findsOneWidget);
    expect(find.text('STIN'), findsWidgets);
    expect(find.textContaining('SKD CAT BKN'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Informasi seleksi'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('selection-info-title')), findsOneWidget);
    expect(find.text('menpan.go.id dan bkn.go.id'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Latihan dan tryout'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('skd-tryout-menu-title')), findsOneWidget);
    await tester.tap(find.byKey(const Key('skd-school-STIN')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('skd-school-tryout-title')), findsOneWidget);
    expect(find.byKey(const Key('skd-tryout-twk')), findsOneWidget);
    expect(find.byKey(const Key('skd-tryout-tiu')), findsOneWidget);
    expect(find.byKey(const Key('skd-tryout-tkp')), findsOneWidget);
    await tester.tap(find.byKey(const Key('skd-tryout-tkp')));
    await tester.pumpAndSettle();
    expect(find.text('Try Out TKP STIN'), findsWidgets);
    expect(find.text('Soal 1 dari 45 · TKP'), findsOneWidget);
  });
  testWidgets('tombol kembali Katalog dan Progres mengarah ke Beranda', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeShell()));

    await tester.tap(find.text('Academy Kreativ'));
    await tester.pump();
    expect(find.text('Academy Kreativ'), findsWidgets);
    await tester.tap(find.byKey(const Key('kembali-ke-beranda')));
    await tester.pump();
    expect(find.text('Mau belajar apa hari ini?'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pump();
    await tester.tap(find.text('Progres'));
    await tester.pumpAndSettle();
    expect(find.text('Progres Kreativ'), findsOneWidget);
    await tester.tap(find.byKey(const Key('kembali-dari-progres')));
    await tester.pump();
    expect(find.text('Profil saya'), findsOneWidget);
  });

  testWidgets('Toko Kreativ menampilkan belanja dan akses jualan premium', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: StorePage()));

    expect(find.byKey(const Key('toko-kreativ-title')), findsOneWidget);
    expect(find.text('E-book Strategi Belajar Efektif'), findsOneWidget);
    expect(find.text('Tumbler Edukreativ'), findsOneWidget);

    await tester.tap(find.text('E-book Strategi Belajar Efektif'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('detail-produk-toko')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tambah-ke-keranjang')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Tumbler Edukreativ'));
    await tester.tap(find.text('Tumbler Edukreativ'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tambah-ke-keranjang')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('keranjang-toko')));
    await tester.tap(find.byKey(const Key('keranjang-toko')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('total-keranjang')), findsOneWidget);
    expect(find.text('Total sementara: Rp90000'), findsOneWidget);
    await tester.tap(find.byKey(const Key('checkout-demo')));
    await tester.pumpAndSettle();
    expect(find.text('Checkout'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('alamat-checkout')),
      'Jl. Kreativ No. 10',
    );
    await tester.enterText(
      find.byKey(const Key('telepon-checkout')),
      '08123456789',
    );
    expect(find.byKey(const Key('total-checkout')), findsOneWidget);
    expect(find.text('Total: Rp100000'), findsOneWidget);
    await tester.tap(find.byKey(const Key('konfirmasi-pesanan')));
    await tester.pumpAndSettle();
    expect(find.text('Pesanan dibuat'), findsOneWidget);
    expect(find.textContaining('Menunggu pembayaran'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tutup-konfirmasi-pesanan')));
    await tester.pumpAndSettle();
    expect(find.text('Keranjang masih kosong'), findsNothing);
    await tester.tap(find.byKey(const Key('keranjang-toko')));
    await tester.pumpAndSettle();
    expect(find.text('Keranjang masih kosong'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('riwayat-pesanan')));
    await tester.pumpAndSettle();
    expect(find.text('ORD-1'), findsOneWidget);
    expect(find.text('Menunggu pembayaran'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('perpustakaan-ebook')));
    await tester.pumpAndSettle();
    expect(find.text('E-book Strategi Belajar Efektif'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jualan'));
    await tester.pump();
    expect(find.text('Lapak Premium Kreativ'), findsOneWidget);
    expect(find.byKey(const Key('ajukan-produk-toko')), findsOneWidget);

    await tester.tap(find.byKey(const Key('ajukan-produk-toko')));
    await tester.pumpAndSettle();
    expect(find.text('Jualan di Toko Kreativ'), findsOneWidget);
    await tester.tap(find.text('Aktifkan demo premium'));
    await tester.pump();
    expect(
      find.text('Status premium aktif · siap mengajukan produk.'),
      findsOneWidget,
    );
    expect(find.text('Produk saya'), findsOneWidget);
    await tester.tap(find.byKey(const Key('ajukan-produk-toko')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'E-book Sains Kreativ',
    );
    await tester.enterText(find.byType(TextField).last, '40000');
    await tester.tap(find.byKey(const Key('simpan-pengajuan-produk')));
    await tester.pumpAndSettle();
    expect(find.text('E-book Sains Kreativ'), findsOneWidget);
    expect(find.text('Menunggu review'), findsWidgets);
    LocalAccount.isPremium = false;
  });
}
