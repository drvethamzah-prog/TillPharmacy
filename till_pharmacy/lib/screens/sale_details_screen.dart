import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class SaleDetailsScreen extends StatefulWidget {
  final String saleId;

  const SaleDetailsScreen({super.key, required this.saleId});

  @override
  State<SaleDetailsScreen> createState() => _SaleDetailsScreenState();
}

class _SaleDetailsScreenState extends State<SaleDetailsScreen> {
  final supabaseService = SupabaseService();

  List items = [];
  Map<String, dynamic>? sale;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final saleData = await supabaseService.getSaleById(widget.saleId);
    final itemsData = await supabaseService.getSaleItems(widget.saleId);

    if (!mounted) return;

    setState(() {
      sale = saleData;
      items = itemsData;
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
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerName = (sale?['customer_name'] ?? '').toString().trim();
    final createdAt = formatDate(sale?['created_at']?.toString());
    final total = formatMoney(sale?['total']);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sale Details"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Sale #${widget.saleId}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Customer: ${customerName.isEmpty ? '-' : customerName}",
                        ),
                        const SizedBox(height: 4),
                        Text("Date: $createdAt"),
                        const SizedBox(height: 4),
                        Text(
                          "Total: $total ₪",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? const Center(
                          child: Text(
                            "No items found",
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];

                            final qty = item['quantity'] ?? 0;
                            final price = formatMoney(item['price']);
                            final itemTotal = formatMoney(item['total']);

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: ListTile(
                                title: Text(
                                  "${item['name']} (${item['unit']})",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Qty: $qty"),
                                      Text("Price: $price ₪"),
                                    ],
                                  ),
                                ),
                                trailing: Text(
                                  "$itemTotal ₪",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}