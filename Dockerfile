FROM lscr.io/linuxserver/code-server:latest

# Cambiar a root para instalar paquetes
USER root

# Actualizar sistema e instalar dependencias básicas
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    ca-certificates \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Instalar Node.js siguiendo la guía oficial de nodejs.org
# Método 1: Usando el script de instalación oficial de NodeSource (recomendado)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs

# Si el método anterior falla, usar la instalación desde binarios oficiales
# RUN NODE_VERSION="20.11.0" \
#     && curl -fsSL https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz -o node.tar.xz \
#     && tar -xJf node.tar.xz -C /usr/local --strip-components=1 \
#     && rm node.tar.xz

# Instalar Claude Code siguiendo la documentación oficial
# https://docs.anthropic.com/en/docs/claude-code/setup
RUN curl -fsSL https://storage.googleapis.com/claude-code/install.sh | bash

# Verificar que Node.js, npm, git y Claude Code estén instalados
RUN node --version && npm --version && git --version && claude-code --version

# Instalar herramientas globales de Node.js
RUN npm install -g \
    yarn \
    typescript \
    nodemon \
    pm2 \
    create-react-app \
    @angular/cli \
    @vue/cli

# Configurar git y Claude Code
RUN git config --system init.defaultBranch main

# Crear directorio para configuración de Claude Code
RUN mkdir -p /home/abc/.config/claude-code

# Nota: El usuario necesitará configurar su API key después del build
# Pueden hacerlo ejecutando: claude-code auth login
# O configurando la variable de entorno ANTHROPIC_API_KEY

# Volver al usuario original (abc que ya existe)
USER abc
