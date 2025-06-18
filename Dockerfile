# Usar imagen base con Node.js incluido
FROM node:20-bullseye

# Instalar dependencias para code-server
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Crear usuario
RUN useradd -m -u 1000 -G sudo abc \
    && echo 'abc ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Instalar code-server
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Instalar herramientas Node.js
RUN npm install -g \
    yarn \
    typescript \
    nodemon \
    pm2 \
    create-react-app \
    @angular/cli

# Configurar usuario y directorios
USER abc
WORKDIR /home/abc

# Crear directorios necesarios
RUN mkdir -p /home/abc/.local/share/code-server \
    && mkdir -p /home/abc/workspace

# Exponer puerto
EXPOSE 8443

# Comando por defecto
CMD ["code-server", "--bind-addr", "0.0.0.0:8443", "--auth", "password", "/home/abc/workspace"]
