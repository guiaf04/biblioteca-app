# Sistema de Biblioteca

Uma aplicação completa de gerenciamento de biblioteca desenvolvida com backend Java (Spring Boot) e frontend JavaScript puro, incluindo containerização Docker, pipeline CI/CD e infraestrutura como código.

## 🚀 Características

- **Backend**: Java 17 + Spring Boot + JPA/Hibernate
- **Frontend**: JavaScript puro + HTML5 + CSS3
- **Banco de Dados**: H2 (em memória)
- **Containerização**: Docker + Docker Compose
- **CI/CD**: GitHub Actions
- **Infraestrutura**: Terraform + Ansible
- **Cloud**: AWS EC2 + ECR
- **Monitoramento**: CloudWatch + Scripts customizados
- **Segurança**: UFW + Fail2ban + SSL/TLS

## 📋 Funcionalidades

### Backend (API REST)
- ✅ CRUD completo de livros
- ✅ Busca por título, autor ou editora
- ✅ Filtros por disponibilidade
- ✅ Estatísticas da biblioteca
- ✅ Validação de dados
- ✅ Tratamento de erros
- ✅ Documentação automática da API

### Frontend
- ✅ Interface responsiva e moderna
- ✅ Listagem de livros com paginação
- ✅ Formulários para adicionar/editar livros
- ✅ Busca em tempo real
- ✅ Filtros dinâmicos
- ✅ Notificações toast
- ✅ Confirmação de exclusão

### DevOps
- ✅ Dockerização completa
- ✅ Pipeline CI/CD automatizada
- ✅ Testes automatizados
- ✅ Deploy automatizado na AWS
- ✅ Monitoramento e logs
- ✅ Backup automatizado
- ✅ Segurança configurada

## 🏗️ Arquitetura

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │    Backend      │    │   Banco H2      │
│  (JavaScript)   │◄──►│  (Spring Boot)  │◄──►│  (Em Memória)   │
│   Port: 80      │    │   Port: 8080    │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Docker        │
                    │   Compose       │
                    └─────────────────┘
```

## 🛠️ Tecnologias Utilizadas

### Backend
- **Java 17**: Linguagem de programação
- **Spring Boot 3.1**: Framework principal
- **Spring Data JPA**: Persistência de dados
- **H2 Database**: Banco de dados em memória
- **Maven**: Gerenciamento de dependências
- **JUnit 5**: Testes unitários

### Frontend
- **HTML5**: Estrutura da página
- **CSS3**: Estilização e responsividade
- **JavaScript ES6+**: Lógica da aplicação
- **Font Awesome**: Ícones
- **Fetch API**: Comunicação com backend

### DevOps
- **Docker**: Containerização
- **Docker Compose**: Orquestração de containers
- **GitHub Actions**: CI/CD
- **Terraform**: Infraestrutura como código
- **Ansible**: Automação de configuração
- **AWS EC2**: Hospedagem
- **AWS ECR**: Registro de imagens Docker

## 📦 Estrutura do Projeto

```
biblioteca-app/
├── backend/                 # Aplicação Spring Boot
│   ├── src/
│   │   ├── main/java/      # Código fonte Java
│   │   ├── main/resources/ # Configurações
│   │   └── test/           # Testes
│   ├── Dockerfile          # Imagem Docker do backend
│   └── pom.xml            # Dependências Maven
├── frontend/               # Aplicação JavaScript
│   ├── index.html         # Página principal
│   ├── styles.css         # Estilos CSS
│   ├── script.js          # Lógica JavaScript
│   ├── test.html          # Página de testes
│   ├── Dockerfile         # Imagem Docker do frontend
│   └── nginx.conf         # Configuração Nginx
├── docker/                # Scripts Docker
│   ├── build.sh          # Script de build
│   └── stop.sh           # Script de parada
├── terraform/             # Infraestrutura como código
│   ├── main.tf           # Configuração principal
│   ├── variables.tf      # Variáveis
│   ├── outputs.tf        # Outputs
│   └── user-data.sh      # Script de inicialização
├── ansible/               # Automação de deploy
│   ├── deploy.yml        # Playbook principal
│   ├── tasks/            # Tarefas específicas
│   └── templates/        # Templates de configuração
├── .github/workflows/     # Pipeline CI/CD
│   ├── ci.yml           # Integração contínua
│   ├── cd.yml           # Deploy contínuo
│   └── cleanup.yml      # Limpeza e rollback
├── docker-compose.yml    # Orquestração local
└── README.md            # Este arquivo
```

## 🚀 Como Executar

### Pré-requisitos
- Docker e Docker Compose
- Java 17 (para desenvolvimento)
- Maven (para desenvolvimento)
- Node.js (para testes frontend)

### Execução Local

1. **Clone o repositório**
```bash
git clone <repository-url>
cd biblioteca-app
```

2. **Execute com Docker Compose**
```bash
# Build e execução
./docker/build.sh

