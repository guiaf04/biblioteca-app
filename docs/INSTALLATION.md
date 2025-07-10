# Guia de Instalação - Sistema Biblioteca

Este guia fornece instruções detalhadas para instalar e configurar o Sistema de Biblioteca em diferentes ambientes.

## 📋 Índice

1. [Pré-requisitos](#pré-requisitos)
2. [Instalação Local](#instalação-local)
3. [Instalação em Produção](#instalação-em-produção)
4. [Configuração AWS](#configuração-aws)
5. [Troubleshooting](#troubleshooting)

## 🔧 Pré-requisitos

### Para Desenvolvimento Local
- **Docker**: versão 20.10 ou superior
- **Docker Compose**: versão 2.0 ou superior
- **Java**: versão 17 ou superior (opcional, para desenvolvimento)
- **Maven**: versão 3.8 ou superior (opcional, para desenvolvimento)
- **Git**: para clonar o repositório

### Para Deploy em Produção
- **Conta AWS**: com permissões adequadas
- **Terraform**: versão 1.5 ou superior
- **Ansible**: versão 2.9 ou superior
- **AWS CLI**: versão 2.0 ou superior
- **Chave SSH**: para acesso às instâncias EC2

## 🏠 Instalação Local

### Método 1: Docker Compose (Recomendado)

1. **Clone o repositório**
```bash
git clone <repository-url>
cd biblioteca-app
```

2. **Execute o script de build**
```bash
chmod +x docker/build.sh
./docker/build.sh
```

3. **Verifique se está funcionando**
```bash
# Verificar containers
docker-compose ps

# Verificar logs
docker-compose logs -f
```

4. **Acesse a aplicação**
- Frontend: http://localhost
- Backend API: http://localhost:8080/api/livros
- Documentação API: http://localhost:8080/swagger-ui.html

### Método 2: Execução Manual

1. **Backend**
```bash
cd backend
mvn clean install
mvn spring-boot:run
```

2. **Frontend (em outro terminal)**
```bash
cd frontend
python3 -m http.server 3000
# ou use qualquer servidor HTTP de sua preferência
```

3. **Acesse**
- Frontend: http://localhost:3000
- Backend: http://localhost:8080

## 🌐 Instalação em Produção

### Passo 1: Configurar AWS CLI

```bash
# Instalar AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configurar credenciais
aws configure
```

### Passo 2: Preparar Chave SSH

```bash
# Gerar chave SSH (se não tiver)
ssh-keygen -t rsa -b 4096 -C "seu-email@exemplo.com"

# A chave pública será usada no Terraform
cat ~/.ssh/id_rsa.pub
```

### Passo 3: Configurar Terraform

```bash
cd terraform

# Copiar arquivo de exemplo
cp terraform.tfvars.example terraform.tfvars

# Editar configurações
nano terraform.tfvars
```

**Configurações mínimas necessárias:**
```hcl
aws_region = "us-east-1"
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E... sua-chave-publica"
allowed_ssh_cidr = ["SEU.IP.PUBLICO/32"]  # Substitua pelo seu IP
```

### Passo 4: Provisionar Infraestrutura

```bash
# Inicializar Terraform
terraform init

# Planejar mudanças
terraform plan

# Aplicar configurações
terraform apply
```

### Passo 5: Configurar Ansible

```bash
cd ../ansible

# Obter IP da instância criada
INSTANCE_IP=$(terraform -chdir=../terraform output -raw instance_public_ip)

# Configurar inventário
cat > inventory.ini << EOF
[biblioteca_servers]
biblioteca-server ansible_host=$INSTANCE_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa
EOF
```

### Passo 6: Deploy da Aplicação

```bash
# Executar playbook
ansible-playbook -i inventory.ini deploy.yml
```

## ☁️ Configuração AWS

### Permissões IAM Necessárias

Crie um usuário IAM com as seguintes políticas:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "ecr:*",
                "iam:*",
                "logs:*"
            ],
            "Resource": "*"
        }
    ]
}
```

### Configuração de Secrets (GitHub Actions)

No seu repositório GitHub, configure os seguintes secrets:

- `AWS_ACCESS_KEY_ID`: Access Key do usuário IAM
- `AWS_SECRET_ACCESS_KEY`: Secret Key do usuário IAM
- `EC2_SSH_PRIVATE_KEY`: Chave privada SSH (conteúdo do arquivo ~/.ssh/id_rsa)

### Configuração de Domínio (Opcional)

Para usar um domínio personalizado:

1. **Configure Route 53**
```bash
# Criar zona hospedada
aws route53 create-hosted-zone --name exemplo.com --caller-reference $(date +%s)
```

2. **Obter certificado SSL**
```bash
# Solicitar certificado
aws acm request-certificate --domain-name exemplo.com --validation-method DNS
```

3. **Atualizar Terraform**
```hcl
enable_ssl = true
domain_name = "exemplo.com"
certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
```

## 🔧 Configurações Avançadas

### Configuração de Backup

```bash
# Configurar backup automático no Ansible
ansible-playbook -i inventory.ini deploy.yml --tags backup
```

### Configuração de Monitoramento

```bash
# Habilitar CloudWatch detalhado
ansible-playbook -i inventory.ini deploy.yml --tags monitoring
```

### Configuração de Auto Scaling

```hcl
# No terraform.tfvars
auto_scaling_enabled = true
min_instances = 1
max_instances = 3
desired_instances = 2
```

## 🚨 Troubleshooting

### Problemas Comuns

#### 1. Erro de Permissão AWS
```bash
# Verificar credenciais
aws sts get-caller-identity

# Verificar permissões
aws iam get-user
```

#### 2. Falha na Conexão SSH
```bash
# Verificar chave SSH
ssh -i ~/.ssh/id_rsa ubuntu@IP_DA_INSTANCIA

# Verificar security group
aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx
```

#### 3. Containers não Iniciam
```bash
# Verificar logs
docker-compose logs backend
docker-compose logs frontend

# Verificar recursos
docker stats
```

#### 4. Aplicação não Responde
```bash
# Verificar portas
netstat -tlnp | grep :8080
netstat -tlnp | grep :80

# Verificar firewall
sudo ufw status
```

### Logs Importantes

```bash
# Logs da aplicação
tail -f /var/log/biblioteca/monitor.log

# Logs do sistema
tail -f /var/log/syslog

# Logs do Docker
journalctl -u docker.service -f

# Logs do Ansible
tail -f ansible.log
```

### Comandos de Diagnóstico

```bash
# Status geral do sistema
./ansible/templates/dashboard.sh

# Auditoria de segurança
sudo /usr/local/bin/security-audit.sh

# Performance
./ansible/templates/performance.sh

# Health check
./ansible/templates/health-check.sh
```

## 🔄 Atualizações

### Atualizar Aplicação

```bash
# Via CI/CD (automático)
git push origin main

# Via Ansible (manual)
ansible-playbook -i inventory.ini deploy.yml --tags app
```

### Atualizar Infraestrutura

```bash
# Atualizar Terraform
terraform plan
terraform apply

# Atualizar configurações
ansible-playbook -i inventory.ini deploy.yml
```

## 📞 Suporte

Para problemas ou dúvidas:

1. Verifique os logs conforme indicado acima
2. Consulte a documentação oficial das ferramentas
3. Abra uma issue no repositório do projeto
4. Entre em contato com a equipe de DevOps

---

**Próximos Passos**: Após a instalação, consulte o [README.md](../README.md) para informações sobre uso e desenvolvimento.

