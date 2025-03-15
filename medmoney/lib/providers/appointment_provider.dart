import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

class AppointmentProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get appointments => _appointments;
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
  int get totalAppointments => _appointments.length;
  
  double get totalExpectedPayment => _appointments.fold(
    0.0, 
    (sum, appointment) => sum + (appointment['expected_payment'] ?? 0.0)
  );
  
  int get completedAppointments => _appointments
    .where((appointment) => appointment['status'] == 'completed')
    .length;
  
  int get scheduledAppointments => _appointments
    .where((appointment) => appointment['status'] == 'scheduled')
    .length;
  
  int get canceledAppointments => _appointments
    .where((appointment) => appointment['status'] == 'canceled')
    .length;

  AppointmentProvider() {
    loadAppointments();
  }

  // Carregar consultas
  Future<void> loadAppointments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _appointments = await _supabaseService.getUserAppointments();
    } catch (e) {
      _error = 'Erro ao carregar consultas: ${e.toString()}';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Adicionar consulta
  Future<bool> addAppointment(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabaseService.createAppointment(data);
      await loadAppointments();
      return true;
    } catch (e) {
      _error = 'Erro ao adicionar consulta: ${e.toString()}';
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Atualizar consulta
  Future<bool> updateAppointment(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabaseService.updateAppointment(id, data);
      await loadAppointments();
      return true;
    } catch (e) {
      _error = 'Erro ao atualizar consulta: ${e.toString()}';
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Marcar consulta como concluída
  Future<bool> completeAppointment(String id, {double? actualPayment}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = {
        'status': 'completed',
        if (actualPayment != null) 'actual_payment': actualPayment,
      };
      
      await _supabaseService.updateAppointment(id, data);
      
      // Se houver pagamento, criar uma transação
      if (actualPayment != null && actualPayment > 0) {
        final appointment = _appointments.firstWhere((a) => a['id'] == id);
        
        await _supabaseService.createTransaction({
          'type': 'income',
          'category': 'Consulta',
          'description': 'Pagamento de consulta para ${appointment['patient_name']}',
          'amount': actualPayment,
          'date': DateTime.now().toIso8601String(),
        });
      }
      
      await loadAppointments();
      return true;
    } catch (e) {
      _error = 'Erro ao concluir consulta: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cancelar consulta
  Future<bool> cancelAppointment(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabaseService.updateAppointment(id, {'status': 'canceled'});
      await loadAppointments();
      return true;
    } catch (e) {
      _error = 'Erro ao cancelar consulta: ${e.toString()}';
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
    loadAppointments();
  }

  // Limpar filtros
  void clearFilters() {
    _startDateFilter = null;
    _endDateFilter = null;
    _statusFilter = null;
    loadAppointments();
  }

  // Limpar erro
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 