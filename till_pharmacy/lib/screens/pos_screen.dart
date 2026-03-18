import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/product.dart';
import '../services/supabase_service.dart';
import 'sales_screen.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final SupabaseService supabaseService = SupabaseService();
  final List<Product> cart = [];
  final TextEditingController searchController = TextEditingController();
  final TextEditingController customerNameController = TextEditingController();

  List<Map<String, dynamic>> suggestions = [];

  double getTotal() {
    return cart.fold<double>(0, (sum, item) => sum + (item.price * item.qty));
  }

  double getLineTotal(Product product) {
    return product.price * product.qty;
  }

  void clearCart() {
    setState(() {
      cart.clear();
      suggestions = [];
      searchController.clear();
      customerNameController.clear();
    });
  }

  void addToCart({
    required String barcode,
    required String name,
    required String unit,
    required double price,
    required double minPrice,
  }) {
    final index = cart.indexWhere(
      (p) => p.barcode == barcode && p.unit == unit,
    );

    setState(() {
      if (index != -1) {
        cart[index].qty++;
      } else {
        cart.add(
          Product(
            barcode: barcode,
            name: name,
            unit: unit,
            price: price,
            minPrice: minPrice,
          ),
        );
      }
    });
  }

  Future<void> editItemPrice(Product product) async {
    final controller = TextEditingController(
      text: product.price.toStringAsFixed(2),
    );

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text("Edit Price - ${product.name} (${product.unit})"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Minimum allowed: ${product.minPrice.toStringAsFixed(2)} ₪"),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Sale price",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final newPrice = double.tryParse(controller.text.trim());

                if (newPrice == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invalid price")),
                  );
                  return;
                }

                if (newPrice < product.minPrice) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Cannot sell below minimum price (${product.minPrice.toStringAsFixed(2)} ₪)",
                      ),
                    ),
                  );
                  return;
                }

                setState(() {
                  product.price = newPrice;
                });

                Navigator.of(dialogContext).pop();
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  List<_UnitOption> buildUnitOptions(Map<String, dynamic> med) {
    final barcode = (med['barcode'] ?? '').toString();
    final name = (med['name'] ?? '').toString();
    final minPrice = ((med['min_price'] ?? 0) as num).toDouble();

    final salePrice = ((med['sale_price'] ?? 0) as num).toDouble();
    final boxPrice =
        ((med['box_price'] ?? med['sale_price'] ?? 0) as num).toDouble();
    final stripPrice = ((med['strip_price'] ?? 0) as num).toDouble();
    final pillPrice = ((med['pill_price'] ?? 0) as num).toDouble();

    final stockBox = ((med['stock_box'] ?? 0) as num).toInt();
    final stockStrip = ((med['stock_strip'] ?? 0) as num).toInt();
    final stockPill = ((med['stock_pill'] ?? 0) as num).toInt();

    final options = <_UnitOption>[];

    if (stockBox > 0) {
      options.add(
        _UnitOption(
          barcode: barcode,
          name: name,
          unit: "BOX",
          price: boxPrice == 0 ? salePrice : boxPrice,
          minPrice: minPrice,
        ),
      );
    }

    if (stockStrip > 0) {
      options.add(
        _UnitOption(
          barcode: barcode,
          name: name,
          unit: "STRIP",
          price: stripPrice,
          minPrice: minPrice,
        ),
      );
    }

    if (stockPill > 0) {
      options.add(
        _UnitOption(
          barcode: barcode,
          name: name,
          unit: "PILL",
          price: pillPrice,
          minPrice: minPrice,
        ),
      );
    }

    if (options.isEmpty && salePrice > 0) {
      options.add(
        _UnitOption(
          barcode: barcode,
          name: name,
          unit: "BOX",
          price: salePrice,
          minPrice: minPrice,
        ),
      );
    }

    return options;
  }

  Future<void> chooseUnitAndAdd(Map<String, dynamic> med) async {
    final options = buildUnitOptions(med);

    if (options.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No sellable unit found for this medicine")),
      );
      return;
    }

    if (options.length == 1) {
      final o = options.first;
      addToCart(
        barcode: o.barcode,
        name: o.name,
        unit: o.unit,
        price: o.price,
        minPrice: o.minPrice,
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text((med['name'] ?? '').toString()),
          content: const Text("Select type"),
          actions: options
              .map(
                (o) => TextButton(
                  onPressed: () {
                    addToCart(
                      barcode: o.barcode,
                      name: o.name,
                      unit: o.unit,
                      price: o.price,
                      minPrice: o.minPrice,
                    );
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text("${o.unit} (${o.price.toStringAsFixed(2)} ₪)"),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Future<void> addProductByBarcode(String barcode) async {
    final med = await supabaseService.getMedicine(barcode);

    if (!mounted) return;

    if (med == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Medicine not found")),
      );
      return;
    }

    await chooseUnitAndAdd(med);
  }

  Future<void> addProductFromSearch(Map<String, dynamic> med) async {
    await chooseUnitAndAdd(med);
  }

  Future<void> scanBarcode() async {
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    if (result == null || result.trim().isEmpty) return;

    await addProductByBarcode(result.trim());
  }

  Future<void> completeSale() async {
    if (cart.isEmpty) return;

    await supabaseService.saveSale(
      cart,
      customerName: customerNameController.text.trim(),
    );

    if (!mounted) return;

    clearCart();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sale saved")),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    customerNameController.dispose();
    super.dispose();
  }

  Widget _buildCartItem(Product product, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${product.name} (${product.unit})",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Text("Price: ${product.price.toStringAsFixed(2)} ₪"),
                Text("Min: ${product.minPrice.toStringAsFixed(2)} ₪"),
                Text("Qty: ${product.qty}"),
                Text(
                  "Line total: ${getLineTotal(product).toStringAsFixed(2)} ₪",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      if (product.qty > 1) {
                        product.qty--;
                      }
                    });
                  },
                  icon: const Icon(Icons.remove),
                  label: const Text("Less"),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      product.qty++;
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("More"),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => editItemPrice(product),
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit Price"),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      cart.removeAt(index);
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Till Pharmacy POS"),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: scanBarcode,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SalesScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: clearCart,
          ),

          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabaseService.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                TextField(
                  controller: customerNameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Customer name",
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Search medicine",
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (text) async {
                    if (text.trim().isEmpty) {
                      setState(() {
                        suggestions = [];
                      });
                      return;
                    }

                    final result = await supabaseService.searchMedicines(text);

                    if (!mounted) return;

                    setState(() {
                      suggestions = result;
                    });
                  },
                  onSubmitted: (value) async {
                    if (suggestions.isEmpty) return;

                    final med = suggestions.first;

                    setState(() {
                      suggestions = [];
                      searchController.clear();
                    });

                    await addProductFromSearch(med);
                  },
                ),
                if (suggestions.isNotEmpty)
                  Container(
                    height: 200,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: suggestions.length,
                      itemBuilder: (context, index) {
                        final med = suggestions[index];
                        final displayPrice =
                            ((med['box_price'] ?? med['sale_price'] ?? 0) as num)
                                .toDouble();

                        return ListTile(
                          title: Text((med['name'] ?? '').toString()),
                          subtitle: Text("${displayPrice.toStringAsFixed(2)} ₪"),
                          onTap: () async {
                            setState(() {
                              suggestions = [];
                              searchController.clear();
                            });

                            await addProductFromSearch(med);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: cart.isEmpty
                ? const Center(
                    child: Text(
                      "No items in cart",
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final product = cart[index];
                      return _buildCartItem(product, index);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            border: const Border(
              top: BorderSide(color: Colors.black12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTAL (${cart.length} items)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${getTotal().toStringAsFixed(2)} ₪',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: cart.isEmpty ? null : completeSale,
                  child: const Text('COMPLETE SALE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BarcodeScannerScreen extends StatelessWidget {
  const BarcodeScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Barcode"),
      ),
      body: MobileScanner(
        onDetect: (BarcodeCapture capture) {
          final List<Barcode> barcodes = capture.barcodes;

          if (barcodes.isEmpty) return;

          final String? code = barcodes.first.rawValue;

          if (code == null || code.trim().isEmpty) return;

          Navigator.pop(context, code.trim());
        },
      ),
    );
  }
}

class _UnitOption {
  final String barcode;
  final String name;
  final String unit;
  final double price;
  final double minPrice;

  _UnitOption({
    required this.barcode,
    required this.name,
    required this.unit,
    required this.price,
    required this.minPrice,
  });
}