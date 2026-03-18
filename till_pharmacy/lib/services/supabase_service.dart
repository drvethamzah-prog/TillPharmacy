import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getSaleById(String saleId) async {
    final response = await supabase
        .from('sales')
        .select()
        .eq('id', saleId)
        .maybeSingle();

    return response;
  }

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

  Future<String?> _findOrCreateCustomer(String? customerName) async {
    final cleanedName = customerName?.trim();

    if (cleanedName == null || cleanedName.isEmpty) {
      return null;
    }

    final existing = await supabase
        .from('customers')
        .select('id, name')
        .ilike('name', cleanedName)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    final inserted = await supabase
        .from('customers')
        .insert({
          'name': cleanedName,
        })
        .select('id')
        .single();

    return inserted['id'] as String;
  }


  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  User? getCurrentUser() {
    return supabase.auth.currentUser;
  }

  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  Future<void> saveSale(
    List<Product> cart, {
    String? customerName,
  }) async {
    final user = supabase.auth.currentUser;

    final total = cart.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.qty),
    );

    final cleanedName = customerName?.trim();
    final customerId = await _findOrCreateCustomer(cleanedName);

    final sale = await supabase
        .from('sales')
        .insert({
          'total': total,
          'payment_type': 'cash',
          'user_id': user?.id,
          'customer_id': customerId,
          'customer_name':
              (cleanedName == null || cleanedName.isEmpty) ? null : cleanedName,
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