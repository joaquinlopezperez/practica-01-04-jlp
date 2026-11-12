# Comprobamos si Apache ya esta instalado
if dpkg -s apache2 >/dev/null 2>&1; then
    echo "Apache ya está instalado."
    exit 0
fi

# Actualizamos la lista de paquetes
sudo apt update

# Instalamos Apache sin intervencion del usuario
sudo DEBIAN_FRONTEND=noninteractive apt install -y apache2

# Habilitamos Apache para que arranque automaticamente
sudo systemctl enable apache2

# Iniciamos Apache
sudo systemctl start apache2

# Mandamos un mensaje de confirmacion
echo "Apache se ha instalado correctamente."
