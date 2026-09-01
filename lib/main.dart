import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:url_launcher/url_launcher.dart';

import 'akpol_cat_data.dart';
import 'akpol_interview_data.dart';
import 'akpol_pmk_data.dart';
import 'tni_academic_data.dart';
import 'tni_tryout_data.dart';
import 'kedinasan_tiu_data.dart';
import 'kedinasan_tkp_data.dart';
import 'kedinasan_twk_data.dart';
import 'mental_ideology_data.dart';

const navy = Color(0xFF152B55);
const blue = Color(0xFF2E6FE8);
const orange = Color(0xFFFF9B42);

class LocalAccount {
  static String? name;
  static String? email;
  static String? password;
  static bool isPremium = false;

  static bool get isRegistered => email != null && password != null;
}

class LearningActivityStore extends ChangeNotifier {
  LearningActivityStore._();

  static final instance = LearningActivityStore._();
  final Map<DateTime, int> _minutesByDay = {};
  final Set<String> _completedMaterials = {};

  DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);

  int minutesFor(DateTime date) => _minutesByDay[_day(date)] ?? 0;

  int get completedMaterials => _completedMaterials.length;

  int get weekMinutes {
    return currentWeekMinutes.fold(0, (total, minutes) => total + minutes);
  }

  List<int> get currentWeekMinutes {
    final today = _day(DateTime.now());
    final start = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(
      7,
      (index) => minutesFor(start.add(Duration(days: index))),
    );
  }

  void recordLesson({
    required String course,
    required int lessonIndex,
    required int minutes,
  }) {
    final key = '$course#$lessonIndex';
    if (!_completedMaterials.add(key)) return;
    final today = _day(DateTime.now());
    _minutesByDay[today] = minutesFor(today) + minutes;
    notifyListeners();
  }
}

void main() => runApp(const EduKreativApp());

class EduKreativApp extends StatelessWidget {
  const EduKreativApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Edukreativ Nusantara',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: blue),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        fontFamily: 'Arial',
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Logo(size: 150),
            SizedBox(height: 18),
            Text(
              'Belajar dengan cara kreatif',
              style: TextStyle(color: navy, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      OfficialBooksPage(onBack: () => setState(() => index = 0)),
      const StorePage(),
      const ProfilePage(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Academy Kreativ',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Toko',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class StoreSellerProduct {
  final String title;
  final String category;
  final String price;
  String status;

  StoreSellerProduct({
    required this.title,
    required this.category,
    required this.price,
    this.status = 'Menunggu review',
  });
}

class StoreOrder {
  final String id;
  final List<String> products;
  final int total;
  final bool hasPhysicalItem;
  final String status;

  const StoreOrder({
    required this.id,
    required this.products,
    required this.total,
    required this.hasPhysicalItem,
    this.status = 'Menunggu pembayaran',
  });
}

class StoreOrderStore {
  static final List<StoreOrder> orders = [];
  static final List<String> ebookLibrary = [];
}

int storePriceValue(String price) {
  final digits = price.replaceAll(RegExp(r'[^0-9]'), '');
  return int.tryParse(digits) ?? 0;
}

typedef StoreProduct = ({
  String title,
  String subtitle,
  String price,
  String seller,
  IconData icon,
  String type,
});

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  int selectedTab = 0;
  final List<StoreProduct> cart = [];
  final List<StoreSellerProduct> sellerProducts = [
    StoreSellerProduct(
      title: 'Panduan Belajar Efektif',
      category: 'E-book',
      price: 'Rp25.000',
    ),
    StoreSellerProduct(
      title: 'Kumpulan Soal Kreativ',
      category: 'E-book',
      price: 'Rp30.000',
      status: 'Aktif',
    ),
  ];

  static const List<StoreProduct> products = [
    (
      title: 'E-book Strategi Belajar Efektif',
      subtitle: 'E-book · Panduan belajar mandiri',
      price: 'Rp25.000',
      seller: 'Kreativ Official',
      icon: Icons.menu_book,
      type: 'E-book',
    ),
    (
      title: 'Buku Saku Matematika Dasar',
      subtitle: 'Buku fisik · Ringkasan konsep dan latihan',
      price: 'Rp45.000',
      seller: 'Kreativ Press',
      icon: Icons.auto_stories,
      type: 'Buku',
    ),
    (
      title: 'Tumbler Edukreativ',
      subtitle: 'Souvenir · Tumbler edisi pelajar',
      price: 'Rp65.000',
      seller: 'Kreativ Official',
      icon: Icons.local_drink,
      type: 'Souvenir',
    ),
    (
      title: 'Paket Persiapan Ujian',
      subtitle: 'Paket belajar · Buku dan akses e-book',
      price: 'Rp85.000',
      seller: 'Kreativ Press',
      icon: Icons.inventory_2,
      type: 'Paket belajar',
    ),
  ];

  void showInfoDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  void showAddProductForm() {
    final titleController = TextEditingController();
    final priceController = TextEditingController();
    String category = 'E-book';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Ajukan produk'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Nama produk'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Jenis produk'),
                  items: ['E-book', 'Buku fisik', 'Souvenir']
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => category = value ?? category),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga',
                    prefixText: 'Rp ',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              key: const Key('simpan-pengajuan-produk'),
              onPressed: () {
                if (titleController.text.trim().isEmpty ||
                    priceController.text.trim().isEmpty) {
                  return;
                }
                setState(() {
                  sellerProducts.add(
                    StoreSellerProduct(
                      title: titleController.text.trim(),
                      category: category,
                      price: 'Rp${priceController.text.trim()}',
                    ),
                  );
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('Kirim review'),
            ),
          ],
        ),
      ),
    );
  }

  void showSellerGate() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Jualan di Toko Kreativ'),
        content: const Text(
          'Status premium diperlukan untuk membuka lapak dan mengajukan e-book. Aktivasi berikut hanya simulasi lokal untuk milestone ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Nanti'),
          ),
          FilledButton(
            onPressed: () {
              LocalAccount.isPremium = true;
              Navigator.pop(dialogContext);
              setState(() {});
            },
            child: const Text('Aktifkan demo premium'),
          ),
        ],
      ),
    );
  }

  Future<void> openProduct(StoreProduct product) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StoreProductDetailPage(product: product),
      ),
    );
    if (added == true && mounted) setState(() => cart.add(product));
  }

  Future<void> openCart() async {
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StoreCartPage(items: List.unmodifiable(cart)),
      ),
    );
    if (completed == true && mounted) {
      setState(cart.clear);
    }
  }

  void openOrders() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const StoreOrdersPage()));
  }

  void openLibrary() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const StoreLibraryPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Toko Kreativ',
                    key: Key('toko-kreativ-title'),
                    style: TextStyle(
                      color: navy,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('keranjang-toko'),
                  tooltip: 'Keranjang',
                  onPressed: openCart,
                  icon: Badge(
                    isLabelVisible: cart.isNotEmpty,
                    label: Text('${cart.length}'),
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      color: navy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Belanja kebutuhan belajar dan dukung karya komunitas Kreativ.',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('riwayat-pesanan'),
                    onPressed: openOrders,
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('Pesanan saya'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('perpustakaan-ebook'),
                    onPressed: openLibrary,
                    icon: const Icon(Icons.library_books_outlined),
                    label: const Text('E-book saya'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _StoreTab(
                    label: 'Belanja',
                    icon: Icons.shopping_bag_outlined,
                    selected: selectedTab == 0,
                    onTap: () => setState(() => selectedTab = 0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StoreTab(
                    label: 'Jualan',
                    icon: Icons.sell_outlined,
                    selected: selectedTab == 1,
                    onTap: () => setState(() => selectedTab = 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (selectedTab == 0) ...[
              const Text(
                'Produk pilihan',
                style: TextStyle(
                  color: navy,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ...products.map(
                (product) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _StoreProductCard(
                    product: product,
                    onTap: () => openProduct(product),
                  ),
                ),
              ),
            ] else if (LocalAccount.isPremium) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.workspace_premium, color: orange, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lapak Premium Kreativ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Status premium aktif · siap mengajukan produk.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                key: const Key('ajukan-produk-toko'),
                onPressed: showAddProductForm,
                icon: const Icon(Icons.add),
                label: const Text('Ajukan produk'),
              ),
              const SizedBox(height: 18),
              const Text(
                'Produk saya',
                style: TextStyle(
                  color: navy,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ...sellerProducts.map(
                (product) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SellerStatusTile(
                    title: product.title,
                    status: product.status,
                    color: product.status == 'Aktif' ? Colors.green : orange,
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, color: orange, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lapak Premium Kreativ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Aktifkan premium untuk mulai menjual e-book dan produk Kreativ.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                key: const Key('ajukan-produk-toko'),
                onPressed: showSellerGate,
                icon: const Icon(Icons.workspace_premium_outlined),
                label: const Text('Buka akses jualan'),
              ),
              const SizedBox(height: 18),
              const Text(
                'Ketentuan awal',
                style: TextStyle(
                  color: navy,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Produk akan ditinjau sebelum tampil. Pastikan e-book adalah karya sendiri atau memiliki izin distribusi.',
                style: TextStyle(color: Colors.black54, height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StoreTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _StoreTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: selected ? blue : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: selected ? Colors.white : navy, size: 19),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : navy,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

class _StoreProductCard extends StatelessWidget {
  final ({
    String title,
    String subtitle,
    String price,
    String seller,
    IconData icon,
    String type,
  })
  product;
  final VoidCallback onTap;

  const _StoreProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C152B55),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(product.icon, color: blue, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.type,
                  style: const TextStyle(
                    color: blue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  product.title,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Text(
                  product.price,
                  style: const TextStyle(
                    color: navy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'oleh ${product.seller}',
                  style: const TextStyle(color: Colors.black45, fontSize: 10),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.black38),
        ],
      ),
    ),
  );
}

class _SellerStatusTile extends StatelessWidget {
  final String title;
  final String status;
  final Color color;

  const _SellerStatusTile({
    required this.title,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        const Icon(Icons.description_outlined, color: blue),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: navy, fontWeight: FontWeight.bold),
          ),
        ),
        Text(
          status,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

class StoreProductDetailPage extends StatelessWidget {
  final StoreProduct product;

  const StoreProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FC),
    appBar: AppBar(
      title: const Text('Detail produk'),
      foregroundColor: navy,
      backgroundColor: const Color(0xFFF7F9FC),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          height: 170,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(product.icon, color: blue, size: 82),
        ),
        const SizedBox(height: 20),
        Text(
          product.type,
          style: const TextStyle(color: blue, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          product.title,
          key: const Key('detail-produk-toko'),
          style: const TextStyle(
            color: navy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(product.subtitle, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 14),
        Text(
          product.price,
          style: const TextStyle(
            color: navy,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Dijual oleh ${product.seller}',
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 24),
        const Text(
          'Deskripsi produk',
          style: TextStyle(
            color: navy,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Produk pilihan untuk mendukung perjalanan belajar. Detail, format, dan pengiriman akan dilengkapi pada tahap transaksi berikutnya.',
          style: TextStyle(color: Colors.black54, height: 1.4),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          key: const Key('tambah-ke-keranjang'),
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Tambah ke keranjang'),
        ),
      ],
    ),
  );
}

class StoreCartPage extends StatelessWidget {
  final List<StoreProduct> items;

  const StoreCartPage({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(
      0,
      (sum, item) => sum + storePriceValue(item.price),
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Keranjang'),
        foregroundColor: navy,
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: items.isEmpty
          ? const Center(child: Text('Keranjang masih kosong'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ...items.map(
                  (item) => Card(
                    child: ListTile(
                      leading: Icon(item.icon, color: blue),
                      title: Text(item.title),
                      subtitle: Text(item.price),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Total sementara: Rp$total',
                  key: const Key('total-keranjang'),
                  style: const TextStyle(
                    color: navy,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  key: const Key('checkout-demo'),
                  onPressed: () async {
                    final completed = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => StoreCheckoutPage(items: items),
                      ),
                    );
                    if (completed == true && context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: const Text('Lanjut checkout'),
                ),
              ],
            ),
    );
  }
}

class StoreCheckoutPage extends StatefulWidget {
  final List<StoreProduct> items;

  const StoreCheckoutPage({super.key, required this.items});

  @override
  State<StoreCheckoutPage> createState() => _StoreCheckoutPageState();
}

class _StoreCheckoutPageState extends State<StoreCheckoutPage> {
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  String shipping = 'Reguler · Rp10.000';

  @override
  void dispose() {
    addressController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void confirmOrder() {
    if (addressController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty) {
      return;
    }
    final subtotal = widget.items.fold<int>(
      0,
      (sum, item) => sum + storePriceValue(item.price),
    );
    final shippingCost = shipping.startsWith('Ekspres') ? 25000 : 10000;
    StoreOrderStore.orders.add(
      StoreOrder(
        id: 'ORD-${StoreOrderStore.orders.length + 1}',
        products: widget.items.map((item) => item.title).toList(),
        total: subtotal + shippingCost,
        hasPhysicalItem: widget.items.any((item) => item.type != 'E-book'),
      ),
    );
    for (final item in widget.items.where((item) => item.type == 'E-book')) {
      if (!StoreOrderStore.ebookLibrary.contains(item.title)) {
        StoreOrderStore.ebookLibrary.add(item.title);
      }
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pesanan dibuat'),
        content: const Text(
          'Status pesanan: Menunggu pembayaran. Ini masih checkout demo dan belum memproses pembayaran nyata.',
        ),
        actions: [
          FilledButton(
            key: const Key('tutup-konfirmasi-pesanan'),
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context, true);
            },
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.items.fold<int>(
      0,
      (sum, item) => sum + storePriceValue(item.price),
    );
    final shippingCost = shipping.startsWith('Ekspres') ? 25000 : 10000;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Checkout'),
        foregroundColor: navy,
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Alamat pengiriman',
            style: TextStyle(
              color: navy,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('alamat-checkout'),
            controller: addressController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Alamat lengkap',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('telepon-checkout'),
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Nomor telepon',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Metode pengiriman',
            style: TextStyle(
              color: navy,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: shipping,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(
                value: 'Reguler · Rp10.000',
                child: Text('Reguler · Rp10.000'),
              ),
              DropdownMenuItem(
                value: 'Ekspres · Rp25.000',
                child: Text('Ekspres · Rp25.000'),
              ),
            ],
            onChanged: (value) => setState(() => shipping = value ?? shipping),
          ),
          const SizedBox(height: 20),
          Text(
            'Subtotal: Rp$subtotal',
            style: const TextStyle(color: Colors.black54),
          ),
          Text(
            'Ongkir: Rp$shippingCost',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            'Total: Rp${subtotal + shippingCost}',
            key: const Key('total-checkout'),
            style: const TextStyle(
              color: navy,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            key: const Key('konfirmasi-pesanan'),
            onPressed: confirmOrder,
            child: const Text('Konfirmasi pesanan'),
          ),
        ],
      ),
    );
  }
}

class StoreOrdersPage extends StatelessWidget {
  const StoreOrdersPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FC),
    appBar: AppBar(
      title: const Text('Pesanan saya'),
      foregroundColor: navy,
      backgroundColor: const Color(0xFFF7F9FC),
    ),
    body: StoreOrderStore.orders.isEmpty
        ? const Center(child: Text('Belum ada pesanan'))
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: StoreOrderStore.orders.length,
            itemBuilder: (context, index) {
              final order = StoreOrderStore.orders.reversed.elementAt(index);
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt_long, color: blue),
                  title: Text(order.id),
                  subtitle: Text(
                    '${order.products.join(', ')}\nRp${order.total}',
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        order.status,
                        style: const TextStyle(color: orange, fontSize: 10),
                      ),
                      if (order.hasPhysicalItem)
                        const Text(
                          'Belum dikirim',
                          style: TextStyle(color: Colors.black45, fontSize: 10),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
  );
}

class StoreLibraryPage extends StatelessWidget {
  const StoreLibraryPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FC),
    appBar: AppBar(
      title: const Text('E-book saya'),
      foregroundColor: navy,
      backgroundColor: const Color(0xFFF7F9FC),
    ),
    body: StoreOrderStore.ebookLibrary.isEmpty
        ? const Center(child: Text('Belum ada e-book'))
        : ListView(
            padding: const EdgeInsets.all(20),
            children: StoreOrderStore.ebookLibrary
                .map(
                  (title) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.menu_book, color: blue),
                      title: Text(title),
                      subtitle: const Text('Tersedia di perpustakaan demo'),
                      trailing: const Icon(
                        Icons.play_circle_outline,
                        color: blue,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
  );
}

class ProgressPage extends StatefulWidget {
  final VoidCallback? onBack;

  const ProgressPage({super.key, this.onBack});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final activity = LearningActivityStore.instance;

  @override
  void initState() {
    super.initState();
    activity.addListener(_refresh);
  }

  @override
  void dispose() {
    activity.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final minutes = activity.currentWeekMinutes;
    final maxMinutes = minutes.fold<int>(
      0,
      (max, value) => value > max ? value : max,
    );
    final targetProgress = (activity.weekMinutes / 180).clamp(0.0, 1.0);
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  key: const Key('kembali-dari-progres'),
                  tooltip: 'Kembali ke Beranda',
                  onPressed: () {
                    if (widget.onBack != null) {
                      widget.onBack!();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
                const Expanded(
                  child: Text(
                    'Progres Kreativ',
                    style: TextStyle(
                      color: navy,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Lihat perkembangan belajarmu minggu ini.',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: navy,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 86,
                    height: 86,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 86,
                          height: 86,
                          child: CircularProgressIndicator(
                            value: targetProgress,
                            strokeWidth: 9,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation(orange),
                          ),
                        ),
                        Text(
                          '${(targetProgress * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Terus berkembang!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          activity.weekMinutes == 0
                              ? 'Belum ada aktivitas minggu ini. Yuk mulai belajar!'
                              : 'Kamu sudah belajar ${activity.weekMinutes} menit minggu ini.',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Aktivitas minggu ini',
              style: TextStyle(
                color: navy,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D152B55),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  for (var index = 0; index < 7; index++)
                    _ProgressBar(
                      day: days[index],
                      value: maxMinutes == 0 ? 0 : minutes[index] / maxMinutes,
                      minutes: '${minutes[index]} mnt',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Pencapaian terbaru',
              style: TextStyle(
                color: navy,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D152B55),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 23,
                    backgroundColor: Color(0xFFFFE8D4),
                    child: Icon(Icons.local_fire_department, color: orange),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Konsisten Kreativ',
                          style: TextStyle(
                            color: navy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Belajar 5 hari berturut-turut',
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final String day;
  final double value;
  final String minutes;

  const _ProgressBar({
    required this.day,
    required this.value,
    required this.minutes,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        SizedBox(
          width: 34,
          child: Text(
            day,
            style: const TextStyle(
              color: navy,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 9,
              backgroundColor: const Color(0xFFE7ECF7),
              valueColor: const AlwaysStoppedAnimation(blue),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 43,
          child: Text(
            minutes,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.black54, fontSize: 10),
          ),
        ),
      ],
    ),
  );
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = LocalAccount.name ?? 'Pelajar Kreativ';
  String email = LocalAccount.email ?? 'Belum masuk';
  bool notificationsEnabled = true;

  Future<void> editProfile() async {
    final controller = TextEditingController(
      text: name == 'Pelajar Kreativ' ? '' : name,
    );
    final updatedName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit profil'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nama panggilan',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (updatedName != null && updatedName.isNotEmpty && mounted) {
      LocalAccount.name = updatedName;
      setState(() => name = updatedName);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.')),
      );
    }
    Future<void>.delayed(const Duration(milliseconds: 300), controller.dispose);
  }

  void showAccountData() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Data diri'),
        content: Text('Nama: $name\\nEmail: $email'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              editProfile();
            },
            child: const Text('Edit profil'),
          ),
        ],
      ),
    );
  }

  void showNotifications() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Notifikasi belajar'),
          content: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Pengingat belajar'),
            subtitle: const Text('Dapatkan pengingat untuk sesi belajarmu'),
            value: notificationsEnabled,
            onChanged: (value) {
              setDialogState(() {});
              setState(() => notificationsEnabled = value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Selesai'),
            ),
          ],
        ),
      ),
    );
  }

  void showInfo(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profil saya',
            style: TextStyle(
              color: navy,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.person, color: navy, size: 34),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        email,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: editProfile,
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  tooltip: 'Edit profil',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ProfileMenuTile(
            icon: Icons.insights_outlined,
            title: 'Progres',
            subtitle: 'Lihat perkembangan belajar minggu ini',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ProgressPage())),
          ),
          const SizedBox(height: 16),
          const _DailyTargetCard(),
          const SizedBox(height: 24),
          Row(
            children: const [
              Expanded(
                child: _ProfileStat(value: '12', label: 'Materi selesai'),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _ProfileStat(value: '8', label: 'Jam belajar'),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _ProfileStat(value: '5', label: 'Lencana'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Pengaturan akun',
            style: TextStyle(
              color: navy,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _ProfileMenuTile(
            icon: Icons.person_outline,
            title: 'Data diri',
            subtitle: 'Kelola informasi profilmu',
            onTap: showAccountData,
          ),
          const SizedBox(height: 10),
          _ProfileMenuTile(
            icon: Icons.notifications_none,
            title: 'Notifikasi',
            subtitle: 'Atur pengingat belajar',
            onTap: showNotifications,
          ),
          const SizedBox(height: 10),
          _ProfileMenuTile(
            icon: Icons.workspace_premium_outlined,
            title: 'Langganan Kreativ',
            subtitle: 'Lihat pilihan akses premium',
            onTap: () => showInfo(
              'Langganan Kreativ',
              'Pilih akses premium untuk membuka materi dan fitur belajar lebih lengkap.',
            ),
          ),
          const SizedBox(height: 10),
          _ProfileMenuTile(
            icon: Icons.help_outline,
            title: 'Pusat bantuan',
            subtitle: 'Temukan jawaban yang kamu butuhkan',
            onTap: () => showInfo(
              'Pusat bantuan',
              'Kamu dapat menghubungi tim Edukreativ melalui menu bantuan.',
            ),
          ),
          const SizedBox(height: 10),
          _ProfileMenuTile(
            icon: Icons.login,
            title: 'Masuk atau daftar',
            subtitle: 'Simpan progres belajar di akunmu',
            onTap: () async {
              final loggedIn = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
              if (loggedIn == true && mounted) {
                setState(() {
                  name = LocalAccount.name ?? name;
                  email = LocalAccount.email ?? email;
                });
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;

  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D152B55),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: blue,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54, fontSize: 10),
        ),
      ],
    ),
  );
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: blue.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: blue, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: navy,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.black54, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    ),
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void submit() {
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi email dan kata sandi dulu.')),
      );
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan alamat email yang valid.')),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kata sandi minimal 6 karakter.')),
      );
      return;
    }
    if (!LocalAccount.isRegistered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun belum terdaftar. Silakan daftar dulu.'),
        ),
      );
      return;
    }
    if (email.toLowerCase() != LocalAccount.email!.toLowerCase() ||
        password != LocalAccount.password) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email atau kata sandi salah.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Berhasil masuk ke akun Kreativ.')),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Masuk'),
        foregroundColor: navy,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: _Logo(size: 78)),
            const SizedBox(height: 22),
            const Text(
              'Selamat datang kembali!',
              style: TextStyle(
                color: navy,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Masuk untuk melanjutkan perjalanan Kreativ-mu.',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 26),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'nama@email.com',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: 'Kata sandi',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => obscurePassword = !obscurePassword),
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text('Lupa kata sandi?'),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: submit,
                style: FilledButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: navy,
                ),
                child: const Text(
                  'Masuk ke akun',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: const [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('atau', style: TextStyle(color: Colors.black45)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const RegisterPage())),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Buat akun baru'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool obscurePassword = true;
  bool obscureConfirm = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  void register() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirm = confirmController.text;
    String? message;
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      message = 'Lengkapi semua data terlebih dahulu.';
    } else if (!email.contains('@') || !email.contains('.')) {
      message = 'Masukkan alamat email yang valid.';
    } else if (password.length < 6) {
      message = 'Kata sandi minimal 6 karakter.';
    } else if (password != confirm) {
      message = 'Konfirmasi kata sandi belum sama.';
    }
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    LocalAccount.name = name;
    LocalAccount.email = email.toLowerCase();
    LocalAccount.password = password;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Akun berhasil dibuat'),
        content: Text('Selamat datang di Edukreativ, $name!'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('Mulai Kreativ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat akun'), foregroundColor: navy),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mulai perjalanan Kreativ-mu',
              style: TextStyle(
                color: navy,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Buat akun untuk menyimpan progres dan lencana belajarmu.',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nama lengkap',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'nama@email.com',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Kata sandi',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => obscurePassword = !obscurePassword),
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: confirmController,
              obscureText: obscureConfirm,
              onSubmitted: (_) => register(),
              decoration: InputDecoration(
                labelText: 'Konfirmasi kata sandi',
                prefixIcon: const Icon(Icons.verified_user_outlined),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => obscureConfirm = !obscureConfirm),
                  icon: Icon(
                    obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: register,
                style: FilledButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: navy,
                ),
                child: const Text(
                  'Buat akun',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Sudah punya akun? Masuk'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, Pelajar Kreativ!',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Mau belajar apa hari ini?',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: navy,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Notifikasi',
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Notifikasi Kreativ'),
                    content: const Text(
                      'Kamu punya 2 pengingat belajar hari ini. Jangan lupa lanjutkan sesi Kreativ-mu, ya!',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Tutup'),
                      ),
                    ],
                  ),
                ),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none, color: navy),
                    Positioned(
                      right: -2,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Text(
                          '2',
                          style: TextStyle(
                            color: navy,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Temukan cara belajar yang Kreativ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      const SizedBox(height: 14),
                      ActionChip(
                        label: const Text(
                          'Mulai jelajah',
                          style: TextStyle(color: navy),
                        ),
                        backgroundColor: orange,
                        onPressed: () => showModalBottomSheet<void>(
                          context: context,
                          showDragHandle: true,
                          builder: (sheetContext) {
                            final methods =
                                <
                                  ({
                                    IconData icon,
                                    String title,
                                    String subtitle,
                                  })
                                >[
                                  (
                                    icon: Icons.flag_outlined,
                                    title: 'Belajar dengan Misi',
                                    subtitle: 'Selesaikan target kecil secara bertahap.',
                                  ),
                                  (
                                    icon: Icons.auto_stories_outlined,
                                    title: 'Belajar melalui Cerita',
                                    subtitle: 'Pahami konsep lewat kisah dan konteks.',
                                  ),
                                  (
                                    icon: Icons.timer_outlined,
                                    title: 'Simulasi Ujian',
                                    subtitle: 'Berlatih dengan suasana ujian sebenarnya.',
                                  ),
                                  (
                                    icon: Icons.today_outlined,
                                    title: 'Tantangan Harian',
                                    subtitle: 'Bangun konsistensi lewat tantangan singkat.',
                                  ),
                                  (
                                    icon: Icons.style_outlined,
                                    title: 'Flashcard Pintar',
                                    subtitle: 'Kuasai istilah, rumus, dan konsep penting.',
                                  ),
                                  (
                                    icon: Icons.tune_outlined,
                                    title: 'Latihan Adaptif',
                                    subtitle: 'Soal menyesuaikan kemampuanmu.',
                                  ),
                                  (
                                    icon: Icons.psychology_outlined,
                                    title: 'Belajar Berbasis Kasus',
                                    subtitle: 'Latih keputusan melalui situasi nyata.',
                                  ),
                                  (
                                    icon: Icons.play_circle_outline,
                                    title: 'Video Interaktif',
                                    subtitle: 'Tonton, jawab, dan pahami secara aktif.',
                                  ),
                                  (
                                    icon: Icons.groups_outlined,
                                    title: 'Belajar dengan Teman',
                                    subtitle: 'Tumbuh bersama melalui diskusi terarah.',
                                  ),
                                  (
                                    icon: Icons.edit_note_outlined,
                                    title: 'Refleksi & Jurnal Belajar',
                                    subtitle:
                                        'Catat pemahaman dan target belajarmu.',
                                  ),
                                  (
                                    icon: Icons.route_outlined,
                                    title: 'Peta Kemajuan',
                                    subtitle: 'Lihat perjalanan dan pencapaian belajarmu.',
                                  ),
                                  (
                                    icon: Icons.auto_awesome_outlined,
                                    title: 'Tutor Kreativ',
                                    subtitle: 'Dapatkan penjelasan dengan gaya pilihanmu.',
                                  ),
                                ];
                            return SafeArea(
                              child: Container(
                                height:
                                    MediaQuery.sizeOf(sheetContext).height *
                                    0.78,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF10254D),
                                      Color(0xFF07142F),
                                    ],
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    8,
                                    18,
                                    18,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: orange.withValues(
                                                alpha: 0.18,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: const Icon(
                                              Icons.auto_awesome,
                                              color: orange,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Temukan cara belajar',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 21,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                SizedBox(height: 3),
                                                Text(
                                                  'Pilih pengalaman belajar Kreativ-mu',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 18),
                                      Expanded(
                                        child: ListView.separated(
                                          padding: EdgeInsets.zero,
                                          itemCount: methods.length,
                                          separatorBuilder: (context, index) =>
                                              const SizedBox(height: 9),
                                          itemBuilder: (_, index) {
                                            final method = methods[index];
                                            return Material(
                                              color: Colors.white.withValues(
                                                alpha: 0.08,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(17),
                                              child: ListTile(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 4,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(17),
                                                ),
                                                leading: CircleAvatar(
                                                  backgroundColor: orange,
                                                  foregroundColor: navy,
                                                  child: Text(
                                                    '${index + 1}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                                title: Text(
                                                  method.title,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  method.subtitle,
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                                trailing: Icon(
                                                  method.icon,
                                                  color: orange,
                                                ),
                                                onTap: () {
                                                  Navigator.pop(sheetContext);
                                                  if (index >= 3) {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            const MissionSeriesPage(),
                                                      ),
                                                    );
                                                    return;
                                                  }
                                                  if (index == 2) {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            const ExamSimulationPage(),
                                                      ),
                                                    );
                                                    return;
                                                  }
                                                  if (index == 1) {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            const StoryLearningPage(),
                                                      ),
                                                    );
                                                    return;
                                                  }
                                                  if (index != 0) return;
                                                  showModalBottomSheet<void>(
                                                    context: context,
                                                    showDragHandle: true,
                                                    builder: (targetContext) => SafeArea(
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.fromLTRB(
                                                              20,
                                                              8,
                                                              20,
                                                              24,
                                                            ),
                                                        child: SingleChildScrollView(
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              const Text(
                                                                'Pilih target belajar',
                                                                style: TextStyle(
                                                                  color: navy,
                                                                  fontSize: 21,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                height: 6,
                                                              ),
                                                              const Text(
                                                                'Misi akan disesuaikan dengan kebutuhanmu.',
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .black54,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                height: 14,
                                                              ),
                                                              ListTile(
                                                                leading: const CircleAvatar(
                                                                  backgroundColor:
                                                                      navy,
                                                                  foregroundColor:
                                                                      orange,
                                                                  child: Icon(
                                                                    Icons
                                                                        .school_outlined,
                                                                  ),
                                                                ),
                                                                title: const Text(
                                                                  'SMA/SMK & Persiapan Seleksi',
                                                                  style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                  ),
                                                                ),
                                                                subtitle:
                                                                    const Text(
                                                                      'Target utama Edukreativ',
                                                                    ),
                                                                trailing:
                                                                    const Icon(
                                                                      Icons
                                                                          .chevron_right,
                                                                    ),
                                                                onTap: () {
                                                                  Navigator.pop(
                                                                    targetContext,
                                                                  );
                                                                  Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder: (
                                                                        _,
                                                                      ) => const MissionJourneyPage(),
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                              ListTile(
                                                                leading: const CircleAvatar(
                                                                  backgroundColor:
                                                                      blue,
                                                                  foregroundColor:
                                                                      Colors
                                                                          .white,
                                                                  child: Icon(
                                                                    Icons
                                                                        .auto_stories_outlined,
                                                                  ),
                                                                ),
                                                                title: const Text(
                                                                  'SMP',
                                                                  style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                  ),
                                                                ),
                                                                subtitle:
                                                                    const Text(
                                                                      'Bangun fondasi dan kebiasaan belajar',
                                                                    ),
                                                                trailing:
                                                                    const Icon(
                                                                      Icons
                                                                          .chevron_right,
                                                                    ),
                                                                onTap: () {
                                                                  Navigator.pop(
                                                                    targetContext,
                                                                  );
                                                                  Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder: (_) =>
                                                                          const MissionJourneyPage(
                                                                            target: 'SMP',
                                                                          ),
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                              ListTile(
                                                                leading: const CircleAvatar(
                                                                  backgroundColor:
                                                                      orange,
                                                                  foregroundColor:
                                                                      navy,
                                                                  child: Icon(
                                                                    Icons
                                                                        .emoji_objects_outlined,
                                                                  ),
                                                                ),
                                                                title: const Text(
                                                                  'SD',
                                                                  style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                  ),
                                                                ),
                                                                subtitle:
                                                                    const Text(
                                                                      'Belajar aktif, seru, dan penuh eksplorasi',
                                                                    ),
                                                                trailing:
                                                                    const Icon(
                                                                      Icons
                                                                          .chevron_right,
                                                                    ),
                                                                onTap: () {
                                                                  Navigator.pop(
                                                                    targetContext,
                                                                  );
                                                                  Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder: (_) =>
                                                                          const MissionJourneyPage(
                                                                            target: 'SD',
                                                                          ),
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const _Logo(size: 64),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _HomeAnimatedSection(
            index: 0,
            child: _CreativeMenuCards(
              onTap: (title) {
              if (title == 'Cerita Kreativ') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StoryCreativePage()),
                );
                return;
              }
              if (title == 'GURU KREATIV JOIN US') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreativeTeacherJoinPage(),
                  ),
                );
                return;
              }
              _showCreativeMenuDialog(context, title);
            },
          ),
        ),
          const SizedBox(height: 14),
          _HomeAnimatedSection(
            index: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _UtbkFeatureCard(
                      category: 'KELAS ONLINE RUTIN',
                      title: 'LiveClass',
                      description:
                          'Belajar online bersama pengajar profesional dan berpengalaman.',
                      tags: 'Live · Profesional · Rutin',
                      actionLabel: 'Lihat jadwal',
                      icon: Icons.ondemand_video_outlined,
                      color: const Color(0xFFD84B78),
                      backgroundColor: const Color(0xFFFFE8F0),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const UtbkLiveClassPage(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _TeacherJoinCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CreativeTeacherJoinPage(),
                        ),
                      ),
                    ),
                  ],
                );
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          _HomeAnimatedSection(
            index: 2,
            child: _KedinasanMenuCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const KedinasanPage()),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const _HomeAnimatedSection(index: 2, child: _PreparationMenuRow()),
          const SizedBox(height: 25),
          _HomeAnimatedSection(
            index: 3,
            child: _RecommendationCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UtbkPage()),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const _HomeAnimatedSection(
            index: 4,
            child: _SiapUtbkCountdownCard(),
          ),
          const SizedBox(height: 14),
          _HomeAnimatedSection(
            index: 5,
            child: _UtbkFeatureCard(
              category: 'SMART PLAYBOOK',
              title: 'Strategi UTBK Terarah (PREMIUM MEMBER)',
              description:
                  'Taktik sesuai masalah belajar, target skor, dan subtes prioritas.',
              tags: 'Taktik · Roadmap · Target',
              actionLabel: 'Pilih strategi',
              icon: Icons.track_changes_outlined,
              color: const Color(0xFFE38A2D),
              backgroundColor: const Color(0xFFFFF2DF),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UtbkStrategyPage()),
              ),
            ),
          ),
          const SizedBox(height: 25),
          _HomeAnimatedSection(
            index: 6,
            child: _CreativeRoomCard(
              onOpenKarya: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreativeWorksPage()),
              ),
              onOpenInspirasi: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CreativeInspirationPage(),
                ),
              ),
              onOpenJurnal: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreativeJournalPage()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeAnimatedSection extends StatefulWidget {
  final int index;
  final Widget child;

  const _HomeAnimatedSection({required this.index, required this.child});

  @override
  State<_HomeAnimatedSection> createState() => _HomeAnimatedSectionState();
}

class _HomeAnimatedSectionState extends State<_HomeAnimatedSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    _startTimer = Timer(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) {
      final value = Curves.easeOutCubic.transform(_controller.value);
      return Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: child,
        ),
      );
    },
  );
}

class _SiapUtbkCountdownCard extends StatefulWidget {
  const _SiapUtbkCountdownCard();

  @override
  State<_SiapUtbkCountdownCard> createState() => _SiapUtbkCountdownCardState();
}

class _SiapUtbkCountdownCardState extends State<_SiapUtbkCountdownCard> {
  static final examDate = DateTime(2027, 3, 1);
  late Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  int get daysLeft =>
      (examDate.difference(DateTime.now()).inSeconds / 86400)
          .ceil()
          .clamp(0, 99999)
          .toInt();

  int get weeksLeft => (daysLeft / 7).ceil();

  int get monthsLeft {
    final now = DateTime.now();
    final value =
        (examDate.year - now.year) * 12 + examDate.month - now.month;
    final dayFraction = (examDate.day - now.day) / 31;
    return (value + dayFraction).ceil().clamp(0, 999).toInt();
  }

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: const Color(0xFFE9F1FF),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: blue.withValues(alpha: .16)),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HITUNG MUNDUR UTBK 2027',
            style: TextStyle(
              color: blue,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Senin, 1 Maret 2027',
            style: TextStyle(
              color: navy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _CountdownValue(value: daysLeft, label: 'hari'),
              const SizedBox(width: 8),
              _CountdownValue(value: weeksLeft, label: 'minggu'),
              const SizedBox(width: 8),
              _CountdownValue(value: monthsLeft, label: 'bulan'),
            ],
          ),
        ],
      ),
    ),
  );
}

class _CountdownValue extends StatelessWidget {
  final int value;
  final String label;

  const _CountdownValue({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(
              color: navy,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    ),
  );
}

class UtbkPage extends StatelessWidget {
  const UtbkPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('SIAP UTBK'), foregroundColor: navy),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        const Text(
          'Semua kebutuhan UTBK, dalam satu halaman',
          style: TextStyle(
            color: navy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pilih ruang belajar sesuai kebutuhanmu hari ini.',
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
        const SizedBox(height: 18),
        _UtbkFeatureCard(
          category: 'DRILL HARIAN',
          title: 'Latihan Soal',
          description:
              'Drill singkat per subtest dan topik, nyaman dipakai di HP.',
          tags: 'Mobile · Fokus · Praktis',
          actionLabel: 'Mulai latihan',
          icon: Icons.assignment_outlined,
          color: const Color(0xFF2E9B68),
          backgroundColor: const Color(0xFFE8F7EE),
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const UtbkPracticePage())),
        ),
        const SizedBox(height: 12),
        _UtbkFeatureCard(
          category: 'SIMULASI UJIAN',
          title: 'Try Out CBT',
          description: 'Uji kesiapan dengan timer, navigator, dan pengalaman ujian nyata.',
          tags: 'Timer · Navigator · Hasil',
          actionLabel: 'Pilih paket CBT',
          icon: Icons.computer_outlined,
          color: blue,
          backgroundColor: const Color(0xFFEAF1FF),
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const UtbkTryoutPage())),
        ),
        const SizedBox(height: 12),
        _UtbkFeatureCard(
          category: 'CONCEPT MASTERY',
          title: 'Materi UTBK Lengkap',
          description: 'Konsep inti, contoh, jebakan umum, dan materi 7 subtes terstruktur.',
          tags: 'Lengkap · Bertahap · HOTS',
          actionLabel: 'Buka materi',
          icon: Icons.menu_book_outlined,
          color: const Color(0xFF8357C7),
          backgroundColor: const Color(0xFFF2EAFE),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const UtbkMateriHubMobilePage()),
          ),
        ),
        const SizedBox(height: 12),
        _UtbkFeatureCard(
          category: 'SMART PLAYBOOK',
          title: 'Strategi UTBK Terarah',
          description: 'Taktik sesuai masalah belajar, target skor, dan subtes prioritas.',
          tags: 'Taktik · Roadmap · Target',
          actionLabel: 'Pilih strategi',
          icon: Icons.track_changes_outlined,
          color: const Color(0xFFE38A2D),
          backgroundColor: const Color(0xFFFFF2DF),
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const UtbkStrategyPage())),
        ),
        const SizedBox(height: 12),
        _UtbkFeatureCard(
          category: 'PERSONAL TRACKER',
          title: 'Progress Belajar',
          description:
              'Pantau kesiapan, analisa hasil, topik lemah, dan targetmu.',
          tags: 'Analisa · Tracker · Personal',
          actionLabel: 'Lihat progress',
          icon: Icons.insights_outlined,
          color: const Color(0xFF168C87),
          backgroundColor: const Color(0xFFE4F7F4),
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const UtbkProgressPage())),
        ),
      ],
    ),
  );
}

