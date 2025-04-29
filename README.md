# Bot Telegram para Venda de Recargas e Gerenciamento

Este é um projeto de bot para Telegram desenvolvido em PHP, projetado para vender cartões de recarga pré-pagos (como planos mensais/anuais) e gerenciar usuários, saldo e códigos. A integração de pagamento é feita via PIX através da API do Mercado Pago, com confirmação automática via webhooks. O bot também inclui um painel de administração via comandos/botões para gerenciamento.

## Funcionalidades Implementadas

**Usuário:**

* **`/start`:** Mensagem de boas-vindas personalizada com nome, saldo atual e número de compras realizadas. Exibe o menu principal.
* **Menu Principal:**
    * **🛒 Comprar:** Inicia fluxo de compra.
        * Seleção de Plano (ex: Mensal, Anual - preços carregados do BD).
        * Seleção de Método de Pagamento (Saldo em Conta ou PIX).
        * **Pagamento com Saldo:** Debita o saldo do usuário, busca um código de recarga disponível no estoque do BD (`recharge_codes`), marca o código como vendido, salva nos detalhes da compra e entrega o código ao usuário.
        * **Pagamento com PIX:** Gera um QR Code/Copia e Cola PIX via API do Mercado Pago e aguarda confirmação.
    * **❓ Ajuda:** Exibe menu com tópicos de ajuda (conteúdo dos tópicos pendente).
    * **💻 Instalar:** Exibe texto com instruções de instalação.
    * **💰 Add Saldo:** Permite ao usuário gerar um PIX para adicionar saldo à sua conta no bot. A confirmação do pagamento via webhook atualiza o saldo automaticamente.
    * **🔙 Cashback:** Exibe o status global (Ativado/Desativado) e a taxa padrão (configuráveis via painel admin e BD). Mostra o total de cashback acumulado pelo usuário. (*Lógica de concessão de cashback implementada apenas para o bônus da primeira compra via PIX*).
    * **👥 Afiliado:**
        * Exibe o status global (Ativado/Desativado) e a taxa de comissão padrão (configuráveis via painel admin e BD).
        * Mostra ganhos acumulados e link de referência pessoal se o usuário for afiliado.
        * Exibe Termos de Uso e botão "Aceitar Termos" para ativar o status de afiliado (salva no BD).
        * (*Lógica de rastreamento e concessão de comissão regular pendente; bônus de 1ª compra PIX implementado*).
    * **📜 Minhas Compras:** Exibe o histórico das últimas compras do usuário, incluindo o código de recarga para compras pagas.
    * **📞 Contato:** Exibe informações de contato .
 
      <img src="https://i.ibb.co/DPJH743T/F9-EAAB89-D481-49-CA-9-A28-40-BA2762-CFEB.png" alt="F9-EAAB89-D481-49-CA-9-A28-40-BA2762-CFEB" border="0">

**Administrador:**

* **`/admin`:** Comando restrito a IDs de administrador pré-definidos. Exibe o painel de administração com botões inline.
* **Gerenciar Cartões:**
    * Adicionar Cartão: Permite adicionar novos códigos de recarga pré-definidos ao banco de dados, associados a um plano (Mensal/Anual), com verificação de duplicidade.
    * Listar Cartões: Exibe uma lista paginada de todos os códigos cadastrados com seus status (Disponível, Vendido, Resgatado - *Resgatado a implementar*), tipo e data.
    * Deletar Cartão: Permite deletar um código específico *apenas se ele estiver disponível*, com etapa de confirmação.
* **Creditar Saldo:** Permite creditar manualmente saldo na conta de qualquer usuário, registrando a transação como 'ADMIN_CREDIT'.
* **BroadCast (/msg):** Exibe instruções sobre como usar o comando `/msg <texto>` para enviar mensagens em massa. (*Lógica de envio do `/msg` pendente*).
* **Configurar Cashback:** Permite ativar/desativar o sistema globalmente e definir a porcentagem padrão via botões. Alterações salvas no BD.
* **Configurar Afiliados:** Permite ativar/desativar o programa globalmente e definir a taxa de comissão padrão via botões. Alterações salvas no BD.
* **Fechar Painel:** Remove a mensagem do painel de admin do chat.

  <img src="https://i.ibb.co/1HnjCtr/EE6-D951-B-D6-B1-4-B75-B5-D2-47955-D1592-AC.png" alt="EE6-D951-B-D6-B1-4-B75-B5-D2-47955-D1592-AC" border="0">

## Tecnologias Utilizadas

* **PHP:** 8.2 ou superior (com extensões PDO/pdo_mysql, JSON, cURL, MBString)
* **MariaDB / MySQL:** Banco de dados relacional.
* **Composer:** Gerenciador de dependências PHP.
* **Mercado Pago SDK (PHP):** v3.x para integração de pagamentos PIX.
* **Telegram Bot API:** Para interação com o Telegram.
* **Webhooks:** Para receber atualizações do Telegram e notificações do Mercado Pago.
* **Cron Job:** Para tarefas agendadas (como expirar pagamentos pendentes).

