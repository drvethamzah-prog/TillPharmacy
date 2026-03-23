import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/supabase_service.dart';
import 'barcode_scanner_screen.dart';
import 'sales_screen.dart';

final TextEditingController searchController = TextEditingController();

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final List<Product> cart = [];
  final SupabaseService supabaseService = SupabaseService();

  String search = '';

  List<Product> get filteredProducts {
    return products
        .where(
          (p) =>
              p.name.toLowerCase().contains(search.toLowerCase()) ||
              p.barcode.contains(search),
        )
        .toList();
  }

  void addToCart(Product product) {
    final index = cart.indexWhere((p) => p.barcode == product.barcode);

    setState(() {
      if (index != -1) {
        cart[index].qty++;
      } else {
        cart.add(
          Product(
            name: product.name,
            barcode: product.barcode,
            price: product.price,
          ),
        );
      }
    });
  }

  Future<void> selectUnit(Map<String, dynamic> data) async {
    final strips = data['strips_per_box'] ?? 1;
    final pills = data['pills_per_strip'] ?? 1;

    // If only one sale unit is available, add directly.
    if (strips == 1 && pills == 1) {
      final product = Product(
        name: data['name'],
        barcode: data['barcode'],
        price: (data['box_price'] ?? 0).toDouble(),
      );

      addToCart(product);
      searchController.clear();
      return;
    }

    final unit = await showDialog<String>(
      context: context,
      builder: (context) {
        final List<Widget> options = [];

        if (data['box_price'] != null) {
          options.add(
            ListTile(
              title: Text('علبة (${data['box_price']} ₪)'),
              onTap: () => Navigator.pop(context, 'box'),
            ),
          );
        }

        if (strips > 1) {
          options.add(
            ListTile(
              title: Text('شريط (${data['strip_price']} ₪)'),
              onTap: () => Navigator.pop(context, 'strip'),
            ),
          );
        }

        if (pills > 1) {
          options.add(
            ListTile(
              title: Text('حبة (${data['pill_price']} ₪)'),
              onTap: () => Navigator.pop(context, 'pill'),
            ),
          );
        }

        return AlertDialog(
          title: Text(data['name']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options,
          ),
        );
      },
    );

    if (unit == null) return;

    double price = 0;

    if (unit == 'box') price = (data['box_price'] ?? 0).toDouble();
    if (unit == 'strip') price = (data['strip_price'] ?? 0).toDouble();
    if (unit == 'pill') price = (data['pill_price'] ?? 0).toDouble();

    final product = Product(
      name: data['name'],
      barcode: data['barcode'],
      price: price,
    );

    addToCart(product);
    searchController.clear();
  }

  Future<void> addMultiple(Product product) async {
    final controller = TextEditingController();

    final qty = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('إضافة متعددة - ${product.name}'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'الكمية',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                Navigator.pop(context, value);
              },
              child: const Text('إضافة'),
            ),
          ],
        );
      },
    );

    if (qty == null || qty <= 0) return;

    final index = cart.indexWhere((p) => p.barcode == product.barcode);

    setState(() {
      if (index != -1) {
        cart[index].qty += qty;
      } else {
        cart.add(
          Product(
            name: product.name,
            barcode: product.barcode,
            price: product.price,
            qty: qty,
          ),
        );
      }
    });
  }

  double get total {
    double t = 0;
    for (final p in cart) {
      t += p.price * p.qty;
    }
    return t;
  }

  Future<void> scanBarcode() async {
    final barcode = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    if (barcode == null || barcode.isEmpty) return;

    final data = await supabaseService.getMedicine(barcode);

    if (data == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicine not found')),
      );

      return;
    }

    await selectUnit(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Till Pharmacy POS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SalesScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Search medicine or barcode',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  search = value;
                });
              },
              onSubmitted: (value) async {
                final data = await supabaseService.getMedicine(value);

                if (data == null) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Medicine not found')),
                  );
                  return;
                }

                await selectUnit(data);
              },
            ),
            ElevatedButton.icon(
              onPressed: scanBarcode,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Barcode'),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: filteredProducts.map((p) {
                  return ListTile(
                    title: Text(p.name),
                    subtitle: Text(p.barcode),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${p.price} ₪'),
                        IconButton(
                          icon: const Icon(Icons.add_box),
                          onPressed: () => addMultiple(p),
                        ),
                      ],
                    ),
                    onTap: () => addToCart(p),
                  );
                }).toList(),
              ),
            ),
            const Divider(),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sales',
                style: TextStyle(fontSize: 20),
              ),
            ),
            Expanded(
              child: cart.isEmpty
                  ? const Center(child: Text('لا يوجد أصناف بعد'))
                  : ListView(
                      children: cart.map((p) {
                        return Dismissible(
                          key: ValueKey('${p.barcode}-${p.name}'),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) {
                            setState(() {
                              cart.remove(p);
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${p.name} removed')),
                            );
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.red,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          child: ListTile(
                            title: Text(p.name),
                            subtitle: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () {
                                    setState(() {
                                      p.qty--;
                                      if (p.qty <= 0) {
                                        cart.remove(p);
                                      }
                                    });
                                  },
                                ),
                                Text('x${p.qty}'),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    setState(() {
                                      p.qty++;
                                    });
                                  },
                                ),
                              ],
                            ),
                            trailing: Text(
                              '${(p.price * p.qty).toStringAsFixed(2)} ₪',
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL (${cart.length} items)',
                  style: const TextStyle(fontSize: 22),
                ),
                Text(
                  total.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                if (cart.isEmpty) return;

                await supabaseService.saveSale(cart);

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sale saved successfully'),
                  ),
                );

                setState(() {
                  cart.clear();
                });
              },
              child: const Text('Complete Sale'),
            ),
          ],
        ),
      ),
    );
  }
}
