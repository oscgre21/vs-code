# Usar la imagen base de LinuxServer code-server
FROM lscr.io/linuxserver/code-server:latest

# Establecer variables de entorno
ENV PUID=1000
ENV PGID=1000
ENV TZ=Etc/UTC
ENV PASSWORD=mi-password
ENV GIT_REPO_URL=""
ENV GIT_USER_NAME="Gregorio Ramos"
ENV GIT_USER_EMAIL="oscgre21@gmail.com"

# Crear directorios necesarios y establecer permisos
RUN mkdir -p /config /config/workspace /custom-cont-init.d \
    && chown -R 1000:1000 /config

# Instalar procps para sysctl y configurar file watchers
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    ca-certificates \
    gnupg \
    lsb-release \
    procps \
    && rm -rf /var/lib/apt/lists/* \
    && echo 'fs.inotify.max_user_watches=524288' >> /etc/sysctl.conf \
    && echo 'fs.inotify.max_user_instances=256' >> /etc/sysctl.conf

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
# Intentar aumentar límite de file watchers (requiere privilegios)\n\
if [ -w /proc/sys/fs/inotify/max_user_watches ]; then\n\
    echo 524288 > /proc/sys/fs/inotify/max_user_watches\n\
    echo 256 > /proc/sys/fs/inotify/max_user_instances\n\
    echo "File watchers configurados correctamente"\n\
else\n\
    echo "ADVERTENCIA: No se pueden configurar file watchers. Ejecute el contenedor con --privileged o configure el host"\n\
    echo "En el host ejecute: echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p"\n\
fi\n\
\n\
# Configurar permisos ANTES de cualquier operación Git\n\
echo "Configurando permisos del workspace..."\n\
chown -R $PUID:$PGID /config/workspace\n\
chmod -R 755 /config/workspace\n\
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
# Clonar repositorio si se especifica\n\
if [ ! -z "$GIT_REPO_URL" ] && [ ! -d "/config/workspace/.git" ]; then\n\
    echo "Clonando repositorio desde: $GIT_REPO_URL"\n\
    cd /config/workspace\n\
    git clone "$GIT_REPO_URL" .\n\
    # Configurar el repositorio clonado para ignorar cambios de permisos\n\
    git config core.filemode false\n\
    echo "Repositorio clonado exitosamente con configuración de permisos"\n\
elif [ ! -z "$GIT_REPO_URL" ] && [ -d "/config/workspace/.git" ]; then\n\
    echo "El directorio ya contiene un repositorio Git"\n\
    cd /config/workspace\n\
    git config core.filemode false\n\
    echo "Configurado repositorio existente para ignorar cambios de permisos"\n\
elif [ -z "$GIT_REPO_URL" ]; then\n\
    echo "No se especificó GIT_REPO_URL, omitiendo clonado"\n\
fi\n\
\n\
# Verificar y corregir permisos finales sin afectar Git\n\
echo "Aplicando permisos finales..."\n\
find /config/workspace -type d -exec chmod 755 {} \\;\n\
find /config/workspace -type f -exec chmod 644 {} \\;\n\
chown -R $PUID:$PGID /config/workspace' > /usr/local/bin/clone-repo.sh && chmod +x /usr/local/bin/clone-repo.sh

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
