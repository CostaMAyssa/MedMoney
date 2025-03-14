import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  User? _user;
  Map<String, dynamic>? _profile;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Verificar se há um usuário autenticado
      _user = Supabase.instance.client.auth.currentUser;
      
      if (_user != null) {
        // Carregar o perfil do usuário
        await _loadUserProfile();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      _profile = await _supabaseService.getUserProfile();
    } catch (e) {
      _error = 'Erro ao carregar perfil: ${e.toString()}';
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabaseService.signIn(
        email: email,
        password: password,
      );
      
      _user = response.user;
      
      if (_user != null) {
        await _loadUserProfile();
        return true;
      }
      
      return false;
    } catch (e) {
      _error = 'Erro ao fazer login: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp(String name, String email, String password, {String? phone}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabaseService.signUp(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      
      _user = response.user;
      
      if (_user != null) {
        await _loadUserProfile();
        return true;
      }
      
      return false;
    } catch (e) {
      _error = 'Erro ao criar conta: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signOut() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabaseService.signOut();
      _user = null;
      _profile = null;
      return true;
    } catch (e) {
      _error = 'Erro ao sair: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      _error = 'Erro ao redefinir senha: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabaseService.updateUserProfile(data);
      await _loadUserProfile();
      return true;
    } catch (e) {
      _error = 'Erro ao atualizar perfil: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 