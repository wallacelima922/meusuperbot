#!/bin/bash

# --- Configurações ---
GITHUB_PRIVATE_REPO_SSH_URL="git@github.com:wallacelima922/bot-telegram.git"
INSTALL_DIR="/opt/telegram-bot-app" # Ou outro caminho padrão
# Nome do arquivo principal do bot
BOT_MAIN_FILE="bot.js"
# Nome para o processo no PM2
PM2_APP_NAME="telegram-bot"
# Versão Major do Node.js LTS desejada
NODE_MAJOR=20
# Arquivo de Log
LOG_FILE="/tmp/bot_install_$(date +%s).log"
# --- Fim Configurações ---

# --- Funções Auxiliares ---
echo_info() { echo -e "\n\e[34mINFO:\e[0m $1"; }
echo_warning() { echo -e "\n\e[33mAVISO:\e[0m $1"; }
echo_error() { echo -e "\n\e[31m!!! ERRO:\e[0m $1"; }
# --- Fim Funções ---

# Função para executar comandos com log e verificação de erro
run_command() {
    local cmd_description="$1"
    shift # Remove a descrição, o resto são os comandos
    local command_to_run="$@"

    echo -n "INFO: ${cmd_description}... " | tee -a "$LOG_FILE" # Mostra e loga início
    # Executa o comando, anexando stdout e stderr ao log
    if eval "$command_to_run" >> "$LOG_FILE" 2>&1; then
        echo -e "\e[32mOK\e[0m" | tee -a "$LOG_FILE" # Mostra e loga OK
        return 0
    else
        echo -e "\e[31mFALHOU\e[0m" | tee -a "$LOG_FILE" # Mostra e loga FALHOU
        echo_error "Falha durante: ${cmd_description}. Verifique $LOG_FILE para detalhes."
        # Não sai automaticamente, permite que a função chamadora decida
        return 1
    fi
}

# --- Script Principal ---
set -e # Sai se um comando fora da função run_command falhar

echo_info "Iniciando instalação do Bot Telegram..."
echo "Log de instalação iniciado em: $(date)" > "$LOG_FILE"
echo "-------------------------------------------" >> "$LOG_FILE"

# --- 1. Verificação Inicial ---
echo_info "Verificando pré-requisitos..."
if [ "$(id -u)" -ne 0 ]; then echo_error "Execute com sudo: curl ... | sudo bash"; exit 1; fi
if [ -f /etc/os-release ]; then . /etc/os-release; if [ "$ID" != "ubuntu" ] || [ "$VERSION_ID" != "20.04" ]; then echo_error "Script para Ubuntu 20.04. Detectado: $ID $VERSION_ID"; exit 1; fi; else echo_error "/etc/os-release não encontrado."; exit 1; fi
echo_info "-> OS e permissões OK."

# --- 2. Instalação de Dependências do Sistema ---
echo_info "Instalando dependências do sistema..."
run_command "Atualizando lista de pacotes (apt update)" "apt-get update -y" || exit 1
run_command "Instalando pacotes básicos (git, curl, build-essential, python3, etc)" "apt-get install -y git curl wget build-essential python3 ca-certificates gnupg" || exit 1
echo_info "Configurando NodeSource Repo (Node v$NODE_MAJOR)..."
run_command "Criando diretório de keyrings" "mkdir -p /etc/apt/keyrings" || exit 1
run_command "Baixando chave GPG NodeSource" "curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg" || exit 1
run_command "Adicionando repo NodeSource" "echo 'deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main' | tee /etc/apt/sources.list.d/nodesource.list > /dev/null" || exit 1
run_command "Atualizando pacotes (pós-NodeSource)" "apt-get update -y" || exit 1
run_command "Instalando Node.js" "apt-get install nodejs -y" || exit 1
echo_info "Verificando Node.js e NPM..."
node -v >> "$LOG_FILE" 2>&1 && npm -v >> "$LOG_FILE" 2>&1 && echo_info "$(node -v) / $(npm -v)" || echo_warning "Falha ao verificar node/npm"
run_command "Instalando PM2 globalmente" "npm install -g pm2" || exit 1
echo_info "-> Dependências do sistema instaladas."

# --- 3. Clonar Repositório Privado via SSH ---
echo_info "Clonando repositório privado do bot via SSH..."
if [ -d "$INSTALL_DIR" ]; then echo_warning "Diretório $INSTALL_DIR já existe, removendo..."; sudo rm -rf "$INSTALL_DIR"; fi
# A autenticação SSH deve funcionar por causa da Deploy Key adicionada pelo painel PHP
run_command "Clonando repo para $INSTALL_DIR" "git clone $GITHUB_PRIVATE_REPO_SSH_URL $INSTALL_DIR" || exit 1
cd "$INSTALL_DIR" # Entra no diretório clonado
echo_info "-> Repositório clonado em $(pwd)."
if [ ! -f "package.json" ]; then echo_error "package.json não encontrado no repo clonado!"; exit 1; fi

