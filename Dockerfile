FROM lscr.io/linuxserver/code-server:latest

USER root

# Instalar Node.js usando snap (más confiable)
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Verificar instalación
RUN which node && which npm && node --version && npm --version

# Instalar solo las herramientas esenciales
RUN npm install -g yarn typescript nodemon

USER abc
