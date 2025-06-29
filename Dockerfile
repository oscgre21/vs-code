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

# Volver al usuario original (abc que ya existe)
USER abc
