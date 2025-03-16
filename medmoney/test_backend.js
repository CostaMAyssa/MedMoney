// Script de teste para validar o backend do MedMoney
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

// Configuração do Supabase
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_ANON_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

// Configuração do Asaas
const asaasApiKey = process.env.ASAAS_API_KEY;
const asaasSandbox = process.env.ASAAS_SANDBOX === 'true';
const asaasBaseUrl = asaasSandbox 
  ? 'https://sandbox.asaas.com/api/v3' 
  : 'https://www.asaas.com/api/v3';

// Cores para o console
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  dim: '\x1b[2m',
  underscore: '\x1b[4m',
  blink: '\x1b[5m',
  reverse: '\x1b[7m',
  hidden: '\x1b[8m',
  
  fg: {
    black: '\x1b[30m',
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    magenta: '\x1b[35m',
    cyan: '\x1b[36m',
    white: '\x1b[37m'
  },
  
  bg: {
    black: '\x1b[40m',
    red: '\x1b[41m',
    green: '\x1b[42m',
    yellow: '\x1b[43m',
    blue: '\x1b[44m',
    magenta: '\x1b[45m',
    cyan: '\x1b[46m',
    white: '\x1b[47m'
  }
};

// Funções auxiliares
function log(message, type = 'info') {
  const timestamp = new Date().toISOString().replace('T', ' ').substring(0, 19);
  
  switch (type) {
    case 'success':
      console.log(`${colors.fg.green}[${timestamp}] ✓ ${message}${colors.reset}`);
      break;
    case 'error':
      console.log(`${colors.fg.red}[${timestamp}] ✗ ${message}${colors.reset}`);
      break;
    case 'warning':
      console.log(`${colors.fg.yellow}[${timestamp}] ⚠ ${message}${colors.reset}`);
      break;
    case 'title':
      console.log(`\n${colors.fg.cyan}${colors.bright}${message}${colors.reset}\n`);
      break;
    default:
      console.log(`${colors.fg.white}[${timestamp}] ℹ ${message}${colors.reset}`);
  }
}

// Variáveis globais para armazenar dados de teste
let testUser = null;
let testSubscription = null;
let testPayment = null;
let testTransaction = null;

// 1. Teste de autenticação e acesso ao dashboard
async function testAuthentication() {
  log('TESTE DE AUTENTICAÇÃO E ACESSO AO DASHBOARD', 'title');
  
  try {
    // 1.1 Criar um usuário de teste
    const email = `test_${Date.now()}@example.com`;
    const password = 'Test@123456';
    
    log(`Criando usuário de teste: ${email}`);
    
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          name: 'Usuário de Teste',
          phone: '11999999999',
        }
      }
    });
    
    if (authError) {
      throw authError;
    }
    
    testUser = authData.user;
    log(`Usuário criado com ID: ${testUser.id}`, 'success');
    
    // 1.2 Verificar se o perfil foi criado automaticamente
    log('Verificando se o perfil foi criado automaticamente');
    
    // Aguardar um momento para o trigger criar o perfil
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    const { data: profileData, error: profileError } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', testUser.id)
      .single();
    
    if (profileError) {
      throw profileError;
    }
    
    log('Perfil criado automaticamente', 'success');
    
    // 1.3 Testar login
    log('Testando login com o usuário criado');
    
    const { data: loginData, error: loginError } = await supabase.auth.signInWithPassword({
      email,
      password
    });
    
    if (loginError) {
      throw loginError;
    }
    
    log('Login realizado com sucesso', 'success');
    
    return true;
  } catch (error) {
    log(`Erro no teste de autenticação: ${error.message}`, 'error');
    return false;
  }
}