class _UtbkFeatureCard extends StatelessWidget {
  final String category;
  final String title;
  final String description;
  final String tags;
  final String actionLabel;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _UtbkFeatureCard({
    required this.category,
    required this.title,
    required this.description,
    required this.tags,
    required this.actionLabel,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: backgroundColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: BorderSide(color: color.withValues(alpha: .16)),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: .8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white.withValues(alpha: .8),
                  child: Icon(icon, color: color, size: 27),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.black54,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: color),
              ],
            ),
            const SizedBox(height: 14),
            Divider(color: color.withValues(alpha: .16), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    tags,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  actionLabel,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class UtbkTryoutPage extends StatelessWidget {
  const UtbkTryoutPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Try Out CBT'), foregroundColor: navy),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        const Text(
          'TRY OUT UTBK',
          style: TextStyle(
            color: blue,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Paket Try Out',
          style: TextStyle(
            color: navy,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Pilih paket CBT dan ukur kesiapan UTBK kamu.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: Card(
            elevation: 0,
            color: const Color(0xFFEAF1FF),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                children: [
                  Text(
                    '9',
                    style: TextStyle(
                      color: navy,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'paket siap',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pilih paket CBT',
          style: TextStyle(
            color: navy,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Kerjakan simulasi UTBK dengan timer dan navigator soal.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        const Text(
          'Try Out tersedia',
          style: TextStyle(
            color: navy,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Paket lengkap dan latihan per subtes.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            FilterChip(label: Text('Semua'), selected: true, onSelected: null),
            FilterChip(label: Text('Try Out Lengkap'), onSelected: null),
            FilterChip(label: Text('Per Subtes'), onSelected: null),
            FilterChip(label: Text('2025'), onSelected: null),
            FilterChip(label: Text('2024'), onSelected: null),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: const Color(0xFFEAF1FF),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Try Out UTBK Lengkap',
                  style: TextStyle(
                    color: navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '153 soal · 3j 50m · Simulasi lengkap UTBK',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    Chip(label: Text('7 Subtes')),
                    Chip(label: Text('Timer')),
                    Chip(label: Text('Published')),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => UtbkRealCbtPage()),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Mulai Try Out →'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Paket per subtes',
          style: TextStyle(
            color: navy,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        ...const [
          ('PU', 'Penalaran Umum', '30 soal · 45 mnt · 2025'),
          ('PPU', 'Pengetahuan dan Pemahaman Umum', '20 soal · 35 mnt · 2025'),
          ('PBM', 'Pemahaman Bacaan dan Menulis', '20 soal · 35 mnt · 2025'),
          ('PK', 'Pengetahuan Kuantitatif', '20 soal · 35 mnt · 2025'),
          ('LBI', 'Literasi Bahasa Indonesia', '30 soal · 45 mnt · 2025'),
          ('LBE', 'Literasi Bahasa Inggris', '20 soal · 35 mnt · 2025'),
          ('PM', 'Penalaran Matematika', '20 soal · 35 mnt · 2025'),
        ].map(
          (pack) => Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFEAF1FF),
                child: Text(
                  pack.$1,
                  style: const TextStyle(
                    color: blue,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              title: Text(
                pack.$2,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(pack.$3),
              trailing: const Icon(Icons.chevron_right, color: blue),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => UtbkRealCbtPage(initialSubject: pack.$2))),
            ),
          ),
        ),
        const Text(
          'Paket lainnya akan muncul setelah dipublikasikan dari admin.',
          style: TextStyle(color: Colors.black54),
        ),
      ],
    ),
  );
}

class UtbkMateriMobilePage extends StatefulWidget {
  const UtbkMateriMobilePage({super.key});

  @override
  State<UtbkMateriMobilePage> createState() => _UtbkMateriMobilePageState();
}

class _UtbkMateriMobilePageState extends State<UtbkMateriMobilePage> {
  static const subtests = ['PU', 'PPU', 'PBM', 'PK', 'LBI', 'LBE', 'PM'];
  String active = 'PU';
  String level = 'Semua tingkat';
  String query = '';
  bool hotsOpen = true;
  bool answerOpen = false;

  final topics = const [
    ('01', 'Bahasa Buatan dan Pola Bilangan', 'Prioritas sedang', 'Menengah'),
    ('02', 'Penalaran Logis', 'Prioritas sedang', 'Menengah'),
    ('03', 'Analisis Informasi', 'Prioritas rendah', 'Dasar'),
    ('04', 'Pola dan Kesimpulan', 'Prioritas tinggi', 'Lanjutan'),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = topics
        .where((topic) => topic.$2.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Materi UTBK'),
        foregroundColor: navy,
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.search))],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          const Text(
            'Daftar materi',
            style: TextStyle(
              color: navy,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pilih topik untuk melihat konsep inti dan lanjut ke modul lengkap.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _stat('4', 'materi tersedia'),
              const SizedBox(width: 8),
              _stat('0', 'prioritas tinggi'),
              const SizedBox(width: 8),
              _stat('1', 'tingkat belajar'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Buka Concept Mastery →'),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Subtes',
            style: TextStyle(
              color: navy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: subtests.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, index) => ChoiceChip(
                label: Text(subtests[index]),
                selected: active == subtests[index],
                selectedColor: blue,
                labelStyle: TextStyle(
                  color: active == subtests[index] ? Colors.white : navy,
                  fontWeight: FontWeight.w800,
                ),
                onSelected: (_) => setState(() => active = subtests[index]),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '4 topik',
                  style: TextStyle(
                    color: navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DropdownButton<String>(
                value: level,
                items: const [
                  DropdownMenuItem(
                    value: 'Semua tingkat',
                    child: Text('Semua tingkat'),
                  ),
                  DropdownMenuItem(value: 'Dasar', child: Text('Dasar')),
                  DropdownMenuItem(value: 'Menengah', child: Text('Menengah')),
                  DropdownMenuItem(value: 'Lanjutan', child: Text('Lanjutan')),
                ],
                onChanged: (value) => setState(() => level = value!),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Cari materi atau topik...',
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => setState(() => query = ''),
                      icon: const Icon(Icons.clear),
                    ),
            ),
            onChanged: (value) => setState(() => query = value),
          ),
          const SizedBox(height: 14),
          ...visible.map((topic) => _topicCard(topic)),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Materi tidak ditemukan.')),
            ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Expanded(
    child: Card(
      elevation: 0,
      color: const Color(0xFFEAF1FF),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: navy,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 10),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _topicCard((String, String, String, String) topic) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    child: ExpansionTile(
      initiallyExpanded: topic.$1 == '01',
      tilePadding: const EdgeInsets.symmetric(horizontal: 14),
      title: Text(
        '${topic.$1}  ${topic.$2}',
        style: const TextStyle(color: navy, fontWeight: FontWeight.w800),
      ),
      subtitle: Wrap(
        spacing: 6,
        children: [
          Chip(label: Text(topic.$3, style: const TextStyle(fontSize: 10))),
          Chip(label: Text(topic.$4, style: const TextStyle(fontSize: 10))),
        ],
      ),
      children: [
        Card(
          color: const Color(0xFFF1F5FF),
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    '01  Soal HOTS',
                    style: TextStyle(color: navy, fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text('5 latihan HOTS dari modul'),
                  trailing: IconButton(
                    icon: Icon(hotsOpen ? Icons.remove : Icons.add),
                    onPressed: () => setState(() => hotsOpen = !hotsOpen),
                  ),
                ),
                if (hotsOpen) ...[
                  const Chip(label: Text('HOTS 1')),
                  const Text(
                    'Bahasa buatan dengan penanda waktu dan objek',
                    style: TextStyle(color: navy, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Dalam bahasa buatan, setiap awalan dan akhiran memiliki arti tertentu. Tentukan bentuk yang paling tepat berdasarkan pola yang diberikan.',
                    style: TextStyle(height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  ...[
                    'pa-ta-ra-kin-na',
                    'ta-pa-ra-na-kin',
                    'pa-ra-ta-kin-pa',
                    'ta-ra-pa-kin-na',
                    'pa-ta-so-kin-na',
                  ].asMap().entries.map(
                    (entry) => Container(
                      margin: const EdgeInsets.only(bottom: 7),
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${String.fromCharCode(65 + entry.key)}.  ${entry.value}',
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => answerOpen = !answerOpen),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            answerOpen
                                ? Icons.keyboard_arrow_down
                                : Icons.chevron_right,
                            color: const Color(0xFF8357C7),
                          ),
                          const Text(
                            'Lihat kunci & alasan',
                            style: TextStyle(
                              color: Color(0xFF8357C7),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (answerOpen)
                    const Text(
                      'Kunci dan alasan akan mengikuti pembahasan dari bank soal backend.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {},
                      child: const Text('Tampilkan 5 soal HOTS'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        ListTile(
          title: const Text('02  Penjelasan singkat'),
          subtitle: const Text('Ringkasan inti topik'),
          trailing: const Icon(Icons.add),
        ),
        ListTile(
          title: const Text('03  Yang harus dipahami'),
          trailing: const Icon(Icons.add),
        ),
      ],
    ),
  );
}

class UtbkMateriHubMobilePage extends StatelessWidget {
  const UtbkMateriHubMobilePage({super.key});

  static const data = <(String, String, int, String)>[
    (
      'PU',
      'Penalaran Umum',
      4,
      'Logika, argumen, simpulan, dan pola penalaran.',
    ),
    (
      'PPU',
      'Pengetahuan dan Pemahaman Umum',
      3,
      'Makna kata, gagasan, dan pemahaman bacaan.',
    ),
    (
      'PBM',
      'Kemampuan Memahami Bacaan dan Menulis',
      3,
      'Pola kalimat, kalimat efektif, dan makna kata.',
    ),
    (
      'PK',
      'Pengetahuan Kuantitatif',
      11,
      'Aritmetika, aljabar, data, peluang, dan geometri.',
    ),
    (
      'LBI',
      'Literasi Bahasa Indonesia',
      3,
      'Membaca kritis, inferensi, klaim, dan bukti.',
    ),
    (
      'LBE',
      'Literasi Bahasa Inggris',
      7,
      'Reading comprehension dan vocabulary in context.',
    ),
    (
      'PM',
      'Penalaran Matematika',
      3,
      'Pemodelan, fungsi, geometri, statistika, dan peluang.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Materi UTBK & TKA'),
      foregroundColor: navy,
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        const Text(
          'Pusat Materi',
          style: TextStyle(
            color: navy,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Pilih ujian dan pelajari materi berdasarkan bidang yang tersedia.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('UTBK-SNBT'),
                selected: true,
                selectedColor: blue,
                labelStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
                onSelected: (_) {},
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Text('TKA'),
                selected: false,
                onSelected: (_) {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Card(
          color: navy,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Concept Mastery UTBK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Konsep inti, contoh soal, strategi cepat, jebakan umum, dan latihan mandiri.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: () {},
                    child: const Text('Mulai Belajar →'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Materi per subtes',
                style: TextStyle(
                  color: navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${data.fold<int>(0, (sum, item) => sum + item.$3)} materi UTBK',
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Pelajari satu bidang sesuai fokus belajar.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        ...data.map(
          (item) => Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 5,
              ),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFEAF1FF),
                child: Text(
                  item.$1,
                  style: const TextStyle(
                    color: blue,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              title: Text(
                item.$2,
                style: const TextStyle(
                  color: navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text('${item.$4}\n${item.$3} materi tersedia'),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right, color: blue),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UtbkMateriMobilePage()),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class UtbkMateriPage extends StatelessWidget {
  const UtbkMateriPage({super.key});

  static const subjects = [
    'Penalaran Umum',
    'Pengetahuan dan Pemahaman Umum',
    'Pemahaman Bacaan dan Menulis',
    'Pengetahuan Kuantitatif',
    'Literasi Bahasa Indonesia',
    'Literasi Bahasa Inggris',
    'Penalaran Matematika',
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Materi UTBK Lengkap'),
      foregroundColor: navy,
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        const Text(
          'Materi 7 subtes UTBK',
          style: TextStyle(
            color: navy,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pelajari konsep inti, contoh soal, dan jebakan umum tiap subtes.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        ...subjects.map(
          (subject) => Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF2EAFE),
                child: Icon(Icons.menu_book_outlined, color: Color(0xFF8357C7)),
              ),
              title: Text(
                subject,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('Konsep · Contoh · Jebakan umum'),
              trailing: const Icon(
                Icons.chevron_right,
                color: Color(0xFF8357C7),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CourseDetailPage(title: subject, free: true),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class UtbkPracticePage extends StatelessWidget {
  const UtbkPracticePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Latihan Soal'), foregroundColor: navy),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        const Text(
          'Pilih jenis latihan',
          style: TextStyle(
            color: navy,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Latihan soal lengkap sesuai kebutuhan belajarmu.',
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
        const SizedBox(height: 20),
        _UtbkFeatureCard(
          category: 'DRILL HARIAN',
          title: 'Latihan Harian',
          description: 'Latihan singkat rutin untuk menjaga konsistensi belajar setiap hari.',
          tags: 'Cepat · Rutin · Fokus',
          actionLabel: 'Mulai latihan',
          icon: Icons.today_outlined,
          color: const Color(0xFF2E9B68),
          backgroundColor: const Color(0xFFE8F7EE),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const UtbkPracticeModePage(
                title: 'Latihan Harian',
                subtitle:
                    'Drill singkat rutin untuk menjaga konsistensi belajar.',
                mode: 'daily',
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _UtbkFeatureCard(
          category: 'LATIHAN PER SUBTES',
          title: 'Per Subtes',
          description:
              'Pilih Penalaran Umum, Literasi, atau subtes UTBK lainnya.',
          tags: '7 Subtes · Terarah · Bertahap',
          actionLabel: 'Pilih subtes',
          icon: Icons.category_outlined,
          color: blue,
          backgroundColor: const Color(0xFFEAF1FF),
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const UtbkSubtestPage())),
        ),
        const SizedBox(height: 12),
        _UtbkFeatureCard(
          category: 'MIXED PRACTICE',
          title: 'Paket Campuran',
          description:
              'Kerjakan paket soal gabungan dari beberapa subtes UTBK.',
          tags: 'Campuran · Variatif · Tantangan',
          actionLabel: 'Lihat paket',
          icon: Icons.library_books_outlined,
          color: const Color(0xFF8357C7),
          backgroundColor: const Color(0xFFF2EAFE),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const UtbkPracticeModePage(
                title: 'Paket Campuran',
                subtitle: 'Latihan gabungan dari beberapa subtes UTBK.',
                mode: 'mixed',
              ),
            ),
          ),
        ),
        const SizedBox(height: 26),
        const Text(
          'Latihan per Subtes',
          style: TextStyle(
            color: navy,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pilih subtes untuk mulai mengerjakan latihan.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        ...UtbkSubtestPage.subtests.map(
          (subtest) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: subtest.color.withValues(alpha: .14)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                leading: CircleAvatar(
                  backgroundColor: subtest.color.withValues(alpha: .12),
                  child: Icon(subtest.icon, color: subtest.color),
                ),
                title: Text(
                  subtest.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text('${subtest.code} · ${subtest.description}'),
                trailing: Icon(Icons.chevron_right, color: subtest.color),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UtbkPracticeModePage(
                      title: subtest.title,
                      subtitle: subtest.description,
                      mode: 'subtest',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class UtbkSubtestPage extends StatelessWidget {
  const UtbkSubtestPage({super.key});

  static const subtests =
      <
        ({
          String code,
          String title,
          String description,
          IconData icon,
          Color color,
        })
      >[
        (
          code: 'PU',
          title: 'Penalaran Umum',
          description: 'Latihan logika, pola, analisis, dan penalaran umum.',
          icon: Icons.psychology_outlined,
          color: Color(0xFF2E9B68),
        ),
        (
          code: 'PPU',
          title: 'Pengetahuan dan Pemahaman Umum',
          description: 'Pahami makna kata, konsep, dan informasi umum.',
          icon: Icons.lightbulb_outline,
          color: Color(0xFF3976D3),
        ),
        (
          code: 'PBM',
          title: 'Pemahaman Bacaan dan Menulis',
          description: 'Latihan memahami bacaan dan menyusun tulisan efektif.',
          icon: Icons.menu_book_outlined,
          color: Color(0xFF8357C7),
        ),
        (
          code: 'PK',
          title: 'Pengetahuan Kuantitatif',
          description:
              'Latihan angka, aljabar, geometri, dan analisis kuantitatif.',
          icon: Icons.calculate_outlined,
          color: Color(0xFFE38A2D),
        ),
        (
          code: 'LBI',
          title: 'Literasi Bahasa Indonesia',
          description:
              'Uji literasi melalui teks dan informasi berbahasa Indonesia.',
          icon: Icons.article_outlined,
          color: Color(0xFF168C87),
        ),
        (
          code: 'LBE',
          title: 'Literasi Bahasa Inggris',
          description:
              'Latihan reading comprehension dan vocabulary bahasa Inggris.',
          icon: Icons.translate_outlined,
          color: Color(0xFFD84B78),
        ),
        (
          code: 'PM',
          title: 'Penalaran Matematika',
          description:
              'Terapkan konsep matematika untuk memecahkan masalah nyata.',
          icon: Icons.functions_outlined,
          color: Color(0xFF5C63C7),
        ),
      ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Latihan Soal'), foregroundColor: navy),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        const Text(
          'Pilih subtes UTBK',
          style: TextStyle(
            color: navy,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Latihan soal lengkap dari Penalaran Umum sampai Penalaran Matematika.',
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
        const SizedBox(height: 20),
        ...subtests.map(
          (subtest) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: subtest.color.withValues(alpha: .14)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: subtest.color.withValues(alpha: .12),
                  child: Icon(subtest.icon, color: subtest.color),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: subtest.color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        subtest.code,
                        style: TextStyle(
                          color: subtest.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        subtest.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(subtest.description),
                ),
                trailing: Icon(Icons.chevron_right, color: subtest.color),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UtbkPracticeModePage(
                      title: subtest.title,
                      subtitle: subtest.description,
                      mode: 'subtest',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class UtbkPracticeModePage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String mode;

  const UtbkPracticeModePage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return _UtbkContentPage(
      title: title,
      subtitle: subtitle,
      icon: Icons.quiz_outlined,
      color: blue,
      sections: [
        _UtbkContentSection(
          title: 'Simpulan Logis',
          description:
              'Latihan pilihan ganda · 36 soal · Fokus satu soal sekali waktu.',
          actionLabel: 'Mulai latihan',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => UtbkRealCbtPage(initialSubject: title))),
        ),
        _UtbkContentSection(
          title: 'Pilih topik lainnya',
          description:
              'Daftar topik akan mengikuti subtes dan bank soal yang tersedia.',
          actionLabel: 'Ganti topik',
          onTap: () => _showComingSoon(context, 'Daftar topik'),
        ),
      ],
    );
  }
}

class UtbkBankPage extends StatefulWidget {
  final String? initialSubject;

  const UtbkBankPage({super.key, this.initialSubject});

  @override
  State<UtbkBankPage> createState() => _UtbkBankPageState();
}

class _UtbkBankPageState extends State<UtbkBankPage> {
  late Future<List<Map<String, dynamic>>> questionsFuture;
  String selectedCode = 'SEMUA';
  String query = '';

  static const subjects = <String, String>{
    'PU': 'Penalaran Umum',
    'PPU': 'Pengetahuan dan Pemahaman Umum',
    'PBM': 'Pemahaman Bacaan dan Menulis',
    'PK': 'Pengetahuan Kuantitatif',
    'LBI': 'Literasi Bahasa Indonesia',
    'LBE': 'Literasi Bahasa Inggris',
    'PM': 'Penalaran Matematika',
  };

  @override
  void initState() {
    super.initState();
    selectedCode = _codeFor(widget.initialSubject) ?? 'SEMUA';
    questionsFuture = _loadQuestions();
  }

  String? _codeFor(String? title) {
    if (title == null) return null;
    for (final entry in subjects.entries) {
      if (title.contains(entry.value)) return entry.key;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _loadQuestions() async {
    final raw = jsonDecode(await rootBundle.loadString('assets/utbk_questions.json'))
        as Map<String, dynamic>;
    return (raw['questions'] as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bank Soal UTBK'), foregroundColor: navy),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: questionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Bank soal gagal dimuat: ${snapshot.error}'));
        }
        final all = snapshot.data ?? const <Map<String, dynamic>>[];
        final visible = all.where((item) {
          final matchesSubject = selectedCode == 'SEMUA' || item['subject_code'] == selectedCode;
          final haystack = '${item['question']} ${item['subject']}'.toLowerCase();
          return matchesSubject && (query.isEmpty || haystack.contains(query.toLowerCase()));
        }).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const Text('Bank Soal UTBK', style: TextStyle(color: navy, fontSize: 25, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('${all.length} soal lengkap · soal, opsi, kunci, dan pembahasan', style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 14),
            TextField(
              onChanged: (value) => setState(() => query = value),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari soal atau mata pelajaran...', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _subjectChip('SEMUA', 'Semua'),
                  ...subjects.entries.map((entry) => _subjectChip(entry.key, entry.key)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text('${visible.length} soal ditampilkan', style: const TextStyle(color: navy, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ...visible.map((item) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                leading: CircleAvatar(backgroundColor: const Color(0xFFEAF1FF), child: Text('${item['source_number']}', style: const TextStyle(color: blue, fontSize: 11, fontWeight: FontWeight.w800))),
                title: Text(item['question'] as String, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: navy, fontWeight: FontWeight.w700)),
                subtitle: Text('${item['subject_code']} · Kunci ${item['answer']}'),
                trailing: const Icon(Icons.chevron_right, color: blue),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => UtbkQuestionDetailPage(question: item))),
              ),
            )),
          ],
        );
      },
    ),
  );

  Widget _subjectChip(String code, String label) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selectedCode == code,
      selectedColor: blue,
      labelStyle: TextStyle(color: selectedCode == code ? Colors.white : navy, fontWeight: FontWeight.w800),
      onSelected: (_) => setState(() => selectedCode = code),
    ),
  );
}

class UtbkQuestionDetailPage extends StatelessWidget {
  final Map<String, dynamic> question;
  const UtbkQuestionDetailPage({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    final options = Map<String, dynamic>.from(question['options'] as Map);
    return Scaffold(
      appBar: AppBar(title: Text('${question['subject_code']} · Soal ${question['source_number']}'), foregroundColor: navy),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        children: [
          Chip(label: Text(question['subject'] as String)),
          const SizedBox(height: 8),
          Text(question['question'] as String, style: const TextStyle(color: navy, fontSize: 17, height: 1.45, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...['A', 'B', 'C', 'D', 'E'].where(options.containsKey).map((key) => Card(elevation: 0, color: Colors.white, child: Padding(padding: const EdgeInsets.all(12), child: Text('$key. ${options[key]}')))),
          const SizedBox(height: 12),
          Card(color: const Color(0xFFE8F7EE), elevation: 0, child: Padding(padding: const EdgeInsets.all(14), child: Text('Kunci jawaban: ${question['answer']}', style: const TextStyle(color: Color(0xFF216B49), fontWeight: FontWeight.w800)))),
          const SizedBox(height: 10),
          Card(color: const Color(0xFFEAF1FF), elevation: 0, child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Pembahasan', style: TextStyle(color: navy, fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text(question['explanation'] as String)]))),
        ],
      ),
    );
  }
}

class UtbkQuestionPage extends StatefulWidget {
  const UtbkQuestionPage({super.key});

  @override
  State<UtbkQuestionPage> createState() => _UtbkQuestionPageState();
}

class _UtbkQuestionPageState extends State<UtbkQuestionPage> {
  Timer? timer;
  int secondsLeft = 76;
  String? selected;

  static const options = <String, String>{
    'A': 'Bergabung dengan ekskul olahraga dan ekskul pramuka.',
    'B': 'Mendaftar sebagai pengurus fotografi setelah orang tua mengizinkan.',
    'C': 'Mendaftar sebagai pengurus olahraga atau pramuka.',
    'D': 'Mendaftar sebagai pengurus olahraga, tetapi tidak di pramuka.',
    'E': 'Mendaftar sebagai pengurus pramuka, tetapi tidak di olahraga.',
  };

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (secondsLeft == 0) {
        timer?.cancel();
      } else {
        setState(() => secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void finish() {
    timer?.cancel();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selesaikan latihan?'),
        content: const Text(
          'Jawaban akan dikirim setelah bank soal terhubung ke sistem.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const UtbkResultPage()),
              );
            },
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (secondsLeft % 60).toString().padLeft(2, '0');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lolos UTBK 800'),
        foregroundColor: navy,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        children: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Align(
              alignment: Alignment.centerLeft,
              child: Text('Ganti Topik'),
            ),
          ),
          const Text(
            'Simpulan Logis',
            style: TextStyle(
              color: navy,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '1 / 36',
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: blue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  '$minutes:$seconds',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: const [
                      Chip(label: Text('Pilihan Ganda')),
                      Chip(label: Text('Mudah')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Di awal semester baru, X akan mendaftar sebagai pengurus olahraga atau pramuka di sekolah. Kakak kelasnya menyarankan X bergabung sebagai pengurus fotografi. Karena pengurus fotografi sering bepergian ke luar kota, orang tuanya tidak mengizinkannya bergabung. Apa yang PALING MUNGKIN dilakukan X pada awal semester?',
                    style: TextStyle(
                      color: navy,
                      fontSize: 16,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...options.entries.map((option) {
                    final isSelected = selected == option.key;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => selected = option.key),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? blue.withValues(alpha: .08)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? blue : Colors.black12,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: isSelected
                                  ? blue
                                  : Colors.black12,
                              child: Text(
                                option.key,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : navy,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(option.value)),
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: isSelected ? blue : Colors.black38,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: selected == null ? null : finish,
                  child: const Text('Selesai'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UtbkRealCbtPage extends StatefulWidget {
  final String? initialSubject;

  static const questionLimits = <String, int>{
    'PU': 30,
    'PPU': 20,
    'PBM': 20,
    'PK': 20,
    'LBI': 30,
    'LBE': 20,
    'PM': 20,
  };

  static int limitFor(String code) => questionLimits[code] ?? 0;

  const UtbkRealCbtPage({super.key, this.initialSubject});

  @override
  State<UtbkRealCbtPage> createState() => _UtbkRealCbtPageState();
}

class _UtbkRealCbtPageState extends State<UtbkRealCbtPage> {
  static const subtests = <String, String>{
    'PU': 'Penalaran Umum',
    'PPU': 'Pengetahuan dan Pemahaman Umum',
    'PBM': 'Pemahaman Bacaan dan Menulis',
    'PK': 'Pengetahuan Kuantitatif',
    'LBI': 'Literasi Bahasa Indonesia',
    'LBE': 'Literasi Bahasa Inggris',
    'PM': 'Penalaran Matematika',
  };

  late Future<List<Map<String, dynamic>>> questionsFuture;
  String activeCode = 'PU';
  int questionIndex = 0;
  int remainingSeconds = 45 * 60;
  Timer? timer;
  final answers = <int, String>{};
  final doubtful = <int>{};
  List<Map<String, dynamic>> activeQuestions = [];

  @override
  void initState() {
    super.initState();
    for (final entry in subtests.entries) {
      if (widget.initialSubject?.contains(entry.value) == true) activeCode = entry.key;
    }
    questionsFuture = _loadQuestions();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (remainingSeconds <= 1) {
        timer?.cancel();
        _finish(auto: true);
      } else {
        setState(() => remainingSeconds--);
      }
    });
  }

  Future<List<Map<String, dynamic>>> _loadQuestions() async {
    final root = jsonDecode(await rootBundle.loadString('assets/utbk_questions.json')) as Map<String, dynamic>;
    return (root['questions'] as List<dynamic>).map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String get timeLabel => '${(remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(remainingSeconds % 60).toString().padLeft(2, '0')}';

  void _finish({bool auto = false}) {
    timer?.cancel();
    final correct = activeQuestions.asMap().entries.where((entry) {
      final answer = answers[entry.key];
      final key = entry.value['answer'] as String? ?? '';
      return answer != null && key.split(',').map((item) => item.trim()).contains(answer);
    }).length;
    showDialog<void>(
      context: context,
      barrierDismissible: !auto,
      builder: (dialogContext) => AlertDialog(
        title: Text(auto ? 'Waktu habis' : 'Selesaikan latihan?'),
        content: Text('${answers.length} dari ${activeQuestions.length} soal dijawab.\nSkor sementara: $correct benar.'),
        actions: [
          if (!auto) TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Kembali')),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => UtbkCbtResultPage(subject: subtests[activeCode]!, correct: correct, answered: answers.length, total: activeQuestions.length)));
            },
            child: const Text('Lihat Skor'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F8FC),
    appBar: AppBar(
      backgroundColor: navy,
      foregroundColor: Colors.white,
      title: const Text('Try Out CBT · UTBK'),
      actions: [Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Text(timeLabel, style: const TextStyle(fontWeight: FontWeight.w800)))],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: questionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Soal gagal dimuat: ${snapshot.error}'));
        final all = snapshot.data ?? const <Map<String, dynamic>>[];
        final questions = all
            .where((q) => q['subject_code'] == activeCode)
            .take(UtbkRealCbtPage.limitFor(activeCode))
            .toList();
        activeQuestions = questions;
        if (questions.isEmpty) return Center(child: Text('Belum ada soal untuk ${subtests[activeCode]}.'));
        final current = questions[questionIndex.clamp(0, questions.length - 1)];
        final options = Map<String, dynamic>.from(current['options'] as Map);
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
          children: [
            if (widget.initialSubject == null)
              SizedBox(height: 44, child: ListView(scrollDirection: Axis.horizontal, children: subtests.entries.map((entry) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(entry.key), selected: activeCode == entry.key, selectedColor: blue, labelStyle: TextStyle(color: activeCode == entry.key ? Colors.white : navy, fontWeight: FontWeight.w800), onSelected: (_) => setState(() { activeCode = entry.key; questionIndex = 0; })))).toList())),
            Card(color: const Color(0xFFEAF1FF), elevation: 0, child: ListTile(leading: const Icon(Icons.info_outline, color: blue), title: Text('${subtests[activeCode]} · Soal ${questionIndex + 1} dari ${questions.length}', style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: const Text('Jawaban tersimpan otomatis · Tandai ragu-ragu bila perlu'))),
            Card(elevation: 0, child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, children: [Chip(label: Text(activeCode)), const Chip(label: Text('Pilihan Ganda'))]),
              const SizedBox(height: 12),
              Text(current['question'] as String, style: const TextStyle(color: navy, fontSize: 17, height: 1.45, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ...['A', 'B', 'C', 'D', 'E'].where(options.containsKey).map((key) { final chosen = answers[questionIndex] == key; return InkWell(onTap: () => setState(() => answers[questionIndex] = key), child: Container(margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: chosen ? const Color(0xFFEAF1FF) : Colors.transparent, border: Border.all(color: chosen ? blue : Colors.black12), borderRadius: BorderRadius.circular(12)), child: Row(children: [CircleAvatar(radius: 15, backgroundColor: chosen ? blue : Colors.black12, child: Text(key, style: TextStyle(color: chosen ? Colors.white : navy, fontWeight: FontWeight.w800))), const SizedBox(width: 10), Expanded(child: Text('${options[key]}')), Icon(chosen ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: chosen ? blue : Colors.black38)]))); }),
              const SizedBox(height: 8),
            ]))),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: questionIndex == 0 ? null : () => setState(() => questionIndex--),
                        child: const Text('Sebelumnya'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => setState(() => doubtful.contains(questionIndex) ? doubtful.remove(questionIndex) : doubtful.add(questionIndex)),
                      child: Text(doubtful.contains(questionIndex) ? 'Ragu ✓' : 'Ragu'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: questionIndex == questions.length - 1 ? () => _finish() : () => setState(() => questionIndex++),
                        child: Text(questionIndex == questions.length - 1 ? 'Selesai' : 'Selanjutnya'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class UtbkCbtResultPage extends StatelessWidget {
  final String subject;
  final int correct;
  final int answered;
  final int total;

  const UtbkCbtResultPage({super.key, required this.subject, required this.correct, required this.answered, required this.total});

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : (correct * 100 / total).round();
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Try Out'), foregroundColor: navy),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.emoji_events_outlined, color: orange, size: 72),
          const SizedBox(height: 12),
          const Text('Try Out selesai!', textAlign: TextAlign.center, style: TextStyle(color: navy, fontSize: 25, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(subject, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 22),
          Card(color: const Color(0xFFEAF1FF), elevation: 0, child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [const Text('Skor kamu', style: TextStyle(color: Colors.black54)), const SizedBox(height: 8), Text('$percent', style: const TextStyle(color: navy, fontSize: 52, fontWeight: FontWeight.w800)), const Text('persen', style: TextStyle(color: Colors.black54))]))),
          const SizedBox(height: 14),
          Row(children: [Expanded(child: _scoreStat('$correct', 'Benar')), const SizedBox(width: 10), Expanded(child: _scoreStat('${total - correct}', 'Salah/kosong')), const SizedBox(width: 10), Expanded(child: _scoreStat('$answered/$total', 'Dijawab'))]),
          const SizedBox(height: 22),
          FilledButton(onPressed: () => Navigator.popUntil(context, (route) => route.isFirst), child: const Text('Kembali ke UTBK')),
        ],
      ),
    );
  }

  Widget _scoreStat(String value, String label) => Card(elevation: 0, child: Padding(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4), child: Column(children: [Text(value, style: const TextStyle(color: blue, fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, fontSize: 10))])));
}

class UtbkCbtPage extends StatefulWidget {
  const UtbkCbtPage({super.key});

  @override
  State<UtbkCbtPage> createState() => _UtbkCbtPageState();
}

class _UtbkCbtPageState extends State<UtbkCbtPage> {
  static const subtests = <String>[
    'PU · Penalaran Umum',
    'PPU · Pengetahuan dan Pemahaman Umum',
    'PBM · Pemahaman Bacaan dan Menulis',
    'PK · Pengetahuan Kuantitatif',
    'LBI · Literasi Bahasa Indonesia',
    'LBE · Literasi Bahasa Inggris',
    'PM · Penalaran Matematika',
  ];

  Timer? timer;
  int remainingSeconds = 45 * 60;
  int question = 1;
  int selected = -1;
  String activeSubtest = subtests.first;
  final answered = <int>{};
  final doubtful = <int>{};

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (remainingSeconds <= 1) {
        timer?.cancel();
        finishExam(auto: true);
      } else {
        setState(() => remainingSeconds--);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String get timeLabel =>
      '${(remainingSeconds ~/ 3600).toString().padLeft(2, '0')}:${((remainingSeconds % 3600) ~/ 60).toString().padLeft(2, '0')}:${(remainingSeconds % 60).toString().padLeft(2, '0')}';

  void chooseAnswer(int value) => setState(() {
    selected = value;
    answered.add(question);
  });

  void next() {
    if (question < 30) {
      setState(() {
        question++;
        selected = -1;
      });
    }
  }

  void previous() {
    if (question > 1) {
      setState(() {
        question--;
        selected = -1;
      });
    }
  }

  void finishExam({bool auto = false}) {
    timer?.cancel();
    showDialog<void>(
      context: context,
      barrierDismissible: !auto,
      builder: (context) => AlertDialog(
        title: Text(auto ? 'Waktu habis' : 'Selesai Ujian?'),
        content: Text(
          auto
              ? 'Waktu ujian telah habis.'
              : 'Jawaban yang sudah tersimpan akan dikirim untuk dinilai.',
        ),
        actions: [
          if (!auto)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali'),
            ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Selesai Ujian'),
          ),
        ],
      ),
    );
  }

  Widget sideInfo() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _examPanel('INFORMASI PESERTA', const [
        'Nama: PESERTA SIMULASI',
        'Sesi: 01',
        'Ruang: CBT-UTBK',
        'Status: Aktif',
      ]),
      _examPanel('PETUNJUK SINGKAT', const [
        'Pilih jawaban A, B, C, D, atau E.',
        'Gunakan Ragu-ragu jika belum yakin.',
        'Jawaban tersimpan otomatis selama sesi.',
      ]),
      _examPanel(
        'DAFTAR SUBTES',
        subtests,
        onItems: (item) => setState(() {
          activeSubtest = item;
          question = 1;
          selected = -1;
        }),
        activeItem: activeSubtest,
      ),
    ],
  );

  Widget _examPanel(
    String title,
    List<String> items, {
    void Function(String)? onItems,
    String? activeItem,
  }) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: navy,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: .5,
            ),
          ),
          const SizedBox(height: 9),
          ...items.map(
            (item) => InkWell(
              onTap: onItems == null ? null : () => onItems(item),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  item,
                  style: TextStyle(
                    color: item == activeItem ? blue : Colors.black87,
                    fontWeight: item == activeItem
                        ? FontWeight.w800
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget questionPanel() => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Soal Nomor $question',
                style: const TextStyle(
                  color: navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              const Chip(label: Text('Pilihan Ganda')),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Mode ujian · jawaban tersimpan otomatis',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const Divider(height: 26),
          Text(
            'Manakah kesimpulan yang paling tepat berdasarkan informasi pada soal berikut?',
            style: const TextStyle(
              color: navy,
              fontSize: 18,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          ...['A', 'B', 'C', 'D', 'E'].asMap().entries.map(
            (entry) => InkWell(
              onTap: () => chooseAnswer(entry.key),
              child: Container(
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected == entry.key ? const Color(0xFFEAF1FF) : null,
                  border: Border.all(
                    color: selected == entry.key ? blue : Colors.black12,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: selected == entry.key
                          ? blue
                          : Colors.black12,
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          color: selected == entry.key ? Colors.white : navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Pilihan jawaban ${entry.value}')),
                    Icon(
                      selected == entry.key
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: selected == entry.key ? blue : Colors.black38,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton(
                onPressed: question == 1 ? null : previous,
                child: const Text('<< Sebelumnya'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => setState(
                  () => doubtful.contains(question)
                      ? doubtful.remove(question)
                      : doubtful.add(question),
                ),
                child: Text(
                  doubtful.contains(question) ? 'Ragu-ragu ✓' : 'Ragu-ragu',
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: next,
                child: const Text('Selanjutnya >>'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget navigatorPanel() => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DAFTAR SOAL',
            style: TextStyle(
              color: navy,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: .5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '30 SOAL',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(30, (index) {
              final number = index + 1;
              final active = number == question;
              final color = active
                  ? blue
                  : answered.contains(number)
                  ? Colors.green
                  : doubtful.contains(number)
                  ? Colors.amber
                  : Colors.white;
              return InkWell(
                onTap: () => setState(() {
                  question = number;
                  selected = -1;
                }),
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(
                      color: active ? blue : Colors.black12,
                      width: active ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '$number',
                    style: TextStyle(
                      color: active || answered.contains(number)
                          ? Colors.white
                          : navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          const Text(
            'Dijawab  ·  Ragu-ragu  ·  Belum  ·  Aktif',
            style: TextStyle(color: Colors.black54, fontSize: 10),
          ),
          const SizedBox(height: 14),
          Text(
            'Dijawab: ${answered.length}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Ragu-ragu: ${doubtful.length}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Belum dijawab: ${30 - answered.length}',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => finishExam(),
              child: const Text('Selesai Ujian'),
            ),
          ),
        ],
      ),
    ),
  );

  void showMobileNavigator() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: navigatorPanel(),
        ),
      ),
    );
  }

  Widget mobileSubtests() => SizedBox(
    height: 44,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: subtests.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final item = subtests[index];
        final active = item == activeSubtest;
        return ChoiceChip(
          label: Text(item.split(' · ').first),
          selected: active,
          selectedColor: blue,
          labelStyle: TextStyle(
            color: active ? Colors.white : navy,
            fontWeight: FontWeight.w800,
          ),
          onSelected: (_) => setState(() {
            activeSubtest = item;
            question = 1;
            selected = -1;
          }),
        );
      },
    ),
  );

  Widget mobileInfo() => Card(
    elevation: 0,
    child: ListTile(
      dense: true,
      leading: const Icon(Icons.info_outline, color: blue),
      title: Text(
        'Soal $question dari 30 · ${activeSubtest.split(' · ').first}',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: const Text('Autosave aktif · Pilih jawaban lalu lanjutkan'),
      trailing: IconButton(
        icon: const Icon(Icons.expand_more),
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          builder: (_) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: sideInfo(),
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => const UtbkRealCbtPage(); /* Scaffold(
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Text(
            'Sisa Waktu: $timeLabel',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(14),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 900) {
              return Column(
                children: [
                  Card(
                    color: const Color(0xFFEAF1FF),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Waktu tersisa',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Text(
                            timeLabel,
                            style: const TextStyle(
                              color: blue,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  mobileInfo(),
                  mobileSubtests(),
                  const SizedBox(height: 8),
                  questionPanel(),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: showMobileNavigator,
                    icon: const Icon(Icons.grid_view_rounded),
                    label: const Text('Daftar soal  ·  Dijawab  ·  Belum'),
                  ),
                ],
              );
            }
            return Column(
              children: [
                Card(
                  color: const Color(0xFFEAF1FF),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Wrap(
                      spacing: 22,
                      runSpacing: 8,
                      children: const [
                        Text('Nomor Soal: 1'),
                        Text('Mata Uji: Penalaran Umum'),
                        Text('Total Soal: 30'),
                        Text(
                          'Mode ujian: timer aktif, navigasi soal, ragu-ragu, autosave',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 235, child: sideInfo()),
                    const SizedBox(width: 14),
                    Expanded(child: questionPanel()),
                    const SizedBox(width: 14),
                    SizedBox(width: 245, child: navigatorPanel()),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    ),
  ); */
}

class UtbkResultPage extends StatelessWidget {
  const UtbkResultPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Hasil Latihan'), foregroundColor: navy),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Latihan selesai',
          style: TextStyle(
            color: navy,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Simpulan Logis · 36 soal',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          color: const Color(0xFFEAF1FF),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: const [
                Text('Skor sementara', style: TextStyle(color: Colors.black54)),
                SizedBox(height: 8),
                Text(
                  '—',
                  style: TextStyle(
                    color: navy,
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Akan dihitung dari bank soal backend',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _UtbkResultAction(
          title: 'Lihat pembahasan',
          subtitle: 'Tinjau jawaban dan pembahasan setiap soal.',
          icon: Icons.menu_book_outlined,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const UtbkDiscussionPage())),
        ),
        _UtbkResultAction(
          title: 'Lihat progress',
          subtitle: 'Pantau hasil latihan di halaman progress belajar.',
          icon: Icons.insights_outlined,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const UtbkProgressPage())),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () =>
              Navigator.popUntil(context, (route) => route.isFirst),
          child: const Text('Kembali ke UTBK'),
        ),
      ],
    ),
  );
}

class _UtbkResultAction extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _UtbkResultAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFEAF1FF),
        child: Icon(icon, color: blue),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class UtbkDiscussionPage extends StatelessWidget {
  const UtbkDiscussionPage({super.key});

  @override
  Widget build(BuildContext context) => _UtbkContentPage(
    title: 'Pembahasan',
    subtitle: 'Tinjau jawaban dan pahami alasan di balik setiap pilihan.',
    icon: Icons.menu_book_outlined,
    color: const Color(0xFF8357C7),
    sections: const [
      _UtbkContentSection(
        title: 'Pembahasan soal',
        description: 'Pembahasan dan kunci jawaban akan tampil setelah bank soal tersedia.',
      ),
      _UtbkContentSection(
        title: 'Catatan belajar',
        description: 'Simpan soal yang perlu diulang untuk latihan berikutnya.',
      ),
    ],
  );
}

class UtbkStrategyPage extends StatelessWidget {
  const UtbkStrategyPage({super.key});

  @override
  Widget build(BuildContext context) => _UtbkContentPage(
    title: 'Strategi UTBK Terarah',
    subtitle:
        'Taktik sesuai masalah belajar, target skor, dan subtes prioritas.',
    icon: Icons.track_changes_outlined,
    color: const Color(0xFFE38A2D),
    sections: const [
      _UtbkContentSection(
        title: 'Roadmap belajar',
        description:
            'Susun langkah belajar berdasarkan target dan waktu yang tersedia.',
      ),
      _UtbkContentSection(
        title: 'Strategi per subtes',
        description:
            'Pelajari taktik untuk PU, PPU, PBM, PK, LBI, LBE, dan PM.',
      ),
      _UtbkContentSection(
        title: 'Target skor',
        description: 'Tentukan target dan prioritas peningkatan kemampuan.',
      ),
    ],
  );
}

class UtbkProgressPage extends StatelessWidget {
  const UtbkProgressPage({super.key});

  @override
  Widget build(BuildContext context) => _UtbkContentPage(
    title: 'Progress Belajar',
    subtitle: 'Pantau kesiapan, analisa hasil, topik lemah, dan targetmu.',
    icon: Icons.insights_outlined,
    color: const Color(0xFF168C87),
    sections: const [
      _UtbkContentSection(
        title: 'Ringkasan progres',
        description: 'Riwayat latihan dan try out akan dirangkum di sini.',
      ),
      _UtbkContentSection(
        title: 'Analisa topik lemah',
        description: 'Lihat subtes yang perlu lebih banyak dilatih.',
      ),
      _UtbkContentSection(
        title: 'Target menuju 800',
        description: 'Pantau perkembangan skor menuju target UTBK.',
      ),
    ],
  );
}

class UtbkLiveClassPage extends StatelessWidget {
  const UtbkLiveClassPage({super.key});

  @override
  Widget build(BuildContext context) => _UtbkContentPage(
    title: 'LiveClass',
    subtitle: 'Belajar online secara berkala bersama pengajar profesional.',
    icon: Icons.ondemand_video_outlined,
    color: const Color(0xFFD84B78),
    sections: const [
      _UtbkContentSection(
        title: 'Jadwal kelas',
        description: 'Kelas mendatang akan tampil di sini.',
      ),
      _UtbkContentSection(
        title: 'Pengajar profesional',
        description: 'Temukan kelas yang sesuai dengan kebutuhan belajarmu.',
      ),
    ],
  );
}

class _UtbkContentSection {
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onTap;

  const _UtbkContentSection({
    required this.title,
    required this.description,
    this.actionLabel,
    this.onTap,
  });
}

class _UtbkContentPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<_UtbkContentSection> sections;

  const _UtbkContentPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), foregroundColor: navy),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: const TextStyle(
            color: navy,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.black54, height: 1.35),
        ),
        const SizedBox(height: 20),
        ...sections.map(
          (section) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: color.withValues(alpha: .14)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: const TextStyle(
                      color: navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    section.description,
                    style: const TextStyle(color: Colors.black54, height: 1.35),
                  ),
                  if (section.actionLabel != null) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: section.onTap,
                        icon: Icon(Icons.arrow_forward_rounded, color: color),
                        label: Text(
                          section.actionLabel!,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class OfficialBook {
  final String title;
  final String level;
  final String subject;
  final String pdfUrl;

  const OfficialBook({
    required this.title,
    required this.level,
    required this.subject,
    required this.pdfUrl,
  });
}

class OfficialBooksPage extends StatefulWidget {
  final VoidCallback? onBack;

  const OfficialBooksPage({super.key, this.onBack});

  @override
  State<OfficialBooksPage> createState() => _OfficialBooksPageState();
}

class _OfficialBooksPageState extends State<OfficialBooksPage> {
  final searchController = TextEditingController();
  String query = '';
  String selectedLevel = 'SD';
  late Future<List<OfficialBook>> booksFuture;

  @override
  void initState() {
    super.initState();
    booksFuture = _loadOfficialBooks();
  }

  Future<List<OfficialBook>> _loadOfficialBooks() async {
    final books = <OfficialBook>[];
    for (var page = 1; page <= 2; page++) {
      final uri = Uri.parse(
        'https://api.buku.cloudapp.web.id/api/catalogue/getBooksByTag'
        '?tag=STEM&page=$page&limit=100&type=pelajaran',
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) continue;
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final results = payload['results'] as List<dynamic>? ?? const [];
      for (final raw in results) {
        final item = raw as Map<String, dynamic>;
        final attachment = item['attachment'] as String? ?? '';
        final title = item['title'] as String? ?? '';
        if (attachment.isEmpty || title.isEmpty) continue;
        books.add(
          OfficialBook(
            title: title,
            level: item['level'] as String? ?? 'Umum',
            subject: item['subject'] as String? ?? 'Buku pelajaran',
            pdfUrl: attachment,
          ),
        );
      }
    }
    return books;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: FutureBuilder<List<OfficialBook>>(
          future: booksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      key: const Key('kembali-ke-beranda'),
                      onPressed: () {
                        if (widget.onBack != null) {
                          widget.onBack!();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.arrow_back),
                    ),
                  ),
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            }
            if (snapshot.hasError) {
              return _OfficialBooksError(
                onRetry: () {
                  setState(() => booksFuture = _loadOfficialBooks());
                },
              );
            }
            final allBooks = snapshot.data ?? const <OfficialBook>[];
            final filtered = allBooks.where((book) {
              final haystack = '${book.title} ${book.subject} ${book.level}'
                  .toLowerCase();
              return (query.isEmpty ||
                      haystack.contains(query.toLowerCase())) &&
                  (selectedLevel == 'Semua' ||
                      book.level.toUpperCase().contains(selectedLevel));
            }).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (widget.onBack != null) {
                          widget.onBack!();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Expanded(
                      child: Text(
                        'Academy Kreativ',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: navy,
                        ),
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Buku resmi Kemendikdasmen untuk dibaca di Edukreativ.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: searchController,
                  onChanged: (value) => setState(() => query = value),
                  decoration: const InputDecoration(
                    hintText: 'Cari judul, mapel, atau jenjang',
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['SD', 'SMP', 'SMA', 'SMK', 'Semua'].map((level) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(level),
                          selected: selectedLevel == level,
                          selectedColor: blue,
                          labelStyle: TextStyle(
                            color: selectedLevel == level ? Colors.white : navy,
                          ),
                          onSelected: (_) =>
                              setState(() => selectedLevel = level),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '${filtered.length} buku resmi',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 10),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(28),
                    child: Text(
                      'Buku tidak ditemukan.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...filtered.map((book) => _OfficialBookCard(book: book)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OfficialBooksError extends StatelessWidget {
  final VoidCallback onRetry;
  const _OfficialBooksError({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Katalog resmi sedang tidak terhubung.'),
        const SizedBox(height: 10),
        FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
      ],
    ),
  );
}

class _OfficialBookCard extends StatelessWidget {
  final OfficialBook book;
  const _OfficialBookCard({required this.book});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    elevation: 0,
    child: ListTile(
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFEAF0FF),
        child: Icon(Icons.menu_book_outlined, color: blue),
      ),
      title: Text(
        book.title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${book.level} · ${book.subject.isEmpty ? 'Buku siswa' : book.subject}',
      ),
      trailing: const Icon(Icons.chevron_right, color: blue),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OfficialPdfReaderPage(book: book)),
      ),
    ),
  );
}

class OfficialPdfReaderPage extends StatefulWidget {
  final OfficialBook book;
  const OfficialPdfReaderPage({super.key, required this.book});

  @override
  State<OfficialPdfReaderPage> createState() => _OfficialPdfReaderPageState();
}

class _OfficialPdfReaderPageState extends State<OfficialPdfReaderPage> {
  String? localPath;
  String? error;

  @override
  void initState() {
    super.initState();
    _preparePdf();
  }

  Future<void> _preparePdf() async {
    try {
      final directory = await getApplicationSupportDirectory();
      final safeName = widget.book.title.replaceAll(
        RegExp(r'[^a-zA-Z0-9]+'),
        '_',
      );
      final file = File('${directory.path}/official_books_$safeName.pdf');
      if (!await file.exists()) {
        final response = await http.get(Uri.parse(widget.book.pdfUrl));
        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}');
        }
        await file.writeAsBytes(response.bodyBytes, flush: true);
      }
      if (mounted) setState(() => localPath = file.path);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'PDF belum bisa disimpan. Periksa koneksi internet.',
        );
      }
    }
  }

  Future<void> _openOfficialDownload() async {
    await launchUrl(
      Uri.parse(widget.book.pdfUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Download dari sumber resmi',
            onPressed: _openOfficialDownload,
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: error != null
          ? Center(child: Text(error!, textAlign: TextAlign.center))
          : localPath == null
          ? const Center(child: CircularProgressIndicator())
          : PdfViewer.file(localPath!),
    );
  }
}

class CatalogPage extends StatefulWidget {
  final VoidCallback? onBack;

  const CatalogPage({super.key, this.onBack});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final searchController = TextEditingController();
  String selectedLevel = 'Semua';
  String query = '';

  static const courses = [
    (
      title: 'Matematika Dasar',
      subtitle: 'SD · Bilangan dan Operasi',
      level: 'SD',
      free: true,
      icon: Icons.calculate,
    ),
    (
      title: 'Bahasa Indonesia SD',
      subtitle: 'SD · Membaca dan Menulis',
      level: 'SD',
      free: true,
      icon: Icons.menu_book_outlined,
    ),
    (
      title: 'IPAS',
      subtitle: 'SD · Makhluk Hidup dan Lingkungan',
      level: 'SD',
      free: false,
      icon: Icons.nature_people_outlined,
    ),
    (
      title: 'Pendidikan Pancasila SD',
      subtitle: 'SD · Hidup Bersama dan Gotong Royong',
      level: 'SD',
      free: true,
      icon: Icons.account_balance,
    ),
    (
      title: 'Bahasa Inggris Dasar',
      subtitle: 'SD · Kosakata dan Percakapan Sehari-hari',
      level: 'SD',
      free: true,
      icon: Icons.translate,
    ),
    (
      title: 'Seni Budaya SD',
      subtitle: 'SD · Ekspresi Seni dan Kreativitas',
      level: 'SD',
      free: false,
      icon: Icons.palette_outlined,
    ),
    (
      title: 'PJOK SD',
      subtitle: 'SD · Gerak Dasar dan Kesehatan',
      level: 'SD',
      free: true,
      icon: Icons.sports_soccer,
    ),
    (
      title: 'Pendidikan Agama dan Budi Pekerti',
      subtitle: 'SD · Akhlak dan Karakter',
      level: 'SD',
      free: false,
      icon: Icons.volunteer_activism_outlined,
    ),
    (
      title: 'Sains di Sekitar Kita',
      subtitle: 'SMP · Makhluk Hidup',
      level: 'SMP',
      free: false,
      icon: Icons.science,
    ),
    (
      title: 'Matematika SMP',
      subtitle: 'SMP · Bilangan dan Aljabar',
      level: 'SMP',
      free: true,
      icon: Icons.calculate_outlined,
    ),
    (
      title: 'Bahasa Inggris SMP',
      subtitle: 'SMP · Descriptive dan Procedure Text',
      level: 'SMP',
      free: true,
      icon: Icons.translate,
    ),
    (
      title: 'IPS Terpadu',
      subtitle: 'SMP · Geografi, Sejarah, dan Ekonomi',
      level: 'SMP',
      free: false,
      icon: Icons.public,
    ),
    (
      title: 'Pendidikan Pancasila',
      subtitle: 'SMP · Konstitusi dan Kebinekaan',
      level: 'SMP',
      free: true,
      icon: Icons.account_balance,
    ),
    (
      title: 'Informatika SMP',
      subtitle: 'SMP · Berpikir Komputasional',
      level: 'SMP',
      free: false,
      icon: Icons.computer,
    ),
    (
      title: 'Seni Budaya',
      subtitle: 'SMP · Seni Rupa dan Musik',
      level: 'SMP',
      free: true,
      icon: Icons.palette_outlined,
    ),
    (
      title: 'PJOK',
      subtitle: 'SMP · Kebugaran dan Permainan',
      level: 'SMP',
      free: true,
      icon: Icons.sports_soccer,
    ),
    (
      title: 'Bahasa Indonesia',
      subtitle: 'SMA · Teks Eksposisi',
      level: 'SMA',
      free: true,
      icon: Icons.auto_stories,
    ),
    (
      title: 'Petualangan Pecahan',
      subtitle: 'SD · Pecahan untuk pemula',
      level: 'SD',
      free: true,
      icon: Icons.functions,
    ),
    (
      title: 'Matematika Tingkat Lanjut',
      subtitle: 'SMA · Fungsi dan Persamaan',
      level: 'SMA',
      free: false,
      icon: Icons.show_chart,
    ),
    (
      title: 'Fisika',
      subtitle: 'SMA · Gerak dan Gaya',
      level: 'SMA',
      free: true,
      icon: Icons.speed,
    ),
    (
      title: 'Kimia',
      subtitle: 'SMA · Atom dan Sistem Periodik',
      level: 'SMA',
      free: false,
      icon: Icons.science_outlined,
    ),
    (
      title: 'Biologi',
      subtitle: 'SMA · Sel dan Keanekaragaman Hayati',
      level: 'SMA',
      free: true,
      icon: Icons.eco,
    ),
    (
      title: 'Ekonomi',
      subtitle: 'SMA · Konsep Dasar Ekonomi',
      level: 'SMA',
      free: true,
      icon: Icons.account_balance_wallet_outlined,
    ),
    (
      title: 'Sosiologi',
      subtitle: 'SMA · Interaksi Sosial',
      level: 'SMA',
      free: false,
      icon: Icons.groups_outlined,
    ),
    (
      title: 'Geografi',
      subtitle: 'SMA · Dinamika Geosfer',
      level: 'SMA',
      free: true,
      icon: Icons.public,
    ),
    (
      title: 'Bahasa Inggris Tingkat Lanjut',
      subtitle: 'SMA · Teks dan Komunikasi Akademik',
      level: 'SMA',
      free: false,
      icon: Icons.translate,
    ),
    (
      title: 'Informatika',
      subtitle: 'SMA · Algoritma dan Pemrograman',
      level: 'SMA',
      free: true,
      icon: Icons.computer,
    ),
    (
      title: 'Koding dan Kecerdasan Artifisial',
      subtitle: 'SMA · Logika, Data, dan AI',
      level: 'SMA',
      free: false,
      icon: Icons.smart_toy_outlined,
    ),
    (
      title: 'Eksperimen Energi',
      subtitle: 'SMP · Energi dan Perubahannya',
      level: 'SMP',
      free: false,
      icon: Icons.bolt,
    ),
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = courses.where((course) {
      final matchesQuery =
          query.isEmpty ||
          '${course.title} ${course.subtitle}'.toLowerCase().contains(
            query.toLowerCase(),
          );
      final matchesLevel =
          selectedLevel == 'Semua' || course.level == selectedLevel;
      return matchesQuery && matchesLevel;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  key: const Key('kembali-ke-beranda'),
                  tooltip: 'Kembali ke Beranda',
                  onPressed: () {
                    if (widget.onBack != null) {
                      widget.onBack!();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
                const Expanded(
                  child: Text(
                    'Academy Kreativ',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: navy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Temukan materi yang cocok untuk perjalanan belajarmu.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: searchController,
              onChanged: (value) => setState(() => query = value),
              decoration: InputDecoration(
                hintText: 'Cari materi atau pelajaran',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus pencarian',
                        onPressed: () {
                          searchController.clear();
                          setState(() => query = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
                filled: true,
                fillColor: Colors.white,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['Semua', 'SD', 'SMP', 'SMA']
                    .map(
                      (level) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(level),
                          selected: selectedLevel == level,
                          onSelected: (_) =>
                              setState(() => selectedLevel = level),
                          selectedColor: blue,
                          labelStyle: TextStyle(
                            color: selectedLevel == level ? Colors.white : navy,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Semua materi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                Text(
                  '${filtered.length} materi',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Materi tidak ditemukan. Coba kata kunci lain.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ...filtered.map(
                (course) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CourseCard(
                    title: course.title,
                    subtitle: course.subtitle,
                    free: course.free,
                    icon: course.icon,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CourseDetailPage extends StatefulWidget {
  final String title;
  final bool free;

  const CourseDetailPage({super.key, required this.title, required this.free});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  final lessons = <String>[
    'Video pengantar',
    'Rangkuman konsep',
    'Contoh soal',
    'Kuis singkat',
  ];
  final completed = <bool>[false, false, false, false];
  bool bookmarked = false;

  int get completedCount => completed.where((item) => item).length;

  void openMaterial() {
    if (!widget.free) {
      showModalBottomSheet(
        context: context,
        builder: (_) => const _PremiumSheet(),
      );
      return;
    }
    setState(() => completed[0] = true);
    LearningActivityStore.instance.recordLesson(
      course: widget.title,
      lessonIndex: 0,
      minutes: 3,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Materi dimulai. Selamat belajar!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = completedCount / lessons.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail materi'),
        actions: [
          IconButton(
            tooltip: 'Simpan materi',
            onPressed: () => setState(() => bookmarked = !bookmarked),
            icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Chip(
                avatar: Icon(
                  widget.free ? Icons.lock_open : Icons.workspace_premium,
                  size: 16,
                ),
                label: Text(widget.free ? 'Materi gratis' : 'Materi premium'),
                backgroundColor: widget.free
                    ? const Color(0xFFE5F6EA)
                    : const Color(0xFFFFF0E4),
              ),
              const SizedBox(width: 8),
              const Text('15 menit', style: TextStyle(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Belajar melalui video, rangkuman, contoh, dan kuis singkat yang dirancang agar mudah dipahami.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: openMaterial,
              icon: Icon(widget.free ? Icons.play_arrow : Icons.lock_outline),
              label: Text(
                widget.free ? 'Mulai belajar' : 'Lihat pilihan akses',
              ),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Progres materi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                    Text(
                      '$completedCount/${lessons.length} selesai',
                      style: const TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                  color: orange,
                  backgroundColor: Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Isi materi',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(
            lessons.length,
            (index) => CheckboxListTile(
              value: completed[index],
              onChanged: widget.free
                  ? (value) {
                      setState(() => completed[index] = value ?? false);
                      if (value == true) {
                        LearningActivityStore.instance.recordLesson(
                          course: widget.title,
                          lessonIndex: index,
                          minutes: index == 0 ? 3 : 4,
                        );
                      }
                    }
                  : null,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(lessons[index]),
              subtitle: Text(index == 0 ? '3 menit' : '4 menit'),
              secondary: Icon(
                index == 3 ? Icons.quiz_outlined : Icons.play_circle_outline,
                color: blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumSheet extends StatelessWidget {
  const _PremiumSheet();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Materi premium',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: navy,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Login atau daftar hanya diperlukan saat kamu ingin melanjutkan ke paket berbayar.',
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Login / Daftar'),
                  content: const Text(
                    'Layar autentikasi akan dihubungkan ke sistem akun pada milestone berikutnya.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Lanjut ke login / daftar'),
          ),
        ),
      ],
    ),
  );
}

class _Logo extends StatelessWidget {
  final double size;
  const _Logo({required this.size});
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/logo_emblem.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
  );
}

class _KedinasanMenuCard extends StatelessWidget {
  final VoidCallback onTap;

  const _KedinasanMenuCard({required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    key: const Key('menu-kedinasan'),
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0x33FFFFFF),
            child: Icon(Icons.military_tech, color: orange, size: 30),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KEDINASAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Persiapan Akademi TNI, AKPOL, dan sekolah kedinasan.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white),
        ],
      ),
    ),
  );
}

class KedinasanPage extends StatelessWidget {
  const KedinasanPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('KEDINASAN'), foregroundColor: navy),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        const Text(
          'Pilih jalur persiapan',
          style: TextStyle(
            color: navy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Materi dan informasi seleksi dapat berubah. Selalu verifikasi melalui sumber resmi.',
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(height: 20),
        _ExamOption(
          title: 'Akademi TNI',
          subtitle: 'Persiapan dasar dan wawasan seleksi',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const KedinasanTrackPage(title: 'Akademi TNI'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ExamOption(
          title: 'AKPOL',
          subtitle: 'Persiapan dasar dan wawasan seleksi',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const KedinasanTrackPage(title: 'AKPOL'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ExamOption(
          title: 'Sekolah Kedinasan',
          subtitle: 'STAN, IPDN, dan sekolah kedinasan lainnya',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  const KedinasanTrackPage(title: 'Sekolah Kedinasan'),
            ),
          ),
        ),
      ],
    ),
  );
}

class KedinasanTrackPage extends StatelessWidget {
  final String title;

  const KedinasanTrackPage({required this.title, super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), foregroundColor: navy),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          title,
          key: const Key('kedinasan-track-title'),
          style: const TextStyle(
            color: navy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Rangkaian belajar untuk jalur ini sedang disiapkan secara bertahap.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        _KedinasanStatusCard(
          icon: Icons.menu_book_outlined,
          title: 'Materi persiapan',
          subtitle: 'Konten akan ditambahkan setelah materi resmi tersedia.',
          onTap: () {
            if (title == 'Sekolah Kedinasan') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SkdMaterialsPage()),
              );
            } else if (title == 'Akademi TNI') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TniMaterialsPage()),
              );
            } else if (title == 'AKPOL') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AkpolMaterialsPage()),
              );
            } else {
              _showComingSoon(context, 'Materi persiapan');
            }
          },
        ),
        const SizedBox(height: 12),
        _KedinasanStatusCard(
          icon: Icons.fact_check_outlined,
          title: 'Latihan dan tryout',
          subtitle:
              'Bank soal dan pembahasan akan hadir pada milestone berikutnya.',
          onTap: () {
            if (title == 'Sekolah Kedinasan') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SkdTryoutMenuPage()),
              );
            } else if (title == 'Akademi TNI') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TniTryoutMenuPage()),
              );
            } else if (title == 'AKPOL') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AkpolTryoutMenuPage()),
              );
            } else {
              _showComingSoon(context, 'Latihan dan tryout');
            }
          },
        ),
        const SizedBox(height: 12),
        _KedinasanStatusCard(
          icon: Icons.info_outline,
          title: 'Informasi seleksi',
          subtitle: 'Syarat dan jadwal dapat berubah; cek selalu sumber resmi.',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SelectionInfoPage(trackTitle: title),
            ),
          ),
        ),
      ],
    ),
  );
}

class SelectionInfoPage extends StatelessWidget {
  const SelectionInfoPage({required this.trackTitle, super.key});

  final String trackTitle;

  String get portal => switch (trackTitle) {
    'Akademi TNI' => 'taruna.rekrutmen-tni.mil.id',
    'AKPOL' => 'penerimaan.polri.go.id',
    _ => 'menpan.go.id dan bkn.go.id',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Informasi Seleksi'),
      foregroundColor: navy,
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Informasi Seleksi $trackTitle',
          key: const Key('selection-info-title'),
          style: const TextStyle(
            color: navy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Gunakan halaman ini sebagai pengingat untuk memeriksa pengumuman terbaru. Persyaratan, jadwal, formasi, tahapan, dan nilai dapat berubah setiap periode.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: const Icon(Icons.verified_outlined, color: navy),
            title: const Text('Portal rujukan resmi'),
            subtitle: Text(portal),
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Checklist sebelum mendaftar\n\n'
              '• Baca pengumuman dan persyaratan tahun berjalan.\n'
              '• Pastikan dokumen dan data identitas sesuai.\n'
              '• Catat jadwal pendaftaran serta lokasi tahapan.\n'
              '• Jangan menggunakan informasi dari pesan berantai sebagai dasar keputusan.',
              style: TextStyle(height: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'EduKreativ hanya menyediakan bahan latihan dan pengingat. Informasi yang mengikat adalah pengumuman dari instansi penyelenggara.',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    ),
  );
}

class KedinasanSchool {
  final String name;
  final String description;
  final String focus;
  final IconData icon;
  final List<KedinasanTwkQuestion> twkQuestions;
  final List<KedinasanTiuQuestion> tiuQuestions;
  final List<KedinasanTkpQuestion> tkpQuestions;
  final List<String> testStages;
  final String officialSource;

  const KedinasanSchool({
    required this.name,
    required this.description,
    required this.focus,
    required this.icon,
    required this.twkQuestions,
    required this.tiuQuestions,
    required this.tkpQuestions,
    required this.testStages,
    required this.officialSource,
  });
}

const _kedinasanSchools = [
  KedinasanSchool(
    name: 'STIN',
    description: 'Sekolah Tinggi Intelijen Negara',
    focus: 'Analisis informasi, intelijen, keamanan nasional, dan ketahanan negara.',
    icon: Icons.security_outlined,
    twkQuestions: STINTwkQuestions,
    tiuQuestions: STINTiuQuestions,
    tkpQuestions: STINTkpQuestions,
    testStages: [
      'Seleksi administrasi',
      'SKD CAT BKN',
      'Seleksi Kompetensi Bidang (SKB)',
      'Pantukhir',
    ],
    officialSource: 'ptb.stin.ac.id — pengumuman seleksi STIN 2026',
  ),
  KedinasanSchool(
    name: 'PKN STAN',
    description: 'Politeknik Keuangan Negara STAN',
    focus: 'Keuangan negara, akuntansi, ekonomi, numerik, dan ketelitian administrasi.',
    icon: Icons.account_balance_outlined,
    twkQuestions: PKNSTANTwkQuestions,
    tiuQuestions: PKNSTANTiuQuestions,
    tkpQuestions: PKNSTANTkpQuestions,
    testStages: [
      'Seleksi administrasi',
      'SKD CAT BKN',
      'Seleksi Lanjutan I',
      'Seleksi Lanjutan II',
      'Seleksi Lanjutan III',
    ],
    officialSource: 'pknstan.ac.id — Siaran Pers SPMB PKN STAN 2025',
  ),
  KedinasanSchool(
    name: 'Poltek SSN',
    description: 'Politeknik Siber dan Sandi Negara',
    focus: 'Keamanan siber, jaringan, logika komputasi, persandian, dan keamanan informasi.',
    icon: Icons.computer_outlined,
    twkQuestions: PoltekSSNTwkQuestions,
    tiuQuestions: PoltekSSNTiuQuestions,
    tkpQuestions: PoltekSSNTkpQuestions,
    testStages: [
      'Seleksi administrasi',
      'SKD CAT BKN',
      'Seleksi akademik/lanjutan',
      'Seleksi kesehatan dan tahap lanjutan sesuai pengumuman',
    ],
    officialSource:
        'penerimaan.poltekssn.ac.id — pengumuman SPTB Poltek SSN 2026',
  ),
  KedinasanSchool(
    name: 'IPDN',
    description: 'Institut Pemerintahan Dalam Negeri',
    focus: 'Pemerintahan, pelayanan publik, administrasi negara, dan kepemimpinan.',
    icon: Icons.account_balance_outlined,
    twkQuestions: IPDNTwkQuestions,
    tiuQuestions: IPDNTiuQuestions,
    tkpQuestions: IPDNTkpQuestions,
    testStages: [
      'Seleksi administrasi',
      'SKD CAT BKN',
      'Seleksi kesehatan',
      'Tes psikologi',
      'Tes kesamaptaan',
      'Wawancara dan tahapan akhir sesuai pengumuman',
    ],
    officialSource: 'pppkp.ipdn.ac.id — pengumuman SPCP IPDN 2026',
  ),
  KedinasanSchool(
    name: 'STMKG',
    description: 'Sekolah Tinggi Meteorologi Klimatologi dan Geofisika',
    focus: 'Matematika, fisika, geografi, cuaca, iklim, dan kebumian.',
    icon: Icons.cloud_outlined,
    twkQuestions: STMKGTwkQuestions,
    tiuQuestions: STMKGTiuQuestions,
    tkpQuestions: STMKGTkpQuestions,
    testStages: [
      'Seleksi administrasi',
      'SKD CAT BKN',
      'Seleksi Kompetensi Bidang (SKB)',
      'Tahapan lanjutan sesuai pengumuman PTB',
    ],
    officialSource: 'ptb.stmkg.ac.id — ketentuan PTB STMKG 2025',
  ),
  KedinasanSchool(
    name: 'Poltekip',
    description: 'Politeknik Ilmu Pemasyarakatan',
    focus: 'Hukum dasar, pemasyarakatan, pelayanan, disiplin, integritas, dan fisik.',
    icon: Icons.gavel_outlined,
    twkQuestions: PoltekipTwkQuestions,
    tiuQuestions: PoltekipTiuQuestions,
    tkpQuestions: PoltekipTkpQuestions,
    testStages: [
      'Seleksi administrasi',
      'SKD CAT BKN',
      'Seleksi lanjutan sesuai pengumuman penerimaan taruna',
    ],
    officialSource: 'Portal Sekdin BKN dan laman resmi Poltekip',
  ),
  KedinasanSchool(
    name: 'Poltekim',
    description: 'Politeknik Imigrasi',
    focus: 'Keimigrasian, hukum, kewarganegaraan, pelayanan publik, dan kebangsaan.',
    icon: Icons.public_outlined,
    twkQuestions: PoltekimTwkQuestions,
    tiuQuestions: PoltekimTiuQuestions,
    tkpQuestions: PoltekimTkpQuestions,
    testStages: [
      'Seleksi administrasi',
      'SKD CAT BKN',
      'Seleksi lanjutan sesuai pengumuman penerimaan taruna',
    ],
    officialSource: 'Portal Sekdin BKN dan laman resmi Poltekim',
  ),
];

class _SkdSchoolCard extends StatelessWidget {
  final KedinasanSchool school;
  final VoidCallback onTap;

  const _SkdSchoolCard({required this.school, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      key: Key('skd-school-${school.name}'),
      onTap: onTap,
      contentPadding: const EdgeInsets.all(16),
      leading: CircleAvatar(
        backgroundColor: orange.withValues(alpha: .18),
        child: Icon(school.icon, color: navy),
      ),
      title: Text(
        school.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(school.description),
      ),
      trailing: const Icon(Icons.chevron_right, color: navy),
    ),
  );
}

class SkdMaterialsPage extends StatelessWidget {
  const SkdMaterialsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Materi Persiapan Sekolah Kedinasan'),
      foregroundColor: navy,
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Pilih Sekolah Kedinasan',
          key: Key('skd-materials-title'),
          style: TextStyle(
            color: navy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pilih sekolah untuk melihat fokus materi persiapan masing-masing. Setiap halaman sekolah memuat materi yang disesuaikan dengan jalur tersebut.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        ..._kedinasanSchools.map(
          (school) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: ListTile(
                key: Key('skd-school-${school.name}'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SkdSchoolMaterialsPage(school: school),
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: orange.withValues(alpha: .18),
                  child: Icon(school.icon, color: navy),
                ),
                title: Text(
                  school.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(school.description),
                ),
                trailing: const Icon(Icons.chevron_right, color: navy),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class SkdSchoolMaterialsPage extends StatelessWidget {
  final KedinasanSchool school;
  const SkdSchoolMaterialsPage({required this.school, super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Materi ${school.name}'), foregroundColor: navy),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          school.name,
          key: const Key('skd-school-detail-title'),
          style: const TextStyle(
            color: navy,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(school.description, style: const TextStyle(color: Colors.black54)),
        const Text(
          'Petunjuk tahapan tes',
          key: Key('skd-test-stages-title'),
          style: TextStyle(
            color: navy,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...school.testStages.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: orange.withValues(alpha: .18),
                  child: Text(
                    '${entry.key + 1}',
                    style: const TextStyle(
                      color: navy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(entry.value),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _SkdMaterialCard(
          title: 'Petunjuk SKD CAT BKN — TWK, TIU, dan TKP',
          subtitle: 'Komponen tes yang perlu dipersiapkan: wawasan kebangsaan, kemampuan verbal/numerik/logika, serta karakteristik pribadi seperti pelayanan, integritas, dan kerja sama.',
          icon: Icons.fact_check_outlined,
        ),
        const SizedBox(height: 12),
        _SkdMaterialCard(
          title: 'Fokus khusus ${school.name}',
          subtitle: school.focus,
          icon: school.icon,
        ),
        const SizedBox(height: 12),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Strategi persiapan\n\n• Pelajari konsep lalu latihan dengan batas waktu.\n• Evaluasi kesalahan dan catat topik yang belum dikuasai.\n• Pantau jadwal dan persyaratan pada portal resmi.\n• Fokus khusus di halaman ini adalah panduan umum, bukan kisi-kisi resmi.',
              style: TextStyle(height: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Sumber resmi acuan: ${school.officialSource}. Selalu cek pengumuman terbaru karena ketentuan dapat berubah.',
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    ),
  );
}

class SkdLegacyMaterialsPage extends StatelessWidget {
  const SkdLegacyMaterialsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Materi SKD Dasar'),
      foregroundColor: navy,
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        Text(
          'Materi SKD Sekolah Kedinasan',
          style: TextStyle(
            color: navy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Ringkasan belajar berdasarkan komponen TWK, TIU, dan TKP. Materi ini adalah bahan latihan, bukan naskah resmi seleksi.',
          style: TextStyle(color: Colors.black54),
        ),
        SizedBox(height: 20),
        _SkdMaterialCard(
          title: 'TWK — Tes Wawasan Kebangsaan',
          subtitle: 'Pancasila, UUD 1945, Bhinneka Tunggal Ika, NKRI, nasionalisme, integritas, dan bela negara.',
          icon: Icons.flag_outlined,
        ),
        SizedBox(height: 12),
        _SkdMaterialCard(
          title: 'TIU — Tes Intelegensia Umum',
          subtitle: 'Kemampuan verbal, numerik, logika, analisis, analogi, silogisme, dan pola figural.',
          icon: Icons.psychology_outlined,
        ),
        SizedBox(height: 12),
        _SkdMaterialCard(
          title: 'TKP — Tes Karakteristik Pribadi',
          subtitle: 'Pelayanan publik, integritas, kerja sama, profesionalisme, adaptasi, dan pengambilan keputusan.',
          icon: Icons.groups_outlined,
        ),
      ],
    ),
  );
}

class _SkdMaterialCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SkdMaterialCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: CircleAvatar(
        backgroundColor: orange.withValues(alpha: .18),
        child: Icon(icon, color: navy),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(subtitle),
      ),
    ),
  );
}

class _SkdQuestion {
  final String category;
  final String question;
  final List<String> options;
  final int answer;
  final String explanation;

  const _SkdQuestion({
    required this.category,
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
  });
}

const _skdQuestions = [
  _SkdQuestion(
    category: 'TWK',
    question:
        'Sikap yang paling sesuai dengan sila Persatuan Indonesia adalah ...',
    options: [
      'Mengutamakan kepentingan kelompok sendiri',
      'Menghargai perbedaan dan menjaga keutuhan bangsa',
      'Menolak semua budaya daerah',
      'Membatasi kerja sama antarwilayah',
    ],
    answer: 1,
    explanation: 'Persatuan diwujudkan dengan menghargai keberagaman dan menjaga keutuhan bangsa.',
  ),
  _SkdQuestion(
    category: 'TWK',
    question: 'Lembaga yang berwenang mengubah dan menetapkan UUD adalah ...',
    options: ['DPR', 'MPR', 'MA', 'BPK'],
    answer: 1,
    explanation: 'UUD 1945 memberikan kewenangan tersebut kepada MPR.',
  ),
  _SkdQuestion(
    category: 'TWK',
    question: 'Bhinneka Tunggal Ika bermakna ...',
    options: [
      'Berbeda-beda tetapi tetap satu',
      'Satu bahasa tanpa perbedaan',
      'Semua daerah harus sama',
      'Perbedaan harus dihilangkan',
    ],
    answer: 0,
    explanation: 'Maknanya adalah keberagaman tetap berada dalam persatuan.',
  ),
  _SkdQuestion(
    category: 'TWK',
    question: 'Contoh perilaku berintegritas adalah ...',
    options: [
      'Mengubah data agar terlihat baik',
      'Menunda pekerjaan tanpa alasan',
      'Menyampaikan data sesuai fakta',
      'Menerima hadiah untuk mempercepat layanan',
    ],
    answer: 2,
    explanation: 'Integritas menuntut kejujuran dan kesesuaian antara data, ucapan, dan tindakan.',
  ),
  _SkdQuestion(
    category: 'TWK',
    question:
        'Bela negara dalam kehidupan sehari-hari dapat dilakukan dengan ...',
    options: [
      'Menyebarkan kabar yang belum terverifikasi',
      'Menaati aturan dan berkontribusi positif',
      'Menghindari semua kegiatan masyarakat',
      'Mengutamakan kepentingan pribadi',
    ],
    answer: 1,
    explanation: 'Bela negara dapat diwujudkan melalui kepatuhan hukum dan kontribusi positif.',
  ),
  _SkdQuestion(
    category: 'TIU',
    question: 'Jika 3x + 5 = 20, nilai x adalah ...',
    options: ['3', '5', '7', '8'],
    answer: 1,
    explanation: '3x = 15 sehingga x = 5.',
  ),
  _SkdQuestion(
    category: 'TIU',
    question: 'Deret 2, 5, 10, 17, 26, ... memiliki angka berikutnya ...',
    options: ['35', '36', '37', '38'],
    answer: 2,
    explanation: 'Selisihnya 3, 5, 7, 9, lalu 11; 26 + 11 = 37.',
  ),
  _SkdQuestion(
    category: 'TIU',
    question:
        'Semua taruna disiplin. Raka adalah taruna. Kesimpulan yang tepat ...',
    options: [
      'Raka tidak disiplin',
      'Raka mungkin disiplin',
      'Raka disiplin',
      'Semua yang disiplin adalah taruna',
    ],
    answer: 2,
    explanation: 'Raka termasuk kelompok taruna, sehingga mengikuti premis bahwa semua taruna disiplin.',
  ),
  _SkdQuestion(
    category: 'TIU',
    question: 'Sinonim kata “akurat” adalah ...',
    options: ['Tepat', 'Lambat', 'Rumit', 'Luas'],
    answer: 0,
    explanation: 'Akurat berarti tepat atau benar.',
  ),
  _SkdQuestion(
    category: 'TIU',
    question: 'Sebuah pekerjaan selesai dalam 6 hari oleh 4 orang. Dengan kecepatan sama, 8 orang menyelesaikannya dalam ...',
    options: ['2 hari', '3 hari', '6 hari', '12 hari'],
    answer: 1,
    explanation:
        'Jumlah pekerja dua kali lipat, waktu menjadi setengahnya: 3 hari.',
  ),
  _SkdQuestion(
    category: 'TKP',
    question:
        'Anda menemukan kesalahan kecil pada laporan sebelum dikirim. Anda ...',
    options: [
      'Membiarkannya',
      'Menyalahkan rekan',
      'Memperbaiki dan memeriksa kembali',
      'Menghapus laporan',
    ],
    answer: 2,
    explanation: 'Tindakan profesional adalah memperbaiki kesalahan dan melakukan pemeriksaan ulang.',
  ),
  _SkdQuestion(
    category: 'TKP',
    question:
        'Rekan satu tim berbeda pendapat tentang pembagian tugas. Anda ...',
    options: [
      'Memaksakan pendapat',
      'Mengajak berdiskusi berdasarkan tujuan pekerjaan',
      'Meninggalkan tim',
      'Melaporkan tanpa berdiskusi',
    ],
    answer: 1,
    explanation: 'Diskusi objektif membantu menemukan pembagian tugas yang adil dan efektif.',
  ),
  _SkdQuestion(
    category: 'TKP',
    question: 'Saat layanan sedang ramai, langkah terbaik adalah ...',
    options: [
      'Melayani yang dikenal dahulu',
      'Menutup layanan',
      'Mengikuti prosedur dan mengatur antrean',
      'Mengabaikan pertanyaan',
    ],
    answer: 2,
    explanation: 'Pelayanan publik harus tertib, adil, dan mengikuti prosedur.',
  ),
  _SkdQuestion(
    category: 'TKP',
    question: 'Anda mendapat tugas baru dengan batas waktu singkat. Anda ...',
    options: [
      'Menolak tanpa mencari tahu',
      'Menyusun prioritas dan mengklarifikasi target',
      'Menunggu diingatkan',
      'Mengerjakan secara acak',
    ],
    answer: 1,
    explanation: 'Prioritas dan klarifikasi target membantu pekerjaan selesai tepat dan terarah.',
  ),
  _SkdQuestion(
    category: 'TKP',
    question: 'Anda menerima informasi penting dari grup percakapan. Sebelum membagikan, Anda ...',
    options: [
      'Langsung meneruskan',
      'Memeriksa sumber dan kebenarannya',
      'Mengubah judulnya',
      'Menyimpan lalu melupakannya',
    ],
    answer: 1,
    explanation: 'Informasi perlu diverifikasi agar tidak menyebarkan kabar yang keliru.',
  ),
];

class SkdTryoutMenuPage extends StatelessWidget {
  const SkdTryoutMenuPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Tryout Sekolah Kedinasan'),
      foregroundColor: navy,
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Pilih Sekolah',
          key: Key('skd-tryout-menu-title'),
          style: TextStyle(
            color: navy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pilih sekolah untuk mengakses latihan TWK, TIU, dan TKP sesuai konteks sekolah tersebut.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        ..._kedinasanSchools.map(
          (school) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SkdSchoolCard(
              school: school,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SkdSchoolTryoutPage(school: school),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class SkdSchoolTryoutPage extends StatelessWidget {
  final KedinasanSchool school;
  const SkdSchoolTryoutPage({required this.school, super.key});

  List<TniBankQuestion> _twkQuestions() => school.twkQuestions
      .map(
        (item) => TniBankQuestion(
          number: item.number,
          category: 'TWK',
          question: item.question,
          options: item.options,
          answer: item.answer,
          explanation: item.explanation,
          interview: false,
        ),
      )
      .toList(growable: false);

  List<TniBankQuestion> _tiuQuestions() => school.tiuQuestions
      .map(
        (item) => TniBankQuestion(
          number: item.number,
          category: 'TIU',
          question: item.question,
          options: item.options,
          answer: item.answer,
          explanation: item.explanation,
          interview: false,
        ),
      )
      .toList(growable: false);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Tryout ${school.name}'), foregroundColor: navy),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          school.name,
          key: const Key('skd-school-tryout-title'),
          style: const TextStyle(
            color: navy,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(school.description, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 16),
        _tryoutTile(
          context,
          key: 'skd-tryout-twk',
          title: 'Latihan TWK',
          subtitle:
              '${school.twkQuestions.length} soal TWK khusus ${school.name}',
          icon: Icons.flag_outlined,
          questions: _twkQuestions(),
        ),
        const SizedBox(height: 12),
        _tryoutTile(
          context,
          key: 'skd-tryout-tiu',
          title: 'Latihan TIU',
          subtitle:
              '${school.tiuQuestions.length} soal TIU khusus ${school.name}',
          icon: Icons.calculate_outlined,
          questions: _tiuQuestions(),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            key: const Key('skd-tryout-tkp'),
            leading: const Icon(Icons.groups_outlined, color: navy),
            title: const Text('Latihan TKP'),
            subtitle: Text(
              '${school.tkpQuestions.length} soal TKP khusus ${school.name}',
            ),
            trailing: const Icon(Icons.chevron_right, color: navy),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TkpPracticePage(
                  title: 'Try Out TKP ${school.name}',
                  questions: school.tkpQuestions,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _tryoutTile(
    BuildContext context, {
    required String key,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<TniBankQuestion> questions,
  }) => Card(
    child: ListTile(
      key: Key(key),
      leading: Icon(icon, color: navy),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, color: navy),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TniBankPracticePage(
            title: 'Try Out $title ${school.name}',
            questions: questions,
          ),
        ),
      ),
    ),
  );
}

class SkdPracticePage extends StatefulWidget {
  const SkdPracticePage({super.key});

  @override
  State<SkdPracticePage> createState() => _SkdPracticePageState();
}

class _SkdPracticePageState extends State<SkdPracticePage> {
  int index = 0;
  int score = 0;
  int? selected;

  void _next() {
    if (selected == null) return;
    if (selected == _skdQuestions[index].answer) score++;
    if (index == _skdQuestions.length - 1) {
      setState(() => index++);
    } else {
      setState(() {
        index++;
        selected = null;
      });
    }
  }

  void _restart() => setState(() {
    index = 0;
    score = 0;
    selected = null;
  });

  @override
  Widget build(BuildContext context) {
    if (index >= _skdQuestions.length) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Hasil Latihan SKD'),
          foregroundColor: navy,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  color: orange,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Latihan selesai',
                  style: TextStyle(
                    color: navy,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Skor kamu: $score/${_skdQuestions.length}',
                  key: const Key('skd-score'),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _restart,
                  child: const Text('Ulangi latihan'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final item = _skdQuestions[index];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Latihan SKD Dasar'),
        foregroundColor: navy,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Soal ${index + 1} dari ${_skdQuestions.length} · ${item.category}',
            style: const TextStyle(color: blue, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            item.question,
            style: const TextStyle(
              color: navy,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            item.options.length,
            (optionIndex) => Card(
              child: ListTile(
                leading: Icon(
                  selected == optionIndex
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected == optionIndex ? blue : Colors.black38,
                ),
                title: Text(item.options[optionIndex]),
                onTap: () => setState(() => selected = optionIndex),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: selected == null ? null : _next,
            child: Text(
              index == _skdQuestions.length - 1
                  ? 'Lihat hasil'
                  : 'Soal berikutnya',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Soal latihan orisinal EduKreativ. Bukan soal resmi atau bocoran seleksi.',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class TkpPracticePage extends StatefulWidget {
  final String title;
  final List<KedinasanTkpQuestion> questions;

  const TkpPracticePage({
    required this.title,
    required this.questions,
    super.key,
  });

  @override
  State<TkpPracticePage> createState() => _TkpPracticePageState();
}

class _TkpPracticePageState extends State<TkpPracticePage> {
  int index = 0;
  final Map<int, int> selected = {};
  bool submitted = false;
  int get score => selected.entries.fold(
    0,
    (sum, item) => sum + widget.questions[item.key].scores[item.value],
  );

  @override
  Widget build(BuildContext context) {
    if (submitted) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title), foregroundColor: navy),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  size: 64,
                  color: orange,
                ),
                const SizedBox(height: 12),
                Text(
                  'Skor TKP: $score / ${widget.questions.length * 5}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Skor ini adalah simulasi berbobot 1–5, bukan nilai resmi seleksi.',
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kembali ke daftar TKP'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final item = widget.questions[index];
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), foregroundColor: navy),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Soal ${index + 1} dari ${widget.questions.length} · TKP',
            style: const TextStyle(color: navy, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            item.question,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          RadioGroup<int>(
            groupValue: selected[index],
            onChanged: (value) {
              if (value != null) setState(() => selected[index] = value);
            },
            child: Column(
              children: List.generate(
                item.options.length,
                (option) => RadioListTile<int>(
                  value: option,
                  title: Text(
                    '${String.fromCharCode(65 + option)}. ${item.options[option]}',
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: selected[index] == null
                ? null
                : () {
                    if (index == widget.questions.length - 1) {
                      setState(() => submitted = true);
                    } else {
                      setState(() => index++);
                    }
                  },
            child: Text(
              index == widget.questions.length - 1
                  ? 'Lihat hasil'
                  : 'Soal berikutnya',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Penilaian TKP menggunakan skor situasional bertingkat. Pilih respons yang paling tepat.',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class TniBankQuestion {
  final int number;
  final String category;
  final String question;
  final List<String> options;
  final int? answer;
  final String explanation;
  final bool interview;

  const TniBankQuestion({
    required this.number,
    required this.category,
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
    required this.interview,
  });
}

final _mentalIdeologyTryoutItems = mentalIdeologyQuestions
    .map(
      (item) => TniBankQuestion(
        number: item.number,
        category: item.category,
        question: item.question,
        options: item.options,
        answer: item.answer,
        explanation: item.explanation,
        interview: item.interview,
      ),
    )
    .toList(growable: false);

final _tniAcademicTryoutItems = tniAcademicQuestions
    .map(
      (item) => TniBankQuestion(
        number: item.number,
        category: item.category,
        question: item.question,
        options: item.options,
        answer: item.answer,
        explanation: item.explanation,
        interview: false,
      ),
    )
    .toList(growable: false);

final _akpolCatTryoutItems = akpolCatQuestions
    .map(
      (item) => TniBankQuestion(
        number: item.number,
        category: item.category,
        question: item.question,
        options: item.options,
        answer: item.answer,
        explanation: item.explanation,
        interview: false,
      ),
    )
    .toList(growable: false);

class TniBankPracticePage extends StatefulWidget {
  final String title;
  final List<TniBankQuestion> questions;

  const TniBankPracticePage({
    required this.title,
    required this.questions,
    super.key,
  });

  @override
  State<TniBankPracticePage> createState() => _TniBankPracticePageState();
}

class _TniBankPracticePageState extends State<TniBankPracticePage> {
  static const totalSeconds = 60 * 60;
  final responseController = TextEditingController();
  int index = 0;
  int score = 0;
  int answered = 0;
  int remainingSeconds = totalSeconds;
  int? selected;
  bool checked = false;
  bool resultSaved = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || remainingSeconds <= 1) {
        timer?.cancel();
        if (mounted && remainingSeconds <= 1) _finish(timedOut: true);
        return;
      }
      setState(() => remainingSeconds--);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    responseController.dispose();
    super.dispose();
  }

  String get timeLabel {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _checkAnswer() {
    final item = widget.questions[index];
    if (checked ||
        (item.interview
            ? responseController.text.trim().isEmpty
            : selected == null)) {
      return;
    }
    if (!item.interview && selected == item.answer) {
      score++;
    }
    answered++;
    setState(() => checked = true);
  }

  void _next() {
    if (!checked) return;
    if (index == widget.questions.length - 1) {
      _finish();
      return;
    }
    responseController.clear();
    setState(() {
      index++;
      selected = null;
      checked = false;
    });
  }

  void _finish({bool timedOut = false}) {
    timer?.cancel();
    if (!resultSaved) {
      TniTryoutHistory.add(
        TniTryoutResult(
          score: score,
          total: widget.questions.length,
          completedAt: DateTime.now(),
          timedOut: timedOut,
        ),
      );
      resultSaved = true;
    }
    setState(() => index = widget.questions.length);
  }

  void _restart() {
    timer?.cancel();
    responseController.clear();
    setState(() {
      index = 0;
      score = 0;
      answered = 0;
      remainingSeconds = totalSeconds;
      selected = null;
      checked = false;
      resultSaved = false;
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (index >= widget.questions.length) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Hasil ${widget.title}'),
          foregroundColor: navy,
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.emoji_events_outlined, color: orange, size: 64),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Latihan selesai',
                style: const TextStyle(
                  color: navy,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Skor pilihan ganda: $score/${widget.questions.length}',
                key: const Key('tni-bank-score'),
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Respons diperiksa: $answered/${widget.questions.length}',
                style: const TextStyle(color: Colors.black54),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Sumber soal: TB XI',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _restart,
              child: const Text('Ulangi latihan'),
            ),
          ],
        ),
      );
    }

    final item = widget.questions[index];
    final correct = selected == item.answer;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        foregroundColor: navy,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                timeLabel,
                key: const Key('tni-bank-timer'),
                style: const TextStyle(
                  color: navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.title,
            key: const Key('tni-bank-title'),
            style: const TextStyle(
              color: navy,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Soal ${index + 1} dari ${widget.questions.length} · ${item.category}',
            style: const TextStyle(color: blue, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          Text(
            item.question,
            style: const TextStyle(
              color: navy,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (item.interview)
            TextField(
              controller: responseController,
              enabled: !checked,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Tuliskan jawabanmu',
                border: OutlineInputBorder(),
              ),
            )
          else
            ...List.generate(
              item.options.length,
              (optionIndex) => Card(
                child: ListTile(
                  leading: Icon(
                    selected == optionIndex
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected == optionIndex ? blue : Colors.black38,
                  ),
                  title: Text(item.options[optionIndex]),
                  onTap: checked
                      ? null
                      : () => setState(() => selected = optionIndex),
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (checked)
            Card(
              key: const Key('tni-bank-explanation'),
              color: item.interview
                  ? const Color(0xFFEAF2FF)
                  : (correct
                        ? const Color(0xFFE7F7EE)
                        : const Color(0xFFFFF0E4)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  item.interview
                      ? 'Arah pengembangan jawaban:\n${item.explanation}'
                      : '${correct ? 'Jawaban benar.' : 'Jawaban belum tepat.'}\n\nJawaban yang tepat: ${item.options[item.answer!]}\n${item.explanation}',
                  style: const TextStyle(height: 1.45),
                ),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: item.interview
                  ? (responseController.text.trim().isEmpty
                        ? null
                        : (checked ? _next : _checkAnswer))
                  : (selected == null
                        ? null
                        : (checked ? _next : _checkAnswer)),
              child: Text(
                checked
                    ? (index == widget.questions.length - 1
                          ? 'Lihat hasil'
                          : 'Soal berikutnya')
                    : 'Periksa jawaban',
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sumber soal: TB XI',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class AkpolPmkPage extends StatefulWidget {
  const AkpolPmkPage({super.key});

  @override
  State<AkpolPmkPage> createState() => _AkpolPmkPageState();
}

class _AkpolPmkPageState extends State<AkpolPmkPage> {
  late final List<TextEditingController> controllers;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(
      akpolPmkQuestions.length,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('PMK AKPOL'), foregroundColor: navy),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'PMK — Penelusuran Mental Kepribadian',
          key: Key('akpol-pmk-title'),
          style: TextStyle(
            color: navy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Latihan wawancara dan refleksi diri. PMK bukan tes hafalan dan tidak dinilai benar atau salah.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        Card(
          color: const Color(0xFFEAF2FF),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Panduan persiapan',
                  style: TextStyle(color: navy, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...akpolPmkGuidance.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $item'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...akpolPmkQuestions.asMap().entries.map(
          (entry) => Card(
            child: ExpansionTile(
              key: Key('akpol-pmk-question-${entry.key + 1}'),
              title: Text(
                '${entry.value.number}. ${entry.value.question}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(entry.value.category),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                TextField(
                  controller: controllers[entry.key],
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Jawaban pribadi',
                    hintText:
                        'Tuliskan jawaban sesuai pengalaman sebenarnya...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Lihat contoh pola jawaban'),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        entry.value.exampleAnswer,
                        style: const TextStyle(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sumber: TB XI. Contoh jawaban bukan jawaban resmi dan tidak untuk dihafalkan.',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    ),
  );
}

class AkpolInterviewPage extends StatefulWidget {
  const AkpolInterviewPage({super.key});

  @override
  State<AkpolInterviewPage> createState() => _AkpolInterviewPageState();
}

class _AkpolInterviewPageState extends State<AkpolInterviewPage> {
  late final List<TextEditingController> controllers;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(
      akpolInterviewQuestions.length,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Wawancara AKPOL'), foregroundColor: navy),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Materi Wawancara AKPOL',
          key: Key('akpol-interview-title'),
          style: TextStyle(
            color: navy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Latihan motivasi, kepribadian, kebangsaan, dan kesiapan tugas. Contoh jawaban harus disesuaikan dengan fakta diri.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        Card(
          color: const Color(0xFFEAF2FF),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cara menggunakan materi',
                  style: TextStyle(color: navy, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...akpolInterviewGuidance.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $item'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...akpolInterviewQuestions.asMap().entries.map(
          (entry) => Card(
            child: ExpansionTile(
              key: Key('akpol-interview-question-${entry.key + 1}'),
              title: Text(
                '${entry.value.number}. ${entry.value.question}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(entry.value.category),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                TextField(
                  controller: controllers[entry.key],
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Jawaban pribadi',
                    hintText:
                        'Tuliskan jawaban sesuai pengalaman sebenarnya...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Lihat contoh cara menjawab'),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        entry.value.exampleAnswer,
                        style: const TextStyle(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sumber: TB XI. Contoh jawaban bukan jawaban resmi dan tidak untuk dihafalkan.',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    ),
  );
}

class AkpolTryoutMenuPage extends StatelessWidget {
  const AkpolTryoutMenuPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Try Out AKPOL'), foregroundColor: navy),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Pilih try out AKPOL',
          key: Key('akpol-tryout-menu-title'),
          style: TextStyle(
            color: navy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Latihan berdasarkan bagian seleksi AKPOL.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        _TryoutMenuOption(
          key: const Key('akpol-tryout-akademik-cat'),
          title: 'Tes Akademik CAT',
          subtitle: 'Pengetahuan umum, wawasan, bahasa, matematika, dan logika',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TniBankPracticePage(
                title: 'Try Out Tes Akademik CAT AKPOL',
                questions: _akpolCatTryoutItems,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _TryoutMenuOption(
          key: const Key('akpol-tryout-pmk'),
          title: 'PMK — Penelusuran Mental Kepribadian',
          subtitle:
              'Latihan integritas, kepribadian, dan penelusuran rekam jejak',
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const AkpolPmkPage())),
        ),
        const SizedBox(height: 12),
        _TryoutMenuOption(
          key: const Key('akpol-tryout-wawancara'),
          title: 'Wawancara',
          subtitle:
              'Latihan menjawab pertanyaan secara jujur, jelas, dan konsisten',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AkpolInterviewPage())),
        ),
        const SizedBox(height: 12),
        _TryoutMenuOption(
          key: const Key('akpol-tryout-psikotest'),
          title: 'Psikotest',
          subtitle: 'Latihan ketelitian, konsistensi, dan pengenalan diri',
          onTap: () => _showComingSoon(context, 'Psikotest'),
        ),
      ],
    ),
  );
}

class TniTryoutMenuPage extends StatelessWidget {
  const TniTryoutMenuPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Try Out Akademi TNI'),
      foregroundColor: navy,
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Pilih try out',
          key: Key('tni-tryout-menu-title'),
          style: TextStyle(
            color: navy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Latihan berdasarkan bagian seleksi Akademi TNI.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        _TryoutMenuOption(
          key: const Key('tryout-tka-akademi-tni'),
          title: 'TKA Akademi TNI',
          subtitle: '50 soal · Matematika, bahasa, IPA, wawasan, dan logika',
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const TniPracticePage())),
        ),
        const SizedBox(height: 12),
        _TryoutMenuOption(
          key: const Key('tryout-mental-ideologi'),
          title: 'Mental Ideologi',
          subtitle:
              'Latihan nilai kebangsaan, NKRI, integritas, dan tanggung jawab',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TniBankPracticePage(
                title: 'Try Out Mental Ideologi',
                questions: _mentalIdeologyTryoutItems,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _TryoutMenuOption(
          key: const Key('tryout-akademik-siber'),
          title: 'Akademik dan Siber',
          subtitle: 'Latihan akademik dasar dan keamanan siber',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TniBankPracticePage(
                title: 'Try Out Akademik dan Siber',
                questions: _tniAcademicTryoutItems,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _TryoutMenuOption(
          key: const Key('tryout-psikotest'),
          title: 'Psikotest',
          subtitle: 'Persiapan latihan psikologi dan pengenalan diri',
          onTap: () => _showComingSoon(context, 'Psikotest'),
        ),
      ],
    ),
  );
}

class _TryoutMenuOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TryoutMenuOption({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFFFE8D4),
        child: Icon(Icons.fact_check_outlined, color: navy),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(subtitle),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class TniTryoutResult {
  final int score;
  final int total;
  final DateTime completedAt;
  final bool timedOut;

  const TniTryoutResult({
    required this.score,
    required this.total,
    required this.completedAt,
    required this.timedOut,
  });
}

class TniTryoutHistory {
  TniTryoutHistory._();

  static final results = <TniTryoutResult>[];

  static void add(TniTryoutResult result) => results.insert(0, result);
}

class TniPracticePage extends StatefulWidget {
  const TniPracticePage({super.key});

  @override
  State<TniPracticePage> createState() => _TniPracticePageState();
}

class _TniPracticePageState extends State<TniPracticePage> {
  static const totalSeconds = 60 * 60;
  int index = 0;
  int score = 0;
  int? selected;
  bool checked = false;
  int remainingSeconds = totalSeconds;
  Timer? timer;
  bool resultSaved = false;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || remainingSeconds <= 1) {
        timer?.cancel();
        if (mounted && remainingSeconds <= 1) _finish(timedOut: true);
        return;
      }
      setState(() => remainingSeconds--);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String get timeLabel {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _checkAnswer() {
    if (selected == null || checked) return;
    if (selected == tniTryoutQuestions[index].answer) score++;
    setState(() => checked = true);
  }

  void _next() {
    if (!checked) return;
    if (index == tniTryoutQuestions.length - 1) {
      _finish();
      return;
    }
    setState(() {
      index++;
      selected = null;
      checked = false;
    });
  }

  void _finish({bool timedOut = false}) {
    timer?.cancel();
    if (!resultSaved) {
      TniTryoutHistory.add(
        TniTryoutResult(
          score: score,
          total: tniTryoutQuestions.length,
          completedAt: DateTime.now(),
          timedOut: timedOut,
        ),
      );
      resultSaved = true;
    }
    setState(() => index = tniTryoutQuestions.length);
  }

  void _restart() {
    timer?.cancel();
    setState(() {
      index = 0;
      score = 0;
      selected = null;
      checked = false;
      remainingSeconds = totalSeconds;
      resultSaved = false;
    });
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || remainingSeconds <= 1) {
        timer?.cancel();
        if (mounted && remainingSeconds <= 1) _finish(timedOut: true);
        return;
      }
      setState(() => remainingSeconds--);
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }

  Widget _historyView() {
    if (TniTryoutHistory.results.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        const Text(
          'Riwayat hasil',
          style: TextStyle(
            color: navy,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...TniTryoutHistory.results.map(
          (result) => Card(
            child: ListTile(
              leading: const Icon(Icons.history, color: blue),
              title: Text('Skor ${result.score}/${result.total}'),
              subtitle: Text(
                '${_formatDate(result.completedAt)}${result.timedOut ? ' · Waktu habis' : ''}',
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (index >= tniTryoutQuestions.length) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Hasil Try Out Akademi TNI'),
          foregroundColor: navy,
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.emoji_events_outlined, color: orange, size: 64),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Try out selesai',
                style: TextStyle(
                  color: navy,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Skor kamu: $score/${tniTryoutQuestions.length}',
                key: const Key('tni-tryout-score'),
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Sumber soal: TB XI',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            if (resultSaved && TniTryoutHistory.results.first.timedOut)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    'Waktu habis. Jawaban yang sudah diperiksa tetap dihitung.',
                  ),
                ),
              ),
            _historyView(),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _restart,
              child: const Text('Ulangi try out'),
            ),
          ],
        ),
      );
    }

    final item = tniTryoutQuestions[index];
    final correct = selected == item.answer;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Try Out TKD Akademi TNI'),
        foregroundColor: navy,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                timeLabel,
                key: const Key('tni-tryout-timer'),
                style: TextStyle(
                  color: remainingSeconds < 300 ? Colors.red : navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Try Out TKD Akademi TNI',
            key: Key('tni-tryout-title'),
            style: TextStyle(
              color: navy,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Soal ${index + 1} dari ${tniTryoutQuestions.length} · ${item.category}',
            style: const TextStyle(color: blue, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          Text(
            item.question,
            style: const TextStyle(
              color: navy,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            item.options.length,
            (optionIndex) => Card(
              child: ListTile(
                leading: Icon(
                  selected == optionIndex
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected == optionIndex ? blue : Colors.black38,
                ),
                title: Text(item.options[optionIndex]),
                onTap: checked
                    ? null
                    : () => setState(() => selected = optionIndex),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (checked)
            Card(
              key: const Key('tni-explanation'),
              color: correct
                  ? const Color(0xFFE7F7EE)
                  : const Color(0xFFFFF0E4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${correct ? 'Jawaban benar.' : 'Jawaban belum tepat.'}\n\n'
                  'Jawaban yang tepat: ${item.options[item.answer]}\n'
                  '${item.explanation}',
                  style: const TextStyle(height: 1.45),
                ),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: selected == null
                  ? null
                  : (checked ? _next : _checkAnswer),
              child: Text(
                checked
                    ? (index == tniTryoutQuestions.length - 1
                          ? 'Lihat hasil'
                          : 'Soal berikutnya')
                    : 'Periksa jawaban',
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sumber soal: TB XI',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class AkpolMaterialsPage extends StatelessWidget {
  const AkpolMaterialsPage({super.key});

  static const modules = [
    (
      'Administrasi dan verifikasi',
      'Pahami dokumen, verifikasi, pakta integritas, dan kesesuaian data sesuai pengumuman penerimaan tahun berjalan.',
      Icons.fact_check_outlined,
    ),
    (
      'Tes Akademik CAT',
      'Persiapkan pengetahuan umum, wawasan kebangsaan, Bahasa Indonesia, Bahasa Inggris, Matematika, serta kemampuan logis dan analitis.',
      Icons.school_outlined,
    ),
    (
      'Psikologi dan wawancara',
      'Latih ketelitian, konsistensi, pengenalan diri, serta kemampuan menjelaskan pengalaman dan motivasi secara jujur.',
      Icons.psychology_outlined,
    ),
    (
      'PMK — Penelusuran Mental Kepribadian',
      'Pahami pentingnya integritas, rekam jejak, tanggung jawab, relasi sosial, dan keterbukaan dalam proses penelusuran.',
      Icons.manage_search_outlined,
    ),
    (
      'Kesehatan',
      'Jaga kondisi kesehatan dan pahami bahwa pemeriksaan kesehatan tahap I dan II mengikuti ketentuan panitia serta standar yang berlaku.',
      Icons.health_and_safety_outlined,
    ),
    (
      'Jasmani',
      'Bangun daya tahan, kekuatan, kecepatan, kelincahan, dan kebugaran secara bertahap dengan latihan yang aman.',
      Icons.directions_run_outlined,
    ),
    (
      'Antropometri',
      'Pahami bahwa pengukuran dan penilaian antropometri dilakukan sesuai ketentuan seleksi yang berlaku pada tahun berjalan.',
      Icons.straighten_outlined,
    ),
    (
      'Uji kompetensi dan sidang',
      'Siapkan sikap, dokumen, dan komunikasi untuk tahapan uji kompetensi serta sidang sesuai jadwal resmi.',
      Icons.gavel_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Materi AKPOL'), foregroundColor: navy),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Materi Persiapan AKPOL',
          key: Key('akpol-materials-title'),
          style: TextStyle(
            color: navy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Struktur mengikuti tahapan seleksi AKPOL yang diumumkan Polri. Persyaratan, materi, jadwal, dan pembobotan dapat berubah.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        ...modules.map(
          (module) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: blue.withValues(alpha: .12),
                  child: Icon(module.$3, color: blue),
                ),
                title: Text(
                  module.$1,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(module.$2),
                ),
              ),
            ),
          ),
        ),
        const Text(
          'Sumber acuan: penerimaan.polri.go.id. Verifikasi selalu pengumuman resmi terbaru sebelum mengikuti seleksi.',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    ),
  );
}

class TniMaterialsPage extends StatelessWidget {
  const TniMaterialsPage({super.key});

  static const modules = [
    (
      'Administrasi',
      'Siapkan dokumen sesuai pengumuman resmi dan periksa kesesuaian data sebelum pendaftaran.',
    ),
    (
      'Tes Kompetensi Dasar',
      'Latihan penalaran, wawasan kebangsaan, kemampuan verbal, dan numerik secara terukur.',
    ),
    (
      'Kesehatan',
      'Pahami pemeriksaan kesehatan tahap I dan II; kondisi serta ketentuan dapat berbeda tiap penerimaan.',
    ),
    (
      'Kesamaptaan jasmani',
      'Bangun daya tahan, kekuatan, kecepatan, dan kelincahan dengan latihan bertahap dan aman.',
    ),
    (
      'Mental ideologi',
      'Pelajari nilai kebangsaan, komitmen terhadap NKRI, integritas, dan tanggung jawab sebagai calon prajurit.',
    ),
    (
      'Psikologi',
      'Latih konsistensi, ketelitian, pengenalan diri, dan kesiapan menghadapi asesmen psikologi.',
    ),
    (
      'Akademik dan siber',
      'Perkuat pelajaran dasar yang diumumkan serta kewaspadaan digital dan keamanan informasi.',
    ),
    (
      'Pantukhir',
      'Persiapkan rekam data, sikap, kebugaran, dan komunikasi; keputusan mengikuti ketentuan panitia resmi.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Materi Akademi TNI'),
      foregroundColor: navy,
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Materi Persiapan Akademi TNI',
          key: Key('tni-materials-title'),
          style: TextStyle(
            color: navy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Rangkuman ini mengikuti struktur tahapan pada portal rekrutmen TNI. Syarat dan materi dapat berubah sesuai pengumuman tahun berjalan.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        ...modules.map(
          (module) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: orange.withValues(alpha: .18),
                  child: const Icon(Icons.military_tech, color: navy),
                ),
                title: Text(
                  module.$1,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(module.$2),
                ),
              ),
            ),
          ),
        ),
        const Text(
          'Sumber acuan: taruna.rekrutmen-tni.mil.id. Verifikasi selalu informasi terbaru melalui portal resmi sebelum mengikuti seleksi.',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    ),
  );
}

class _KedinasanStatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _KedinasanStatusCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: blue.withValues(alpha: .12),
        child: Icon(icon, color: blue),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class ExamPage extends StatelessWidget {
  const ExamPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ujian Kreativ'), foregroundColor: navy),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Pilih ujian',
          style: TextStyle(
            color: navy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text('Uji pemahamanmu dengan latihan singkat.'),
        const SizedBox(height: 20),
        _ExamOption(
          title: 'Ujian Matematika Dasar',
          subtitle: '10 soal · 15 menit',
          onTap: () => _showComingSoon(context, 'Ujian Matematika Dasar'),
        ),
        const SizedBox(height: 12),
        _ExamOption(
          title: 'Ujian Sains SMP',
          subtitle: '10 soal · 15 menit',
          onTap: () => _showComingSoon(context, 'Ujian Sains SMP'),
        ),
      ],
    ),
  );
}

class _ExamOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExamOption({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFFFE8D4),
        child: Icon(Icons.quiz, color: orange),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class AskKreativPage extends StatefulWidget {
  const AskKreativPage({super.key});

  @override
  State<AskKreativPage> createState() => _AskKreativPageState();
}

class _AskKreativPageState extends State<AskKreativPage> {
  final questionController = TextEditingController();
  String? answer;

  @override
  void dispose() {
    questionController.dispose();
    super.dispose();
  }

  void ask() {
    if (questionController.text.trim().isEmpty) return;
    setState(() {
      answer = 'Pertanyaanmu sudah dicatat. Coba cari topiknya di Academy Kreativ untuk mulai belajar.';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tanya Kreativ'), foregroundColor: navy),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Tanya apa saja',
          style: TextStyle(
            color: navy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text('Tuliskan pertanyaan belajar yang ingin kamu pahami.'),
        const SizedBox(height: 20),
        TextField(
          controller: questionController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Pertanyaanmu',
            hintText: 'Contoh: bagaimana cara menghitung luas segitiga?',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: ask,
          icon: const Icon(Icons.send),
          label: const Text('Kirim pertanyaan'),
        ),
        if (answer != null) ...[
          const SizedBox(height: 20),
          Card(
            color: const Color(0xFFEAF8F2),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(answer!),
            ),
          ),
        ],
      ],
    ),
  );
}

void _showComingSoon(BuildContext context, String title) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text('Fitur $title belum tersedia.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );
}

class _TeacherJoinCard extends StatelessWidget {
  final VoidCallback onTap;

  const _TeacherJoinCard({required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFD8F3E6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF168C87).withValues(alpha: .28)),
        boxShadow: const [
          BoxShadow(color: Color(0x0C152B55), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'GURU KREATIV',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF126B4B), fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'JOIN US',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF126B4B), fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    ),
  );
}

class _CreativeMenuCards extends StatelessWidget {
  final ValueChanged<String> onTap;

  const _CreativeMenuCards({required this.onTap});

  static const items = [
    (title: 'Game Kreativ', icon: Icons.sports_esports_outlined, color: blue),
    (title: 'Cerita Kreativ', icon: Icons.auto_stories_outlined, color: orange),
    (
      title: 'Promo Kreativ',
      icon: Icons.local_offer_outlined,
      color: Color(0xFF45B88A),
    ),
    (
      title: 'Camp Kreativ',
      icon: Icons.groups_2_outlined,
      color: Color(0xFF8B6FE8),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 122,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = ((constraints.maxWidth - 36) / 4).clamp(
            68.0,
            110.0,
          ).toDouble();
          return Row(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  SizedBox(
                    width: width,
                    child: InkWell(
                      onTap: () => onTap(items[index].title),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        height: 122,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: items[index].color.withValues(alpha: .18),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0C152B55),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: items[index].color.withValues(
                                  alpha: .15,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(
                                items[index].icon,
                                color: items[index].color,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              items[index].title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: navy,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (index < items.length - 1) const SizedBox(width: 12),
                ],
              ],
            );
        },
      ),
    );
  }
}

class CreativeStory {
  final String title;
  final String origin;
  final String summary;
  final String moral;
  final IconData icon;
  final Color color;
  final List<String> pages;

  const CreativeStory({
    required this.title,
    required this.origin,
    required this.summary,
    required this.moral,
    required this.icon,
    required this.color,
    required this.pages,
  });
}

const creativeStories = [
  CreativeStory(
    title: 'Timun Mas',
    origin: 'Jawa Tengah',
    summary: 'Kisah keberanian seorang anak menghadapi raksasa.',
    moral: 'Berani menghadapi masalah dan tidak mudah menyerah.',
    icon: Icons.eco_outlined,
    color: Color(0xFF45B88A),
    pages: [
      'Di sebuah desa yang dikelilingi sawah dan hutan, hiduplah Mbok Srini, seorang janda yang bekerja keras. Setiap sore ia duduk di depan rumah sambil memandangi anak-anak bermain. “Andai aku memiliki anak, tentu rumah ini terasa lebih ramai,” gumamnya. Malamnya ia berdoa, “Tuhan, izinkan aku merawat seorang anak dengan penuh kasih.”',
      'Suatu pagi, saat mencari kayu di hutan, Mbok Srini bertemu Buto Ijo, raksasa bertubuh besar. “Aku tahu keinginanmu,” kata Buto Ijo. Ia menyerahkan sebuah biji mentimun. “Tanamlah. Kelak kau mendapat anak.” Mbok Srini bertanya, “Apa yang harus kubayar?” Buto Ijo menjawab, “Ketika anak itu berusia tujuh belas tahun, serahkan ia kepadaku.” Karena sangat ingin menjadi ibu, Mbok Srini menyetujui syarat itu.',
      'Mbok Srini menanam biji tersebut di belakang rumah dan merawatnya setiap hari. Tanaman itu tumbuh cepat, sulurnya memenuhi halaman, dan muncul satu mentimun emas yang sangat besar. Saat dibelah, di dalamnya terdapat bayi perempuan. “Anakku,” seru Mbok Srini sambil menangis bahagia. Ia menamai bayi itu Timun Mas dan membesarkannya dengan kasih sayang.',
      'Timun Mas tumbuh menjadi gadis yang rajin. Ia membantu di ladang, mengambil air, dan selalu berbicara lembut kepada ibunya. Namun, ketika ulang tahunnya yang ketujuh belas semakin dekat, Mbok Srini sering terlihat murung. “Ibu menyembunyikan kesedihan,” kata Timun Mas. Akhirnya Mbok Srini menceritakan perjanjian dengan Buto Ijo. “Jangan takut, Nak. Kita akan mencari pertolongan,” ujarnya sambil memeluk Timun Mas.',
      'Mereka pergi menemui seorang pertapa di atas bukit. Setelah mendengar kisahnya, pertapa berkata, “Buto Ijo kuat, tetapi kecerdikan dan keberanian dapat mengalahkannya.” Ia memberikan empat bungkusan: biji mentimun, jarum, garam, dan terasi. “Gunakan satu per satu ketika ia mengejar,” pesannya. Timun Mas menggenggam bungkusan itu dan berjanji, “Aku akan berusaha sekuat tenaga.”',
      'Pada pagi yang telah ditentukan, Buto Ijo datang mengguncang rumah. “Mbok Srini, serahkan Timun Mas!” teriaknya. Sang ibu berkata, “Beri kami sedikit waktu.” Timun Mas segera berlari ke hutan. Buto Ijo menyusul dengan langkah panjang. Ketika jaraknya dekat, Timun Mas menaburkan biji mentimun. Seketika tumbuh ladang luas. “Tanaman kecil tidak akan menghentikanku!” geram Buto Ijo sambil merobek sulur-sulur mentimun.',
      'Timun Mas terus berlari. Saat raksasa hampir menangkapnya, ia melemparkan jarum. Jarum-jarum itu berubah menjadi hutan bambu yang rapat dan runcing. Buto Ijo terluka, tetapi ia tetap mengejar. Timun Mas lalu menaburkan garam. Tanah berubah menjadi lautan luas. Raksasa berenang dengan susah payah sambil berteriak, “Aku pasti mendapatimu!”',
      'Buto Ijo kembali mendekat. Dengan napas terengah-engah, Timun Mas melemparkan bungkusan terakhir. Terasi itu berubah menjadi lautan lumpur mendidih. Buto Ijo terperosok semakin dalam. “Tolong!” teriaknya, tetapi lumpur menelannya. Timun Mas berlari pulang dan memeluk ibunya. “Kita selamat, Bu.” Mbok Srini menjawab, “Keberanianmu menyelamatkan kita.” Sejak itu mereka hidup damai dan selalu mengingat bahwa kasih sayang harus disertai keberanian.',
    ],
  ),
  CreativeStory(
    title: 'Seribu Kunang-Kunang',
    origin: 'Cerita inspiratif Nusantara',
    summary: 'Cahaya kecil yang menjadi harapan bagi sebuah desa.',
    moral: 'Kebaikan kecil akan berarti jika dilakukan bersama-sama.',
    icon: Icons.lightbulb_outline,
    color: Color(0xFFFF9B42),
    pages: [
      'Di Desa Lembah Jernih, tinggal Raka bersama ibunya, Bu Sari. Setiap malam Raka mengamati kunang-kunang di tepi sawah. “Mengapa mereka tetap bercahaya saat desa kita gelap?” tanyanya. Bu Sari menjawab, “Mungkin karena satu sama lain saling menerangi.”',
      'Kemarau panjang membuat sungai mengering dan sawah retak. Anak-anak sulit belajar, sementara warga harus pulang sebelum malam. Raka berkata kepada Pak Lurah, “Kita masih punya mata air di bukit.” Pak Lurah menggeleng, “Salurannya sudah tertutup longsor.”',
      'Raka mengajak teman-temannya naik ke bukit. Mereka menemukan saluran lama penuh batu dan ranting. “Kalau kita membersihkannya bersama, air bisa mengalir lagi,” kata Raka. Beberapa orang menertawakan mereka, tetapi Bu Sari membawa makanan dan mulai membantu.',
      'Keesokan harinya, warga ikut bekerja. Mereka mengangkat batu, memotong semak, dan memperbaiki bagian saluran yang pecah. Pak Lurah berkata, “Jangan terburu-buru. Kita harus bekerja aman.” Raka menjawab, “Baik, Pak. Yang penting kita tidak menyerah.”',
      'Malam datang sebelum pekerjaan selesai. Hujan deras turun di bukit dan air tiba-tiba meluncur melalui saluran. Dinding tanah hampir jebol. “Semua mundur!” seru Pak Lurah. Raka melihat bambu dan karung pasir di dekat pos jaga lalu berkata, “Kita bisa membuat penahan sementara!”',
      'Warga bekerja bersama. Ada yang mengikat bambu, ada yang mengisi karung, dan anak-anak menerangi tempat kerja dengan lentera. “Aku takut,” bisik seorang anak. Raka menjawab, “Tak apa takut, tetapi kita tetap berhati-hati dan saling menjaga.”',
      'Menjelang pagi, aliran air menjadi tenang. Saluran belum sempurna, tetapi sawah mulai mendapat air. Pak Lurah menepuk bahu Raka. “Usulmu menyatukan warga,” katanya. Raka tersenyum, “Saya hanya memulai. Yang membuatnya berhasil adalah semua orang.”',
      'Warga lalu membuat lentera dari botol bekas dan menaruhnya di sepanjang jalan. Cahaya itu berkelip seperti seribu kunang-kunang. Anak-anak dapat belajar di balai desa, dan desa menjadi lebih aman. Raka memahami bahwa harapan kecil akan menjadi terang besar jika dijaga bersama.',
    ],
  ),
  CreativeStory(
    title: 'Malin Kundang',
    origin: 'Sumatera Barat',
    summary: 'Pelajaran tentang kasih sayang dan menghormati orang tua.',
    moral: 'Jangan melupakan orang yang telah menyayangi dan membesarkan kita.',
    icon: Icons.directions_boat_outlined,
    color: Color(0xFF2E6FE8),
    pages: [
      'Di sebuah kampung pesisir Sumatera Barat, hiduplah Malin bersama ibunya, Mande Rubayah. Mereka miskin, tetapi ibunya selalu berusaha menyediakan makanan. “Ibu tidak apa-apa makan sedikit,” kata Malin. Ibunya tersenyum, “Asalkan kamu tumbuh sehat, Ibu sudah bahagia.”',
      'Malin rajin membantu nelayan dan sering memandangi kapal yang berlayar. “Aku ingin pergi merantau dan menjadi orang berhasil,” katanya. Ibunya cemas. “Boleh, Nak, tetapi jangan lupakan kampung dan ibumu.” Malin menjawab, “Aku akan pulang membawa kabar baik.”',
      'Suatu hari kapal saudagar kaya berlabuh. Malin meminta izin ikut bekerja. Ibunya membekali kain dan makanan. “Ini sedikit bekal dari Ibu,” katanya. Malin memeluknya, “Doakan aku.” Kapal pun berlayar, meninggalkan ibunya yang terus melambaikan tangan.',
      'Di kapal, Malin bekerja dengan tekun. Ia belajar membaca arah angin, berdagang, dan menghitung barang. Ketika kapal diserang badai dan perompak, Malin membantu menyusun rencana. Saudagar kagum. “Kau cerdas dan berani. Kelak kau akan menjadi pedagang besar,” katanya.',
      'Tahun berlalu. Malin memiliki kapal sendiri, harta, dan seorang istri dari keluarga terpandang. Namun ia jarang mengirim kabar. Ketika kapalnya singgah di kampung asalnya, ibunya mendengar berita itu dan berlari ke pelabuhan sambil membawa kain lama milik Malin.',
      '“Malin! Anakku, akhirnya kau pulang!” seru ibunya sambil memeluknya. Malin terkejut melihat pakaian ibunya yang sederhana. Istrinya bertanya, “Siapa perempuan itu?” Malin menunduk malu, lalu berkata keras, “Aku tidak mengenalnya. Ibuku bukan orang seperti dia.”',
      'Warga terdiam. Ibunya menatap Malin dengan air mata. “Malin, lihatlah wajahku. Akulah yang melahirkan dan membesarkanmu.” Malin membuang muka. Hatinya terluka oleh kesombongan anaknya, lalu ia berdoa, “Jika benar ia anakku, semoga ia mendapat pelajaran.”',
      'Kapal Malin berlayar kembali, tetapi langit mendadak gelap. Angin meraung dan ombak menghantam kapal. “Turunkan layar!” teriak awak kapal. Petir menyambar, kapal pecah, dan Malin terseret ke pantai. Tubuhnya perlahan menjadi batu. Ia baru menyadari kesalahannya, tetapi penyesalan datang terlambat.',
    ],
  ),
  CreativeStory(
    title: 'Sangkuriang',
    origin: 'Jawa Barat',
    summary: 'Legenda tentang asal-usul Gunung Tangkuban Perahu.',
    moral: 'Pikirkan akibat dari tindakan sebelum mengambil keputusan.',
    icon: Icons.landscape_outlined,
    color: Color(0xFF8B6FE8),
    pages: [
      'Di sebuah desa di Jawa Barat, Dayang Sumbi hidup bersama putranya, Sangkuriang, dan anjing kesayangannya, Tumang. Sangkuriang senang berburu. “Jangan pergi terlalu jauh,” pesan ibunya. “Aku akan berhati-hati,” jawabnya.',
      'Suatu hari, Dayang Sumbi meminta hati kijang untuk hidangan. Sangkuriang pergi bersama Tumang, tetapi sepanjang hari tidak menemukan buruan. “Kejar kijang itu!” perintahnya. Tumang diam karena ia bukan anjing biasa, melainkan titisan ayah Sangkuriang.',
      'Sangkuriang marah dan membunuh Tumang. Ketika pulang, ia membawa hati hewan itu. Dayang Sumbi mengetahui kebenarannya dan sangat sedih. “Mengapa kau melakukan ini?” serunya. Dalam kemarahan, ia memukul kepala Sangkuriang dengan sendok.',
      'Sangkuriang pergi tanpa menoleh. Ia mengembara bertahun-tahun, belajar banyak hal, dan tumbuh menjadi pemuda kuat. Sementara itu, Dayang Sumbi terus berdoa. Berkat kesaktiannya, wajahnya tidak banyak berubah.',
      'Suatu hari Sangkuriang kembali ke daerah itu. Ia melihat seorang perempuan cantik di tepi hutan. “Siapakah namamu?” tanyanya. “Dayang Sumbi,” jawab perempuan itu. Mereka saling menyukai, tanpa menyadari hubungan mereka.',
      'Saat Dayang Sumbi merapikan rambut Sangkuriang, ia melihat bekas luka di kepalanya. Ia tersentak. “Luka ini… kau Sangkuriang!” katanya. Sangkuriang bingung, tetapi Dayang Sumbi berusaha menyembunyikan ketakutannya.',
      'Dayang Sumbi mencari cara membatalkan pernikahan. “Aku akan menerimamu jika kau membuat danau dan perahu besar sebelum fajar,” katanya. Sangkuriang menyanggupi. Dengan bantuan makhluk gaib, ia menebang pohon dan menggali tanah sepanjang malam.',
      'Pekerjaan hampir selesai. Dayang Sumbi membentangkan kain putih di timur dan meminta warga menyalakan obor. Ayam berkokok karena mengira pagi tiba. Para makhluk gaib melarikan diri, meninggalkan pekerjaan mereka.',
      'Sangkuriang melihat langit terang dan menyadari dirinya gagal. “Aku ditipu!” teriaknya. Dalam amarah, ia menendang perahu raksasa itu. Perahu terbalik dan berubah menjadi Gunung Tangkuban Perahu.',
      'Dayang Sumbi selamat, tetapi peristiwa itu menjadi pelajaran bagi semua orang. Keinginan yang besar harus disertai pertimbangan, dan kemarahan tidak boleh dibiarkan menguasai diri.',
    ],
  ),
  CreativeStory(
    title: 'Bawang Merah Bawang Putih',
    origin: 'Riau',
    summary: 'Kisah tentang ketulusan, kesabaran, dan iri hati.',
    moral: 'Kebaikan dan ketulusan akan membawa kebaikan kembali.',
    icon: Icons.local_florist_outlined,
    color: Color(0xFFE66D9B),
    pages: [
      'Bawang Putih tinggal bersama ayah, ibu tiri, dan saudara tirinya, Bawang Merah. Setelah ibunya meninggal, semua pekerjaan rumah dibebankan kepadanya. “Putih, cuci pakaian ini!” perintah ibu tirinya. Bawang Putih menjawab lembut, “Baik, Bu.”',
      'Bawang Merah sering bermalas-malasan dan mengejeknya. Ayah mereka sebenarnya sayang kepada Bawang Putih, tetapi terlalu lemah untuk melawan istrinya. Bawang Putih tetap sabar. Ia percaya kebaikan tidak perlu selalu dibalas dengan kemarahan.',
      'Suatu pagi, kain kesayangan ibu tirinya hanyut di sungai. “Jangan pulang sebelum menemukannya!” bentak sang ibu. Bawang Putih menyusuri sungai sampai jauh dan melihat seorang nenek membawa kain itu.',
      '“Apakah ini kain yang kau cari?” tanya nenek. “Benar, Nek. Bolehkah saya membawanya pulang?” jawab Bawang Putih. Nenek berkata, “Boleh, tetapi bantulah aku menyiapkan kayu dan membersihkan rumah.” Bawang Putih bekerja dengan tulus sampai sore.',
      'Sebelum pulang, nenek menunjukkan dua labu. “Pilih salah satu sebagai ucapan terima kasih.” Bawang Putih memilih labu kecil. “Saya tidak ingin mengambil terlalu banyak,” katanya. Nenek tersenyum, “Hati yang merasa cukup akan menemukan kebahagiaan.”',
      'Di rumah, Bawang Putih membelah labu itu. Perhiasan dan permata berkilauan di dalamnya. Ibu tiri dan Bawang Merah terkejut. “Besok kau harus pergi ke sungai dan lakukan hal yang sama,” perintah mereka, “tetapi pilih labu yang paling besar.”',
      'Bawang Merah sengaja menghanyutkan kain lalu menemukan rumah nenek. Ia menolak membantu. “Aku datang untuk mengambil hadiah,” katanya. Nenek tetap memberinya dua labu, dan Bawang Merah segera memilih yang besar tanpa berterima kasih.',
      'Saat labu besar dibelah, keluarlah ular, katak, dan hewan-hewan lain. Bawang Merah dan ibunya menjerit ketakutan. Bawang Putih membantu mengusir hewan-hewan itu. Ayah mereka berkata, “Kita telah memperlakukan Putih dengan tidak adil.”',
      'Ibu tiri dan Bawang Merah meminta maaf. Bawang Putih menerima permintaan itu, tetapi berkata, “Maaf harus dibuktikan dengan perubahan.” Sejak hari itu mereka berbagi pekerjaan, berbicara lebih lembut, dan hidup rukun.',
    ],
  ),
  CreativeStory(
    title: 'Danau Toba',
    origin: 'Sumatera Utara',
    summary: 'Legenda tentang janji, keluarga, dan asal-usul danau.',
    moral: 'Jaga janji dan kendalikan emosi saat berbicara.',
    icon: Icons.water_outlined,
    color: Color(0xFF27A7B8),
    pages: [
      'Di sebuah lembah subur di Sumatera Utara, hiduplah petani bernama Toba. Setiap hari ia mencangkul dan mencari ikan. Suatu sore ia berkata, “Hari ini aku hanya mendapat sedikit.” Namun kailnya tiba-tiba tertarik kuat.',
      'Toba menarik kail dan menemukan ikan emas besar. Saat dibawa pulang, ikan itu berubah menjadi perempuan. “Jangan takut,” katanya. “Aku terkena kutukan.” Toba terpesona dan ingin menikahinya. Perempuan itu berkata, “Aku bersedia dengan satu syarat: jangan pernah sebut asal-usulku.”',
      'Toba berjanji dan mereka menikah. Mereka hidup rukun, lalu memiliki anak bernama Samosir. Anak itu disayangi, tetapi sering ceroboh dan mudah lupa. Ibunya berpesan, “Hormati ayahmu dan bantulah pekerjaannya.” Samosir menjawab, “Baik, Ibu.”',
      'Suatu hari Toba meminta Samosir mengantarkan makanan ke ladang. Di tengah jalan, Samosir mencium bau makanan. “Aku makan sedikit saja,” katanya. Tanpa sadar ia menghabiskan hampir seluruh bekal dan menyisakan sedikit nasi serta lauk.',
      'Toba menunggu dalam keadaan lapar. Ketika Samosir datang, ia membuka rantang dan melihat isinya. “Mengapa makananku tinggal sedikit?” tanyanya. Samosir menunduk, “Maaf, Ayah. Aku lapar di jalan.”',
      'Kelelahan dan marah, Toba kehilangan kendali. “Dasar anak ikan!” teriaknya. Samosir terkejut. Ibunya mendengar ucapan itu dan wajahnya berubah sedih. “Kau telah melanggar janji,” katanya kepada Toba.',
      'Ibu Samosir segera memanggil anaknya. “Naiklah ke bukit tertinggi. Jangan turun sebelum Ibu datang.” Samosir bertanya, “Apa yang terjadi?” Ia hanya menjawab, “Percayalah kepada Ibu dan berdoalah.”',
      'Langit mendadak gelap. Hujan turun tanpa henti, sungai meluap, dan air menutupi rumah serta ladang. Toba menyesal. “Maafkan aku,” katanya, tetapi air terus meninggi. Istri dan anaknya telah berada di tempat yang aman.',
      'Lembah itu akhirnya berubah menjadi danau luas. Bukit tempat Samosir berlindung menjadi sebuah pulau di tengahnya. Orang-orang kemudian menyebutnya Danau Toba dan Pulau Samosir.',
      'Kisah itu diwariskan agar orang selalu menjaga janji dan tidak mengucapkan kata-kata kasar ketika marah. Kesalahan dapat terjadi, tetapi kita harus belajar berpikir sebelum berbicara dan berani meminta maaf.',
    ],
  ),
];

class StoryCreativePage extends StatelessWidget {
  const StoryCreativePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text('Cerita Kreativ'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          const Text(
            'Cerita pendek Nusantara',
            style: TextStyle(
              color: navy,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Baca kisahnya, kenali budayanya, dan temukan pesan baik di dalamnya.',
            style: TextStyle(color: Colors.black54, fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 20),
          ...creativeStories.map(
            (story) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _storyCard(context, story),
            ),
          ),
        ],
      ),
    );
  }

  Widget _storyCard(BuildContext context, CreativeStory story) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => StoryReaderPage(story: story))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 76,
              decoration: BoxDecoration(
                color: story.color.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(story.icon, color: story.color, size: 32),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.title,
                    style: const TextStyle(
                      color: navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(story.origin, style: const TextStyle(color: blue)),
                  const SizedBox(height: 5),
                  Text(
                    story.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54, height: 1.3),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: navy),
          ],
        ),
      ),
    ),
  );
}

class StoryReaderPage extends StatefulWidget {
  final CreativeStory story;

  const StoryReaderPage({super.key, required this.story});

  @override
  State<StoryReaderPage> createState() => _StoryReaderPageState();
}

class _StoryReaderPageState extends State<StoryReaderPage> {
  int page = 0;

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final isLast = page == story.pages.length - 1;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: Text(story.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              story.origin,
              style: const TextStyle(color: blue, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Halaman ${page + 1} dari ${story.pages.length}',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (page + 1) / story.pages.length,
                minHeight: 7,
                color: orange,
                backgroundColor: orange.withValues(alpha: .18),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: [
                      Icon(story.icon, color: story.color, size: 54),
                      const SizedBox(height: 22),
                      Text(
                        story.pages[page],
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 19,
                          height: 1.7,
                        ),
                      ),
                      if (isLast) ...[
                        const SizedBox(height: 28),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF5E9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Pesan cerita\n${story.moral}',
                            style: const TextStyle(
                              color: navy,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLast
                    ? () => Navigator.pop(context)
                    : () => setState(() => page++),
                icon: Icon(isLast ? Icons.check : Icons.arrow_forward),
                label: Text(isLast ? 'Selesai membaca' : 'Lanjut halaman'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreativeWorksPage extends StatelessWidget {
  const CreativeWorksPage({super.key});

  static const works = [
    (
      title: 'Poster Hemat Air',
      creator: 'Alya · Kelas 8',
      description: 'Poster kampanye sederhana untuk menjaga air di rumah.',
      icon: Icons.water_drop_outlined,
      color: blue,
    ),
    (
      title: 'Kebun Mini dari Botol Bekas',
      creator: 'Raka · Kelas 6',
      description: 'Proyek sains dan lingkungan yang bisa dicoba di rumah.',
      icon: Icons.eco_outlined,
      color: Color(0xFF238B62),
    ),
    (
      title: 'Cerita tentang Kejujuran',
      creator: 'Naya · Kelas 5',
      description: 'Cerita pendek dengan pesan untuk berani berkata jujur.',
      icon: Icons.auto_stories_outlined,
      color: orange,
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FC),
    appBar: AppBar(
      title: const Text('Karya Kreativ'),
      foregroundColor: navy,
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        const Text(
          'Karya nyata dari ide yang diwujudkan.',
          style: TextStyle(
            color: navy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Lihat karya pilihan dan temukan inspirasi untuk membuat karyamu sendiri.',
          style: TextStyle(color: Colors.black54, height: 1.4),
        ),
        const SizedBox(height: 20),
        ...works.map(
          (work) => Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: CircleAvatar(
                backgroundColor: work.color.withValues(alpha: .14),
                foregroundColor: work.color,
                child: Icon(work.icon),
              ),
              title: Text(
                work.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('${work.creator}\\n${work.description}'),
              isThreeLine: true,
            ),
          ),
        ),
      ],
    ),
  );
}

class CreativeInspirationPage extends StatelessWidget {
  const CreativeInspirationPage({super.key});

  static const ideas = [
    (
      title: 'Mulai dari benda di sekitarmu',
      description: 'Pilih satu benda dan tuliskan tiga kegunaan atau cerita tentangnya.',
      icon: Icons.lightbulb_outline,
    ),
    (
      title: 'Ubah masalah menjadi ide',
      description: 'Pikirkan masalah kecil di rumah atau sekolah, lalu cari solusi sederhana.',
      icon: Icons.auto_awesome_outlined,
    ),
    (
      title: 'Cerita dari budaya Nusantara',
      description: 'Cari satu tradisi daerah dan ceritakan kembali dengan caramu sendiri.',
      icon: Icons.public,
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FC),
    appBar: AppBar(
      title: const Text('Inspirasi Kreativ'),
      foregroundColor: navy,
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        const Text(
          'Temukan ide, lalu kembangkan dengan caramu.',
          style: TextStyle(
            color: navy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Inspirasi bukan untuk disalin, tetapi untuk memulai sesuatu yang baru.',
          style: TextStyle(color: Colors.black54, height: 1.4),
        ),
        const SizedBox(height: 20),
        ...ideas.map(
          (idea) => Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFFFE8D4),
                foregroundColor: orange,
                child: Icon(idea.icon, color: orange),
              ),
              title: Text(
                idea.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(idea.description),
            ),
          ),
        ),
      ],
    ),
  );
}

class CreativeTeacherJoinPage extends StatelessWidget {
  const CreativeTeacherJoinPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FC),
    appBar: AppBar(
      title: const Text('GURU KREATIV JOIN US'),
      foregroundColor: navy,
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Card(
          elevation: 0,
          color: const Color(0xFFE5F7F4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFF168C87),
                  child: Icon(Icons.school_outlined, color: Colors.white),
                ),
                SizedBox(height: 18),
                Text(
                  'Mari tumbuh dan mengajar bersama EduKreativ.',
                  style: TextStyle(
                    color: navy,
                    fontSize: 24,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Bagikan ilmu, pengalaman, dan cara belajar yang bermakna untuk lebih banyak pelajar.',
                  style: TextStyle(color: Colors.black54, height: 1.45),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Mengapa bergabung?',
          style: TextStyle(
            color: navy,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        const _TeacherJoinBenefit(
          icon: Icons.menu_book_outlined,
          title: 'Bagikan keahlian',
          description: 'Bantu pelajar memahami materi dengan pendekatanmu.',
        ),
        const _TeacherJoinBenefit(
          icon: Icons.groups_outlined,
          title: 'Jangkau lebih banyak pelajar',
          description: 'Bangun kelas dan pengalaman belajar yang berdampak.',
        ),
        const _TeacherJoinBenefit(
          icon: Icons.auto_awesome_outlined,
          title: 'Tumbuh bersama komunitas',
          description: 'Kembangkan ide pembelajaran bersama EduKreativ.',
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: Colors.white,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Kami terbuka untuk guru, tutor, praktisi, dan orang-orang yang memiliki pengalaman belajar untuk dibagikan.',
              style: TextStyle(color: Colors.black54, height: 1.45),
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Minat bergabung'),
                content: const Text(
                  'Pendaftaran guru akan dihubungkan ke sistem EduKreativ pada tahap berikutnya. Terima kasih sudah tertarik bergabung.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Saya tertarik bergabung'),
          ),
        ),
      ],
    ),
  );
}

class _TeacherJoinBenefit extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _TeacherJoinBenefit({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(
      backgroundColor: const Color(0xFFE5F7F4),
      foregroundColor: const Color(0xFF168C87),
      child: Icon(icon),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(description),
  );
}

class CreativeJournalPage extends StatefulWidget {
  const CreativeJournalPage({super.key});

  @override
  State<CreativeJournalPage> createState() => _CreativeJournalPageState();
}

class _CreativeJournalPageState extends State<CreativeJournalPage> {
  final controller = TextEditingController();
  final entries = <String>[];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void saveEntry() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      entries.insert(0, text);
      controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FC),
    appBar: AppBar(
      title: const Text('Jurnal Kreativ'),
      foregroundColor: navy,
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        const Text(
          'Catat proses, ide, dan perkembanganmu.',
          style: TextStyle(
            color: navy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Jurnal ini menjadi tempat untuk berhenti sejenak, mengingat, dan merencanakan langkah berikutnya.',
          style: TextStyle(color: Colors.black54, height: 1.4),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Catatan hari ini',
            hintText: 'Apa yang kamu pelajari atau ingin coba?',
            alignLabelWithHint: true,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: saveEntry,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Simpan jurnal'),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Catatan terbaru',
          style: TextStyle(
            color: navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          const Card(
            elevation: 0,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Belum ada catatan. Tulis satu ide untuk memulai.'),
            ),
          )
        else
          ...entries.map(
            (entry) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.edit_note, color: blue),
                title: Text(entry),
              ),
            ),
          ),
      ],
    ),
  );
}

class _CreativeRoomCard extends StatelessWidget {
  final VoidCallback onOpenKarya;
  final VoidCallback onOpenInspirasi;
  final VoidCallback onOpenJurnal;

  const _CreativeRoomCard({
    required this.onOpenKarya,
    required this.onOpenInspirasi,
    required this.onOpenJurnal,
  });

  void _openMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Ruang Kreativ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              subtitle: Text('Pilih cara untuk belajar dan berkarya.'),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFE8D4),
                child: Icon(Icons.palette_outlined, color: orange),
              ),
              title: const Text('Karya Kreativ'),
              subtitle: const Text('Baca, lihat, dan nikmati karya edukatif.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(sheetContext);
                onOpenKarya();
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE3EDFF),
                child: Icon(Icons.quiz_outlined, color: blue),
              ),
              title: const Text('Inspirasi Kreativ'),
              subtitle: const Text('Temukan ide dan cerita yang menginspirasi.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(sheetContext);
                onOpenInspirasi();
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE5F7EF),
                child: Icon(Icons.flag_outlined, color: Color(0xFF238B62)),
              ),
              title: const Text('Jurnal Kreativ'),
              subtitle: const Text('Catat ide, proses, dan refleksi belajarmu.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(sheetContext);
                onOpenJurnal();
              },
            ),
            const SizedBox(height: 8),
          ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: navy,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: InkWell(
      key: const Key('ruang-kreativ'),
      borderRadius: BorderRadius.circular(20),
      onTap: () => _openMenu(context),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: orange,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.auto_awesome, color: navy, size: 28),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ruang Kreativ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Karya, inspirasi, dan jurnal dalam satu ruang.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    ),
  );
}

void _showCreativeMenuDialog(BuildContext context, String title) {
  final messages = {
    'Game Kreativ': 'Kumpulan game edukasi Kreativ sedang disiapkan.',
    'Cerita Kreativ': 'Cerita pendek edukatif Kreativ sedang disiapkan.',
    'Promo Kreativ': 'Informasi promo Edukreativ akan tampil di sini.',
    'Camp Kreativ': 'Program camp kemandirian dan persiapan sekolah kedinasan akan tampil di sini.',
  };
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(messages[title] ?? 'Menu Kreativ.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );
}

class _RecommendationCard extends StatelessWidget {
  final VoidCallback onTap;
  const _RecommendationCard({required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rekomendasi untukmu',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'SIAP UTBK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'TPS · Literasi · Latihan soal',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white),
        ],
      ),
    ),
  );
}

class _PreparationMenuRow extends StatelessWidget {
  const _PreparationMenuRow();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 190,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _PreparationMenuButton(
            title: 'Psikotest',
            icon: Icons.psychology_outlined,
            color: blue,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PreparationPlaceholderPage(
                  title: 'Psikotest',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PreparationMenuButton(
            title: 'SMA Taruna Nusantara',
            icon: Icons.school_outlined,
            color: const Color(0xFF238B62),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PreparationPlaceholderPage(
                  title: 'SMA Taruna Nusantara',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PreparationMenuButton(
            title: 'Universitas Pertahanan',
            icon: Icons.account_balance_outlined,
            color: const Color(0xFFE38A2D),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PreparationPlaceholderPage(
                  title: 'Universitas Pertahanan',
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _PreparationMenuButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PreparationMenuButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: EdgeInsets.zero,
    color: color.withValues(alpha: .1),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: color.withValues(alpha: .2)),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: color.withValues(alpha: .16),
              foregroundColor: color,
              child: Icon(icon, size: 27),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: navy,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class PreparationPlaceholderPage extends StatelessWidget {
  final String title;

  const PreparationPlaceholderPage({required this.title, super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), foregroundColor: navy),
    backgroundColor: const Color(0xFFF7F9FC),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction_outlined, color: orange, size: 56),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: navy,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Materi dan latihan untuk menu ini sedang disiapkan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, height: 1.4),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DailyTargetCard extends StatelessWidget {
  const _DailyTargetCard();

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Target UTBK hari ini'),
        content: const Text(
          'Fokus hari ini: TPS, Literasi, dan Penalaran Matematika. Satu sesi lagi untuk mencapai targetmu!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Siap'),
          ),
        ],
      ),
    ),
    borderRadius: BorderRadius.circular(18),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D152B55),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: orange, size: 21),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Target UTBK hari ini',
                  style: TextStyle(
                    color: navy,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '2/3 sesi',
                style: TextStyle(
                  color: blue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _TargetSubjectRow(label: 'TPS', progress: .8),
          const SizedBox(height: 8),
          _TargetSubjectRow(label: 'Literasi', progress: .55),
          const SizedBox(height: 8),
          _TargetSubjectRow(label: 'Penalaran Matematika', progress: .35),
          const SizedBox(height: 10),
          const Text(
            'Satu sesi lagi untuk mencapai targetmu!',
            style: TextStyle(color: Color(0xFF667085), fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _TargetSubjectRow extends StatelessWidget {
  final String label;
  final double progress;

  const _TargetSubjectRow({required this.label, required this.progress});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 132,
        child: Text(
          label,
          style: const TextStyle(
            color: navy,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: const Color(0xFFE7ECF7),
            valueColor: const AlwaysStoppedAnimation<Color>(orange),
          ),
        ),
      ),
    ],
  );
}

class _CourseCard extends StatelessWidget {
  final String title, subtitle;
  final bool free;
  final IconData icon;
  const _CourseCard({
    required this.title,
    required this.subtitle,
    required this.free,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseDetailPage(title: title, free: free),
      ),
    ),
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C152B55),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: blue.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: blue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          Chip(
            label: Text(
              free ? 'GRATIS' : 'PREMIUM',
              style: TextStyle(
                fontSize: 10,
                color: free
                    ? Colors.green.shade800
                    : Colors.deepOrange.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: free
                ? const Color(0xFFE4F6ED)
                : const Color(0xFFFFEBDD),
          ),
        ],
      ),
    ),
  );
}

class ExamSimulationPage extends StatefulWidget {
  final bool utbkOnly;

  const ExamSimulationPage({super.key, this.utbkOnly = false});

  @override
  State<ExamSimulationPage> createState() => _ExamSimulationPageState();
}

class _ExamSimulationPageState extends State<ExamSimulationPage> {
  String target = 'SMA/SMK & Persiapan Seleksi';
  int stage = 0;
  int questionIndex = 0;
  int? selectedAnswer;
  int score = 0;
  Timer? examTimer;
  int remainingSeconds = 0;
  bool get isSD => target == 'SD';
  bool get isSMP => target == 'SMP';

  String get remainingLabel {
    final hours = remainingSeconds ~/ 3600;
    final minutes = (remainingSeconds % 3600) ~/ 60;
    final seconds = remainingSeconds % 60;
    return hours > 0
        ? '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
        : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void startExamTimer() {
    examTimer?.cancel();
    remainingSeconds = widget.utbkOnly ? 230 * 60 : 30 * 60;
    examTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (remainingSeconds <= 1) {
        examTimer?.cancel();
        setState(() {
          remainingSeconds = 0;
          stage = 3;
        });
      } else {
        setState(() => remainingSeconds--);
      }
    });
  }

  @override
  void dispose() {
    examTimer?.cancel();
    super.dispose();
  }

  List<String> get questions {
    if (isSD) {
      return [
        '8 + 7 = ...?',
        'Hewan yang bertelur adalah ...?',
        'Lawan kata “besar” adalah ...?',
      ];
    }
    if (isSMP) {
      return [
        'Nilai x dari 3x = 18 adalah ...?',
        'Proses tumbuhan membuat makanan disebut ...?',
        'Sumber informasi digital perlu ... sebelum dipercaya?',
      ];
    }
    return [
      'Jika 4, 8, 16, 32, ... angka berikutnya adalah ...?',
      'Sinonim kata “akurat” adalah ...?',
      'Sikap terbaik saat waktu ujian terbatas adalah ...?',
    ];
  }

  List<List<String>> get options {
    if (isSD) {
      return [
        ['12', '15', '16', '18'],
        ['Kucing', 'Ayam', 'Sapi', 'Kambing'],
        ['Kecil', 'Tinggi', 'Panjang', 'Lebar'],
      ];
    }
    if (isSMP) {
      return [
        ['3', '6', '9', '12'],
        ['Fotosintesis', 'Evaporasi', 'Respirasi', 'Erosi'],
        ['Dibagikan', 'Diperiksa sumbernya', 'Diubah judulnya', 'Dihapus'],
      ];
    }
    return [
      ['36', '48', '64', '72'],
      ['Tepat', 'Lambat', 'Samar', 'Berbeda'],
      [
        'Menebak semua',
        'Mengatur prioritas waktu',
        'Berhenti mengerjakan',
        'Menyalin jawaban',
      ],
    ];
  }

  List<int> get correctAnswers => isSD
      ? [1, 1, 0]
      : isSMP
      ? [1, 0, 1]
      : [2, 0, 1];

  void chooseTarget(String value) => setState(() {
    target = value;
    stage = 1;
  });

  void nextQuestion() {
    if (selectedAnswer == null) return;
    if (selectedAnswer == correctAnswers[questionIndex]) score++;
    setState(() {
      selectedAnswer = null;
      if (questionIndex == questions.length - 1) {
        stage = 3;
      } else {
        questionIndex++;
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F8FC),
    appBar: AppBar(
      backgroundColor: navy,
      foregroundColor: Colors.white,
      title: Text(
        stage == 0
            ? 'Simulasi Ujian'
            : stage == 3
            ? 'Hasil Simulasi'
            : 'Misi 3: Simulasi',
      ),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: stage == 0
            ? _targetPicker()
            : stage == 1
            ? _briefing()
            : stage == 2
            ? _questionView()
            : _result(),
      ),
    ),
  );

  Widget _targetPicker() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Pilih target simulasi',
        style: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w800,
          color: navy,
        ),
      ),
      const SizedBox(height: 8),
      const Text('Soal ujian akan menyesuaikan jenjang dan kebutuhanmu.'),
      const SizedBox(height: 18),
      ...[
        if (widget.utbkOnly) 'SMA/SMK & Persiapan Seleksi',
        if (!widget.utbkOnly) ...['SMA/SMK & Persiapan Seleksi', 'SMP', 'SD'],
      ].map(
        (value) => Card(
          child: ListTile(
            leading: const Icon(Icons.school_outlined, color: blue),
            title: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => chooseTarget(value),
          ),
        ),
      ),
    ],
  );

  Widget _briefing() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _heroCard(
        'Simulasi ${isSD
            ? 'Dasar'
            : isSMP
            ? 'Menengah'
            : 'Seleksi'}',
        'Target: $target\n3 soal pilihan ganda • tanpa tekanan • fokus dan teliti',
        Icons.timer_outlined,
      ),
      const SizedBox(height: 20),
      const Text(
        'Aturan simulasi',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: navy,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Baca setiap soal dengan teliti. Pilih satu jawaban, lalu lanjutkan sampai semua soal selesai.',
      ),
      const Spacer(),
      _button('Mulai simulasi', () {
        setState(() => stage = 2);
        startExamTimer();
      }),
    ],
  );

  Widget _questionView() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      LinearProgressIndicator(
        value: (questionIndex + 1) / questions.length,
        color: orange,
        backgroundColor: navy.withValues(alpha: .15),
      ),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: remainingSeconds < 300
              ? Colors.red.shade50
              : const Color(0xFFEAF1FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.timer_outlined,
              color: remainingSeconds < 300 ? Colors.red : blue,
            ),
            const SizedBox(width: 8),
            const Text(
              'Waktu tersisa',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              remainingLabel,
              style: TextStyle(
                color: remainingSeconds < 300 ? Colors.red : blue,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      Text(
        'Soal ${questionIndex + 1} dari ${questions.length}',
        style: const TextStyle(color: blue, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      Text(
        questions[questionIndex],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: navy,
        ),
      ),
      const SizedBox(height: 18),
      ...options[questionIndex].asMap().entries.map(
        (entry) => ListTile(
          leading: Icon(
            selectedAnswer == entry.key
                ? Icons.radio_button_checked
                : Icons.radio_button_off,
            color: selectedAnswer == entry.key ? blue : Colors.black38,
          ),
          title: Text(entry.value),
          onTap: () => setState(() => selectedAnswer = entry.key),
        ),
      ),
      const Spacer(),
      _button(
        questionIndex == questions.length - 1
            ? 'Lihat hasil'
            : 'Soal berikutnya',
        nextQuestion,
      ),
    ],
  );

  Widget _result() => Column(
    children: [
      const SizedBox(height: 42),
      const Icon(Icons.emoji_events_outlined, color: orange, size: 86),
      const SizedBox(height: 16),
      const Text(
        'Simulasi selesai!',
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: navy,
        ),
      ),
      const SizedBox(height: 10),
      _heroCard(
        'Skor kamu',
        '$score/${questions.length} jawaban benar\n${score == questions.length ? 'Mantap, semua jawaban tepat!' : 'Bagus, jadikan hasil ini sebagai bahan latihan berikutnya.'}',
        Icons.insights_outlined,
      ),
      const Spacer(),
      _button(
        'Ulangi simulasi',
        () => setState(() {
          examTimer?.cancel();
          stage = 1;
          questionIndex = 0;
          selectedAnswer = null;
          score = 0;
        }),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Kembali ke beranda'),
        ),
      ),
    ],
  );

  Widget _button(String label, VoidCallback onPressed) => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_forward),
      label: Text(label),
    ),
  );

  Widget _heroCard(String title, String subtitle, IconData icon) => Card(
    color: navy,
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(icon, color: orange, size: 38),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class MissionSeriesPage extends StatefulWidget {
  const MissionSeriesPage({super.key});

  @override
  State<MissionSeriesPage> createState() => _MissionSeriesPageState();
}

class _MissionSeriesPageState extends State<MissionSeriesPage> {
  String target = 'SMA/SMK & Persiapan Seleksi';
  int mission = 4;
  int stage = 0;
  int? selectedAnswer;
  int completed = 0;
  int score = 0;

  bool get isSD => target == 'SD';
  bool get isSMP => target == 'SMP';

  List<String> get missionNames => [
    'Belajar aktif',
    'Latihan fokus',
    'Baca cepat',
    'Pecahkan pola',
    'Uji ketelitian',
    'Susun strategi',
    'Tantangan konsep',
    'Sprint pemahaman',
    'Final challenge',
  ];

  String get question {
    final sd = [
      'Jumlah sisi segitiga adalah ...?',
      'Benda cair mengikuti bentuk ...?',
      'Kata “ibu” terdiri dari ... suku kata?',
      '5 + 6 = ...?',
      'Warna hasil campuran merah dan kuning?',
      'Alat untuk mengukur panjang?',
      'Hewan yang hidup di air?',
      'Lawan kata “rajin”?',
      'Planet tempat kita tinggal?',
    ];
    final smp = [
      'Hasil 5² adalah ...?',
      'Satuan gaya adalah ...?',
      'Kalimat utama berisi ...?',
      'Jika x + 7 = 12, x = ...?',
      'Perubahan cair menjadi gas disebut ...?',
      'Data yang dapat dipercaya berasal dari ...?',
      'Sudut siku-siku besarnya ...?',
      'Energi dari matahari disebut ...?',
      'Langkah awal memecahkan masalah?',
    ];
    final sma = [
      'Hasil 2³ × 2² adalah ...?',
      'Rumus luas lingkaran adalah ...?',
      'Ide pokok paragraf disebut ...?',
      'Jika f(x)=2x+1, f(3)=...?',
      'Sikap kritis dimulai dengan ...?',
      'Peluang kejadian pasti bernilai ...?',
      'Argumen kuat didukung oleh ...?',
      'Prioritas waktu ditentukan oleh ...?',
      'Kunci evaluasi belajar adalah ...?',
    ];
    return (isSD
        ? sd
        : isSMP
        ? smp
        : sma)[mission - 4];
  }

  List<String> get options {
    if (isSD) {
      return [
        ['2', '3', '4', '5'],
        ['Wadah', 'Meja', 'Batu', 'Udara'],
        ['1', '2', '3', '4'],
        ['10', '11', '12', '13'],
        ['Hijau', 'Ungu', 'Oranye', 'Biru'],
        ['Jam', 'Penggaris', 'Termometer', 'Timbangan'],
        ['Kucing', 'Ikan', 'Ayam', 'Kambing'],
        ['Tekun', 'Malas', 'Ceria', 'Cepat'],
        ['Mars', 'Bumi', 'Venus', 'Jupiter'],
      ][mission - 4];
    }
    if (isSMP) {
      return [
        ['10', '20', '25', '30'],
        ['Joule', 'Newton', 'Watt', 'Volt'],
        ['Contoh tambahan', 'Gagasan utama', 'Judul buku', 'Kata sulit'],
        ['3', '4', '5', '6'],
        ['Membeku', 'Menguap', 'Mencair', 'Mengembun'],
        [
          'Sumber tepercaya',
          'Pesan berantai',
          'Komentar anonim',
          'Judul menarik',
        ],
        ['45°', '90°', '180°', '360°'],
        ['Panas bumi', 'Cahaya matahari', 'Bunyi', 'Gerak'],
        ['Menentukan fakta', 'Menebak', 'Menyalin', 'Mengabaikan'],
      ][mission - 4];
    }
    return [
      ['8', '16', '32', '64'],
      ['πr²', '2πr', 'p×l', 's×s'],
      ['Kesimpulan', 'Gagasan utama', 'Ilustrasi', 'Keterangan'],
      ['5', '6', '7', '8'],
      [
        'Bertanya dan memeriksa bukti',
        'Langsung percaya',
        'Mengikuti mayoritas',
        'Menghapus data',
      ],
      ['0', '1', '2', 'Tidak tentu'],
      ['Bukti relevan', 'Perasaan', 'Tebakan', 'Popularitas'],
      ['Dampak dan urgensi', 'Warna catatan', 'Jumlah halaman', 'Ukuran layar'],
      [
        'Meninjau kesalahan',
        'Mengulang tanpa refleksi',
        'Berhenti mencoba',
        'Menghafal skor',
      ],
    ][mission - 4];
  }

  int get correctAnswer {
    if (isSD) return [1, 0, 1, 1, 2, 1, 1, 1, 1][mission - 4];
    if (isSMP) return [2, 1, 1, 1, 1, 0, 1, 1, 0][mission - 4];
    return [2, 0, 1, 1, 0, 1, 0, 0, 0][mission - 4];
  }

  void finishMission() {
    if (selectedAnswer == correctAnswer) score++;
    completed++;
    setState(() => stage = 3);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (mission < 12) {
        setState(() {
          mission++;
          selectedAnswer = null;
          stage = 1;
        });
      } else {
        setState(() => stage = 4);
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F8FC),
    appBar: AppBar(
      backgroundColor: navy,
      foregroundColor: Colors.white,
      title: Text(
        stage == 0
            ? 'Misi 4–12'
            : stage == 4
            ? 'Semua Misi Selesai'
            : 'Misi $mission dari 12',
      ),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: stage == 0
            ? _targets()
            : stage == 1
            ? _briefing()
            : stage == 2
            ? _question()
            : stage == 3
            ? _transition()
            : _result(),
      ),
    ),
  );

  Widget _targets() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Mulai rangkaian Misi 4',
        style: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w800,
          color: navy,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Setelah satu misi selesai, misi berikutnya terbuka otomatis sampai Misi 12.',
      ),
      const SizedBox(height: 18),
      ...['SMA/SMK & Persiapan Seleksi', 'SMP', 'SD'].map(
        (value) => Card(
          child: ListTile(
            title: Text(value),
            trailing: const Icon(Icons.play_arrow),
            onTap: () => setState(() {
              target = value;
              stage = 1;
            }),
          ),
        ),
      ),
    ],
  );

  Widget _briefing() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Misi $mission: ${missionNames[mission - 4]}',
        style: const TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w800,
          color: navy,
        ),
      ),
      const SizedBox(height: 12),
      Card(
        color: navy,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Target: $target\nSatu tantangan singkat untuk menjaga ritme belajarmu.',
            style: const TextStyle(color: Colors.white, height: 1.5),
          ),
        ),
      ),
      const Spacer(),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => setState(() => stage = 2),
          child: const Text('Mulai misi'),
        ),
      ),
    ],
  );

  Widget _question() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      LinearProgressIndicator(value: mission / 12, color: orange),
      const SizedBox(height: 24),
      Text(
        'Tantangan Misi $mission',
        style: const TextStyle(color: blue, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      Text(
        question,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: navy,
        ),
      ),
      const SizedBox(height: 16),
      ...options.asMap().entries.map(
        (entry) => ListTile(
          leading: Icon(
            selectedAnswer == entry.key
                ? Icons.radio_button_checked
                : Icons.radio_button_off,
            color: selectedAnswer == entry.key ? blue : Colors.black38,
          ),
          title: Text(entry.value),
          onTap: () => setState(() => selectedAnswer = entry.key),
        ),
      ),
      const Spacer(),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: selectedAnswer == null ? null : finishMission,
          child: const Text('Selesaikan misi'),
        ),
      ),
    ],
  );

  Widget _transition() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline, color: orange, size: 76),
        const SizedBox(height: 16),
        Text(
          'Misi $mission selesai!',
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            color: navy,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          mission < 12
              ? 'Membuka Misi ${mission + 1}...'
              : 'Menyiapkan hasil akhir...',
        ),
      ],
    ),
  );

  Widget _result() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.workspace_premium_outlined, color: orange, size: 90),
      const SizedBox(height: 18),
      const Text(
        'Misi 4–12 selesai!',
        style: TextStyle(
          fontSize: 29,
          fontWeight: FontWeight.w800,
          color: navy,
        ),
      ),
      const SizedBox(height: 8),
      Text('$completed misi dituntaskan • $score jawaban benar'),
      const SizedBox(height: 32),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Kembali ke beranda'),
        ),
      ),
    ],
  );
}

class StoryLearningPage extends StatefulWidget {
  const StoryLearningPage({super.key});

  @override
  State<StoryLearningPage> createState() => _StoryLearningPageState();
}

class _StoryLearningPageState extends State<StoryLearningPage> {
  String target = 'SMA/SMK & Persiapan Seleksi';
  int stage = 0;
  int? selectedAnswer;
  bool get isSD => target == 'SD';
  bool get isSMP => target == 'SMP';

  String get storyTitle {
    if (isSD) return 'Rara dan Taman Hemat Air';
    if (isSMP) return 'Dimas Membaca Data Banjir';
    return 'Naya dan Strategi di Persimpangan';
  }

  String get story {
    if (isSD) {
      return 'Rara melihat keran di sekolah menetes terus. Ia mengajak teman-temannya menutup keran dengan rapat dan menampung air untuk menyiram tanaman. Sejak itu, taman tetap subur tanpa membuang-buang air.';
    }
    if (isSMP) {
      return 'Dimas mendapat tugas mengamati banjir di kotanya. Ia membandingkan curah hujan, kondisi selokan, dan tinggi genangan. Dari data itu, ia menyimpulkan bahwa selokan tersumbat membuat genangan lebih cepat tinggi.';
    }
    return 'Naya harus memilih cara belajar menjelang seleksi. Ia membagi waktu menjadi sesi singkat, mencatat pola soal yang sering muncul, lalu mengevaluasi kesalahan setiap sore. Strateginya membuat latihan terasa lebih terarah.';
  }

  String get question {
    if (isSD) return 'Apa tindakan Rara yang menunjukkan sikap hemat air?';
    if (isSMP) return 'Mengapa Dimas membandingkan beberapa jenis data?';
    return 'Apa inti strategi belajar Naya dalam cerita?';
  }

  List<String> get options {
    if (isSD) {
      return [
        'Membiarkan keran terbuka',
        'Menutup keran dan memakai ulang air',
        'Menyiram jalan',
        'Membuang air ke selokan',
      ];
    }
    if (isSMP) {
      return [
        'Agar ceritanya lebih panjang',
        'Agar dapat menemukan hubungan penyebab dan dampak',
        'Agar tidak perlu mengamati',
        'Agar semua data terlihat sama',
      ];
    }
    return [
      'Belajar tanpa jadwal',
      'Menghafal semua soal sekaligus',
      'Membagi waktu dan mengevaluasi kesalahan',
      'Menghindari soal yang sulit',
    ];
  }

  int get correctAnswer => isSD ? 1 : 1;

  void next() {
    if (stage == 2 && selectedAnswer == null) return;
    setState(() {
      if (stage == 2) {
        stage = 3;
      } else {
        stage++;
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F8FC),
    appBar: AppBar(
      backgroundColor: navy,
      foregroundColor: Colors.white,
      title: Text(
        stage == 0
            ? 'Belajar melalui Cerita'
            : stage == 3
            ? 'Cerita selesai'
            : 'Misi 2: Cerita',
      ),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: stage == 0
            ? _targetPicker()
            : stage == 1
            ? _storyView()
            : stage == 2
            ? _quizView()
            : _doneView(),
      ),
    ),
  );

  Widget _targetPicker() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Pilih target cerita',
        style: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w800,
          color: navy,
        ),
      ),
      const SizedBox(height: 8),
      const Text('Kisah dan pertanyaan akan disesuaikan dengan jenjangmu.'),
      const SizedBox(height: 18),
      ...[
        'SMA/SMK & Persiapan Seleksi',
        'SMP',
        'SD',
      ].map((item) => _targetCard(item)),
    ],
  );

  Widget _targetCard(String value) => Card(
    child: ListTile(
      leading: Icon(
        value == 'SD'
            ? Icons.emoji_objects_outlined
            : value == 'SMP'
            ? Icons.auto_stories_outlined
            : Icons.school_outlined,
        color: blue,
      ),
      title: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        value == 'SD'
            ? 'Cerita konkret dan dekat dengan keseharian'
            : value == 'SMP'
            ? 'Cerita berbasis pengamatan dan data'
            : 'Cerita strategi dan pengambilan keputusan',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => setState(() {
        target = value;
        stage = 1;
      }),
    ),
  );

  Widget _storyView() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _heroCard(
        storyTitle,
        'Baca kisahnya, lalu temukan konsep penting di balik cerita.',
        Icons.auto_stories_outlined,
      ),
      const SizedBox(height: 18),
      const Text(
        'Kisah hari ini',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: navy,
        ),
      ),
      const SizedBox(height: 10),
      Text(story, style: const TextStyle(fontSize: 17, height: 1.6)),
      const Spacer(),
      _actionButton('Lanjut ke refleksi cerita'),
    ],
  );

  Widget _quizView() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Temukan maknanya',
        style: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w800,
          color: navy,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        question,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 14),
      ...options.asMap().entries.map(
        (entry) => ListTile(
          leading: Icon(
            selectedAnswer == entry.key
                ? Icons.radio_button_checked
                : Icons.radio_button_off,
            color: selectedAnswer == entry.key ? blue : Colors.black38,
          ),
          title: Text(entry.value),
          onTap: () => setState(() => selectedAnswer = entry.key),
        ),
      ),
      const Spacer(),
      _actionButton('Selesaikan cerita'),
    ],
  );

  Widget _doneView() => Column(
    children: [
      const SizedBox(height: 40),
      const Icon(Icons.auto_awesome, color: orange, size: 82),
      const SizedBox(height: 16),
      const Text(
        'Cerita selesai!',
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: navy,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        selectedAnswer == correctAnswer
            ? 'Jawabanmu tepat. Kamu berhasil menangkap pesan utama cerita.'
            : 'Kamu sudah menyelesaikan cerita. Coba baca kembali bagian pentingnya.',
        textAlign: TextAlign.center,
      ),
      const Spacer(),
      _actionButton(
        'Baca cerita berikutnya',
        onPressed: () => setState(() {
          stage = 1;
          selectedAnswer = null;
        }),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Kembali ke beranda'),
        ),
      ),
    ],
  );

  Widget _actionButton(String label, {VoidCallback? onPressed}) => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: onPressed ?? next,
      icon: const Icon(Icons.arrow_forward),
      label: Text(label),
    ),
  );

  Widget _heroCard(String title, String subtitle, IconData icon) => Card(
    color: navy,
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(icon, color: orange, size: 38),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class MissionJourneyPage extends StatefulWidget {
  const MissionJourneyPage({
    super.key,
    this.target = 'SMA/SMK & Persiapan Seleksi',
  });

  final String target;
  @override
  State<MissionJourneyPage> createState() => _MissionJourneyPageState();
}

class _MissionJourneyPageState extends State<MissionJourneyPage> {
  int stage = 0;
  String? field;
  String? mission;
  int missionStep = 0;
  int? selectedAnswer;
  int score = 0;
  bool get isSD => widget.target == 'SD';
  bool get isSMP => widget.target == 'SMP';

  List<(String, IconData)> get fields {
    if (isSD) {
      return const [
        ('Matematika Dasar', Icons.calculate_outlined),
        ('Bahasa Indonesia', Icons.menu_book_outlined),
        ('IPA Dasar', Icons.science_outlined),
        ('Pendidikan Pancasila', Icons.flag_outlined),
      ];
    }
    if (isSMP) {
      return const [
        ('Aljabar dan Geometri', Icons.functions_outlined),
        ('Bahasa Indonesia', Icons.menu_book_outlined),
        ('IPA Terpadu', Icons.science_outlined),
        ('Literasi Digital', Icons.devices_outlined),
      ];
    }
    return const [
      ('Tes Potensi Akademik', Icons.psychology_outlined),
      ('Matematika', Icons.functions_outlined),
      ('Bahasa Indonesia', Icons.menu_book_outlined),
      ('Wawasan Kebangsaan', Icons.account_balance_outlined),
    ];
  }

  List<String> get missions {
    if (isSD) {
      return const [
        'Hitung cepat perkalian dan pembagian',
        'Temukan ide pokok dalam bacaan pendek',
        'Amati lingkungan dan jelaskan perubahan wujud benda',
      ];
    }
    if (isSMP) {
      return const [
        'Taklukkan pola aljabar dalam 15 menit',
        'Susun argumen dari teks eksplanasi',
        'Pecahkan kasus sains dengan data sederhana',
      ];
    }
    return const [
      'Taklukkan 10 soal logika dalam 15 menit',
      'Bangun strategi cepat membaca pola',
      'Uji ketelitianmu lewat tantangan campuran',
    ];
  }

  final steps = const [
    ('Briefing misi', 'Pahami tujuan dan aturan tantangan.'),
    ('Materi singkat', 'Pelajari konsep inti dengan contoh sederhana.'),
    ('Tantangan utama', 'Terapkan konsep dan selesaikan soal misi.'),
    ('Review jawaban', 'Lihat pembahasan dan temukan pola kesalahan.'),
  ];

  String get nextMissionTitle {
    final currentIndex = mission == null ? -1 : missions.indexOf(mission!);
    return missions[(currentIndex + 1) % missions.length];
  }

  String get challengeQuestion {
    if (isSD) {
      return switch (field) {
        'Matematika Dasar' => 'Berapakah hasil dari 6 × 4?',
        'Bahasa Indonesia' => 'Apa ide pokok sebuah paragraf?',
        'IPA Dasar' => 'Air yang dipanaskan terus-menerus akan ...?',
        _ => 'Lambang sila pertama Pancasila adalah ...?',
      };
    }
    if (isSMP) {
      return switch (field) {
        'Aljabar dan Geometri' => 'Jika 2x + 4 = 12, berapakah nilai x?',
        'Bahasa Indonesia' => 'Kalimat manakah yang merupakan fakta?',
        'IPA Terpadu' => 'Satuan SI untuk kuat arus listrik adalah ...?',
        _ => 'Sikap aman saat menerima tautan asing adalah ...?',
      };
    }
    return switch (field) {
      'Matematika' => 'Berapakah hasil dari 3 × 8?',
      'Bahasa Indonesia' => 'Manakah kata baku yang tepat?',
      'Wawasan Kebangsaan' => 'Apa semboyan bangsa Indonesia?',
      _ => 'Jika semua A adalah B, dan C adalah A, maka C adalah ...?',
    };
  }

  List<String> get challengeOptions {
    if (isSD) {
      return switch (field) {
        'Matematika Dasar' => ['18', '20', '24', '28'],
        'Bahasa Indonesia' => [
          'Kalimat penutup',
          'Gagasan utama',
          'Judul buku',
          'Nama penulis',
        ],
        'IPA Dasar' => ['Membeku', 'Menguap', 'Mencair', 'Mengembun'],
        _ => ['Pohon beringin', 'Bintang', 'Rantai', 'Padi dan kapas'],
      };
    }
    if (isSMP) {
      return switch (field) {
        'Aljabar dan Geometri' => ['2', '4', '6', '8'],
        'Bahasa Indonesia' => [
          'Bumi mengelilingi Matahari.',
          'Sebaiknya kita belajar.',
          'Buku itu sangat menarik.',
          'Cuaca hari ini menyenangkan.',
        ],
        'IPA Terpadu' => ['Volt', 'Ampere', 'Ohm', 'Watt'],
        _ => [
          'Membagikan segera',
          'Mengeklik tanpa membaca',
          'Memeriksa sumber dan alamatnya',
          'Mengirimkan data pribadi',
        ],
      };
    }
    return switch (field) {
      'Matematika' => ['12', '18', '24', '30'],
      'Bahasa Indonesia' => ['Analisa', 'Analisis', 'Analisah', 'Analysa'],
      'Wawasan Kebangsaan' => [
        'Tut Wuri Handayani',
        'Bhinneka Tunggal Ika',
        'Ing Ngarsa Sung Tuladha',
        'Jalesveva Jayamahe',
      ],
      _ => ['B', 'A', 'C', 'Tidak dapat ditentukan'],
    };
  }

  int get correctAnswer {
    if (isSD) {
      return field == 'Matematika Dasar' || field == 'IPA Dasar' ? 2 : 1;
    }
    if (isSMP) {
      return field == 'Aljabar dan Geometri'
          ? 1
          : field == 'IPA Terpadu'
          ? 1
          : field == 'Literasi Digital'
          ? 2
          : 0;
    }
    return field == 'Matematika'
        ? 2
        : field == 'Bahasa Indonesia' || field == 'Wawasan Kebangsaan'
        ? 1
        : 0;
  }

  String get challengeExplanation {
    if (isSD) {
      return switch (field) {
        'Matematika Dasar' =>
          '6 × 4 berarti 6 kelompok berisi 4, jadi hasilnya 24.',
        'Bahasa Indonesia' => 'Ide pokok adalah gagasan utama yang menjadi inti pembahasan paragraf.',
        'IPA Dasar' => 'Air yang terus dipanaskan berubah menjadi uap melalui proses menguap.',
        _ => 'Bintang melambangkan Ketuhanan Yang Maha Esa pada sila pertama.',
      };
    }
    if (isSMP) {
      return switch (field) {
        'Aljabar dan Geometri' => '2x + 4 = 12, maka 2x = 8 dan x = 4.',
        'Bahasa Indonesia' => 'Pernyataan bahwa Bumi mengelilingi Matahari dapat dibuktikan sehingga termasuk fakta.',
        'IPA Terpadu' => 'Ampere adalah satuan SI untuk kuat arus listrik.',
        _ =>
          'Tautan asing perlu diperiksa sumber dan alamatnya sebelum dibuka.',
      };
    }
    return switch (field) {
      'Matematika' => '3 × 8 berarti 3 kelompok yang masing-masing berisi 8. Jadi, 8 + 8 + 8 = 24.',
      'Bahasa Indonesia' => 'Bentuk baku yang tercantum dalam KBBI adalah “analisis”, bukan “analisa”.',
      'Wawasan Kebangsaan' => 'Bhinneka Tunggal Ika berarti berbeda-beda tetapi tetap satu, dan menjadi semboyan bangsa Indonesia.',
      _ =>
        'Karena C termasuk A dan semua A termasuk B, maka C juga termasuk B.',
    };
  }

  void next() => setState(() {
    if (stage == 3 && missionStep == 2 && selectedAnswer == null) {
      return;
    }
    if (stage == 3 && missionStep == 2 && selectedAnswer == correctAnswer) {
      score = 100;
    }
    if (stage == 3 && missionStep < steps.length - 1) {
      missionStep++;
      selectedAnswer = null;
    } else {
      stage = 4;
    }
  });

  void restartMission() => setState(() {
    mission = nextMissionTitle;
    stage = 3;
    missionStep = 0;
    selectedAnswer = null;
    score = 0;
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F8FC),
    appBar: AppBar(
      backgroundColor: navy,
      foregroundColor: Colors.white,
      title: Text(
        [
          'Pilih bidang',
          'Pilih misi',
          'Detail misi',
          'Misi berjalan',
          'Misi selesai',
        ][stage],
      ),
    ),
    body: SafeArea(
      child: Padding(padding: const EdgeInsets.all(20), child: _body()),
    ),
  );

  Widget _body() {
    if (stage == 0) {
      return _selection(
        'Pilih bidang yang ingin kamu kuasai',
        fields
            .map(
              (item) => _card(
                item.$1,
                'Misi disesuaikan dengan bidang ini',
                item.$2,
                () => setState(() {
                  field = item.$1;
                  stage = 1;
                }),
              ),
            )
            .toList(),
      );
    }
    if (stage == 1) {
      return _selection(
        'Pilih misi pertamamu',
        missions
            .map(
              (item) => _card(
                item,
                field!,
                Icons.flag_outlined,
                () => setState(() {
                  mission = item;
                  stage = 2;
                }),
              ),
            )
            .toList(),
      );
    }
    if (stage == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heroCard(
            'Misi: $mission',
            'Target: ${widget.target}\nBidang: $field',
            Icons.rocket_launch_outlined,
          ),
          const SizedBox(height: 20),
          const Text(
            'Tahapan misi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: navy,
            ),
          ),
          const SizedBox(height: 10),
          ...steps.asMap().entries.map(
            (entry) => ListTile(
              leading: CircleAvatar(
                backgroundColor: orange,
                foregroundColor: navy,
                child: Text('${entry.key + 1}'),
              ),
              title: Text(
                entry.value.$1,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(entry.value.$2),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => stage = 3),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Mulai misi'),
            ),
          ),
        ],
      );
    }
    if (stage == 3) {
      final current = steps[missionStep];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: (missionStep + 1) / steps.length,
            color: orange,
            backgroundColor: navy.withValues(alpha: .15),
          ),
          const SizedBox(height: 28),
          Text(
            'Tahap ${missionStep + 1} dari ${steps.length}',
            style: const TextStyle(color: blue, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            current.$1,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: navy,
            ),
          ),
          const SizedBox(height: 12),
          _heroCard(current.$1, current.$2, Icons.auto_awesome_outlined),
          if (missionStep == 2) ...[
            const SizedBox(height: 18),
            const Text(
              'Pilih jawaban yang paling tepat:',
              style: TextStyle(fontWeight: FontWeight.w700, color: navy),
            ),
            const SizedBox(height: 8),
            ...challengeOptions.asMap().entries.map(
              (entry) => ListTile(
                leading: Icon(
                  selectedAnswer == entry.key
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selectedAnswer == entry.key ? blue : Colors.black38,
                ),
                title: Text(entry.value),
                onTap: () => setState(() => selectedAnswer = entry.key),
              ),
            ),
          ],
          if (missionStep == 3) ...[
            const SizedBox(height: 18),
            Text(
              'Skor tantangan: $score/100',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              score == 100
                  ? 'Jawaban tepat. Pertahankan strategi ini!'
                  : 'Belum tepat, pelajari kembali pola pada materi.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Pembahasan',
              style: TextStyle(fontWeight: FontWeight.w800, color: navy),
            ),
            const SizedBox(height: 6),
            Text(challengeExplanation),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: next,
              child: Text(
                missionStep == steps.length - 1
                    ? 'Selesaikan misi'
                    : 'Lanjutkan',
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        const SizedBox(height: 30),
        const Icon(Icons.emoji_events_outlined, color: orange, size: 84),
        const SizedBox(height: 16),
        const Text(
          'Misi selesai!',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: navy,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Kamu berhasil melewati semua tahapan misi.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        _heroCard(
          'Skor progres',
          '4/4 tahapan selesai\nSkor tantangan: $score/100\nRekomendasi: lanjutkan ke misi berikutnya.',
          Icons.trending_up,
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: restartMission,
            child: const Text('Coba misi berikutnya'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kembali ke beranda'),
          ),
        ),
      ],
    );
  }

  Widget _selection(String heading, List<Widget> cards) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        heading,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: navy,
        ),
      ),
      const SizedBox(height: 6),
      const Text('Pilih satu untuk melanjutkan perjalanan belajarmu.'),
      const SizedBox(height: 18),
      ...cards,
    ],
  );

  Widget _card(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: navy,
        foregroundColor: orange,
        child: Icon(icon),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );

  Widget _heroCard(String title, String subtitle, IconData icon) => Card(
    color: navy,
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(icon, color: orange, size: 38),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
