FROM lscr.io/linuxserver/code-server:latest

USER root

# Variables de entorno
ENV NODE_VERSION=20
ENV NVM_DIR=/usr/local/nvm

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    python3 \
    python3-pip \
    vim \
    nano \
    htop \
    tree \
    jq \
    zip \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Instalar NVM y Node.js
RUN mkdir -p $NVM_DIR \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm use $NODE_VERSION \
    && nvm alias default $NODE_VERSION

# Agregar Node.js al PATH
ENV PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# Instalar herramientas de desarrollo
RUN npm install -g \
    yarn \
    pnpm \
    typescript \
    ts-node \
    @types/node \
    nodemon \
    pm2 \
    express-generator \
    create-react-app \
    @angular/cli \
    @vue/cli \
    nestjs \
    vite

# Instalar VS Code extensions útiles
RUN mkdir -p /tmp/extensions \
    && cd /tmp/extensions \
    && wget https://github.com/microsoft/vscode-node-debug2/releases/download/v1.43.0/node-debug2-1.43.0.vsix \
    && code-server --install-extension ms-vscode.vscode-typescript-next \
    && code-server --install-extension bradlc.vscode-tailwindcss \
    && code-server --install-extension esbenp.prettier-vscode

# Configurar Git
RUN git config --system init.defaultBranch main \
    && git config --system pull.rebase false

USER abc

# Verificar instalaciones
RUN node --version && npm --version && git --version
