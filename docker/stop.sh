#!/bin/bash

# Script para parar a aplicação biblioteca

set -e

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

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Navegar para o diretório raiz do projeto
cd "$(dirname "$0")/.."

log "🛑 Parando aplicação Biblioteca..."

# Parar containers
log "Parando containers..."
docker-compose down

# Se --clean foi passado, limpar tudo
if [ "$1" = "--clean" ]; then
    log "Limpando volumes e imagens..."
    docker-compose down --volumes --remove-orphans
    
    # Remover imagens da aplicação
    docker rmi biblioteca-backend:latest 2>/dev/null || true
    docker rmi biblioteca-frontend:latest 2>/dev/null || true
    
    # Limpar sistema Docker
    docker system prune -f
    
    log "✅ Limpeza completa realizada!"
else
    log "✅ Aplicação parada!"
fi

info "💡 Para limpar completamente, use: ./docker/stop.sh --clean"

