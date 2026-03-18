import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'sale_details_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final supabaseService = SupabaseService();

  List sales = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSales();
  }

  Future<void> loadSales() async {
    final data = await supabaseService.getSales();

    if (!mounted) return;

    setState(() {
      sales = data;
      isLoading = false;
    });
  }

  String formatMoney(dynamic value) {
    final number = (value ?? 0) as num;
    return number.toStringAsFixed(2);
    }

  String formatDate(String? value) {
    if (value == null || value.isEmpty) return '-';

    try {
      final dt = DateTime.parse(value).toLocal();
      return
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales History"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : sales.isEmpty
              ? const Center(
                  child: Text(
                    "No sales found",
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadSales,
                  child: ListView.builder(
                    itemCount: sales.length,
                    itemBuilder: (context, index) {
                      final sale = sales[index];

                      final customerName =
                          (sale['customer_name'] ?? '').toString().trim();
                      final createdAt = formatDate(sale['created_at']?.toString());
                      final total = formatMoney(sale['total']);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          title: Text(
                            "Sale #${sale['id']}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Customer: ${customerName.isEmpty ? '-' : customerName}",
                                ),
                                const SizedBox(height: 4),
                                Text("Date: $createdAt"),
                              ],
                            ),
                          ),
                          trailing: Text(
                            "$total ₪",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SaleDetailsScreen(
                                  saleId: sale['id'].toString(),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}