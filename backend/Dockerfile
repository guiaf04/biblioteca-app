# Dockerfile para Backend Java Spring Boot
FROM openjdk:17-jdk-slim as builder

# Instalar Maven
RUN apt-get update && apt-get install -y maven && rm -rf /var/lib/apt/lists/*

# Definir diretório de trabalho
WORKDIR /app

# Copiar arquivos de configuração do Maven
COPY pom.xml .

# Baixar dependências (cache layer)
RUN mvn dependency:go-offline -B

# Copiar código fonte
COPY src ./src

# Compilar aplicação
RUN mvn clean package -DskipTests

# Estágio final - runtime
FROM openjdk:17-jdk-slim

# Criar usuário não-root
RUN groupadd -r biblioteca && useradd -r -g biblioteca biblioteca

# Definir diretório de trabalho
WORKDIR /app

# Instala o curl para que o healthcheck do Docker Compose funcione
RUN apt-get update && apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

# Copiar JAR da aplicação do estágio builder
COPY --from=builder /app/target/*.jar app.jar

# Alterar proprietário dos arquivos
RUN chown -R biblioteca:biblioteca /app

# Mudar para usuário não-root
USER biblioteca

# Expor porta da aplicação
EXPOSE 8080

# Configurar variáveis de ambiente
ENV JAVA_OPTS="-Xmx512m -Xms256m"
ENV SPRING_PROFILES_ACTIVE=docker

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/api/livros/estatisticas || exit 1

# Comando para executar a aplicação
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]