# --- 4. Configurar .env do BOT ---
echo_info "Configurando arquivo .env do BOT..."
if [ -f ".env" ]; then echo_warning "Arquivo .env existente, fazendo backup..."; mv .env .env.bak.$(date +%s); fi
echo_info "Por favor, forneça as configurações específicas para este BOT:"
read -p "-> Token do Bot Telegram: " TELEGRAM_BOT_TOKEN
read -p "-> Access Token Mercado Pago (Bot): " MERCADOPAGO_ACCESS_TOKEN
read -p "-> ID Telegram Admin (Bot): " ADMIN_TELEGRAM_ID
read -p "-> Webhook Domain (HTTPS - Bot): " WEBHOOK_DOMAIN
read -p "-> Porta Local (Bot) [3000]: " SERVER_PORT; SERVER_PORT=${SERVER_PORT:-3000}
read -p "-> Preço Mensal (Bot) [10.00]: " PRECO_MENSAL; PRECO_MENSAL=${PRECO_MENSAL:-10.00}
read -p "-> Preço Anual (Bot) [100.00]: " PRECO_ANUAL; PRECO_ANUAL=${PRECO_ANUAL:-100.00}
read -p "-> % Cashback (Bot) [0]: " CASHBACK_PERCENT; CASHBACK_PERCENT=${CASHBACK_PERCENT:-0}
read -p "-> % Comissão Afiliado (Bot) [0]: " AFFILIATE_COMMISSION_PERCENT; AFFILIATE_COMMISSION_PERCENT=${AFFILIATE_COMMISSION_PERCENT:-0}
read -p "-> Ativar Cashback (Bot)? [0]: " ATIVAR_CASHBACK; ATIVAR_CASHBACK=${ATIVAR_CASHBACK:-0}
read -p "-> Ativar Afiliados (Bot)? [0]: " ATIVAR_AFILIADO; ATIVAR_AFILIADO=${ATIVAR_AFILIADO:-0}
read -p "-> Username do Bot (@...) [Opcional]: " BOT_USERNAME
if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$MERCADOPAGO_ACCESS_TOKEN" ] || [ -z "$ADMIN_TELEGRAM_ID" ] || [ -z "$WEBHOOK_DOMAIN" ]; then echo_error "Token Bot, Token MP, ID Admin e Webhook Domain são obrigatórios." exit 1; fi
echo_info "Criando .env..."
cat << EOF > .env
# Configurações do Bot Telegram (Gerado por install.sh)
TELEGRAM_BOT_TOKEN='$TELEGRAM_BOT_TOKEN'
ADMIN_TELEGRAM_ID='$ADMIN_TELEGRAM_ID'
WEBHOOK_DOMAIN='$WEBHOOK_DOMAIN'
SERVER_PORT='$SERVER_PORT'
MERCADOPAGO_ACCESS_TOKEN='$MERCADOPAGO_ACCESS_TOKEN'
PIX_EXPIRATION_MINUTES=15
PRECO_MENSAL='$PRECO_MENSAL'
PRECO_ANUAL='$PRECO_ANUAL'
CASHBACK_PERCENT='$CASHBACK_PERCENT'
AFFILIATE_COMMISSION_PERCENT='$AFFILIATE_COMMISSION_PERCENT'
ATIVAR_CASHBACK='$ATIVAR_CASHBACK'
ATIVAR_AFILIADO='$ATIVAR_AFILIADO'
BOT_USERNAME='$BOT_USERNAME'
LOG_LEVEL=info
EOF
echo_info "-> .env do BOT criado."

# --- 5. Instalar Dependências Node.js do BOT ---
echo_info "Instalando dependências Node.js do BOT..."
run_command "Removendo node_modules antigo (se existir)" "rm -rf node_modules" # Ignora erro se não existir
run_command "Executando npm install" "npm install --omit=dev --verbose" || exit 1
echo_info "-> Dependências do BOT instaladas."

# --- 6. Iniciar BOT com PM2 ---
echo_info "Configurando e iniciando o BOT com PM2..."
if [ ! -f "$BOT_MAIN_FILE" ]; then echo_error "Arquivo principal '$BOT_MAIN_FILE' não encontrado." exit 1; fi
run_command "Parando/Deletando instância PM2 antiga (se existir)" "pm2 delete $PM2_APP_NAME --silent" # Ignora erro se não existir
# Usa --cwd para garantir que pm2 saiba de onde rodar
run_command "Iniciando BOT com PM2" "pm2 start $BOT_MAIN_FILE --name $PM2_APP_NAME --cwd $(pwd) --output /dev/null --error /dev/null" || exit 1
run_command "Salvando configuração PM2" "pm2 save --force" || exit 1
# Comando Startup PM2
echo_info "Configurando PM2 para iniciar no boot..."
STARTUP_COMMAND=$(pm2 startup | grep 'sudo env') || STARTUP_COMMAND="pm2 startup (comando não capturado automaticamente, execute manualmente)"
echo ""; echo_warning "--------------------------------------------------------------------"; echo_warning "IMPORTANTE: Execute o comando abaixo para o PM2 iniciar com a VPS:"; echo ""; echo "    $STARTUP_COMMAND"; echo ""; echo_warning "(Copie, cole e execute no terminal AGORA)"; echo_warning "--------------------------------------------------------------------"; echo ""

echo_info "----- Instalação/Configuração do BOT Concluída em $(pwd)! -----"
echo_info "Use 'pm2 list' e 'pm2 logs $PM2_APP_NAME'."
echo_info "Verifique o log de instalação se necessário: $LOG_FILE"
echo_info "---------------------------------"

exit 0
