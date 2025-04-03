import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction.dart';
import 'supabase_service.dart';

class TransactionService {
  // Singleton pattern
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;
  TransactionService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final SupabaseService _supabaseService = SupabaseService();

  // Obter todas as transações do usuário atual
  Future<List<Transaction>> getTransactions() async {
    try {
      final userId = _supabaseService.getCurrentUserId();
      
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }
      
      final response = await _client
          .from('transactions')
          .select('*, categories:category_id(*)')
          .eq('user_id', userId)
          .order('date', ascending: false);
      
      final data = response as List;
      
      return data.map((item) {
        // Ajustar o objeto para incluir o nome da categoria do relacionamento
        final categoryName = item['categories'] != null ? item['categories']['name'] : 'Outros';
        
        return Transaction(
          id: item['id'],
          date: DateTime.parse(item['date']),
          amount: double.parse(item['amount'].toString()),
          category: categoryName,
          description: item['description'],
          type: item['type'],
          userId: item['user_id'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Erro ao obter transações: $e');
      return [];
    }
  }

  // Obter transações filtradas por tipo (income, expense)
  Future<List<Transaction>> getTransactionsByType(String type) async {
    try {
      final userId = _supabaseService.getCurrentUserId();
      
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }
      
      final response = await _client
          .from('transactions')
          .select('*, categories:category_id(*)')
          .eq('user_id', userId)
          .eq('type', type)
          .order('date', ascending: false);
      
      final data = response as List;
      
      return data.map((item) {
        // Ajustar o objeto para incluir o nome da categoria do relacionamento
        final categoryName = item['categories'] != null ? item['categories']['name'] : 'Outros';
        
        return Transaction(
          id: item['id'],
          date: DateTime.parse(item['date']),
          amount: double.parse(item['amount'].toString()),
          category: categoryName,
          description: item['description'],
          type: item['type'],
          userId: item['user_id'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Erro ao obter transações por tipo: $e');
      return [];
    }
  }

  // Obter transações filtradas por período
  Future<List<Transaction>> getTransactionsByPeriod(DateTime startDate, DateTime endDate) async {
    try {
      final userId = _supabaseService.getCurrentUserId();
      
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }
      
      final response = await _client
          .from('transactions')
          .select('*, categories:category_id(*)')
          .eq('user_id', userId)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0])
          .order('date', ascending: false);
      
      final data = response as List;
      
      return data.map((item) {
        // Ajustar o objeto para incluir o nome da categoria do relacionamento
        final categoryName = item['categories'] != null ? item['categories']['name'] : 'Outros';
        
        return Transaction(
          id: item['id'],
          date: DateTime.parse(item['date']),
          amount: double.parse(item['amount'].toString()),
          category: categoryName,
          description: item['description'],
          type: item['type'],
          userId: item['user_id'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Erro ao obter transações por período: $e');
      return [];
    }
  }

  // Obter categorias únicas das transações do usuário
  Future<List<String>> getUniqueCategories(String type) async {
    try {
      final userId = _supabaseService.getCurrentUserId();
      
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }
      
      final response = await _client
          .from('categories')
          .select('name')
          .eq('user_id', userId)
          .eq('type', type)
          .order('name');
      
      final data = response as List;
      
      return data.map((item) => item['name'] as String).toList();
    } catch (e) {
      debugPrint('Erro ao obter categorias únicas: $e');
      return [];
    }
  }

  // Criar uma nova transação
  Future<bool> createTransaction(Transaction transaction) async {
    try {
      final userId = _supabaseService.getCurrentUserId();
      
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }
      
      // Obter ou criar categoria
      String categoryId = await _getCategoryId(transaction.category, transaction.type);
      
      // Formatar data para o formato aceito pelo Supabase (YYYY-MM-DD)
      final formattedDate = transaction.date.toIso8601String().split('T')[0];
      
      await _client
          .from('transactions')
          .insert({
            'user_id': userId,
            'category_id': categoryId,
            'description': transaction.description,
            'amount': transaction.amount,
            'type': transaction.type,
            'date': formattedDate,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
      
      return true;
    } catch (e) {
      debugPrint('Erro ao criar transação: $e');
      return false;
    }
  }

  // Atualizar uma transação existente
  Future<bool> updateTransaction(Transaction transaction) async {
    try {
      // Obter ou criar categoria
      String categoryId = await _getCategoryId(transaction.category, transaction.type);
      
      // Formatar data para o formato aceito pelo Supabase (YYYY-MM-DD)
      final formattedDate = transaction.date.toIso8601String().split('T')[0];
      
      await _client
          .from('transactions')
          .update({
            'category_id': categoryId,
            'description': transaction.description,
            'amount': transaction.amount,
            'type': transaction.type,
            'date': formattedDate,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', transaction.id);
      
      return true;
    } catch (e) {
      debugPrint('Erro ao atualizar transação: $e');
      return false;
    }
  }

  // Excluir uma transação
  Future<bool> deleteTransaction(String id) async {
    try {
      await _client
          .from('transactions')
          .delete()
          .eq('id', id);
      
      return true;
    } catch (e) {
      debugPrint('Erro ao excluir transação: $e');
      return false;
    }
  }

  // Calcular o total de receitas
  Future<double> getTotalIncome() async {
    try {
      final transactions = await getTransactionsByType('income');
      double total = 0;
      for (var transaction in transactions) {
        total += transaction.amount;
      }
      return total;
    } catch (e) {
      debugPrint('Erro ao calcular total de receitas: $e');
      return 0;
    }
  }

  // Calcular o total de despesas
  Future<double> getTotalExpense() async {
    try {
      final transactions = await getTransactionsByType('expense');
      double total = 0;
      for (var transaction in transactions) {
        total += transaction.amount;
      }
      return total;
    } catch (e) {
      debugPrint('Erro ao calcular total de despesas: $e');
      return 0;
    }
  }

  // Calcular o saldo
  Future<double> getBalance() async {
    try {
      final income = await getTotalIncome();
      final expense = await getTotalExpense();
      return income - expense;
    } catch (e) {
      debugPrint('Erro ao calcular saldo: $e');
      return 0;
    }
  }

  // Obter dados agrupados por mês
  Future<Map<String, dynamic>> getMonthlyData() async {
    try {
      final transactions = await getTransactions();
      final Map<String, Map<String, double>> monthlyData = {};
      
      for (var transaction in transactions) {
        final month = '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';
        
        if (!monthlyData.containsKey(month)) {
          monthlyData[month] = {
            'income': 0,
            'expense': 0,
            'balance': 0,
          };
        }
        
        if (transaction.type == 'income') {
          monthlyData[month]!['income'] = (monthlyData[month]!['income'] ?? 0) + transaction.amount;
        } else {
          monthlyData[month]!['expense'] = (monthlyData[month]!['expense'] ?? 0) + transaction.amount;
        }
        
        monthlyData[month]!['balance'] = (monthlyData[month]!['income'] ?? 0) - (monthlyData[month]!['expense'] ?? 0);
      }
      
      return monthlyData;
    } catch (e) {
      debugPrint('Erro ao obter dados mensais: $e');
      return {};
    }
  }

  // Obter dados agrupados por categoria
  Future<Map<String, double>> getCategoryData(String type) async {
    try {
      final transactions = await getTransactionsByType(type);
      final Map<String, double> categoryData = {};
      
      for (var transaction in transactions) {
        if (!categoryData.containsKey(transaction.category)) {
          categoryData[transaction.category] = 0;
        }
        
        categoryData[transaction.category] = (categoryData[transaction.category] ?? 0) + transaction.amount;
      }
      
      return categoryData;
    } catch (e) {
      debugPrint('Erro ao obter dados por categoria: $e');
      return {};
    }
  }

  // Método auxiliar para obter ou criar ID da categoria
  Future<String> _getCategoryId(String categoryName, String type) async {
    try {
      final userId = _supabaseService.getCurrentUserId();
      
      // Verificar se a categoria já existe
      final existingCategories = await _client
          .from('categories')
          .select('id')
          .eq('name', categoryName)
          .eq('type', type)
          .or('user_id.eq.$userId,is_default.eq.true');
      
      if (existingCategories != null && (existingCategories as List).isNotEmpty) {
        return existingCategories[0]['id'];
      }
      
      // Criar nova categoria se não existir
      final newCategory = await _client
          .from('categories')
          .insert({
            'user_id': userId,
            'name': categoryName,
            'type': type,
            'color': type == 'income' ? '#4CAF50' : '#F44336',
            'icon': 'attach_money',
            'is_default': false,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('id');
      
      return newCategory[0]['id'];
    } catch (e) {
      debugPrint('Erro ao obter/criar categoria: $e');
      throw Exception('Erro ao processar categoria: $e');
    }
  }
} 