# Ou manualmente
docker-compose up -d
```

3. **Acesse a aplicação**
- Frontend: http://localhost
- Backend API: http://localhost:8080/api/livros
- Testes Frontend: http://localhost/test

### Desenvolvimento

1. **Backend**
```bash
cd backend
mvn spring-boot:run
```

2. **Frontend**
```bash
cd frontend
# Servir com qualquer servidor HTTP
python3 -m http.server 3000
# ou
npx http-server -p 3000
```

## 🧪 Testes

### Backend
```bash
cd backend
mvn test
```

### Frontend
Abra `frontend/test.html` no navegador ou execute:
```bash
cd frontend
npx http-server -p 3000
# Acesse http://localhost:3000/test.html
```

## 🌐 Deploy na AWS

### Pré-requisitos
- Conta AWS configurada
- Terraform instalado
- Ansible instalado
- Chave SSH configurada

### Deploy Automático (CI/CD)

1. **Configure secrets no GitHub**
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
EC2_SSH_PRIVATE_KEY
```

2. **Push para branch main**
```bash
git push origin main
```

O pipeline automaticamente:
- Executa testes
- Constrói imagens Docker
- Faz push para ECR
- Provisiona infraestrutura
- Faz deploy da aplicação

### Deploy Manual

1. **Provisionar infraestrutura**
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edite terraform.tfvars com suas configurações
terraform init
terraform plan
terraform apply
```

2. **Deploy da aplicação**
```bash
cd ansible
# Configure inventory.ini com IP da instância
ansible-playbook -i inventory.ini deploy.yml
```

## 📊 Monitoramento

### Logs
```bash
# Logs da aplicação
docker-compose logs -f

# Logs do sistema
tail -f /var/log/biblioteca/monitor.log
```

### Métricas
- CloudWatch (AWS)
- Scripts de monitoramento customizados
- Dashboard web simples

### Health Checks
- Backend: `GET /api/livros/estatisticas`
- Frontend: `GET /`
- Containers: Docker health checks

## 🔒 Segurança

### Implementado
- ✅ Firewall UFW configurado
- ✅ Fail2ban para proteção SSH
- ✅ SSL/TLS (configurável)
- ✅ Atualizações automáticas
- ✅ Usuário não-root nos containers
- ✅ Secrets management
- ✅ Network isolation

### Recomendações Adicionais
- Configure SSL/TLS com certificado válido
- Use AWS Secrets Manager para credenciais
- Configure backup regular
- Monitore logs de segurança
- Mantenha dependências atualizadas

## 🔧 Configuração

### Variáveis de Ambiente

#### Backend
```bash
SPRING_PROFILES_ACTIVE=docker
JAVA_OPTS=-Xmx512m -Xms256m
AWS_REGION=us-east-1
```

#### Frontend
```bash
API_BASE_URL=http://localhost:8080/api
```

### Configurações Terraform
Veja `terraform/terraform.tfvars.example` para todas as opções disponíveis.

### Configurações Ansible
Veja `ansible/inventory.ini` para configurações de hosts.

## 📚 API Documentation

### Endpoints Principais

#### Livros
- `GET /api/livros` - Listar todos os livros
- `GET /api/livros/{id}` - Buscar livro por ID
- `POST /api/livros` - Criar novo livro
- `PUT /api/livros/{id}` - Atualizar livro
- `DELETE /api/livros/{id}` - Deletar livro
- `GET /api/livros/buscar?termo={termo}` - Buscar livros
- `GET /api/livros/disponiveis` - Listar livros disponíveis
- `GET /api/livros/estatisticas` - Estatísticas da biblioteca

### Exemplo de Payload

```json
{
  "titulo": "Dom Casmurro",
  "autor": "Machado de Assis",
  "isbn": "978-85-359-0277-5",
  "anoPublicacao": 1899,
  "editora": "Companhia das Letras",
  "descricao": "Romance clássico da literatura brasileira",
  "disponivel": true
}
```

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 👥 Autores

- **DevOps Team** - *Desenvolvimento inicial* - [GitHub](https://github.com)

## 🙏 Agradecimentos

- Spring Boot community
- Docker community
- AWS documentation
- Open source contributors

---

**Nota**: Este é um projeto de demonstração para fins educacionais e de portfólio. Para uso em produção, considere implementar funcionalidades adicionais de segurança e performance.

