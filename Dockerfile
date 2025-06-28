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

# NOTA: Claude Code está en research preview y no tiene instalador público disponible
# Para instalarlo, sigue las instrucciones oficiales en:
# https://docs.anthropic.com/en/docs/claude-code/setup
# Una vez que esté disponible públicamente, se puede instalar con:
# RUN curl -fsSL https://storage.googleapis.com/claude-code/install.sh | bash

# Verificar que Node.js, npm y git estén instalados
RUN node --version && npm --version && git --version

# Instalar herramientas globales de Node.js
RUN npm install -g \
    yarn \
    typescript \
    nodemon \
    pm2 \
    create-react-app \
    @angular/cli \
    @vue/cli

# Configurar git
RUN git config --system init.defaultBranch main

# Volver al usuario original (abc que ya existe) pero crear los directorios primero
# Y configurar el volumen /config para que sea propiedad del usuario abc
RUN mkdir -p /config/.config /config/workspace /config/data /config/extensions \
    && chown -R abc:abc /config \
    && chmod -R 755 /config

USER abc

# Crear variable de entorno para evitar problemas de permisos
ENV HOME=/config
