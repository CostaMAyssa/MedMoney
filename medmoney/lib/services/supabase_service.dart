import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  // Singleton pattern
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late final SupabaseClient _client;
  
  // Método de inicialização como método de instância
  Future<void> initialize() async {
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseKey = dotenv.env['SUPABASE_KEY'] ?? '';
    
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
    
    _client = Supabase.instance.client;
  }
  
  // Método para obter o cliente Supabase
  SupabaseClient get client => Supabase.instance.client;

  // Credenciais do Supabase
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? 'https://rwotvxqknrjurqrhxhjv.supabase.co';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3b3R2eHFrbnJqdXJxcmh4aGp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE4OTI0MzIsImV4cCI6MjA1NzQ2ODQzMn0.RgrvQZ2ltMtxVFWkcO2fRD2ySSeYdvaHVmM7MNGZt_M';
  
  // Inicializar o Supabase
  static Future<void> initializeStatic() async {
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
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      debugPrint('Iniciando processo de criação de conta para: $email');
      
      // Registrar o usuário no Supabase Auth
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
        },
      );
      
      debugPrint('Resposta do Supabase: ${response.user != null ? 'Usuário criado' : 'Falha na criação do usuário'}');
      
      // Se o usuário foi criado com sucesso, tentar criar o perfil
      // Mas não falhar se o perfil não puder ser criado
      if (response.user != null) {
        debugPrint('Usuário criado com sucesso: ${response.user!.id}');
        
        try {
          // Tentar criar o perfil, mas não falhar se não conseguir
          await client.from('profiles').insert({
            'id': response.user!.id,
            'name': name,
            'email': email,
            'phone': phone,
            'created_at': DateTime.now().toIso8601String(),
          }).execute();
          
          debugPrint('Perfil criado com sucesso');
        } catch (profileError) {
          // Ignorar erros ao criar o perfil
          debugPrint('Erro ao criar perfil (ignorado): $profileError');
          debugPrint('O usuário foi criado com sucesso, mas o perfil não pôde ser criado.');
          debugPrint('Isso pode acontecer se a tabela "profiles" não existir no banco de dados.');
          debugPrint('Execute o script SQL fornecido para criar as tabelas necessárias.');
        }
      }
      
      return response;
    } catch (e) {
      debugPrint('Erro detalhado ao criar conta: $e');
      rethrow;
    }
  }
  
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Iniciando processo de login para: $email');
      
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      debugPrint('Resposta do login: ${response.user != null ? 'Login bem-sucedido' : 'Falha no login'}');
      
      return response;
    } catch (e) {
      debugPrint('Erro detalhado ao fazer login: $e');
      rethrow;
    }
  }
  
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      debugPrint('Erro ao fazer logout: $e');
      rethrow;
    }
  }
  
  // Perfil do usuário
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final userId = client.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }
      
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      return response as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Erro ao obter perfil: $e');
      rethrow;
    }
  }
  
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final userId = client.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }
      
      await client
          .from('profiles')
          .update(data)
          .eq('id', userId);
      
    } catch (e) {
      debugPrint('Erro ao atualizar perfil: $e');
      rethrow;
    }
  }
  
  // Assinaturas
  Future<Map<String, dynamic>?> getUserSubscription() async {
    try {
      final userId = client.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }
      
      final response = await client
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);
      
      final data = response as List;
      
      if (data.isEmpty) {
        return null;
      }
      
      return data.first as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Erro ao obter assinatura: $e');
      rethrow;
    }
  }
  
  Future<void> createSubscription(Map<String, dynamic> data) async {
    try {
      final userId = client.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }
      
      data['user_id'] = userId;
      data['created_at'] = DateTime.now().toIso8601String();
      
      await client
          .from('subscriptions')
          .insert(data);
      
    } catch (e) {
      debugPrint('Erro ao criar assinatura: $e');
      rethrow;
    }
  }
  
  Future<void> updateSubscription(String id, Map<String, dynamic> data) async {
    try {
      await client
          .from('subscriptions')
          .update(data)
          .eq('id', id);
      
    } catch (e) {
      debugPrint('Erro ao atualizar assinatura: $e');
      rethrow;
    }
  }
  
  // Planos
  Future<List<Map<String, dynamic>>> getPlans() async {
    try {
      final response = await client
          .from('plans')
          .select()
          .order('price', ascending: true);
      
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Erro ao obter planos: $e');
      rethrow;
    }
  }
  
  // Transações
  Future<void> createTransaction(Map<String, dynamic> data) async {
    try {
      final userId = client.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }
      
      data['user_id'] = userId;
      data['created_at'] = DateTime.now().toIso8601String();
      
      await client
          .from('transactions')
          .insert(data);
      
    } catch (e) {
      debugPrint('Erro ao criar transação: $e');
      rethrow;
    }
  }
  
  Future<void> updateTransaction(String id, Map<String, dynamic> data) async {
    try {
      await client
          .from('transactions')
          .update(data)
          .eq('id', id);
      
    } catch (e) {
      debugPrint('Erro ao atualizar transação: $e');
      rethrow;
    }
  }
  
  Future<void> deleteTransaction(String id) async {
    try {
      await client
          .from('transactions')
          .delete()
          .eq('id', id);
      
    } catch (e) {
      debugPrint('Erro ao excluir transação: $e');
      rethrow;
    }
  }
  
  Future<List<Map<String, dynamic>>> getUserTransactions() async {
    try {
      final userId = client.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }
      
      final response = await client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);
      
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Erro ao obter transações: $e');
      rethrow;
    }
  }
  
  // Categorias
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await client
          .from('categories')
          .select()
          .order('name', ascending: true);
      
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Erro ao obter categorias: $e');
      rethrow;
    }
  }
  
  Future<void> createCategory(Map<String, dynamic> data) async {
    try {
      final userId = client.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }
      
      data['user_id'] = userId;
      data['created_at'] = DateTime.now().toIso8601String();
      
      await client
          .from('categories')
          .insert(data);
      
    } catch (e) {
      debugPrint('Erro ao criar categoria: $e');
      rethrow;
    }
  }
  
  // Plantões
  Future<void> createShift(Map<String, dynamic> data) async {
    try {
      final userId = client.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }
      
      data['user_id'] = userId;
      data['created_at'] = DateTime.now().toIso8601String();
      
      await client
          .from('shifts')
          .insert(data);
      
    } catch (e) {
      debugPrint('Erro ao criar plantão: $e');
      rethrow;
    }
  }
  
  Future<void> updateShift(String id, Map<String, dynamic> data) async {
    try {
      await client
          .from('shifts')
          .update(data)
          .eq('id', id);
      
    } catch (e) {
      debugPrint('Erro ao atualizar plantão: $e');
      rethrow;
    }
  }
  
  Future<void> deleteShift(String id) async {
    try {
      await client
          .from('shifts')
          .delete()
          .eq('id', id);
      
    } catch (e) {
      debugPrint('Erro ao excluir plantão: $e');
      rethrow;
    }
  }
  
  Future<List<Map<String, dynamic>>> getUserShifts() async {
    try {
      final userId = client.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }
      
      final response = await client
          .from('shifts')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);
      
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Erro ao obter plantões: $e');
      rethrow;
    }
  }
  
  // Consultas
  Future<void> createAppointment(Map<String, dynamic> data) async {
    try {
      final userId = client.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }
      
      data['user_id'] = userId;
      data['created_at'] = DateTime.now().toIso8601String();
      
      await client
          .from('appointments')
          .insert(data);
      
    } catch (e) {
      debugPrint('Erro ao criar consulta: $e');
      rethrow;
    }
  }
  
  Future<void> updateAppointment(String id, Map<String, dynamic> data) async {
    try {
      await client
          .from('appointments')
          .update(data)
          .eq('id', id);
      
    } catch (e) {
      debugPrint('Erro ao atualizar consulta: $e');
      rethrow;
    }
  }
  
  Future<void> deleteAppointment(String id) async {
    try {
      await client
          .from('appointments')
          .delete()
          .eq('id', id);
      
    } catch (e) {
      debugPrint('Erro ao excluir consulta: $e');
      rethrow;
    }
  }
  
  Future<List<Map<String, dynamic>>> getUserAppointments() async {
    try {
      final userId = client.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }
      
      final response = await client
          .from('appointments')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);
      
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Erro ao obter consultas: $e');
      rethrow;
    }
  }

  // Método para inicializar o banco de dados
  Future<void> initializeDatabase() async {
    try {
      debugPrint('Verificando tabelas existentes...');
      
      // Verificar tabelas existentes
      final profilesExist = await _checkTableExists('profiles');
      final plansExist = await _checkTableExists('plans');
      final subscriptionsExist = await _checkTableExists('subscriptions');
      final transactionsExist = await _checkTableExists('transactions');
      
      debugPrint('Tabelas existentes: profiles=${profilesExist}, plans=${plansExist}, subscriptions=${subscriptionsExist}, transactions=${transactionsExist}');
      
      // Inserir planos padrão se a tabela de planos existir mas estiver vazia
      if (plansExist) {
        final plans = await getPlans();
        if (plans.isEmpty) {
          await _insertDefaultPlans();
        }
      }
      
      debugPrint('Inicialização do banco de dados concluída com sucesso!');
    } catch (e) {
      debugPrint('Erro ao verificar banco de dados: $e');
      // Não lançar exceção para não interromper o fluxo do aplicativo
    }
  }
  
  // Verificar se uma tabela existe
  Future<bool> _checkTableExists(String tableName) async {
    try {
      // Tentar fazer uma consulta simples na tabela
      await client.from(tableName).select('id').limit(1);
      return true;
    } catch (e) {
      if (e.toString().contains('relation') && e.toString().contains('does not exist')) {
        return false;
      }
      // Para outros erros, considerar que a tabela existe
      return true;
    }
  }
  
  // Inserir planos padrão
  Future<void> _insertDefaultPlans() async {
    try {
      debugPrint('Inserindo planos padrão...');
      
      // Plano Básico Mensal
      await client.from('plans').insert({
        'name': 'Básico',
        'type': 'monthly',
        'price': 19.90,
        'description': 'Bot no WhatsApp',
        'features': ['Bot no WhatsApp', 'Suporte por email'],
      });
      
      // Plano Básico Anual
      await client.from('plans').insert({
        'name': 'Básico',
        'type': 'annual',
        'price': 199.00,
        'description': 'Bot no WhatsApp',
        'features': ['Bot no WhatsApp', 'Suporte por email'],
      });
      
      // Plano Premium Mensal
      await client.from('plans').insert({
        'name': 'Premium',
        'type': 'monthly',
        'price': 29.90,
        'description': 'Bot + Dashboard',
        'features': ['Bot no WhatsApp', 'Dashboard completo', 'Suporte prioritário'],
      });
      
      // Plano Premium Anual
      await client.from('plans').insert({
        'name': 'Premium',
        'type': 'annual',
        'price': 299.00,
        'description': 'Bot + Dashboard',
        'features': ['Bot no WhatsApp', 'Dashboard completo', 'Suporte prioritário'],
      });
      
      debugPrint('Planos padrão inseridos com sucesso!');
    } catch (e) {
      debugPrint('Erro ao inserir planos padrão: $e');
      // Não lançar exceção para não interromper o fluxo
    }
  }
} 