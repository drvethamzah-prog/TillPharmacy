import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getMedicine(String barcode) async {
    final data = await supabase
        .from('medicines')
        .select()
        .eq('barcode', barcode)
        .maybeSingle();

    return data;
  }

  Future<List<Map<String, dynamic>>> searchMedicines(String text) async {
    if (text.trim().isEmpty) return [];

    final response = await supabase
        .from('medicines')
        .select()
        .ilike('name', '%$text%')
        .limit(20);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> saveSale(List<Product> cart) async {
    final user = supabase.auth.currentUser;

    final total = cart.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.qty),
    );

    final sale = await supabase
        .from('sales')
        .insert({
          'total': total,
          'payment_type': 'cash',
          'user_id': user?.id,
        })
        .select()
        .single();

    final saleId = sale['id'];

    for (final item in cart) {
      await supabase.from('sale_items').insert({
        'sale_id': saleId,
        'barcode': item.barcode,
        'name': item.name,
        'unit': item.unit,
        'quantity': item.qty,
        'price': item.price,
        'min_price': item.minPrice,
        'total': item.price * item.qty,
      });
    }
  }


  Future<List<Map<String, dynamic>>> getSales() async {

    final response = await supabase
        .from('sales')
        .select()
        .order('created_at', ascending: false)
        .limit(50);

    return List<Map<String, dynamic>>.from(response);

  }

  Future<List<Map<String, dynamic>>> getSaleItems(String saleId) async {

    final response = await supabase
        .from('sale_items')
        .select()
        .eq('sale_id', saleId);

    return List<Map<String, dynamic>>.from(response);

  }
}