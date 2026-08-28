/// Materi latihan wawancara AKPOL dari TB XI.
class AkpolInterviewQuestion {
  final int number;
  final String category;
  final String question;
  final String exampleAnswer;

  const AkpolInterviewQuestion({
    required this.number,
    required this.category,
    required this.question,
    required this.exampleAnswer,
  });
}

const akpolInterviewQuestions = <AkpolInterviewQuestion>[
  AkpolInterviewQuestion(
    number: 1,
    category: 'Identitas',
    question: 'Ceritakan identitas dan latar belakang pendidikan Anda.',
    exampleAnswer: 'Sampaikan nama, domisili, pendidikan, kegiatan saat ini, dan fakta penting secara singkat serta sesuai dokumen.',
  ),
  AkpolInterviewQuestion(
    number: 2,
    category: 'Identitas',
    question: 'Apa kegiatan Anda sehari-hari?',
    exampleAnswer: 'Jelaskan kegiatan utama secara jujur, misalnya belajar, latihan, membantu keluarga, organisasi, atau pekerjaan.',
  ),
  AkpolInterviewQuestion(
    number: 3,
    category: 'Identitas',
    question: 'Apa kelebihan utama Anda?',
    exampleAnswer: 'Sebutkan satu atau dua kelebihan yang benar-benar dimiliki, lalu berikan contoh perilaku atau hasilnya.',
  ),
  AkpolInterviewQuestion(
    number: 4,
    category: 'Identitas',
    question: 'Apa kekurangan Anda?',
    exampleAnswer: 'Sampaikan kekurangan yang realistis dan langkah konkret yang sedang dilakukan untuk memperbaikinya.',
  ),
  AkpolInterviewQuestion(
    number: 5,
    category: 'Identitas',
    question: 'Prestasi apa yang paling Anda banggakan?',
    exampleAnswer: 'Jelaskan prestasinya, proses mencapainya, peran Anda, dan pelajaran yang diperoleh; jangan melebih-lebihkan.',
  ),
  AkpolInterviewQuestion(
    number: 6,
    category: 'Identitas',
    question: 'Kegagalan apa yang pernah Anda alami?',
    exampleAnswer: 'Akui kegagalan secara tenang, jelaskan tanggung jawab Anda, perbaikan yang dilakukan, dan hasil pembelajarannya.',
  ),
  AkpolInterviewQuestion(
    number: 7,
    category: 'Identitas',
    question: 'Bagaimana Anda mengambil keputusan?',
    exampleAnswer: 'Jelaskan bahwa Anda mengumpulkan fakta, mempertimbangkan aturan dan dampak, meminta arahan bila perlu, lalu bertanggung jawab atas keputusan.',
  ),
  AkpolInterviewQuestion(
    number: 8,
    category: 'Keluarga',
    question: 'Bagaimana hubungan Anda dengan orang tua?',
    exampleAnswer: 'Jawab sesuai kondisi sebenarnya dan jelaskan cara berkomunikasi serta saling menghormati di keluarga.',
  ),
  AkpolInterviewQuestion(
    number: 9,
    category: 'Keluarga',
    question: 'Apa pekerjaan orang tua/wali Anda?',
    exampleAnswer: 'Sampaikan apa adanya. Tidak perlu merasa rendah diri atau membesar-besarkan kondisi ekonomi keluarga.',
  ),
  AkpolInterviewQuestion(
    number: 10,
    category: 'Keluarga',
    question: 'Siapa yang paling membentuk karakter Anda?',
    exampleAnswer: 'Sebutkan orang yang benar-benar berpengaruh dan nilai positif yang dipelajari dari orang tersebut.',
  ),
  AkpolInterviewQuestion(
    number: 11,
    category: 'Keluarga',
    question: 'Bagaimana jika keluarga tidak setuju Anda masuk Akpol?',
    exampleAnswer: 'Saya akan mendengarkan kekhawatiran mereka, menjelaskan pertimbangan saya dengan sopan, dan tetap menghormati keluarga tanpa mengambil keputusan secara emosional.',
  ),
  AkpolInterviewQuestion(
    number: 12,
    category: 'Pergaulan',
    question: 'Bagaimana memilih teman?',
    exampleAnswer: 'Saya memilih lingkungan yang mendukung kegiatan positif, disiplin, dan saling mengingatkan. Saya tetap menghormati semua orang tetapi menjaga batas.',
  ),
  AkpolInterviewQuestion(
    number: 13,
    category: 'Pergaulan',
    question: 'Pernah terlibat konflik dengan teman?',
    exampleAnswer: 'Ceritakan fakta singkat, cara menyelesaikan melalui komunikasi, dan pelajaran yang didapat.',
  ),
  AkpolInterviewQuestion(
    number: 14,
    category: 'Pergaulan',
    question: 'Apa yang dilakukan jika teman mengajak melanggar aturan?',
    exampleAnswer: 'Saya menolak, menjelaskan alasannya, dan menjauh dari tindakan tersebut. Jika serius atau berulang, saya melapor melalui jalur yang tepat.',
  ),
  AkpolInterviewQuestion(
    number: 15,
    category: 'Pergaulan',
    question: 'Bagaimana pengaruh media sosial terhadap Anda?',
    exampleAnswer: 'Gunakan media sosial secara bertanggung jawab, menjaga bahasa, memeriksa informasi, dan tidak mengunggah hal yang melanggar hukum atau merugikan institusi.',
  ),
  AkpolInterviewQuestion(
    number: 16,
    category: 'Motivasi Polri',
    question: 'Mengapa ingin menjadi anggota Polri?',
    exampleAnswer: 'Saya ingin mengabdi, melindungi dan melayani masyarakat, membantu menjaga keamanan, serta menegakkan hukum dengan adil dan bertanggung jawab.',
  ),
  AkpolInterviewQuestion(
    number: 17,
    category: 'Motivasi Polri',
    question: 'Mengapa memilih Akpol?',
    exampleAnswer: 'Saya ingin memperoleh pendidikan kepemimpinan, akademik, karakter, dan profesi kepolisian secara terarah untuk mempersiapkan diri menjadi perwira.',
  ),
  AkpolInterviewQuestion(
    number: 18,
    category: 'Motivasi Polri',
    question: 'Apa yang Anda pahami tentang pengabdian?',
    exampleAnswer: 'Pengabdian berarti mendahulukan kepentingan masyarakat dan negara, bekerja sesuai aturan, serta tetap bertanggung jawab ketika tugas sulit.',
  ),
  AkpolInterviewQuestion(
    number: 19,
    category: 'Motivasi Polri',
    question: 'Apa yang Anda lakukan jika tidak diterima?',
    exampleAnswer: 'Saya menerima hasil secara sportif, mengevaluasi kekurangan, memperbaiki diri, dan melanjutkan pendidikan atau pekerjaan secara bertanggung jawab.',
  ),
  AkpolInterviewQuestion(
    number: 20,
    category: 'Motivasi Polri',
    question: 'Apa tujuan jangka panjang Anda?',
    exampleAnswer: 'Jelaskan tujuan yang realistis: menyelesaikan pendidikan, menjadi anggota yang berintegritas, meningkatkan kemampuan, dan memberi pelayanan yang bermanfaat.',
  ),
  AkpolInterviewQuestion(
    number: 21,
    category: 'Polri',
    question: 'Apa tugas utama Polri?',
    exampleAnswer: 'Polri bertugas memelihara keamanan dan ketertiban masyarakat, menegakkan hukum, serta memberikan perlindungan, pengayoman, dan pelayanan kepada masyarakat.',
  ),
  AkpolInterviewQuestion(
    number: 22,
    category: 'Polri',
    question: 'Apa arti pelayanan masyarakat?',
    exampleAnswer: 'Membantu masyarakat sesuai hukum dan kewenangan dengan sikap cepat, sopan, adil, tidak diskriminatif, dan dapat dipertanggungjawabkan.',
  ),
  AkpolInterviewQuestion(
    number: 23,
    category: 'Polri',
    question: 'Apa yang dimaksud penegakan hukum yang adil?',
    exampleAnswer: 'Menegakkan aturan berdasarkan fakta, hukum, dan prosedur tanpa membedakan status, kedekatan, suku, agama, atau kepentingan pribadi.',
  ),
  AkpolInterviewQuestion(
    number: 24,
    category: 'Polri',
    question: 'Apa arti profesional bagi anggota Polri?',
    exampleAnswer: 'Bekerja berdasarkan kompetensi, aturan, etika, disiplin, dan tanggung jawab, serta terus meningkatkan kemampuan.',
  ),
  AkpolInterviewQuestion(
    number: 25,
    category: 'Polri',
    question: 'Bagaimana menjaga kepercayaan masyarakat?',
    exampleAnswer: 'Dengan jujur, transparan sesuai kewenangan, konsisten menaati aturan, tidak menyalahgunakan jabatan, dan memberi pelayanan yang baik.',
  ),
  AkpolInterviewQuestion(
    number: 26,
    category: 'Polri',
    question: 'Apa yang Anda pahami tentang Tribrata?',
    exampleAnswer: 'Pelajari rumusan resmi Tribrata dan jelaskan maknanya sesuai pemahaman, terutama kesetiaan kepada negara, menjunjung kebenaran, dan melindungi masyarakat.',
  ),
  AkpolInterviewQuestion(
    number: 27,
    category: 'Kebangsaan',
    question: 'Apa arti setia kepada NKRI?',
    exampleAnswer: 'Menjunjung Pancasila dan UUD 1945, menjaga persatuan, menaati hukum, dan mendahulukan kepentingan bangsa serta masyarakat.',
  ),
  AkpolInterviewQuestion(
    number: 28,
    category: 'Kebangsaan',
    question: 'Bagaimana menerapkan Pancasila dalam kehidupan?',
    exampleAnswer: 'Menghormati keyakinan, memperlakukan manusia secara adil, menjaga persatuan, bermusyawarah, dan membantu mewujudkan keadilan sosial.',
  ),
  AkpolInterviewQuestion(
    number: 29,
    category: 'Kebangsaan',
    question: 'Bagaimana sikap terhadap perbedaan?',
    exampleAnswer: 'Menghormati perbedaan suku, agama, budaya, dan pendapat tanpa memaksakan kehendak, sambil menjaga persatuan.',
  ),
  AkpolInterviewQuestion(
    number: 30,
    category: 'Kebangsaan',
    question: 'Bagaimana menghadapi ujaran kebencian?',
    exampleAnswer: 'Tidak membalas dengan kebencian, tidak menyebarkan, menyimpan bukti bila perlu, dan melaporkan melalui kanal yang sesuai.',
  ),
  AkpolInterviewQuestion(
    number: 31,
    category: 'Kebangsaan',
    question: 'Apa arti bela negara bagi calon peserta?',
    exampleAnswer: 'Belajar dan berlatih sungguh-sungguh, disiplin, menaati hukum, menjaga persatuan, dan mempersiapkan diri untuk mengabdi.',
  ),
  AkpolInterviewQuestion(
    number: 32,
    category: 'Integritas',
    question: 'Apa arti integritas?',
    exampleAnswer: 'Keselarasan antara ucapan, nilai, dan tindakan, termasuk tetap jujur ketika tidak diawasi.',
  ),
  AkpolInterviewQuestion(
    number: 33,
    category: 'Integritas',
    question: 'Bagaimana jika menemukan uang atau barang?',
    exampleAnswer: 'Saya menyerahkan kepada pemilik bila diketahui atau kepada panitia/petugas berwenang dan menjelaskan tempat menemukannya.',
  ),
  AkpolInterviewQuestion(
    number: 34,
    category: 'Integritas',
    question: 'Bagaimana jika teman menyontek?',
    exampleAnswer: 'Saya mengingatkan dengan baik. Jika berlanjut dan memengaruhi proses seleksi, saya melaporkan melalui prosedur yang benar.',
  ),
  AkpolInterviewQuestion(
    number: 35,
    category: 'Integritas',
    question: 'Bagaimana jika ditawari bantuan dengan imbalan agar lulus?',
    exampleAnswer: 'Saya menolak karena seleksi harus jujur dan melalui prosedur resmi. Saya tidak memberi maupun menerima imbalan untuk memengaruhi hasil.',
  ),
  AkpolInterviewQuestion(
    number: 36,
    category: 'Integritas',
    question: 'Pernahkah Anda berbohong?',
    exampleAnswer: 'Jawab sesuai fakta. Jika pernah, jelaskan konteksnya, akui dampaknya, dan terangkan perbaikan agar tidak mengulanginya.',
  ),
  AkpolInterviewQuestion(
    number: 37,
    category: 'Disiplin',
    question: 'Bagaimana mengatur waktu?',
    exampleAnswer: 'Saya membuat prioritas, jadwal, dan menyiapkan kebutuhan lebih awal agar kewajiban selesai tepat waktu.',
  ),
  AkpolInterviewQuestion(
    number: 38,
    category: 'Disiplin',
    question: 'Apa yang dilakukan jika terlambat karena kesalahan sendiri?',
    exampleAnswer: 'Saya mengakui, meminta maaf, menerima konsekuensi sesuai aturan, dan memperbaiki penyebabnya tanpa membuat alasan palsu.',
  ),
  AkpolInterviewQuestion(
    number: 39,
    category: 'Disiplin',
    question: 'Bagaimana menerima kritik?',
    exampleAnswer: 'Saya mendengarkan, meminta penjelasan bila perlu, lalu memperbaiki kekurangan tanpa bersikap defensif.',
  ),
  AkpolInterviewQuestion(
    number: 40,
    category: 'Disiplin',
    question: 'Bagaimana menghadapi latihan berat?',
    exampleAnswer: 'Saya menjaga konsistensi, membagi target, mengikuti arahan pelatih, menjaga pemulihan, dan tidak menyerah hanya karena tidak nyaman.',
  ),
  AkpolInterviewQuestion(
    number: 41,
    category: 'Kesiapan Tugas',
    question: 'Apakah siap ditempatkan di seluruh Indonesia?',
    exampleAnswer: 'Saya siap ditempatkan sesuai kebutuhan organisasi dan negara serta berusaha beradaptasi dengan lingkungan baru.',
  ),
  AkpolInterviewQuestion(
    number: 42,
    category: 'Kesiapan Tugas',
    question: 'Bagaimana jika mendapat tugas yang tidak disukai?',
    exampleAnswer: 'Jika tugas itu sah dan sesuai aturan, saya melaksanakannya dengan sungguh-sungguh. Bila belum jelas, saya meminta arahan.',
  ),
  AkpolInterviewQuestion(
    number: 43,
    category: 'Kesiapan Tugas',
    question: 'Bagaimana jika menghadapi tekanan?',
    exampleAnswer: 'Saya tetap tenang, menentukan prioritas, berkomunikasi dengan pihak yang tepat, dan menyelesaikan masalah tahap demi tahap.',
  ),
  AkpolInterviewQuestion(
    number: 44,
    category: 'Kesiapan Tugas',
    question: 'Bagaimana bekerja dalam tim?',
    exampleAnswer: 'Saya memahami tujuan bersama, menjalankan bagian saya, berkomunikasi, membantu rekan, dan menerima evaluasi.',
  ),
  AkpolInterviewQuestion(
    number: 45,
    category: 'Etika',
    question: 'Bagaimana sikap terhadap narkoba?',
    exampleAnswer: 'Saya menolak narkoba karena merusak kesehatan, keluarga, masa depan, dan melanggar hukum. Saya menjauhi lingkungan penyalahgunaan.',
  ),
  AkpolInterviewQuestion(
    number: 46,
    category: 'Etika',
    question: 'Bagaimana sikap terhadap radikalisme dan intoleransi?',
    exampleAnswer: 'Saya menolak paham atau ajakan yang bertentangan dengan Pancasila, UUD 1945, hukum, dan persatuan NKRI.',
  ),
  AkpolInterviewQuestion(
    number: 47,
    category: 'Etika',
    question: 'Bagaimana menjaga rahasia kedinasan?',
    exampleAnswer: 'Saya hanya menyampaikan informasi kepada pihak berwenang melalui saluran resmi dan tidak mengunggah dokumen atau lokasi sensitif.',
  ),
  AkpolInterviewQuestion(
    number: 48,
    category: 'Etika',
    question: 'Bagaimana jika keluarga meminta bantuan menggunakan jabatan?',
    exampleAnswer: 'Saya menjelaskan bahwa jabatan tidak boleh digunakan untuk kepentingan pribadi. Bantuan hanya dapat diberikan melalui cara yang sah dan adil.',
  ),
  AkpolInterviewQuestion(
    number: 49,
    category: 'Skenario',
    question: 'Jika masyarakat marah karena layanan lambat, apa tindakan Anda?',
    exampleAnswer: 'Saya tetap tenang, mendengarkan keluhan, menjelaskan prosedur, meminta maaf bila ada kekurangan, dan mencari solusi sesuai kewenangan.',
  ),
  AkpolInterviewQuestion(
    number: 50,
    category: 'Skenario',
    question: 'Jika atasan mengoreksi Anda di depan umum?',
    exampleAnswer: 'Saya menerima koreksi dengan hormat, memperbaiki kesalahan, dan membahas hal yang belum jelas secara sopan pada waktu yang tepat.',
  ),
];

const akpolInterviewGuidance = [
  'Jawab langsung, singkat, sopan, dan konsisten dengan dokumen pendaftaran.',
  'Gunakan pola pengalaman, tindakan, hasil, atau pelajaran.',
  'Jika membahas kekurangan, sertakan langkah perbaikan yang nyata.',
  'Jangan mengarang pengalaman, prestasi, kondisi keluarga, atau riwayat diri.',
];
