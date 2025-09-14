#!/bin/bash

# Script de Deploy do Banco ClickBus na VPS - Docker Only
# Uso: ./deploy.sh

set -e

echo "🐳 Iniciando deploy do Banco ClickBus (Docker Only)..."

# Configurações
VPS_HOST="72.60.50.72"
VPS_USER="root"
PROJECT_DIR="/opt/clickbus-db"
REQUIRED_FILES=("docker-compose.yml" "sql/")

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Verificar se os arquivos necessários existem
log "Verificando arquivos necessários..."
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -e "$file" ]; then
        error "Arquivo necessário não encontrado: $file"
    fi
done

# Verificar conectividade SSH
log "Testando conexão SSH com a VPS..."
if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "$VPS_USER@$VPS_HOST" exit 2>/dev/null; then
    error "Não foi possível conectar à VPS. Verifique as credenciais SSH."
fi

# Criar diretório no servidor
log "Criando diretório do projeto na VPS..."
ssh "$VPS_USER@$VPS_HOST" "mkdir -p $PROJECT_DIR"

# Transferir apenas arquivos essenciais
log "Transferindo arquivos Docker para a VPS..."
scp docker-compose.yml "$VPS_USER@$VPS_HOST:$PROJECT_DIR/"
scp -r sql/ "$VPS_USER@$VPS_HOST:$PROJECT_DIR/"

# Executar comandos na VPS
log "Configurando ambiente Docker na VPS..."
ssh "$VPS_USER@$VPS_HOST" << 'EOF'
    cd /opt/clickbus-db

    # Verificar se Docker está instalado
    if ! command -v docker &> /dev/null; then
        echo "🐳 Instalando Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
        systemctl enable docker
        systemctl start docker
        echo "✅ Docker instalado com sucesso"
    else
        echo "✅ Docker já está instalado"
    fi

    # Verificar se Docker Compose está instalado
    if ! command -v docker-compose &> /dev/null; then
        echo "🐳 Instalando Docker Compose..."
        DOCKER_COMPOSE_VERSION="v2.24.0"
        curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        echo "✅ Docker Compose instalado com sucesso"
    else
        echo "✅ Docker Compose já está instalado"
    fi

    # Parar e remover containers existentes
    echo "🛑 Parando containers existentes..."
    docker-compose down --volumes 2>/dev/null || true

    # Remover volumes órfãos se existirem
    echo "🧹 Limpando volumes órfãos..."
    docker volume prune -f 2>/dev/null || true

    # Baixar imagens mais recentes
    echo "📥 Baixando imagens Docker..."
    docker-compose pull

    # Iniciar os serviços
    echo "🚀 Iniciando serviços do ClickBus..."
    docker-compose up -d

    # Aguardar inicialização do PostgreSQL
    echo "⏳ Aguardando inicialização do PostgreSQL..."
    timeout 120 bash -c 'until docker exec clickbus_postgres pg_isready -U clickbus_admin -d clickbus_db; do sleep 2; done'

    # Verificar status
    echo "📊 Status dos serviços:"
    docker-compose ps

    echo "📋 Informações dos containers:"
    docker ps --filter "name=clickbus" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
EOF

# Verificar se os serviços estão acessíveis
log "Verificando conectividade dos serviços..."

# Aguardar um pouco mais para garantir que os serviços estejam prontos
sleep 10

# Testar PostgreSQL
if timeout 10 bash -c "echo > /dev/tcp/$VPS_HOST/5432" 2>/dev/null; then
    log "✅ PostgreSQL está acessível na porta 5432"
else
    warn "❌ PostgreSQL não está acessível na porta 5432"
fi

# Testar pgAdmin
if timeout 10 bash -c "echo > /dev/tcp/$VPS_HOST/8080" 2>/dev/null; then
    log "✅ pgAdmin está acessível na porta 8080"
else
    warn "❌ pgAdmin não está acessível na porta 8080"
fi

log "🎉 Deploy Docker concluído!"
echo ""
info "📋 Informações de acesso:"
echo "  🐘 PostgreSQL: $VPS_HOST:5432"
echo "     Database: clickbus_db"
echo "     User: clickbus_admin"
echo "     Password: ClickBus2024!@#"
echo ""
echo "  🌐 pgAdmin: http://$VPS_HOST:8080"
echo "     Email: admin@clickbus.com"
echo "     Password: admin123"
echo ""
info "🐳 Comandos úteis:"
echo "  Verificar status: ssh $VPS_USER@$VPS_HOST 'cd $PROJECT_DIR && docker-compose ps'"
echo "  Ver logs: ssh $VPS_USER@$VPS_HOST 'cd $PROJECT_DIR && docker-compose logs'"
echo "  Parar serviços: ssh $VPS_USER@$VPS_HOST 'cd $PROJECT_DIR && docker-compose down'"
echo "  Reiniciar: ssh $VPS_USER@$VPS_HOST 'cd $PROJECT_DIR && docker-compose restart'"