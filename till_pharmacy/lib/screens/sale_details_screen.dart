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

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  Future<void> loadItems() async {

    final data = await supabaseService.getSaleItems(widget.saleId);

    setState(() {
      items = data;
    });

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("Sale #${widget.saleId}"),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {

          final item = items[index];

          return ListTile(
            title: Text("${item['name']} (${item['unit']})"),
            subtitle: Text("Qty: ${item['quantity']}"),
            trailing: Text("${item['total']} ₪"),
          );

        },
      ),
    );

  }

}