# Dockerfile para Frontend JavaScript
FROM nginx:alpine

# Instalar curl para health check
RUN apk add --no-cache curl

# Remover configuração padrão do nginx
RUN rm -rf /usr/share/nginx/html/*

# Copiar arquivos do frontend
COPY index.html /usr/share/nginx/html/
COPY styles.css /usr/share/nginx/html/
COPY script.js /usr/share/nginx/html/
COPY test.html /usr/share/nginx/html/

# Criar configuração customizada do nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expor porta 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Comando padrão do nginx
CMD ["nginx", "-g", "daemon off;"]

