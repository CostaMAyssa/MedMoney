import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/transaction_service.dart';
import '../../models/transaction.dart';
import '../../utils/theme.dart';
import 'widgets/summary_card.dart';
import 'widgets/bar_chart_widget.dart';
import 'widgets/pie_chart_widget.dart';
import 'widgets/transactions_table.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isCheckingSubscription = true;
  Map<String, dynamic>? _subscription;
  
  // Dados do dashboard
  bool _isLoadingTransactions = true;
  List<Transaction> _transactions = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _balance = 0;
  Map<String, dynamic> _monthlyData = {};
  Map<String, double> _incomeCategoryData = {};
  Map<String, double> _expenseCategoryData = {};

  // Serviços
  final SupabaseService _supabaseService = SupabaseService();
  final TransactionService _transactionService = TransactionService();

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }
  
  // Verificar se o usuário tem uma assinatura ativa
  Future<void> _checkSubscription() async {
    try {
      setState(() {
        _isCheckingSubscription = true;
      });
      
      // Não precisa armazenar userId se não for usado
      _supabaseService.getCurrentUserId();
      
      // Usar o método que retorna Map<String, dynamic> para manter compatibilidade
      final subscriptionMap = await _supabaseService.getUserSubscriptionMap();
      
      setState(() {
        _subscription = subscriptionMap;
        _isCheckingSubscription = false;
      });
      
      // Verificar se o usuário tem uma assinatura ativa e paga
      bool hasValidSubscription = false;
      
      if (subscriptionMap != null) {
        // Verificar se a assinatura está ativa
        bool isActive = subscriptionMap['status'] == 'active';
        
        // Verificar se o pagamento foi confirmado
        bool isPaid = subscriptionMap['payment_status'] == 'confirmed' || 
                      subscriptionMap['payment_status'] == 'paid';
        
        // Verificar se é um plano premium (que dá acesso ao dashboard)
        bool isPremium = subscriptionMap['plan_name']?.toLowerCase() == 'premium';
        
        // Acesso permitido apenas se todas as condições forem atendidas
        hasValidSubscription = isActive && isPaid && isPremium;
        
        debugPrint('Status da assinatura: ${subscriptionMap['status']}');
        debugPrint('Status do pagamento: ${subscriptionMap['payment_status']}');
        debugPrint('Plano: ${subscriptionMap['plan_name']}');
        debugPrint('Acesso ao dashboard: ${hasValidSubscription ? 'Permitido' : 'Negado'}');
      }
      
      // Se não tiver assinatura válida, redirecionar para a página de planos
      if (!hasValidSubscription) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Você precisa de uma assinatura Premium ativa para acessar o dashboard.'),
              backgroundColor: AppTheme.warningColor,
              duration: Duration(seconds: 5),
            ),
          );
          
          // Redirecionar para a página inicial após 2 segundos
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/');
            }
          });
        }
      } else {
        // Se tiver assinatura válida, carregar os dados do dashboard
        _loadDashboardData();
      }
    } catch (e) {
      debugPrint('Erro ao verificar assinatura: $e');
      setState(() {
        _isCheckingSubscription = false;
      });
    }
  }

  // Carregar dados do dashboard
  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoadingTransactions = true;
      });
      
      // Carregar transações
      final transactions = await _transactionService.getTransactions();
      
      // Calcular totais
      final totalIncome = await _transactionService.getTotalIncome();
      final totalExpense = await _transactionService.getTotalExpense();
      final balance = totalIncome - totalExpense;
      
      // Carregar dados mensais
      final monthlyData = await _transactionService.getMonthlyData();
      
      // Carregar dados por categoria
      final incomeCategoryData = await _transactionService.getCategoryData('income');
      final expenseCategoryData = await _transactionService.getCategoryData('expense');
      
      setState(() {
        _transactions = transactions;
        _totalIncome = totalIncome;
        _totalExpense = totalExpense;
        _balance = balance;
        _monthlyData = monthlyData;
        _incomeCategoryData = incomeCategoryData;
        _expenseCategoryData = expenseCategoryData;
        _isLoadingTransactions = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar dados do dashboard: $e');
      setState(() {
        _isLoadingTransactions = false;
      });
    }
  }

  // Logout
  Future<void> _logout() async {
    try {
      await _supabaseService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      debugPrint('Erro ao fazer logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao fazer logout: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verificar se o usuário tem uma assinatura premium ativa
    bool hasValidSubscription = false;
    
    if (_subscription != null) {
      bool isActive = _subscription!['status'] == 'active';
      bool isPaid = _subscription!['payment_status'] == 'confirmed' || 
                    _subscription!['payment_status'] == 'paid';
      bool isPremium = _subscription!['plan_name']?.toLowerCase() == 'premium';
      
      hasValidSubscription = isActive && isPaid && isPremium;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 50,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            const Text('Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          // Exibir status da assinatura
          if (_subscription != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Chip(
                backgroundColor: hasValidSubscription
                    ? AppTheme.successColor.withOpacity(0.2) 
                    : AppTheme.warningColor.withOpacity(0.2),
                label: Text(
                  hasValidSubscription
                      ? 'Premium Ativo' 
                      : _subscription!['plan_name'] == 'Premium' 
                          ? 'Premium Pendente'
                          : 'Básico',
                  style: TextStyle(
                    color: hasValidSubscription
                        ? AppTheme.successColor 
                        : AppTheme.warningColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                avatar: Icon(
                  hasValidSubscription
                      ? Icons.check_circle 
                      : Icons.warning,
                  color: hasValidSubscription
                      ? AppTheme.successColor 
                      : AppTheme.warningColor,
                  size: 16,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout, size: 26),
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isCheckingSubscription
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Verificando sua assinatura...',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : !hasValidSubscription
              ? _buildNoSubscriptionView()
              : _buildDashboardContent(),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cartões de resumo
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  title: 'Receitas',
                  value: _totalIncome,
                  icon: Icons.arrow_upward,
                  color: AppTheme.incomeColor,
                  isLoading: _isLoadingTransactions,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SummaryCard(
                  title: 'Despesas',
                  value: _totalExpense,
                  icon: Icons.arrow_downward,
                  color: AppTheme.expenseColor,
                  isLoading: _isLoadingTransactions,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SummaryCard(
                  title: 'Saldo',
                  value: _balance.abs(),
                  icon: Icons.account_balance_wallet,
                  color: _balance >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor,
                  isLoading: _isLoadingTransactions,
                  isNegative: _balance < 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Gráfico de barras
          _buildSectionTitle('Fluxo Mensal'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: BarChartWidget(
                monthlyData: _monthlyData,
                isLoading: _isLoadingTransactions,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Gráficos de pizza
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Receitas por Categoria'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: PieChartWidget(
                          categoryData: _incomeCategoryData,
                          type: 'income',
                          isLoading: _isLoadingTransactions,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Despesas por Categoria'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: PieChartWidget(
                          categoryData: _expenseCategoryData,
                          type: 'expense',
                          isLoading: _isLoadingTransactions,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Transações recentes
          _buildSectionTitle('Transações Recentes'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TransactionsTable(
                transactions: _transactions.take(10).toList(),
                isLoading: _isLoadingTransactions,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNoSubscriptionView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock,
              size: 80,
              color: AppTheme.warningColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Acesso Restrito',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Para acessar o dashboard completo, você precisa ter uma assinatura Premium ativa.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/plans');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Ver Planos Disponíveis'),
            ),
          ],
        ),
      ),
    );
  }
}
