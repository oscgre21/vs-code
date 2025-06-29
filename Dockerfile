# Usar la imagen base de LinuxServer code-server
FROM lscr.io/linuxserver/code-server:latest

# Establecer variables de entorno
ENV PUID=1000
ENV PGID=1000
ENV TZ=Etc/UTC
ENV PASSWORD=mi-password

# Crear directorios necesarios
RUN mkdir -p /config /config/workspace /custom-cont-init.d

# Copiar archivos de configuración personalizada (opcional)
# COPY custom-cont-init.d/ /custom-cont-init.d/

# Exponer los puertos
EXPOSE 8443 8080

# Configurar el directorio de trabajo
WORKDIR /config

# Configurar volúmenes
VOLUME ["/config", "/config/workspace", "/custom-cont-init.d"]

# El comando de inicio se hereda de la imagen base
