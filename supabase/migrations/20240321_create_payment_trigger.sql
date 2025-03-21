-- Função trigger para criar tabela do usuário quando pagamento for confirmado
CREATE OR REPLACE FUNCTION handle_payment_confirmation()
RETURNS TRIGGER AS $$
BEGIN
    -- Se o status mudou para 'confirmed'/'pago'
    IF (TG_OP = 'UPDATE' AND NEW.status = 'confirmed' AND OLD.status != 'confirmed') OR
       (TG_OP = 'INSERT' AND NEW.status = 'confirmed') THEN
        -- Criar tabela personalizada para o usuário usando a função existente
        PERFORM create_user_table_manually(NEW.user_id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Criar o trigger na tabela de pagamentos
DROP TRIGGER IF EXISTS on_payment_confirmation ON public.payments;
CREATE TRIGGER on_payment_confirmation
    AFTER INSERT OR UPDATE ON public.payments
    FOR EACH ROW
    EXECUTE FUNCTION handle_payment_confirmation(); 