## Pré-requisitos

* Servidor web (Apache, Nginx, LiteSpeed) com suporte a PHP e HTTPS (SSL obrigatório para webhooks).
* Acesso SSH ao servidor (recomendado para instalação e gerenciamento).
* Composer instalado no servidor ou localmente.
* Banco de dados MariaDB ou MySQL.
* Um Token de Bot do Telegram (obtido via @BotFather).
* Credenciais de Aplicação do Mercado Pago (Access Token de Produção e/ou Sandbox).
* Domínio com HTTPS configurado para os webhooks.

## Instalação

1.  **Clone o Repositório:**
    ```bash
    git clone <url_do_repositorio> seu_diretorio_bot
    cd seu_diretorio_bot
    ```
2.  **Instale Dependências:**
    ```bash
    composer install --no-dev -o
    ```
3.  **Banco de Dados:**
    * Crie um banco de dados e um usuário no seu MariaDB/MySQL.
    * Importe a estrutura das tabelas. Crie um arquivo `schema.sql` com os comandos `CREATE TABLE` para `users`, `transactions`, `purchases`, `recharge_codes`, `bot_settings` (baseado nas queries fornecidas durante o desenvolvimento) ou execute as queries manualmente.
4.  **Configuração:**
    * Vá para o diretório `config/`.
    * Copie `config_db.php.example` para `config_db.php` (ou crie o arquivo) e preencha com suas credenciais do banco de dados.
    * Copie `config_tokens.php.example` para `config_tokens.php` (ou crie o arquivo) e preencha com:
        * `$botToken` (Token do Telegram)
        * `$mercadoPagoAccessToken` (Token do MP - Produção ou Sandbox)
        * `$botUsername` (Username do seu bot sem o @)
        * `$webhookUrlMP` (URL completa HTTPS para `webhooks/mercadopago.php`)
        * `$adminUserIds` (Array com os IDs numéricos dos admins do Telegram)
5.  **Servidor Web:**
    * Configure o DocumentRoot do seu domínio/subdomínio para apontar para a pasta `public_html` (ou a raiz onde os arquivos `config`, `includes` etc. estão localizados, dependendo da sua estrutura final).
    * Certifique-se de que o servidor está configurado para servir PHP (ex: via PHP-FPM com LiteSpeed/Nginx/Apache).
6.  **Webhooks:**
    * **Telegram:** Configure o webhook do Telegram para apontar para a URL **HTTPS** do seu script de entrada: `https://SEU_DOMINIO/webhooks/telegram.php` (use o método `setWebhook` da API do Telegram).
    * **Mercado Pago:** Configure a URL de **Webhook de Produção** (e/ou Sandbox) nas configurações da sua aplicação no painel do Mercado Pago para apontar para: `https://SEU_DOMINIO/webhooks/mercadopago.php`. Certifique-se de ativar os eventos de pagamento (`payment`).
7.  **Popule Códigos:** Insira seus códigos de recarga reais na tabela `recharge_codes` com `status = 'available'`.
8.  **Cron Job:**
    * Crie o script `check_expirations.php` (conforme fornecido anteriormente).
    * Configure um Cron Job no seu servidor (via `crontab -e` ou painel de controle) para executar o script periodicamente (ex: a cada 15 minutos). Exemplo de comando:
        ```bash
        */15 * * * * /usr/bin/php /caminho/completo/para/public_html/check_expirations.php >> /caminho/completo/para/public_html/cron_job.log 2>&1
        ```
        *(Verifique o caminho correto para o executável `php` no seu servidor com `which php`)*.
9.  **Permissões:** Garanta que o usuário do servidor web (ex: `www-data`, `apache`, ou o usuário do site no CyberPanel como `teste4935`) tenha permissão de **leitura** em todos os arquivos `.php` e na pasta `vendor`, e permissão de **escrita** nos arquivos de log (`bot_log.txt`, `cron_job.log`). Use `chown` e `chmod` se necessário.

## Uso

* **Usuários:** Iniciam a interação com `/start`. Navegam pelos botões inline. Enviam valores quando solicitado (para Add Saldo).
* **Administradores:**
    * Usam `/start` normalmente.
    * Usam `/admin` para acessar o painel de controle via botões inline.
    * Usam `/msg <texto>` para enviar broadcast (após implementação).

## Estrutura de Pastas (Simplificada)
├── config/             # Arquivos de configuração (BD, Tokens)
├── includes/           # Funções auxiliares (DB, Telegram API, Helpers, Broadcast)
├── handlers/           # Lógica de tratamento (Comandos, Mensagens, Callbacks)
├── webhooks/           # Scripts de entrada para Webhooks (Telegram, Mercado Pago)
├── vendor/             # Dependências do Composer (SDK MP, etc.)
├── bot_log.txt         # Log principal do bot (precisa de permissão de escrita)
├── cron_job.log        # Log do Cron Job (opcional, precisa de permissão de escrita)
├── composer.json
└── composer.lock

Contato: wallace_lima@ymail.com
