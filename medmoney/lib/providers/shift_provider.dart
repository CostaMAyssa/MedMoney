import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

class ShiftProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _shifts = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get shifts => _shifts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtros
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;
  String? _statusFilter;

  DateTime? get startDateFilter => _startDateFilter;
  DateTime? get endDateFilter => _endDateFilter;
  String? get statusFilter => _statusFilter;

  // Estatísticas
  int get totalShifts => _shifts.length;
  
  double get totalExpectedPayment => _shifts.fold(
    0.0, 
    (sum, shift) => sum + (shift['expected_payment'] ?? 0.0)
  );
  
  int get completedShifts => _shifts
    .where((shift) => shift['status'] == 'completed')
    .length;
  
  int get scheduledShifts => _shifts
    .where((shift) => shift['status'] == 'scheduled')
    .length;
  
  int get canceledShifts => _shifts
    .where((shift) => shift['status'] == 'canceled')
    .length;

  ShiftProvider() {
    loadShifts();
  }

  Future<void> loadShifts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _shifts = await _supabaseService.getUserShifts();
    } catch (e) {
      _error = 'Erro ao carregar plantões: ${e.toString()}';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addShift(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabaseService.createShift(data);
      await loadShifts();
      return true;
    } catch (e) {
      _error = 'Erro ao adicionar plantão: ${e.toString()}';
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateShift(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabaseService.updateShift(id, data);
      await loadShifts();
      return true;
    } catch (e) {
      _error = 'Erro ao atualizar plantão: ${e.toString()}';
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteShift(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabaseService.deleteShift(id);
      await loadShifts();
      return true;
    } catch (e) {
      _error = 'Erro ao excluir plantão: ${e.toString()}';
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Marcar plantão como concluído
  Future<bool> completeShift(String id, {double? actualPayment}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = {
        'status': 'completed',
        if (actualPayment != null) 'actual_payment': actualPayment,
      };
      
      await _supabaseService.updateShift(id, data);
      
      // Se houver pagamento, criar uma transação
      if (actualPayment != null && actualPayment > 0) {
        final shift = _shifts.firstWhere((s) => s['id'] == id);
        
        await _supabaseService.createTransaction({
          'type': 'income',
          'category': 'Plantão',
          'description': 'Pagamento de plantão em ${shift['location']}',
          'amount': actualPayment,
          'date': DateTime.now().toIso8601String(),
        });
      }
      
      await loadShifts();
      return true;
    } catch (e) {
      _error = 'Erro ao concluir plantão: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cancelar plantão
  Future<bool> cancelShift(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabaseService.updateShift(id, {'status': 'canceled'});
      await loadShifts();
      return true;
    } catch (e) {
      _error = 'Erro ao cancelar plantão: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Aplicar filtros
  void applyFilters({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    _startDateFilter = startDate;
    _endDateFilter = endDate;
    _statusFilter = status;
    loadShifts();
  }

  // Limpar filtros
  void clearFilters() {
    _startDateFilter = null;
    _endDateFilter = null;
    _statusFilter = null;
    loadShifts();
  }

  // Limpar erro
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 