// 2. Teste de gestão de planos e assinaturas
async function testSubscriptions() {
  log('TESTE DE GESTÃO DE PLANOS E ASSINATURAS', 'title');
  
  try {
    if (!testUser) {
      throw new Error('Usuário de teste não disponível');
    }
    
    // 2.1 Verificar planos disponíveis
    log('Verificando planos disponíveis');
    
    const { data: plansData, error: plansError } = await supabase
      .from('plans')
      .select('*')
      .eq('is_active', true);
    
    if (plansError) {
      throw plansError;
    }
    
    if (plansData.length === 0) {
      throw new Error('Nenhum plano disponível');
    }
    
    log(`${plansData.length} planos disponíveis`, 'success');
    
    // 2.2 Criar uma assinatura para o usuário de teste
    log('Criando assinatura para o usuário de teste');
    
    const selectedPlan = plansData.find(plan => plan.name === 'Premium') || plansData[0];
    
    const subscriptionData = {
      user_id: testUser.id,
      plan_id: selectedPlan.id,
      plan_name: selectedPlan.name,
      plan_type: 'monthly',
      price: selectedPlan.price,
      status: 'pending',
      payment_method: 'pix',
      start_date: new Date().toISOString(),
      next_billing_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
    };
    
    const { data: subscription, error: subscriptionError } = await supabase
      .from('subscriptions')
      .insert(subscriptionData)
      .select()
      .single();
    
    if (subscriptionError) {
      throw subscriptionError;
    }
    
    testSubscription = subscription;
    log(`Assinatura criada com ID: ${testSubscription.id}`, 'success');
    
    // 2.3 Atualizar status da assinatura para ativo
    log('Atualizando status da assinatura para ativo');
    
    const { error: updateError } = await supabase
      .from('subscriptions')
      .update({
        status: 'active',
        payment_status: 'confirmed',
        updated_at: new Date().toISOString(),
      })
      .eq('id', testSubscription.id);
    
    if (updateError) {
      throw updateError;
    }
    
    log('Status da assinatura atualizado para ativo', 'success');
    
    return true;
  } catch (error) {
    log(`Erro no teste de assinaturas: ${error.message}`, 'error');
    return false;
  }
}

