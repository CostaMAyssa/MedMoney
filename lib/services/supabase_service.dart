import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/subscription.dart';

class SupabaseService {
  // Singleton pattern
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

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
  
  // Método de inicialização como método de instância
  Future<void> initialize() async {
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseKey = dotenv.env['SUPABASE_KEY'] ?? '';
    
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
  }
  
  // Autenticação
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String city,
    required String state,
    required String? cpf,
    required String selectedPlan,
    required bool isAnnualPlan,
  }) async {
    try {
      debugPrint('Iniciando processo de criação de conta para: $email');
      debugPrint('Telefone original: $phone');
      debugPrint('Tipo do telefone original: ${phone.runtimeType}');
      
      // Garantir que o telefone seja uma string válida e não nula
      final String phoneAsString = phone.toString().trim();
      debugPrint('Telefone após toString: $phoneAsString');
      
      // Criando um mapa de metadados para o usuário
      final Map<String, dynamic> userData = {
        'name': name,
        'city': city,
        'state': state,
        'cpf': cpf,
        'selectedPlan': selectedPlan,
        'isAnnualPlan': isAnnualPlan,
      };
      
      // Adicionar o telefone apenas se não for vazio
      if (phoneAsString.isNotEmpty) {
        userData['phone'] = phoneAsString;
        debugPrint('Telefone adicionado aos metadados: $phoneAsString');
      } else {
        debugPrint('Telefone vazio, não será adicionado aos metadados');
      }
      
      // Registrar o usuário no Supabase Auth
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: userData,
      );
      
      debugPrint('Resposta do Supabase: ${response.user != null ? 'Usuário criado' : 'Falha na criação do usuário'}');
      
      // Se o usuário foi criado com sucesso, tentar criar o perfil
      // Mas não falhar se o perfil não puder ser criado
      if (response.user != null) {
        debugPrint('Usuário criado com sucesso: ${response.user!.id}');
        
        try {
          // Preparar os dados do perfil
          final Map<String, dynamic> profileData = {
            'id': response.user!.id,
            'email': email,
            'name': name,
            'city': city,
            'state': state,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };
          
          // Adicionar CPF apenas se não for nulo ou vazio
          if (cpf != null && cpf.isNotEmpty) {
            profileData['cpf'] = cpf;
          }
          
          // Adicionar o telefone apenas se não for vazio
          if (phoneAsString.isNotEmpty) {
            profileData['phone'] = phoneAsString;
            debugPrint('Telefone adicionado ao perfil: $phoneAsString');
          } else {
            debugPrint('Telefone vazio, não será adicionado ao perfil');
          }
          
          // Tentar criar o perfil, mas não falhar se não conseguir
          await client
              .from('profiles')
              .insert(profileData);
          
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
      
      debugPrint('Buscando perfil para o usuário: $userId');
      
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      final profileData = response as Map<String, dynamic>;
      
      // Log detalhado do perfil
      debugPrint('Perfil recuperado do Supabase: $profileData');
      
      // Verificar telefone
      if (profileData.containsKey('phone')) {
        debugPrint('Telefone no perfil: ${profileData['phone']}');
        debugPrint('Tipo do telefone no perfil: ${profileData['phone']?.runtimeType}');
        
        // Se o telefone for nulo mas temos o telefone nos metadados do usuário
        if ((profileData['phone'] == null || profileData['phone'].toString().isEmpty) && 
             client.auth.currentUser?.userMetadata?['phone'] != null) {
          
          final metadataPhone = client.auth.currentUser!.userMetadata!['phone'].toString();
          debugPrint('Telefone encontrado nos metadados: $metadataPhone');
          
          // Atualizar o perfil com o telefone dos metadados
          try {
            await updateUserProfile({'phone': metadataPhone});
            profileData['phone'] = metadataPhone;
            debugPrint('Perfil atualizado com telefone dos metadados');
          } catch (e) {
            debugPrint('Erro ao atualizar perfil com telefone dos metadados: $e');
          }
        }
      } else {
        debugPrint('Campo telefone não existe no perfil');
        
        // Verificar se temos telefone nos metadados
        if (client.auth.currentUser?.userMetadata?['phone'] != null) {
          final metadataPhone = client.auth.currentUser!.userMetadata!['phone'].toString();
          debugPrint('Telefone encontrado apenas nos metadados: $metadataPhone');
          
          // Tentar atualizar o perfil com o telefone
          try {
            await updateUserProfile({'phone': metadataPhone});
            profileData['phone'] = metadataPhone;
            debugPrint('Perfil atualizado com telefone dos metadados');
          } catch (e) {
            debugPrint('Erro ao atualizar perfil com telefone dos metadados: $e');
          }
        }
      }
      
      return profileData;
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
  Future<Map<String, dynamic>?> getUserSubscriptionMap() async {
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
  
  // Buscar assinatura pelo ID externo (ID do pagamento ou assinatura no Asaas)
  Future<Map<String, dynamic>?> getSubscriptionByExternalId(String externalId) async {
    try {
      final response = await client
          .from('subscriptions')
          .select()
          .eq('external_id', externalId)
          .limit(1);
      
      final data = response as List;
      
      if (data.isEmpty) {
        return null;
      }
      
      return data.first as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Erro ao buscar assinatura pelo ID externo: $e');
      return null;
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

  // Inicializar o banco de dados
  Future<void> initializeDatabase() async {
    try {
      debugPrint('Verificando tabelas existentes...');
      
      // Verificar se as tabelas existentes
      final profilesExist = await _checkTableExists('profiles');
      final plansExist = await _checkTableExists('plans');
      final subscriptionsExist = await _checkTableExists('subscriptions');
      final transactionsExist = await _checkTableExists('transactions');
      final asaasLogsExist = await _checkTableExists('asaas_logs');
      
      debugPrint('Tabelas existentes: profiles=$profilesExist, plans=$plansExist, subscriptions=$subscriptionsExist, transactions=$transactionsExist, asaas_logs=$asaasLogsExist');
      
      // Criar tabela para logs do Asaas se não existir
      if (!asaasLogsExist) {
        debugPrint('Tabela asaas_logs não existe, criando...');
        // Como não temos acesso direto ao PostgreSQL via Supabase Client,
        // vamos ignorar a criação da tabela aqui e assumir que ela será
        // criada por migrations ou manualmente no Supabase Studio
        debugPrint('Para criar a tabela asaas_logs, execute o seguinte SQL no Supabase Studio:');
        debugPrint('''
        CREATE TABLE IF NOT EXISTS asaas_logs (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          payment_id TEXT,
          external_reference TEXT,
          status TEXT,
          subscription_id UUID,
          webhook_data JSONB,
          processed BOOLEAN DEFAULT FALSE,
          error TEXT,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        ''');
      }
      
      // Inserir planos padrão se a tabela existir mas estiver vazia
      if (plansExist) {
        try {
          final plans = await client.from('plans').select('id');
          final plansData = plans as List;
          
          if (plansData.isEmpty) {
            debugPrint('Inserindo planos padrão...');
            await _insertDefaultPlans();
          }
        } catch (e) {
          debugPrint('Erro ao inserir planos padrão: $e');
        }
      }
      
      debugPrint('Inicialização do banco de dados concluída com sucesso!');
    } catch (e) {
      debugPrint('Erro ao inicializar banco de dados: $e');
    }
  }
  
  // Verificar se uma tabela existe
  Future<bool> _checkTableExists(String tableName) async {
    try {
      await client.from(tableName).select('id').limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Inserir planos padrão
  Future<void> _insertDefaultPlans() async {
    try {
      await client.from('plans').insert([
        {
          'name': 'Basic',
          'price': 29.90,
          'price_annual': 299.90,
          'setup_fee': 0,
          'features': [
            'Acesso ao dashboard básico',
            'Controle de despesas',
            'Alertas financeiros',
          ],
          'is_active': true,
          'type': 'basic',
        },
        {
          'name': 'Premium',
          'price': 59.90,
          'price_annual': 599.90,
          'setup_fee': 19.90,
          'features': [
            'Acesso ao dashboard completo',
            'Controle de despesas e receitas',
            'Alertas financeiros personalizados',
            'Relatórios detalhados',
            'Consultas financeiras mensais',
          ],
          'is_active': true,
          'type': 'premium',
        },
        {
          'name': 'Enterprise',
          'price': 99.90,
          'price_annual': 999.90,
          'setup_fee': 0,
          'features': [
            'Acesso a todos os recursos',
            'Suporte prioritário',
            'Relatórios avançados',
            'Integração com outros sistemas',
            'Consultoria financeira completa',
            'Acesso multi-usuário',
          ],
          'is_active': true,
          'type': 'enterprise',
        },
      ]);
      
      debugPrint('Planos padrão inseridos com sucesso');
    } catch (e) {
      debugPrint('Erro ao inserir planos padrão: $e');
      throw e;
    }
  }

  // Obter assinaturas ativas do usuário
  Future<List<Map<String, dynamic>>> getActiveSubscriptions() async {
    try {
      // Verificar se o usuário está autenticado
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return [];
      }
      
      // Buscar assinaturas ativas do usuário
      final response = await client
          .from('subscriptions')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'active')
          .order('created_at', ascending: false);
      
      // Converter o resultado para o formato esperado
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Erro ao buscar assinaturas ativas: $e');
      return [];
    }
  }

  // Obter o ID do usuário atual
  String? getCurrentUserId() {
    return client.auth.currentUser?.id;
  }

  // Obter o nome de exibição do usuário
  Future<String?> getUserDisplayName() async {
    final userId = getCurrentUserId();
    if (userId == null) return null;

    try {
      final response = await client
          .from('profiles')
          .select('full_name, username')
          .eq('id', userId)
          .single();

      if (response != null) {
        final fullName = response['full_name'] as String?;
        final username = response['username'] as String?;
        return fullName?.isNotEmpty == true ? fullName : username;
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao obter nome do usuário: $e');
      return null;
    }
  }

  // Obter a assinatura do usuário por ID
  Future<Subscription?> getUserSubscription(String userId) async {
    try {
      final response = await client
          .from('subscriptions')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return Subscription.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao obter assinatura: $e');
      return null;
    }
  }

  // Obter assinatura por payment_id
  Future<Subscription?> getSubscriptionByPaymentId(String paymentId) async {
    try {
      final response = await client
          .from('subscriptions')
          .select('*')
          .eq('payment_id', paymentId)
          .maybeSingle();

      if (response != null) {
        return Subscription.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao obter assinatura por payment_id: $e');
      return null;
    }
  }

  // Obter assinatura por external_reference
  Future<Subscription?> getSubscriptionByExternalRef(String externalRef) async {
    try {
      final response = await client
          .from('subscriptions')
          .select('*')
          .eq('external_reference', externalRef)
          .maybeSingle();

      if (response != null) {
        return Subscription.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao obter assinatura por external_reference: $e');
      return null;
    }
  }

  // Atualizar o status da assinatura
  Future<bool> updateSubscriptionStatus(String subscriptionId, String status) async {
    try {
      await client
          .from('subscriptions')
          .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', subscriptionId);
      return true;
    } catch (e) {
      debugPrint('Erro ao atualizar status da assinatura: $e');
      return false;
    }
  }

  // Processar webhook do Asaas
  Future<bool> processAsaasWebhook(Map<String, dynamic> webhookData) async {
    try {
      // Extrair informações relevantes do webhook
      final externalReference = webhookData['externalReference'] as String?;
      final paymentId = webhookData['payment']['id'] as String?;
      final status = webhookData['payment']['status'] as String?;
      
      debugPrint('Processando webhook Asaas: paymentId=$paymentId, status=$status, externalRef=$externalReference');

      // Registrar log do webhook
      await _logAsaasWebhook(
        paymentId: paymentId,
        externalReference: externalReference,
        status: status,
        webhookData: webhookData,
      );

      // Se não tiver referência ou id de pagamento, não conseguimos processar
      if (externalReference == null && paymentId == null) {
        debugPrint('Webhook sem identificação (externalReference ou paymentId)');
        return false;
      }

      // Tentar encontrar a assinatura pelo externalReference ou pelo paymentId
      Subscription? subscription;
      
      if (externalReference != null) {
        subscription = await getSubscriptionByExternalRef(externalReference);
      }
      
      if (subscription == null && paymentId != null) {
        subscription = await getSubscriptionByPaymentId(paymentId);
      }

      // Se não encontrou a assinatura, não conseguimos processar
      if (subscription == null) {
        debugPrint('Assinatura não encontrada para o webhook');
        return false;
      }

      // Atualizar o status da assinatura baseado no status do pagamento Asaas
      if (status != null) {
        String newStatus = 'pending'; // Status padrão
        
        // Mapear status do Asaas para status da assinatura
        switch (status.toLowerCase()) {
          case 'confirmed':
          case 'received':
            newStatus = 'active';
            break;
          case 'overdue':
            newStatus = 'overdue';
            break;
          case 'pending':
            newStatus = 'pending';
            break;
          case 'refunded':
          case 'cancelled':
            newStatus = 'cancelled';
            break;
          default:
            newStatus = status.toLowerCase();
        }
        
        // Atualizar o status no banco
        final updated = await updateSubscriptionStatus(subscription.id, newStatus);
        if (updated) {
          debugPrint('Status da assinatura atualizado para: $newStatus');
          await _updateAsaasLogProcessed(paymentId, true);
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Erro ao processar webhook Asaas: $e');
      return false;
    }
  }

  // Registrar log de webhook do Asaas
  Future<void> _logAsaasWebhook({
    String? paymentId,
    String? externalReference,
    String? status,
    required Map<String, dynamic> webhookData,
    String? subscriptionId,
    bool processed = false,
    String? error,
  }) async {
    try {
      await client.from('asaas_logs').insert({
        'payment_id': paymentId,
        'external_reference': externalReference,
        'status': status,
        'subscription_id': subscriptionId,
        'webhook_data': webhookData,
        'processed': processed,
        'error': error,
      });
      debugPrint('Log de webhook Asaas registrado com sucesso');
    } catch (e) {
      debugPrint('Erro ao registrar log de webhook Asaas: $e');
    }
  }

  // Atualizar status de processamento do log
  Future<void> _updateAsaasLogProcessed(String? paymentId, bool processed, {String? error}) async {
    if (paymentId == null) return;
    
    try {
      await client
          .from('asaas_logs')
          .update({
            'processed': processed,
            'error': error,
          })
          .eq('payment_id', paymentId);
    } catch (e) {
      debugPrint('Erro ao atualizar status de processamento do log: $e');
    }
  }

  // Método para salvar o plano escolhido pelo usuário
  Future<void> saveSelectedPlan({
    required String userId,
    required String planType, // Aqui é o nome do plano (Basic, Premium, etc.)
    required String billingFrequency, // Aqui é 'annual' ou 'monthly'
    required double price,
    required String externalReference,
    required String? paymentId,
  }) async {
    try {
      debugPrint('Salvando plano escolhido: userId=$userId, planName=$planType, billingFrequency=$billingFrequency, price=$price');
      debugPrint('Tipo do userId: ${userId.runtimeType}');
      
      // Buscar plano existente
      final existingSubscription = await getUserSubscription(userId);
      
      // Se já existe uma assinatura, atualizamos ela
      if (existingSubscription != null) {
        debugPrint('Assinatura existente encontrada com ID ${existingSubscription.id}, atualizando...');
        
        await client
          .from('subscriptions')
          .update({
            'plan_name': planType, // planType contém o nome do plano (Basic, Premium, etc.)
            'plan_type': billingFrequency, // billingFrequency contém 'annual' ou 'monthly'
            'price': price,
            'payment_id': paymentId,
            'external_reference': externalReference,
            'status': 'pending', // Status inicial é pendente até confirmação do webhook
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existingSubscription.id);
      } else {
        // Caso contrário, criamos uma nova
        debugPrint('Nenhuma assinatura existente, criando nova...');
        
        await client
          .from('subscriptions')
          .insert({
            'user_id': userId,
            'plan_name': planType, // planType contém o nome do plano (Basic, Premium, etc.)
            'plan_type': billingFrequency, // billingFrequency contém 'annual' ou 'monthly'
            'price': price,
            'payment_id': paymentId,
            'external_reference': externalReference,
            'status': 'pending', // Status inicial é pendente até confirmação do webhook
            'start_date': DateTime.now().toIso8601String(),
            'next_billing_date': DateTime.now().add(Duration(days: 30)).toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
      }
      
      debugPrint('Plano salvo com sucesso');
    } catch (e) {
      debugPrint('Erro ao salvar plano escolhido: $e');
      rethrow;
    }
  }
} 