# Usar la imagen base de LinuxServer code-server
FROM lscr.io/linuxserver/code-server:latest

# Establecer variables de entorno
ENV PUID=1000
ENV PGID=1000
ENV TZ=Etc/UTC
ENV PASSWORD=mi-password
ENV GIT_REPO_URL=""
ENV GIT_USER_NAME=""
ENV GIT_USER_EMAIL=""

# Crear directorios necesarios y establecer permisos
RUN mkdir -p /config /config/workspace /config/.claude /config/.cache /custom-cont-init.d \
    && chown -R 1000:1000 /config

# Instalar dependencias del sistema - PASO A PASO para mejor debug
RUN apt-get update

RUN apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    ca-certificates \
    gnupg \
    lsb-release \
    procps

RUN apt-get install -y \
    python3 \
    python3-dev \
    python3-pip \
    python3-setuptools

RUN apt-get install -y \
    make \
    g++ \
    gcc \
    libc6-dev \
    libsqlite3-dev \
    pkg-config

# Limpiar cache
RUN rm -rf /var/lib/apt/lists/*

# Configurar límites de file watchers
RUN echo 'fs.inotify.max_user_watches=524288' >> /etc/sysctl.conf \
    && echo 'fs.inotify.max_user_instances=256' >> /etc/sysctl.conf

# Instalar distutils para Python (necesario para node-gyp)
RUN pip3 install --break-system-packages setuptools wheel

# Crear enlaces simbólicos para compatibilidad
RUN ln -sf /usr/bin/python3 /usr/bin/python

# Instalar Node.js LTS
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
RUN apt-get install -y nodejs
RUN rm -rf /var/lib/apt/lists/*

# Las configuraciones de Python para npm ahora se manejan con variables de entorno
# que ya están configuradas más abajo en el Dockerfile

# Instalar .NET Core 9.0 - Detectar arquitectura y usar el paquete correcto
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
        dpkg -i packages-microsoft-prod.deb && \
        rm packages-microsoft-prod.deb && \
        apt-get update && \
        apt-get install -y dotnet-sdk-9.0; \
    elif [ "$ARCH" = "arm64" ]; then \
        wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh && \
        chmod +x dotnet-install.sh && \
        ./dotnet-install.sh --channel 9.0 --install-dir /usr/share/dotnet && \
        ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet && \
        rm dotnet-install.sh; \
    fi
RUN rm -rf /var/lib/apt/lists/*

# Verificar que las herramientas estén instaladas
RUN node --version && npm --version && git --version && python --version && (dotnet --version || echo ".NET Core no instalado")

# Instalar herramientas globales de Node.js
RUN npm install -g yarn typescript nodemon pm2 create-react-app @angular/cli @vue/cli node-gyp

# Instalar Claude Code desde npm
RUN npm install -g @anthropic-ai/claude-code

# Verificar la instalación de Claude Code
RUN claude --version

# Crear script de inicialización para clonar repositorio
RUN echo '#!/bin/bash\n\
# Intentar aumentar límite de file watchers\n\
if [ -w /proc/sys/fs/inotify/max_user_watches ]; then\n\
    echo 524288 > /proc/sys/fs/inotify/max_user_watches\n\
    echo 256 > /proc/sys/fs/inotify/max_user_instances\n\
    echo "File watchers configurados correctamente"\n\
else\n\
    echo "ADVERTENCIA: No se pueden configurar file watchers. Configure el host:"\n\
    echo "echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p"\n\
fi\n\
\n\
# Configurar usuario Git global\n\
if [ ! -z "$GIT_USER_NAME" ]; then\n\
    git config --global user.name "$GIT_USER_NAME"\n\
    echo "Configurado Git user.name: $GIT_USER_NAME"\n\
fi\n\
\n\
if [ ! -z "$GIT_USER_EMAIL" ]; then\n\
    git config --global user.email "$GIT_USER_EMAIL"\n\
    echo "Configurado Git user.email: $GIT_USER_EMAIL"\n\
fi\n\
\n\
# Configurar Git para ignorar cambios de permisos\n\
git config --global core.filemode false\n\
echo "Git configurado para ignorar cambios de permisos"\n\
\n\
# Aplicar ownership y permisos al directorio workspace ANTES de clonar\n\
echo "Configurando ownership y permisos del workspace antes de clonar..."\n\
chown -R $PUID:$PGID /config/workspace\n\
chmod -R 755 /config/workspace\n\
\n\
# Clonar repositorio si se especifica\n\
if [ ! -z "$GIT_REPO_URL" ] && [ ! -d "/config/workspace/.git" ]; then\n\
    echo "Clonando repositorio desde: $GIT_REPO_URL"\n\
    cd /config/workspace\n\
    git clone "$GIT_REPO_URL" .\n\
    git config core.filemode false\n\
    echo "Repositorio clonado exitosamente"\n\
elif [ ! -z "$GIT_REPO_URL" ] && [ -d "/config/workspace/.git" ]; then\n\
    echo "El directorio ya contiene un repositorio Git"\n\
    cd /config/workspace\n\
    git config core.filemode false\n\
fi\n\
\n\
# Aplicar permisos finales a directorios de configuración\n\
echo "Aplicando permisos finales a directorios de configuración..."\n\
chown -R $PUID:$PGID /config/.claude /config/.cache 2>/dev/null || true\n\
chmod -R 755 /config/.claude /config/.cache 2>/dev/null || true\n\
\n\
echo "Inicialización completada"' > /usr/local/bin/clone-repo.sh

RUN chmod +x /usr/local/bin/clone-repo.sh

# Crear script de inicialización personalizado
RUN echo '#!/bin/bash\n\
# Configurar variables de entorno para compilación\n\
export PYTHON=/usr/bin/python3\n\
export CXX=g++\n\
export CC=gcc\n\
export npm_config_python=/usr/bin/python3\n\
\n\
# Ejecutar script de clonado\n\
/usr/local/bin/clone-repo.sh\n\
\n\
# Continuar con la inicialización normal\n\
exec "$@"' > /custom-cont-init.d/01-clone-repo

RUN chmod +x /custom-cont-init.d/01-clone-repo

# Configurar variables de entorno permanentes para compilación
ENV PYTHON=/usr/bin/python3
ENV CXX=g++
ENV CC=gcc
ENV npm_config_python=/usr/bin/python3

# Exponer los puertos
EXPOSE 8443 8080

# Configurar el directorio de trabajo
WORKDIR /config

# Configurar volúmenes
VOLUME ["/config", "/config/workspace", "/custom-cont-init.d"]

# El comando de inicio se hereda de la imagen base
