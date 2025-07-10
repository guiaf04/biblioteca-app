#!/bin/bash

# User Data script para configurar instância EC2 da aplicação Biblioteca
# Este script é executado na primeira inicialização da instância

set -e

# Variáveis
AWS_REGION="${aws_region}"
BACKEND_IMAGE="${backend_image}"
FRONTEND_IMAGE="${frontend_image}"
ECR_BACKEND_REPO="${ecr_backend_repo}"
ECR_FRONTEND_REPO="${ecr_frontend_repo}"

# Função para log
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/user-data.log
}

log "🚀 Iniciando configuração da instância EC2 para aplicação Biblioteca"

# Atualizar sistema
log "📦 Atualizando sistema..."
apt-get update -y
apt-get upgrade -y

# Instalar dependências
log "📦 Instalando dependências..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    unzip \
    jq \
    htop \
    tree \
    git

# Instalar AWS CLI v2
log "☁️ Instalando AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Configurar AWS CLI
log "⚙️ Configurando AWS CLI..."
aws configure set region $AWS_REGION
aws configure set output json

# Instalar Docker
log "🐳 Instalando Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Iniciar e habilitar Docker
systemctl start docker
systemctl enable docker

# Adicionar usuário ubuntu ao grupo docker
usermod -aG docker ubuntu

# Instalar Docker Compose
log "🐳 Instalando Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Verificar instalações
log "✅ Verificando instalações..."
docker --version
docker-compose --version
aws --version

# Configurar diretório da aplicação
log "📁 Configurando diretório da aplicação..."
mkdir -p /opt/biblioteca
chown ubuntu:ubuntu /opt/biblioteca
cd /opt/biblioteca

# Criar arquivo docker-compose.yml
log "📝 Criando docker-compose.yml..."
cat > docker-compose.yml << EOF
version: '3.8'

services:
  backend:
    image: $ECR_BACKEND_REPO:latest
    container_name: biblioteca-backend
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=docker
      - JAVA_OPTS=-Xmx512m -Xms256m
    networks:
      - biblioteca-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/api/livros/estatisticas"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  frontend:
    image: $ECR_FRONTEND_REPO:latest
    container_name: biblioteca-frontend
    ports:
      - "80:80"
    depends_on:
      backend:
        condition: service_healthy
    networks:
      - biblioteca-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

networks:
  biblioteca-network:
    driver: bridge
    name: biblioteca-network
EOF

# Criar script de deploy
log "📝 Criando script de deploy..."
cat > deploy.sh << 'EOF'
#!/bin/bash

set -e

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "🚀 Iniciando deploy da aplicação Biblioteca..."

# Login no ECR
log "🔐 Fazendo login no ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $(echo $ECR_BACKEND_REPO | cut -d'/' -f1)

# Pull das imagens mais recentes
log "📥 Baixando imagens mais recentes..."
docker pull $ECR_BACKEND_REPO:latest || log "⚠️ Falha ao baixar imagem do backend"
docker pull $ECR_FRONTEND_REPO:latest || log "⚠️ Falha ao baixar imagem do frontend"

# Parar containers existentes
log "🛑 Parando containers existentes..."
docker-compose down || true

# Remover imagens antigas (manter apenas as 3 mais recentes)
log "🧹 Limpando imagens antigas..."
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.CreatedAt}}" | grep biblioteca | tail -n +4 | awk '{print $1}' | xargs -r docker rmi || true

# Iniciar aplicação
log "🚀 Iniciando aplicação..."
docker-compose up -d

# Aguardar containers ficarem saudáveis
log "⏳ Aguardando containers ficarem saudáveis..."
sleep 30

# Verificar status
log "📊 Verificando status dos containers..."
docker-compose ps

# Testar conectividade
log "🧪 Testando conectividade..."
sleep 10

if curl -s http://localhost:8080/api/livros/estatisticas > /dev/null; then
    log "✅ Backend está respondendo!"
else
    log "⚠️ Backend pode não estar pronto ainda"
fi

if curl -s http://localhost > /dev/null; then
    log "✅ Frontend está respondendo!"
else
    log "⚠️ Frontend pode não estar pronto ainda"
fi

log "🎉 Deploy concluído!"
EOF

chmod +x deploy.sh
chown ubuntu:ubuntu deploy.sh

# Criar script de monitoramento
log "📝 Criando script de monitoramento..."
cat > monitor.sh << 'EOF'
#!/bin/bash

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "📊 Status da aplicação Biblioteca:"
echo ""

# Status dos containers
echo "🐳 Containers:"
docker-compose ps

echo ""

# Uso de recursos
echo "💻 Uso de recursos:"
echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
echo "Memória: $(free -h | awk 'NR==2{printf "%.1f%%", $3*100/$2}')"
echo "Disco: $(df -h / | awk 'NR==2{print $5}')"

echo ""

# Logs recentes
echo "📝 Logs recentes do backend:"
docker-compose logs --tail=5 backend

echo ""
echo "📝 Logs recentes do frontend:"
docker-compose logs --tail=5 frontend
EOF

chmod +x monitor.sh
chown ubuntu:ubuntu monitor.sh

# Configurar cron para monitoramento
log "⏰ Configurando monitoramento automático..."
cat > /etc/cron.d/biblioteca-monitor << EOF
# Monitoramento da aplicação Biblioteca
*/5 * * * * ubuntu cd /opt/biblioteca && ./monitor.sh >> /var/log/biblioteca-monitor.log 2>&1
0 2 * * * ubuntu cd /opt/biblioteca && docker system prune -f >> /var/log/biblioteca-cleanup.log 2>&1
EOF

# Configurar logrotate
log "📋 Configurando rotação de logs..."
cat > /etc/logrotate.d/biblioteca << EOF
/var/log/biblioteca-*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 ubuntu ubuntu
}
EOF

# Configurar CloudWatch agent (se disponível)
log "☁️ Configurando CloudWatch agent..."
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -O /tmp/amazon-cloudwatch-agent.deb
dpkg -i /tmp/amazon-cloudwatch-agent.deb || true
rm /tmp/amazon-cloudwatch-agent.deb

# Criar configuração do CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/user-data.log",
                        "log_group_name": "/aws/ec2/biblioteca/user-data",
                        "log_stream_name": "{instance_id}"
                    },
                    {
                        "file_path": "/var/log/biblioteca-monitor.log",
                        "log_group_name": "/aws/ec2/biblioteca/monitor",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "Biblioteca/EC2",
        "metrics_collected": {
            "cpu": {
                "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": ["used_percent"],
                "metrics_collection_interval": 60,
                "resources": ["*"]
            },
            "mem": {
                "measurement": ["mem_used_percent"],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

# Iniciar CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s || true

# Executar deploy inicial
log "🚀 Executando deploy inicial..."
cd /opt/biblioteca
sudo -u ubuntu ./deploy.sh

# Configurar firewall básico
log "🔥 Configurando firewall..."
ufw --force enable
ufw allow ssh
ufw allow 80
ufw allow 8080

log "✅ Configuração da instância EC2 concluída!"
log "🌐 Aplicação disponível em: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
log "🔧 API disponível em: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080/api"

# Sinalizar que a configuração foi concluída
touch /var/log/user-data-completed
log "🎉 User data script concluído com sucesso!"

