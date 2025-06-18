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

# Instalar Node.js usando el método oficial de NodeSource
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | gpg --dearmor -o /usr/share/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x $(lsb_release -cs) main" > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y nodejs

# Verificar que Node.js y npm estén instalados correctamente
RUN node --version && npm --version

# Instalar herramientas globales de Node.js (separadas para mejor debugging)
RUN npm install -g yarn
RUN npm install -g typescript
RUN npm install -g nodemon
RUN npm install -g pm2
RUN npm install -g create-react-app
RUN npm install -g @angular/cli
RUN npm install -g @vue/cli

# Configurar git globalmente
RUN git config --system init.defaultBranch main

# Volver al usuario original
USER abc

# Verificar instalaciones finales
RUN node --version && npm --version && git --version
