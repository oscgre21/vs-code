# Usar la imagen base de LinuxServer code-server
FROM lscr.io/linuxserver/code-server:latest

# Establecer variables de entorno
ENV PUID=1000
ENV PGID=1000
ENV TZ=Etc/UTC
ENV PASSWORD=mi-password
ENV GIT_REPO_URL=""

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

# Instalar .NET Core 9.0
RUN wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y dotnet-sdk-9.0 \
    && rm -rf /var/lib/apt/lists/*

# Verificar que Node.js, npm, git y .NET estén instalados
RUN node --version && npm --version && git --version && dotnet --version

# Instalar herramientas globales de Node.js
RUN npm install -g \
    yarn \
    typescript \
    nodemon \
    pm2 \
    create-react-app \
    @angular/cli \
    @vue/cli

# Instalar Claude Code desde npm
RUN npm install -g @anthropic-ai/claude-code

# Verificar la instalación de Claude Code
RUN claude --version

# Crear script de inicialización para clonar repositorio
RUN echo '#!/bin/bash\n\
if [ ! -z "$GIT_REPO_URL" ] && [ ! -d "/config/workspace/.git" ]; then\n\
    echo "Clonando repositorio desde: $GIT_REPO_URL"\n\
    cd /config/workspace\n\
    git clone "$GIT_REPO_URL" .\n\
    echo "Repositorio clonado exitosamente"\n\
elif [ ! -z "$GIT_REPO_URL" ] && [ -d "/config/workspace/.git" ]; then\n\
    echo "El directorio ya contiene un repositorio Git"\n\
elif [ -z "$GIT_REPO_URL" ]; then\n\
    echo "No se especificó GIT_REPO_URL, omitiendo clonado"\n\
fi' > /usr/local/bin/clone-repo.sh && chmod +x /usr/local/bin/clone-repo.sh

# Crear script de inicialización personalizado
RUN echo '#!/bin/bash\n\
# Ejecutar script de clonado\n\
/usr/local/bin/clone-repo.sh\n\
\n\
# Continuar con la inicialización normal\n\
exec "$@"' > /custom-cont-init.d/01-clone-repo && chmod +x /custom-cont-init.d/01-clone-repo

# Copiar archivos de configuración personalizada (opcional)
# COPY custom-cont-init.d/ /custom-cont-init.d/

# Exponer los puertos
EXPOSE 8443 8080

# Configurar el directorio de trabajo
WORKDIR /config

# Configurar volúmenes
VOLUME ["/config", "/config/workspace", "/custom-cont-init.d"]

# El comando de inicio se hereda de la imagen base
