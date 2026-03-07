import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/app_config.dart';
import 'checkout.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();

  int _currentImageIndex = 0;
  bool _isAppBarExpanded = true;

  final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final offset = _scrollController.offset;
        if (offset < (300 - kToolbarHeight) && !_isAppBarExpanded) {
          setState(() => _isAppBarExpanded = true);
        } else if (offset >= (300 - kToolbarHeight) && _isAppBarExpanded) {
          setState(() => _isAppBarExpanded = false);
        }
      }
    });
  }

  // --- Getters ---
  List<String> get _imageUrls {
    final images = <String>[];
    if (widget.product['gambar'] != null) images.add(widget.product['gambar']);
    if (widget.product['gambar2'] != null)
      images.add(widget.product['gambar2']);
    if (widget.product['gambar3'] != null)
      images.add(widget.product['gambar3']);
    return images;
  }

  double get _harga => (widget.product['harga'] as num?)?.toDouble() ?? 0;
  double get _hargaDiskon =>
      (widget.product['harga_diskon'] as num?)?.toDouble() ?? 0;
  bool get _hasDiscount => _hargaDiskon > 0 && _hargaDiskon < _harga;
  double get _finalPrice => _hasDiscount ? _hargaDiskon : _harga;
  int get _stok => widget.product['stok'] ?? 0;
  String get _unit => widget.product['unit'] ?? 'pcs';

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildMainInfo(),
                    _buildSectionDivider(),
                    _buildSpecification(),
                    _buildSectionDivider(),
                    _buildDescription(),
                    _buildSectionDivider(),
                    _buildLocation(),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 350,
      pinned: true,
      elevation: 0,
      backgroundColor: _isAppBarExpanded
          ? Colors.transparent
          : appConfig.primaryColor,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: _isAppBarExpanded
              ? Colors.black45
              : Colors.transparent,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _imageUrls.length,
              onPageChanged: (i) => setState(() => _currentImageIndex = i),
              itemBuilder: (context, i) => Image.network(
                _imageUrls[i],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, size: 50),
              ),
            ),
            if (_imageUrls.length > 1)
              Positioned(
                bottom: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1} / ${_imageUrls.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _currencyFormatter.format(_finalPrice),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              if (_hasDiscount) ...[
                const SizedBox(width: 10),
                Text(
                  _currencyFormatter.format(_harga),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.product['nama_barang'] ?? '',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoBadge(
                Icons.inventory_2,
                Colors.blueGrey,
                "Stok: $_stok $_unit",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecification() {
    return _buildCardSection(
      title: "Spesifikasi",
      child: Column(
        children: [
          _specRow("Kategori", widget.product['menu_title'] ?? "-"),
          _specRow("Berat", "${widget.product['berat'] ?? '0'} Gram"),
          _specRow("Satuan", _unit),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return _buildCardSection(
      title: "Deskripsi",
      child: Text(
        widget.product['deskripsi'] ?? 'Tidak ada deskripsi.',
        style: const TextStyle(color: Colors.black87, height: 1.5),
      ),
    );
  }

  Widget _buildLocation() {
    final lokasi =
        widget.product['lokasi']?['alamat_lengkap'] ?? "Lokasi tidak tersedia";
    return _buildCardSection(
      title: "Dikirim Dari",
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(lokasi, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider() =>
      Container(height: 8, color: const Color(0xFFEEEEEE));

  Widget _buildCardSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _specRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(IconData icon, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.home_outlined,
                size: 30,
                color: Colors.black87,
              ),
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: _stok > 0 ? () {} : null,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: appConfig.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text(
                  "Keranjang",
                  style: TextStyle(
                    color: appConfig.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _stok > 0
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CheckoutPage(product: widget.product),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: appConfig.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text(
                  widget.product['tombol_beli'] ?? "Beli",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- CLASS TERPISAH: PRODUCT CHECKOUT PAGE ---
class ProductCheckoutPage extends StatelessWidget {
  final Map<String, dynamic> product;
  const ProductCheckoutPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final price =
        (product['harga_diskon'] != null && product['harga_diskon'] > 0)
        ? product['harga_diskon']
        : product['harga'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product['gambar'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product['gambar'],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['nama_barang'] ?? '-',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Rp $price",
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            const Text(
              "Alamat Pengiriman",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product['lokasi']?['alamat_lengkap'] ?? "Alamat belum diatur",
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            _summaryRow(
              "Metode Pembayaran",
              product['bayar_online'] == true ? "Online Payment" : "Manual/COD",
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: appConfig.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Konfirmasi Pesanan",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black87)),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
