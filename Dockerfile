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
# Usando el script de instalación oficial de NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs

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

# Crear y configurar permisos para el directorio de configuración
RUN mkdir -p /config/.config /config/.local /config/.cache && \
    chown -R abc:abc /config && \
    chmod -R 755 /config

# Crear directorio home para el usuario abc y configurar permisos
RUN mkdir -p /home/abc/.config /home/abc/.local /home/abc/.cache && \
    chown -R abc:abc /home/abc && \
    chmod -R 755 /home/abc

# Verificar que el usuario abc existe y mostrar información
RUN id abc && ls -la /config && ls -la /home/abc

# Volver al usuario original (abc que ya existe)
USER abc