// 3. Teste de processamento de pagamentos
async function testPayments() {
  log('TESTE DE PROCESSAMENTO DE PAGAMENTOS', 'title');
  
  try {
    if (!testUser || !testSubscription) {
      throw new Error('Usuário ou assinatura de teste não disponível');
    }
    
    // 3.1 Criar um pagamento para a assinatura
    log('Criando pagamento para a assinatura');
    
    const paymentData = {
      user_id: testUser.id,
      subscription_id: testSubscription.id,
      amount: testSubscription.price,
      payment_method: 'pix',
      status: 'pending',
      transaction_id: `test_${Date.now()}`,
      payment_date: null,
    };
    
    const { data: payment, error: paymentError } = await supabase
      .from('payments')
      .insert(paymentData)
      .select()
      .single();
    
    if (paymentError) {
      throw paymentError;
    }
    
    testPayment = payment;
    log(`Pagamento criado com ID: ${testPayment.id}`, 'success');
    
    // 3.2 Atualizar status do pagamento para confirmado
    log('Atualizando status do pagamento para confirmado');
    
    const { error: updateError } = await supabase
      .from('payments')
      .update({
        status: 'completed',
        payment_date: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .eq('id', testPayment.id);
    
    if (updateError) {
      throw updateError;
    }
    
    log('Status do pagamento atualizado para confirmado', 'success');
    
    return true;
  } catch (error) {
    log(`Erro no teste de pagamentos: ${error.message}`, 'error');
    return false;
  }
}

// 4. Teste de controle financeiro
async function testFinancialControl() {
  log('TESTE DE CONTROLE FINANCEIRO', 'title');
  
  try {
    if (!testUser) {
      throw new Error('Usuário de teste não disponível');
    }
    
    // 4.1 Criar uma transação de receita
    log('Criando transação de receita');
    
    const incomeData = {
      user_id: testUser.id,
      description: 'Salário',
      amount: 5000,
      type: 'income',
      date: new Date().toISOString().split('T')[0],
    };
    
    const { data: income, error: incomeError } = await supabase
      .from('transactions')
      .insert(incomeData)
      .select()
      .single();
    
    if (incomeError) {
      throw incomeError;
    }
    
    testTransaction = income;
    log(`Transação de receita criada com ID: ${testTransaction.id}`, 'success');
    
    // 4.2 Criar uma transação de despesa
    log('Criando transação de despesa');
    
    const expenseData = {
      user_id: testUser.id,
      description: 'Aluguel',
      amount: 1500,
      type: 'expense',
      date: new Date().toISOString().split('T')[0],
    };
    
    const { data: expense, error: expenseError } = await supabase
      .from('transactions')
      .insert(expenseData)
      .select()
      .single();
    
    if (expenseError) {
      throw expenseError;
    }
    
    log(`Transação de despesa criada com ID: ${expense.id}`, 'success');
    
    // 4.3 Listar transações do usuário
    log('Listando transações do usuário');
    
    const { data: transactions, error: transactionsError } = await supabase
      .from('transactions')
      .select('*')
      .eq('user_id', testUser.id);
    
    if (transactionsError) {
      throw transactionsError;
    }
    
    log(`${transactions.length} transações encontradas`, 'success');
    
    return true;
  } catch (error) {
    log(`Erro no teste de controle financeiro: ${error.message}`, 'error');
    return false;
  }
}

// 5. Teste de segurança e performance
async function testSecurity() {
  log('TESTE DE SEGURANÇA E PERFORMANCE', 'title');
  
  try {
    // 5.1 Criar um segundo usuário para testar acesso indevido
    const email2 = `test2_${Date.now()}@example.com`;
    const password2 = 'Test@123456';
    
    log(`Criando segundo usuário de teste: ${email2}`);
    
    const { data: authData2, error: authError2 } = await supabase.auth.signUp({
      email: email2,
      password: password2,
      options: {
        data: {
          name: 'Usuário de Teste 2',
          phone: '11988888888',
        }
      }
    });
    
    if (authError2) {
      throw authError2;
    }
    
    const testUser2 = authData2.user;
    log(`Segundo usuário criado com ID: ${testUser2.id}`, 'success');
    
    // Aguardar um momento para o trigger criar o perfil
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // 5.2 Fazer login com o segundo usuário
    log('Fazendo login com o segundo usuário');
    
    const { data: loginData2, error: loginError2 } = await supabase.auth.signInWithPassword({
      email: email2,
      password: password2
    });
    
    if (loginError2) {
      throw loginError2;
    }
    
    log('Login realizado com sucesso', 'success');
    
    // 5.3 Tentar acessar transações do primeiro usuário
    log('Tentando acessar transações do primeiro usuário (deve falhar)');
    
    const { data: transactions, error: transactionsError } = await supabase
      .from('transactions')
      .select('*')
      .eq('user_id', testUser.id);
    
    if (transactions && transactions.length > 0) {
      throw new Error('Falha de segurança: segundo usuário conseguiu acessar transações do primeiro usuário');
    }
    
    if (transactionsError) {
      log('Acesso negado corretamente', 'success');
    } else {
      log('Nenhuma transação retornada, o que é esperado devido às políticas de RLS', 'success');
    }
    
    return true;
  } catch (error) {
    log(`Erro no teste de segurança: ${error.message}`, 'error');
    return false;
  }
}

// Função principal para executar todos os testes
async function runTests() {
  log('INICIANDO TESTES DO BACKEND DO MEDMONEY', 'title');
  
  const results = {
    authentication: false,
    subscriptions: false,
    payments: false,
    financialControl: false,
    security: false
  };
  
  // Executar testes em sequência
  results.authentication = await testAuthentication();
  
  if (results.authentication) {
    results.subscriptions = await testSubscriptions();
    
    if (results.subscriptions) {
      results.payments = await testPayments();
    }
    
    results.financialControl = await testFinancialControl();
    results.security = await testSecurity();
  }
  
  // Exibir resultados
  log('RESULTADOS DOS TESTES', 'title');
  
  for (const [test, result] of Object.entries(results)) {
    if (result) {
      log(`${test}: PASSOU`, 'success');
    } else {
      log(`${test}: FALHOU`, 'error');
    }
  }
  
  const totalTests = Object.keys(results).length;
  const passedTests = Object.values(results).filter(Boolean).length;
  
  log(`\nResumo: ${passedTests}/${totalTests} testes passaram`, passedTests === totalTests ? 'success' : 'warning');
  
  // Limpar dados de teste
  if (testUser) {
    log('\nLimpando dados de teste...');
    
    try {
      // Excluir usuário de teste
      await supabase.auth.admin.deleteUser(testUser.id);
      log('Usuário de teste excluído', 'success');
    } catch (error) {
      log(`Erro ao limpar dados de teste: ${error.message}`, 'error');
    }
  }
}

// Executar testes
runTests().catch(error => {
  log(`Erro ao executar testes: ${error.message}`, 'error');
}); 