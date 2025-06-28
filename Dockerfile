FROM lscr.io/linuxserver/code-server:latest

# Cambiar a root para instalar paquetes
USER root

# Diagnóstico inicial - ver qué usuarios y directorios existen
RUN echo "=== DIAGNÓSTICO INICIAL ===" && \
    cat /etc/passwd | grep abc && \
    id abc && \
    echo "Directorio /config:" && ls -la /config || echo "/config no existe" && \
    echo "Directorio /home:" && ls -la /home || echo "/home no existe" && \
    echo "Directorio raíz abc:" && ls -la / | grep abc || echo "No hay directorio abc en raíz"

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

# Encontrar el directorio home real del usuario abc
RUN echo "=== ENCONTRANDO DIRECTORIO HOME ===" && \
    getent passwd abc | cut -d: -f6 && \
    ABC_HOME=$(getent passwd abc | cut -d: -f6) && \
    echo "Home directory de abc: $ABC_HOME" && \
    ls -la $ABC_HOME || echo "El directorio home no existe o no es accesible"

# Crear y configurar permisos de manera segura
RUN echo "=== CONFIGURANDO PERMISOS ===" && \
    # Crear /config si no existe
    mkdir -p /config && \
    # Crear subdirectorios necesarios
    mkdir -p /config/.config /config/.local /config/.cache /config/.npm && \
    # Obtener el directorio home real
    ABC_HOME=$(getent passwd abc | cut -d: -f6) && \
    # Crear el directorio home si no existe
    mkdir -p $ABC_HOME && \
    # Crear subdirectorios en el home
    mkdir -p $ABC_HOME/.config $ABC_HOME/.local $ABC_HOME/.cache $ABC_HOME/.npm && \
    # Cambiar propietario de /config
    chown -R abc:abc /config && \
    # Cambiar propietario del directorio home
    chown -R abc:abc $ABC_HOME && \
    # Establecer permisos
    chmod -R 755 /config && \
    chmod -R 755 $ABC_HOME

# Verificación final
RUN echo "=== VERIFICACIÓN FINAL ===" && \
    ls -la /config && \
    ABC_HOME=$(getent passwd abc | cut -d: -f6) && \
    ls -la $ABC_HOME && \
    echo "Permisos configurados correctamente"

# Volver al usuario original
USER abc

# Verificar que podemos escribir en los directorios
RUN echo "=== PRUEBA DE ESCRITURA ===" && \
    touch /config/.test_write && \
    rm /config/.test_write && \
    echo "Escritura en /config: OK" && \
    ABC_HOME=$(getent passwd abc | cut -d: -f6) && \
    touch $ABC_HOME/.test_write && \
    rm $ABC_HOME/.test_write && \
    echo "Escritura en home: OK"
