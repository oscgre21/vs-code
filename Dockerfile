# Usar la imagen base de LinuxServer code-server
FROM lscr.io/linuxserver/code-server:latest

# Establecer variables de entorno
ENV PUID=1000
ENV PGID=1000
ENV TZ=Etc/UTC
ENV PASSWORD=mi-password

# Crear directorios necesarios
RUN mkdir -p /config /config/workspace /custom-cont-init.d

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

# Instalar Claude Code
# Descargar e instalar Claude Code desde el repositorio oficial
RUN curl -fsSL https://api.github.com/repos/anthropics/claude-code/releases/latest \
    | grep "browser_download_url.*linux-x64" \
    | cut -d '"' -f 4 \
    | wget -qi - -O /tmp/claude-code.tar.gz \
    && tar -xzf /tmp/claude-code.tar.gz -C /usr/local/bin/ \
    && chmod +x /usr/local/bin/claude-code \
    && rm /tmp/claude-code.tar.gz

# Verificar la instalación de Claude Code
RUN claude-code --version

# Copiar archivos de configuración personalizada (opcional)
# COPY custom-cont-init.d/ /custom-cont-init.d/

# Exponer los puertos
EXPOSE 8443 8080

# Configurar el directorio de trabajo
WORKDIR /config

# Configurar volúmenes
VOLUME ["/config", "/config/workspace", "/custom-cont-init.d"]

# El comando de inicio se hereda de la imagen base
