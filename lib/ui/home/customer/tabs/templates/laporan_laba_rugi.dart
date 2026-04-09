import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/network/api_service.dart';
import '../../../../../core/network/session_manager.dart';
import '../transaction_history_tab.dart';

class LaporanLabaRugi extends StatefulWidget {
  const LaporanLabaRugi({super.key});

  @override
  State<LaporanLabaRugi> createState() => _LaporanLabaRugiState();
}

class _LaporanLabaRugiState extends State<LaporanLabaRugi>
    with SingleTickerProviderStateMixin {
  late ApiService _apiService;
  late TabController _tabController;

  // Data state
  bool _isLoading = true;
  String _selectedPeriode = 'month';
  Map<String, dynamic>? _summaryData;
  List<Map<String, dynamic>> _chartData = [];
  List<dynamic> _prabayarCategory = [];
  List<dynamic> _pascabayarCategory = [];
  List<dynamic> _recentTransactions = [];

  // Periode options
  final List<Map<String, String>> _periodeOptions = [
    {'value': 'today', 'label': 'Hari Ini'},
    {'value': 'week', 'label': 'Minggu Ini'},
    {'value': 'month', 'label': 'Bulan Ini'},
    {'value': 'year', 'label': 'Tahun Ini'},
    {'value': 'all', 'label': 'Semua'},
  ];

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(Dio());
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final token = await SessionManager.getToken();
      if (token == null) return;

      // Load all data in parallel
      final results = await Future.wait([
        _apiService.getLaporanLabaSummary(
          token: token,
          periode: _selectedPeriode,
        ),
        _apiService.getLaporanLabaChart(
          token: token,
          periode: _selectedPeriode,
        ),
        _apiService.getLaporanLabaCategory(
          token: token,
          periode: _selectedPeriode,
        ),
        _apiService.getLaporanLabaRecent(token: token, limit: 10),
      ]);

      final summaryResponse = results[0];
      final chartResponse = results[1];
      final categoryResponse = results[2];
      final recentResponse = results[3];

      if (mounted) {
        setState(() {
          // Summary data
          if (summaryResponse.statusCode == 200 &&
              summaryResponse.data['status'] == 'success') {
            _summaryData = summaryResponse.data['data'];
          }

          // Chart data
          if (chartResponse.statusCode == 200 &&
              chartResponse.data['status'] == 'success') {
            final chartDataRaw = chartResponse.data['data'];
            _chartData = List<Map<String, dynamic>>.from(
              chartDataRaw['chart'] ?? [],
            );
          }

          // Category data
          if (categoryResponse.statusCode == 200 &&
              categoryResponse.data['status'] == 'success') {
            final categoryDataRaw = categoryResponse.data['data'];
            _prabayarCategory = categoryDataRaw['prabayar'] ?? [];
            _pascabayarCategory = categoryDataRaw['pascabayar'] ?? [];
          }

          // Recent transactions
          if (recentResponse.statusCode == 200 &&
              recentResponse.data['status'] == 'success') {
            _recentTransactions = recentResponse.data['data'] ?? [];
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatCurrency(dynamic value) {
    final number = (value is int) ? value : int.tryParse(value.toString()) ?? 0;
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Keuntungan Toko',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1DB954),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Header with filter
                    _buildPeriodeFilter(),

                    // Summary Cards
                    _buildSummaryCards(),

                    // Profit Chart
                    _buildProfitChart(),

                    // Tab for Prabayar/Pascabayar breakdown
                    _buildCategorySection(),

                    // Recent Transactions
                    _buildRecentTransactions(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodeFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _periodeOptions.map((option) {
            final isSelected = _selectedPeriode == option['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(option['label']!),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedPeriode = option['value']!);
                    _loadData();
                  }
                },
                selectedColor: const Color(0xFF1DB954),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF1DB954)
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final summary = _summaryData?['summary'];
    final prabayar = _summaryData?['prabayar'];
    final pascabayar = _summaryData?['pascabayar'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Total Profit Card (highlight)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1DB954).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.trending_up,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Keuntungan',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          'dari Markup Member',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _formatCurrency(summary?['total_profit'] ?? 0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${summary?['total_transaksi'] ?? 0} Transaksi Sukses',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Prabayar & Pascabayar Cards
          Row(
            children: [
              Expanded(
                child: _buildMiniCard(
                  title: 'Prabayar',
                  profit: prabayar?['total_profit'] ?? 0,
                  count: prabayar?['total_transaksi'] ?? 0,
                  icon: Icons.phone_android,
                  color: const Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniCard(
                  title: 'Pascabayar',
                  profit: pascabayar?['total_profit'] ?? 0,
                  count: pascabayar?['total_transaksi'] ?? 0,
                  icon: Icons.receipt_long,
                  color: const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard({
    required String title,
    required int profit,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatCurrency(profit),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count transaksi',
            style: const TextStyle(color: Colors.black54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitChart() {
    if (_chartData.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.bar_chart, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Belum ada data chart',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grafik Keuntungan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color.fromARGB(255, 3, 3, 3),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keuntungan harian dari markup member',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 20),
          SizedBox(height: 200, child: _buildBarChart()),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    if (_chartData.isEmpty) {
      return const Center(child: Text('Tidak ada data'));
    }

    final maxY = _chartData.fold<double>(
      0,
      (max, item) => (item['profit'] as int) > max
          ? (item['profit'] as int).toDouble()
          : max,
    );

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => const Color(0xFF1DB954),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final profit = _chartData[groupIndex]['profit'];
              return BarTooltipItem(
                _formatCurrency(profit),
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < _chartData.length) {
                  final date = _chartData[index]['date'] ?? '';
                  // Format date label
                  String label = date;
                  if (date.length >= 10) {
                    label = date.substring(8, 10); // Day only
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('');
                String label;
                if (value >= 1000000) {
                  label = '${(value / 1000000).toStringAsFixed(1)}jt';
                } else if (value >= 1000) {
                  label = '${(value / 1000).toStringAsFixed(0)}rb';
                } else {
                  label = value.toInt().toString();
                }
                return Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? maxY / 4 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
          },
        ),
        barGroups: _chartData.asMap().entries.map((entry) {
          final index = entry.key;
          final profit = (entry.value['profit'] as int).toDouble();
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: profit,
                width: _chartData.length > 15 ? 8 : 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tab Header
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1DB954),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF1DB954),
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Prabayar'),
                Tab(text: 'Pascabayar'),
              ],
            ),
          ),

          // Tab Content
          SizedBox(
            height: 250,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryList(_prabayarCategory, 'prabayar'),
                _buildCategoryList(_pascabayarCategory, 'pascabayar'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(List<dynamic> categories, String type) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada data kategori',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: categories.length > 5 ? 5 : categories.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = categories[index];
        final category = item['category'] ?? 'Unknown';
        final profit = item['total_profit'] ?? 0;
        final count = item['total_transaksi'] ?? 0;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getCategoryColor(index).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getCategoryIcon(category),
              color: _getCategoryColor(index),
              size: 20,
            ),
          ),
          title: Text(
            category.toString().toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.black,
            ),
          ),
          subtitle: Text(
            '$count transaksi',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
          trailing: Text(
            _formatCurrency(profit),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1DB954),
              fontSize: 14,
            ),
          ),
        );
      },
    );
  }

  Color _getCategoryColor(int index) {
    final colors = [
      const Color(0xFF1DB954),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
    ];
    return colors[index % colors.length];
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('pln') || cat.contains('listrik')) return Icons.bolt;
    if (cat.contains('pulsa') ||
        cat.contains('xl') ||
        cat.contains('telkomsel'))
      return Icons.phone_android;
    if (cat.contains('data') || cat.contains('internet')) return Icons.wifi;
    if (cat.contains('bpjs')) return Icons.health_and_safety;
    if (cat.contains('pdam') || cat.contains('air')) return Icons.water_drop;
    if (cat.contains('game')) return Icons.sports_esports;
    if (cat.contains('tv')) return Icons.tv;
    if (cat.contains('emoney') || cat.contains('wallet'))
      return Icons.account_balance_wallet;
    return Icons.category;
  }

  Widget _buildRecentTransactions() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transaksi Terakhir',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color.fromARGB(255, 3, 3, 3),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TransactionHistoryTab(),
                    ),
                  );
                },
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(color: Color(0xFF1DB954)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_recentTransactions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Belum ada transaksi dengan keuntungan',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ..._recentTransactions.take(5).map((trx) {
              final productName = trx['product_name'] ?? '-';
              final profit = trx['profit'] ?? 0;
              final type = trx['type'] ?? 'prabayar';
              final createdAt = trx['created_at'] ?? '';

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: type == 'prabayar'
                            ? const Color(0xFF2196F3).withOpacity(0.1)
                            : const Color(0xFFFF9800).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        type == 'prabayar'
                            ? Icons.phone_android
                            : Icons.receipt_long,
                        color: type == 'prabayar'
                            ? const Color(0xFF2196F3)
                            : const Color(0xFFFF9800),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDateTime(createdAt),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+${_formatCurrency(profit)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1DB954),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateTime);
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
    } catch (_) {
      return dateTime;
    }
  }
}

