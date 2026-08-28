class AkpolPmkQuestion {
  final int number;
  final String category;
  final String question;
  final String exampleAnswer;

  const AkpolPmkQuestion({
    required this.number,
    required this.category,
    required this.question,
    required this.exampleAnswer,
  });
}

const akpolPmkQuestions = [
  AkpolPmkQuestion(
    number: 1,
    category: 'Riwayat Diri',
    question: 'Ceritakan identitas, latar belakang pendidikan, dan kegiatan Anda saat ini.',
    exampleAnswer: 'Saya adalah pribadi yang sedang menempuh pendidikan/beraktivitas di bidang ..., dan saat ini fokus mempersiapkan diri secara akademik, fisik, dan mental.',
  ),
  AkpolPmkQuestion(
    number: 2,
    category: 'Riwayat Diri',
    question: 'Apa kelebihan dan kekurangan utama Anda? Berikan contoh nyata.',
    exampleAnswer: 'Kelebihan saya adalah disiplin dan mau belajar. Kekurangan saya adalah kadang terlalu berhati-hati; saya memperbaikinya dengan membuat batas waktu dan menentukan prioritas.',
  ),
  AkpolPmkQuestion(
    number: 3,
    category: 'Riwayat Diri',
    question: 'Prestasi apa yang paling Anda banggakan dan apa proses mencapainya?',
    exampleAnswer: 'Prestasi yang paling saya banggakan adalah ... Saya mencapainya melalui latihan teratur, menerima masukan, dan tidak mudah menyerah.',
  ),
  AkpolPmkQuestion(
    number: 4,
    category: 'Riwayat Diri',
    question: 'Kegagalan atau kesalahan apa yang pernah Anda alami? Apa pelajaran yang diperoleh?',
    exampleAnswer: 'Saya pernah mengalami kegagalan dalam ... Saya mengakui bagian yang menjadi tanggung jawab saya, mengevaluasi penyebabnya, lalu memperbaiki cara belajar/persiapan.',
  ),
  AkpolPmkQuestion(
    number: 5,
    category: 'Riwayat Diri',
    question: 'Bagaimana Anda mengelola emosi ketika menghadapi tekanan?',
    exampleAnswer: 'Saya mengelola emosi dengan berhenti sejenak, mengatur napas, memahami masalah, lalu mengambil keputusan setelah lebih tenang.',
  ),
  AkpolPmkQuestion(
    number: 6,
    category: 'Keluarga dan Pergaulan',
    question: 'Ceritakan kondisi keluarga dan hubungan Anda dengan orang tua/wali.',
    exampleAnswer: 'Hubungan saya dengan keluarga baik. Kami saling mendukung dan menyelesaikan perbedaan pendapat dengan komunikasi yang terbuka dan sopan.',
  ),
  AkpolPmkQuestion(
    number: 7,
    category: 'Keluarga dan Pergaulan',
    question: 'Siapa yang paling memengaruhi pembentukan karakter Anda? Jelaskan.',
    exampleAnswer: 'Orang tua/wali banyak membentuk karakter saya melalui teladan disiplin, kejujuran, dan tanggung jawab. Namun saya tetap bertanggung jawab atas pilihan saya sendiri.',
  ),
  AkpolPmkQuestion(
    number: 8,
    category: 'Keluarga dan Pergaulan',
    question: 'Bagaimana lingkungan pertemanan Anda?',
    exampleAnswer: 'Saya bergaul dengan teman yang mendukung kegiatan positif. Saya menghormati semua orang, tetapi menjaga batas dari ajakan yang melanggar aturan.',
  ),
  AkpolPmkQuestion(
    number: 9,
    category: 'Keluarga dan Pergaulan',
    question: 'Pernahkah Anda terlibat konflik dengan teman? Bagaimana menyelesaikannya?',
    exampleAnswer: 'Saya pernah berbeda pendapat dengan teman. Saya mendengarkan alasannya, menyampaikan pendapat tanpa emosi, dan mencari jalan tengah yang mendukung tujuan bersama.',
  ),
  AkpolPmkQuestion(
    number: 10,
    category: 'Keluarga dan Pergaulan',
    question: ' Bagaimana sikap Anda jika teman mengajak melanggar aturan?',
    exampleAnswer: 'Saya akan menolak ajakan melanggar aturan, menjelaskan alasannya, dan bila perlu menjauh atau melapor melalui jalur yang tepat.',
  ),
  AkpolPmkQuestion(
    number: 11,
    category: 'Motivasi',
    question: ' Mengapa Anda ingin menjadi anggota Polri melalui Akpol?',
    exampleAnswer: 'Saya ingin menjadi prajurit karena ingin mengabdi, melayani masyarakat, menjaga keamanan, dan menjalankan tugas negara dengan disiplin serta tanggung jawab.',
  ),
  AkpolPmkQuestion(
    number: 12,
    category: 'Motivasi',
    question: ' Apa yang Anda pahami tentang tugas dan tanggung jawab anggota Polri?',
    exampleAnswer: 'Saya memahami Polri bertugas memelihara keamanan dan ketertiban, menegakkan hukum, serta memberikan perlindungan, pengayoman, dan pelayanan kepada masyarakat.',
  ),
  AkpolPmkQuestion(
    number: 13,
    category: 'Motivasi',
    question: ' Mengapa memilih Akpol, bukan jalur pendidikan atau pekerjaan lain?',
    exampleAnswer: 'Saya memilih Akpol karena ingin mendapatkan pendidikan kepemimpinan, akademik, karakter, dan profesi kepolisian secara terarah untuk menjadi perwira.',
  ),
  AkpolPmkQuestion(
    number: 14,
    category: 'Motivasi',
    question: ' Apa bentuk pengabdian yang ingin Anda lakukan kepada masyarakat?',
    exampleAnswer: 'Bentuk pengabdian yang ingin saya lakukan adalah melayani masyarakat secara adil, membantu menyelesaikan masalah sesuai hukum, dan menjaga kepercayaan publik.',
  ),
  AkpolPmkQuestion(
    number: 15,
    category: 'Motivasi',
    question: ' Apakah Anda siap ditempatkan di seluruh wilayah Indonesia? Jelaskan secara jujur.',
    exampleAnswer: 'Saya siap ditempatkan sesuai kebutuhan organisasi dan negara. Saya memahami bahwa pengabdian membutuhkan kemampuan beradaptasi dan kesiapan meninggalkan kenyamanan.',
  ),
  AkpolPmkQuestion(
    number: 16,
    category: 'Integritas',
    question: ' Apa arti integritas bagi Anda? Berikan contoh dalam kehidupan sehari-hari.',
    exampleAnswer: 'Bagi saya, integritas adalah kesesuaian antara ucapan, nilai, dan tindakan, termasuk tetap jujur ketika tidak ada yang mengawasi.',
  ),
  AkpolPmkQuestion(
    number: 17,
    category: 'Integritas',
    question: ' Pernahkah Anda berbohong? Apa yang terjadi dan bagaimana Anda memperbaikinya?',
    exampleAnswer: 'Saya pernah melakukan kesalahan berupa ... Saya tidak membenarkannya, sudah memperbaiki dampaknya, dan membuat langkah agar tidak mengulanginya.',
  ),
  AkpolPmkQuestion(
    number: 18,
    category: 'Integritas',
    question: ' Jika menemukan uang atau barang milik orang lain, apa tindakan Anda?',
    exampleAnswer: 'Saya akan menyerahkan barang atau uang tersebut kepada pemilik jika diketahui, atau kepada panitia/petugas yang berwenang, sambil menjelaskan tempat menemukannya.',
  ),
  AkpolPmkQuestion(
    number: 19,
    category: 'Integritas',
    question: ' Jika mengetahui teman menyontek atau memalsukan data, apa yang Anda lakukan?',
    exampleAnswer: 'Saya akan mengingatkan teman secara baik-baik. Jika tetap dilakukan dan menyangkut proses seleksi, saya akan melaporkan sesuai prosedur tanpa mempermalukannya.',
  ),
  AkpolPmkQuestion(
    number: 20,
    category: 'Integritas',
    question: ' Bagaimana sikap Anda jika ada orang yang menawarkan bantuan dengan imbalan agar lulus seleksi?',
    exampleAnswer: 'Saya akan menolak bantuan berimbalan karena seleksi harus berjalan jujur. Saya hanya menggunakan jalur resmi dan usaha saya sendiri.',
  ),
  AkpolPmkQuestion(
    number: 21,
    category: 'Kedisiplinan',
    question: ' Bagaimana kebiasaan Anda mengatur waktu?',
    exampleAnswer: 'Saya mengatur waktu dengan membuat daftar prioritas, jadwal harian, dan menyiapkan kebutuhan lebih awal agar kewajiban tidak tertunda.',
  ),
  AkpolPmkQuestion(
    number: 22,
    category: 'Kedisiplinan',
    question: ' Apa yang Anda lakukan jika terlambat karena kelalaian sendiri?',
    exampleAnswer: 'Saya akan mengakui keterlambatan, meminta maaf, menerima konsekuensi sesuai aturan, dan memperbaiki penyebabnya tanpa membuat alasan palsu.',
  ),
  AkpolPmkQuestion(
    number: 23,
    category: 'Kedisiplinan',
    question: ' Bagaimana Anda menyikapi perintah yang tidak Anda sukai tetapi sah dan sesuai aturan?',
    exampleAnswer: 'Jika perintah itu sah dan sesuai aturan, saya akan melaksanakannya dengan disiplin. Jika ada hal yang belum jelas, saya meminta klarifikasi dengan sopan.',
  ),
  AkpolPmkQuestion(
    number: 24,
    category: 'Kedisiplinan',
    question: ' Ceritakan pengalaman menjalankan tugas yang membutuhkan ketekunan.',
    exampleAnswer: 'Saya pernah menjalankan tugas ... yang membutuhkan ketekunan. Saya membaginya menjadi beberapa tahap dan menyelesaikannya sampai tuntas.',
  ),
  AkpolPmkQuestion(
    number: 25,
    category: 'Kedisiplinan',
    question: ' Bagaimana Anda menerima kritik dari guru, orang tua, atau atasan?',
    exampleAnswer: 'Saya mendengarkan kritik dengan terbuka, menanyakan bagian yang perlu diperbaiki, lalu menjadikannya bahan evaluasi, bukan alasan untuk bersikap defensif.',
  ),
  AkpolPmkQuestion(
    number: 26,
    category: 'Nilai Kebangsaan',
    question: ' Apa arti Pancasila bagi kehidupan Anda?',
    exampleAnswer: 'Pancasila menjadi pedoman saya untuk menghormati Tuhan, sesama manusia, persatuan, musyawarah, dan keadilan dalam kehidupan sehari-hari.',
  ),
  AkpolPmkQuestion(
    number: 27,
    category: 'Nilai Kebangsaan',
    question: ' Apa arti setia kepada NKRI?',
    exampleAnswer: 'Kesetiaan kepada NKRI berarti menjunjung Pancasila dan UUD 1945, menjaga persatuan, menaati hukum, serta mendahulukan kepentingan bangsa dan negara.',
  ),
  AkpolPmkQuestion(
    number: 28,
    category: 'Nilai Kebangsaan',
    question: ' Bagaimana cara menjaga persatuan di tengah perbedaan suku, agama, dan pendapat?',
    exampleAnswer: 'Saya menghormati perbedaan suku, agama, budaya, dan pendapat. Saya tidak memaksakan kehendak dan tetap bekerja sama untuk tujuan bersama.',
  ),
  AkpolPmkQuestion(
    number: 29,
    category: 'Nilai Kebangsaan',
    question: ' Bagaimana sikap Anda terhadap berita provokatif atau ujaran kebencian di media sosial?',
    exampleAnswer: 'Saya tidak langsung percaya atau menyebarkan berita provokatif. Saya memeriksa sumber resmi, menjaga bahasa, dan melaporkan konten berbahaya bila diperlukan.',
  ),
  AkpolPmkQuestion(
    number: 30,
    category: 'Nilai Kebangsaan',
    question: ' Apa arti pelayanan yang adil dan tidak diskriminatif?',
    exampleAnswer: 'Pelayanan yang adil berarti memberikan hak dan perlakuan sesuai aturan tanpa membedakan latar belakang, kedekatan, status, suku, atau agama.',
  ),
  AkpolPmkQuestion(
    number: 31,
    category: 'Skenario Pelayanan',
    question: ' Jika masyarakat marah karena merasa tidak dilayani dengan baik, bagaimana Anda merespons?',
    exampleAnswer: 'Saya akan tetap tenang, mendengarkan keluhan sampai selesai, meminta maaf bila ada kekurangan layanan, menjelaskan prosedur, dan mencari solusi sesuai kewenangan.',
  ),
  AkpolPmkQuestion(
    number: 32,
    category: 'Skenario Pelayanan',
    question: ' Jika atasan mengoreksi kesalahan Anda di depan orang lain, apa sikap Anda?',
    exampleAnswer: 'Saya akan menerima koreksi dengan hormat, meminta penjelasan bila perlu, memperbaiki kesalahan, dan tidak membalas dengan emosi.',
  ),
  AkpolPmkQuestion(
    number: 33,
    category: 'Skenario Pelayanan',
    question: ' Jika rekan kerja melakukan pelanggaran dan meminta Anda menutupinya, apa tindakan Anda?',
    exampleAnswer: 'Saya tidak akan menutupinya. Saya akan mengingatkan rekan tersebut dan melaporkan melalui mekanisme yang benar, terutama jika menyangkut keselamatan, hukum, atau integritas.',
  ),
  AkpolPmkQuestion(
    number: 34,
    category: 'Skenario Pelayanan',
    question: ' Jika keluarga meminta Anda menggunakan jabatan untuk kepentingan pribadi, bagaimana Anda menjawab?',
    exampleAnswer: 'Saya akan menjelaskan kepada keluarga bahwa jabatan tidak boleh digunakan untuk kepentingan pribadi. Saya akan membantu hanya melalui cara yang sah dan tidak merugikan orang lain.',
  ),
  AkpolPmkQuestion(
    number: 35,
    category: 'Skenario Pelayanan',
    question: ' Bagaimana Anda menjaga informasi yang bersifat rahasia?',
    exampleAnswer: 'Saya hanya menyampaikan informasi kepada pihak berwenang melalui saluran resmi. Saya tidak memotret atau menyebarkan data kedinasan yang bersifat rahasia.',
  ),
  AkpolPmkQuestion(
    number: 36,
    category: 'Skenario Pelayanan',
    question: ' Jika menghadapi masalah yang belum pernah Anda tangani, apa langkah pertama Anda?',
    exampleAnswer: 'Saya akan memahami masalah, memeriksa aturan atau prosedur, meminta arahan dari pihak yang berwenang, lalu mengambil tindakan yang dapat dipertanggungjawabkan.',
  ),
  AkpolPmkQuestion(
    number: 37,
    category: 'Skenario Pelayanan',
    question: ' Bagaimana Anda menyeimbangkan ketegasan dengan sikap humanis saat melayani masyarakat?',
    exampleAnswer: 'Saya akan tetap tegas pada aturan, tetapi menyampaikan keputusan dengan sopan, mendengarkan kondisi masyarakat, dan menghindari tindakan yang merendahkan.',
  ),
  AkpolPmkQuestion(
    number: 38,
    category: 'Refleksi',
    question: ' Nilai apa yang paling penting bagi seorang calon perwira? Mengapa?',
    exampleAnswer: 'Nilai yang penting adalah integritas karena kepercayaan masyarakat dibangun dari kejujuran, konsistensi, dan keberanian bertanggung jawab.',
  ),
  AkpolPmkQuestion(
    number: 39,
    category: 'Refleksi',
    question: ' Kebiasaan apa yang sedang Anda perbaiki sebelum mengikuti seleksi?',
    exampleAnswer: 'Kebiasaan yang sedang saya perbaiki adalah ... Saya memperbaikinya dengan target yang terukur, jadwal rutin, dan evaluasi berkala.',
  ),
  AkpolPmkQuestion(
    number: 40,
    category: 'Refleksi',
    question: ' Apa komitmen konkret Anda jika diterima di Akpol?',
    exampleAnswer: 'Jika diterima, saya berkomitmen belajar sungguh-sungguh, menjaga nama baik institusi, menaati aturan, melayani masyarakat, dan terus memperbaiki diri.',
  ),
];

const akpolPmkGuidance = [
  'Jawablah jujur dan konsisten dengan data administrasi.',
  'Gunakan contoh nyata: situasi, tindakan, dan hasil.',
  'Jangan mengarang, menutupi fakta material, atau menghafalkan jawaban orang lain.',
  'Sampaikan jawaban dengan singkat, jelas, sopan, dan tidak defensif.',
];

const akpolPmkChecklist = [
  'Saya memahami riwayat diri dan keluarga yang saya tulis.',
  'Saya dapat menjelaskan motivasi menjadi anggota Polri dengan jujur.',
  'Saya menyiapkan contoh integritas, disiplin, kerja sama, dan tanggung jawab.',
  'Saya memahami Pancasila, UUD 1945, NKRI, Bhinneka Tunggal Ika, dan tugas Polri.',
  'Saya tidak menyiapkan jawaban palsu atau menghafalkan cerita orang lain.',
];
