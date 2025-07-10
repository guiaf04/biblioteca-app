#!/bin/bash

# Script para build e execução da aplicação biblioteca

set -e

echo "🚀 Iniciando build da aplicação Biblioteca..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    error "Docker não está rodando. Iniciando Docker..."
    sudo systemctl start docker
    sleep 5
fi

# Navegar para o diretório raiz do projeto
cd "$(dirname "$0")/.."

# Limpar containers e imagens antigas (opcional)
if [ "$1" = "--clean" ]; then
    log "Limpando containers e imagens antigas..."
    docker-compose down --volumes --remove-orphans 2>/dev/null || true
    docker system prune -f
fi

# Build das imagens
log "Construindo imagens Docker..."

# Build do backend
info "Construindo imagem do backend..."
cd backend
docker build -t biblioteca-backend:latest .
cd ..

# Build do frontend
info "Construindo imagem do frontend..."
cd frontend
docker build -t biblioteca-frontend:latest .
cd ..

# Verificar se as imagens foram criadas
log "Verificando imagens criadas..."
docker images | grep biblioteca

# Executar docker-compose
log "Iniciando aplicação com docker-compose..."
docker-compose up -d

# Aguardar containers ficarem saudáveis
log "Aguardando containers ficarem saudáveis..."
sleep 10

# Verificar status dos containers
log "Status dos containers:"
docker-compose ps

# Verificar logs se houver problemas
if ! docker-compose ps | grep -q "Up"; then
    warning "Alguns containers podem ter problemas. Verificando logs..."
    docker-compose logs
fi

# Informações de acesso
log "✅ Build concluído!"
echo ""
info "🌐 Acesso à aplicação:"
info "   Frontend: http://localhost"
info "   Backend API: http://localhost:8080/api/livros"
info "   Testes Frontend: http://localhost/test"
echo ""
info "📋 Comandos úteis:"
info "   Ver logs: docker-compose logs -f"
info "   Parar aplicação: docker-compose down"
info "   Reiniciar: docker-compose restart"
echo ""

# Teste básico de conectividade
log "Testando conectividade..."
sleep 5

if curl -s http://localhost:8080/api/livros/estatisticas > /dev/null; then
    log "✅ Backend está respondendo!"
else
    warning "⚠️  Backend pode não estar pronto ainda. Aguarde alguns segundos."
fi

if curl -s http://localhost > /dev/null; then
    log "✅ Frontend está respondendo!"
else
    warning "⚠️  Frontend pode não estar pronto ainda. Aguarde alguns segundos."
fi

log "🎉 Aplicação Biblioteca está rodando!"

