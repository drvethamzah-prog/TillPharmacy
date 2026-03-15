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

  @override
  void initState() {
    super.initState();
    loadSales();
  }

  Future<void> loadSales() async {

    final data = await supabaseService.getSales();

    setState(() {
      sales = data;
    });

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales History"),
      ),
      body: ListView.builder(
        itemCount: sales.length,
        itemBuilder: (context, index) {

          final sale = sales[index];

          return ListTile(
            title: Text("Sale #${sale['id']}"),
            subtitle: Text("${sale['created_at']}"),
            trailing: Text("${sale['total']} ₪"),
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
          );

        },
      ),
    );

  }
}