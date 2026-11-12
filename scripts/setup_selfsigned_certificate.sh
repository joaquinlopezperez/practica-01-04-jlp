#!/usr/bin/env bash
# Crea un certificado autofirmado y configura los virtual hosts HTTP (redirección) y HTTPS.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$SCRIPT_DIR/.env"
CONF_DIR="$REPO_DIR/conf"

if [[ $EUID -ne 0 ]]; then
    echo "Ejecuta este script con sudo." >&2
    exit 1
fi

# 1. Apache debe estar instalado
if ! dpkg -s apache2 2>/dev/null | grep -q '^Status: install ok installed'; then
    echo "Apache no está instalado. Ejecuta antes ./scripts/install_apache.sh" >&2
    exit 1
fi

# 2. Leer variables del .env
if [[ ! -f "$ENV_FILE" ]]; then
    echo "No existe $ENV_FILE. Copia scripts/.env.example a scripts/.env y edítalo." >&2
    exit 1
fi
set -a
source "$ENV_FILE"
set +a

for var in CERT_C CERT_ST CERT_L CERT_O CERT_OU CERT_EMAIL DOMAIN ELASTIC_IP \
           CERT_DAYS KEY_PATH CRT_PATH SITES_AVAILABLE; do
    if [[ -z "${!var:-}" ]]; then
        echo "Falta la variable $var en $ENV_FILE" >&2
        exit 1
    fi
done

# 3. Crear clave privada y certificado con subjectAltName (dominio + IP elástica)
echo "Generando certificado autofirmado para $DOMAIN / $ELASTIC_IP ..."
openssl req -x509 -nodes -days "$CERT_DAYS" -newkey rsa:2048 \
    -keyout "$KEY_PATH" \
    -out "$CRT_PATH" \
    -subj "/C=$CERT_C/ST=$CERT_ST/L=$CERT_L/O=$CERT_O/OU=$CERT_OU/CN=$DOMAIN/emailAddress=$CERT_EMAIL" \
    -addext "subjectAltName=DNS:$DOMAIN,IP:$ELASTIC_IP"

chmod 600 "$KEY_PATH"
chmod 644 "$CRT_PATH"

# 4. Copiar plantillas de conf/ y sustituir los marcadores
for conf in 000-default.conf practica-https-ssl.conf; do
    install -m 644 "$CONF_DIR/$conf" "$SITES_AVAILABLE/$conf"
    sed -i \
        -e "s|__DOMAIN__|$DOMAIN|g" \
        -e "s|__CRT_PATH__|$CRT_PATH|g" \
        -e "s|__KEY_PATH__|$KEY_PATH|g" \
        "$SITES_AVAILABLE/$conf"
done

# 5. Habilitar módulos y sitios
a2enmod ssl rewrite
a2ensite 000-default.conf practica-https-ssl.conf

# 6. Comprobar configuración antes de reiniciar
if ! apache2ctl configtest; then
    echo "La configuración de Apache tiene errores. No se reinicia el servicio." >&2
    exit 1
fi

systemctl restart apache2
echo "HTTPS configurado. Prueba: curl -kI https://$DOMAIN"
