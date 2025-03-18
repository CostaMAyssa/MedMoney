import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

class TransactionProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get transactions => _transactions;
  List<Map<String, dynamic>> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtros
  String? _typeFilter;
  String? _categoryFilter;
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;

  String? get typeFilter => _typeFilter;
  String? get categoryFilter => _categoryFilter;
  DateTime? get startDateFilter => _startDateFilter;
  DateTime? get endDateFilter => _endDateFilter;

  // Estatísticas
  double get totalIncome => _transactions
      .where((t) => t['type'] == 'income')
      .fold(0.0, (sum, item) => sum + (item['amount'] ?? 0.0));

  double get totalExpense => _transactions
      .where((t) => t['type'] == 'expense')
      .fold(0.0, (sum, item) => sum + (item['amount'] ?? 0.0));

  double get balance => totalIncome - totalExpense;

  TransactionProvider() {
    loadTransactions();
    loadCategories();
  }

  Future<void> loadTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = await _supabaseService.getUserTransactions();
    } catch (e) {
      _error = 'Erro ao carregar transações: ${e.toString()}';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _supabaseService.getCategories();
    } catch (e) {
      _error = 'Erro ao carregar categorias: ${e.toString()}';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addTransaction(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabaseService.createTransaction(data);
      await loadTransactions();
      return true;
    } catch (e) {
      _error = 'Erro ao adicionar transação: ${e.toString()}';
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTransaction(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabaseService.updateTransaction(id, data);
      await loadTransactions();
      return true;
    } catch (e) {
      _error = 'Erro ao atualizar transação: ${e.toString()}';
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteTransaction(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabaseService.deleteTransaction(id);
      await loadTransactions();
      return true;
    } catch (e) {
      _error = 'Erro ao excluir transação: ${e.toString()}';
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCategory(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabaseService.createCategory(data);
      await loadCategories();
      return true;
    } catch (e) {
      _error = 'Erro ao adicionar categoria: ${e.toString()}';
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Aplicar filtros
  void applyFilters({
    String? type,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    _typeFilter = type;
    _categoryFilter = category;
    _startDateFilter = startDate;
    _endDateFilter = endDate;
    loadTransactions();
  }

  // Limpar filtros
  void clearFilters() {
    _typeFilter = null;
    _categoryFilter = null;
    _startDateFilter = null;
    _endDateFilter = null;
    loadTransactions();
  }

  // Limpar erro
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 