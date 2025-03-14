import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  // Singleton pattern
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Credenciais do Supabase
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? 'https://rwotvxqknrjurqrhxhjv.supabase.co';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3b3R2eHFrbnJqdXJxcmh4aGp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE4OTI0MzIsImV4cCI6MjA1NzQ2ODQzMn0.RgrvQZ2ltMtxVFWkcO2fRD2ySSeYdvaHVmM7MNGZt_M';
  
  // Cliente Supabase
  SupabaseClient get client => Supabase.instance.client;
  
  // Inicializar o Supabase
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: kDebugMode, // Ativar logs de debug apenas em modo de desenvolvimento
      );
      debugPrint('Supabase inicializado com sucesso');
    } catch (e) {
      debugPrint('Erro ao inicializar Supabase: $e');
      rethrow;
    }
  }
  
  // Autenticação
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
        },
      );
      
      // Se o registro for bem-sucedido, criar o perfil do usuário
      if (response.user != null) {
        await _createUserProfile(response.user!.id, {
          'name': name,
          'phone': phone,
        });
      }
      
      return response;
    } catch (e) {
      debugPrint('Erro no cadastro: $e');
      rethrow;
    }
  }
  
  // Criar perfil do usuário após o registro
  static Future<void> _createUserProfile(String userId, Map<String, dynamic> userData) async {
    try {
      await client.from('profiles').insert({
        'id': userId,
        'name': userData['name'] ?? '',
        'phone': userData['phone'] ?? '',
        'city': userData['city'] ?? '',
        'state': userData['state'] ?? '',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Criar assinatura do usuário
      await _createSubscription(userId, userData);
    } catch (e) {
      debugPrint('Erro ao criar perfil do usuário: $e');
      rethrow;
    }
  }
  
  // Criar assinatura do usuário
  static Future<void> _createSubscription(String userId, Map<String, dynamic> userData) async {
    try {
      final planType = userData['plan_type'] ?? 'monthly';
      final planName = userData['plan'] ?? 'Básico';
      final planPrice = userData['plan_price'] ?? 19.90;
      
      await client.from('subscriptions').insert({
        'user_id': userId,
        'plan_name': planName,
        'plan_type': planType,
        'price': planPrice,
        'status': 'pending', // Aguardando pagamento
        'start_date': DateTime.now().toIso8601String(),
        'next_billing_date': planType == 'annual' 
            ? DateTime.now().add(const Duration(days: 365)).toIso8601String()
            : DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Erro ao criar assinatura: $e');
      rethrow;
    }
  }
  
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      debugPrint('Erro no login: $e');
      rethrow;
    }
  }
  
  static Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      debugPrint('Erro ao fazer logout: $e');
      rethrow;
    }
  }
  
  static Future<void> resetPassword(String email) async {
    try {
      await client.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('Erro ao redefinir senha: $e');
      rethrow;
    }
  }
  
  // Verificar se o usuário está autenticado
  static bool isAuthenticated() {
    return client.auth.currentUser != null;
  }
  
  // Obter o usuário atual
  static User? getCurrentUser() {
    return client.auth.currentUser;
  }
  
  // Obter perfil do usuário
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userId = getCurrentUser()?.id;
      if (userId == null) return null;
      
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      return response;
    } catch (e) {
      debugPrint('Erro ao buscar perfil do usuário: $e');
      return null;
    }
  }
  
  // Obter assinatura do usuário
  static Future<Map<String, dynamic>?> getUserSubscription() async {
    try {
      final userId = getCurrentUser()?.id;
      if (userId == null) return null;
      
      final response = await client
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .single();
      
      return response;
    } catch (e) {
      debugPrint('Erro ao buscar assinatura do usuário: $e');
      return null;
    }
  }
  
  // Atualizar assinatura do usuário
  static Future<void> updateSubscription(Map<String, dynamic> subscriptionData) async {
    try {
      final userId = getCurrentUser()?.id;
      if (userId == null) return;
      
      final subscription = await getUserSubscription();
      if (subscription == null) return;
      
      await client
          .from('subscriptions')
          .update({
            ...subscriptionData,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', subscription['id']);
    } catch (e) {
      debugPrint('Erro ao atualizar assinatura: $e');
      rethrow;
    }
  }
  
  // Processar pagamento
  static Future<Map<String, dynamic>> processPayment({
    required String paymentMethod,
    required double amount,
    required String description,
  }) async {
    try {
      final userId = getCurrentUser()?.id;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }
      
      // Este método está sendo substituído pelo AsaasService
      // Mantido apenas para compatibilidade com código existente
      debugPrint('Aviso: Este método está sendo substituído pelo AsaasService');
      
      // Simular processamento de pagamento
      await Future.delayed(const Duration(seconds: 2));
      
      // Registrar o pagamento no banco de dados
      final paymentData = {
        'user_id': userId,
        'payment_method': paymentMethod,
        'amount': amount,
        'description': description,
        'status': 'completed',
        'created_at': DateTime.now().toIso8601String(),
      };
      
      final response = await client
          .from('payments')
          .insert(paymentData)
          .select()
          .single();
      
      // Atualizar status da assinatura
      await updateSubscription({
        'status': 'active',
        'last_payment_date': DateTime.now().toIso8601String(),
      });
      
      return response;
    } catch (e) {
      debugPrint('Erro ao processar pagamento: $e');
      rethrow;
    }
  }
  
  // CRUD para transações financeiras
  static Future<List<Map<String, dynamic>>> getTransactions() async {
    try {
      final response = await client
          .from('transactions')
          .select()
          .eq('user_id', getCurrentUser()?.id)
          .order('date', ascending: false);
      
      return response;
    } catch (e) {
      debugPrint('Erro ao buscar transações: $e');
      rethrow;
    }
  }
  
  static Future<void> addTransaction(Map<String, dynamic> transactionData) async {
    try {
      await client.from('transactions').insert({
        ...transactionData,
        'user_id': getCurrentUser()?.id,
      });
    } catch (e) {
      debugPrint('Erro ao adicionar transação: $e');
      rethrow;
    }
  }
  
  static Future<void> updateTransaction(
    String id,
    Map<String, dynamic> transactionData,
  ) async {
    try {
      await client
          .from('transactions')
          .update(transactionData)
          .eq('id', id)
          .eq('user_id', getCurrentUser()?.id);
    } catch (e) {
      debugPrint('Erro ao atualizar transação: $e');
      rethrow;
    }
  }
  
  static Future<void> deleteTransaction(String id) async {
    try {
      await client
          .from('transactions')
          .delete()
          .eq('id', id)
          .eq('user_id', getCurrentUser()?.id);
    } catch (e) {
      debugPrint('Erro ao excluir transação: $e');
      rethrow;
    }
  }

  // Perfil do usuário
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    await client
        .from('profiles')
        .update(data)
        .eq('id', user.id);
  }

  // Planos
  Future<List<Map<String, dynamic>>> getPlans() async {
    final response = await client
        .from('plans')
        .select()
        .eq('is_active', true);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // Assinaturas
  Future<Map<String, dynamic>?> getCurrentSubscription() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final response = await client
        .from('subscriptions')
        .select('*, plans(*)')
        .eq('user_id', user.id)
        .eq('status', 'active')
        .maybeSingle();
    
    return response;
  }

  Future<void> createSubscription(Map<String, dynamic> data) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    data['user_id'] = user.id;
    
    await client
        .from('subscriptions')
        .insert(data);
  }

  // Transações
  Future<List<Map<String, dynamic>>> getTransactions({
    String? type,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) return [];

    var query = client
        .from('transactions')
        .select('*, categories(*)')
        .eq('user_id', user.id)
        .order('date', ascending: false);
    
    if (type != null) {
      query = query.eq('type', type);
    }
    
    if (category != null) {
      query = query.eq('category', category);
    }
    
    if (startDate != null) {
      query = query.gte('date', startDate.toIso8601String());
    }
    
    if (endDate != null) {
      query = query.lte('date', endDate.toIso8601String());
    }
    
    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createTransaction(Map<String, dynamic> data) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    data['user_id'] = user.id;
    
    await client
        .from('transactions')
        .insert(data);
  }

  Future<void> updateTransaction(String id, Map<String, dynamic> data) async {
    await client
        .from('transactions')
        .update(data)
        .eq('id', id);
  }

  Future<void> deleteTransaction(String id) async {
    await client
        .from('transactions')
        .delete()
        .eq('id', id);
  }

  // Categorias
  Future<List<Map<String, dynamic>>> getCategories({String? type}) async {
    final user = client.auth.currentUser;
    if (user == null) return [];

    var query = client
        .from('categories')
        .select()
        .or('is_default.eq.true,user_id.eq.${user.id}');
    
    if (type != null) {
      query = query.eq('type', type);
    }
    
    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createCategory(Map<String, dynamic> data) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    data['user_id'] = user.id;
    data['is_default'] = false;
    
    await client
        .from('categories')
        .insert(data);
  }

  // Plantões
  Future<List<Map<String, dynamic>>> getShifts({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) return [];

    var query = client
        .from('shifts')
        .select()
        .eq('user_id', user.id)
        .order('start_time', ascending: false);
    
    if (status != null) {
      query = query.eq('status', status);
    }
    
    if (startDate != null) {
      query = query.gte('start_time', startDate.toIso8601String());
    }
    
    if (endDate != null) {
      query = query.lte('start_time', endDate.toIso8601String());
    }
    
    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createShift(Map<String, dynamic> data) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    data['user_id'] = user.id;
    
    await client
        .from('shifts')
        .insert(data);
  }

  Future<void> updateShift(String id, Map<String, dynamic> data) async {
    await client
        .from('shifts')
        .update(data)
        .eq('id', id);
  }

  // Consultas
  Future<List<Map<String, dynamic>>> getAppointments({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) return [];

    var query = client
        .from('appointments')
        .select()
        .eq('user_id', user.id)
        .order('appointment_time', ascending: false);
    
    if (status != null) {
      query = query.eq('status', status);
    }
    
    if (startDate != null) {
      query = query.gte('appointment_time', startDate.toIso8601String());
    }
    
    if (endDate != null) {
      query = query.lte('appointment_time', endDate.toIso8601String());
    }
    
    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createAppointment(Map<String, dynamic> data) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    data['user_id'] = user.id;
    
    await client
        .from('appointments')
        .insert(data);
  }

  Future<void> updateAppointment(String id, Map<String, dynamic> data) async {
    await client
        .from('appointments')
        .update(data)
        .eq('id', id);
  }

  // Configurações do usuário
  Future<Map<String, dynamic>?> getUserSettings() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final response = await client
        .from('user_settings')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    
    return response;
  }

  Future<void> updateUserSettings(Map<String, dynamic> data) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    // Verificar se já existem configurações
    final settings = await getUserSettings();
    
    if (settings == null) {
      // Criar novas configurações
      data['user_id'] = user.id;
      await client.from('user_settings').insert(data);
    } else {
      // Atualizar configurações existentes
      await client
          .from('user_settings')
          .update(data)
          .eq('user_id', user.id);
    }
  }
} 