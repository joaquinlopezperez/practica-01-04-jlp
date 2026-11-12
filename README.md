# Práctica 1.4 — HTTPS con certificado autofirmado en Apache

## 1. Descripción de la práctica
 
En esta práctica se ha configurado un servidor web Apache en una instancia de Amazon EC2 con Ubuntu Server, habilitando el protocolo HTTPS mediante un certificado digital autofirmado.
 
## 2. Entorno de trabajo
 
Para realizar la práctica se han utilizado las siguientes herramientas y tecnologías:
 
- **Amazon Web Services (AWS):** servicio utilizado para crear y administrar la instancia EC2.
- **Ubuntu Server:** sistema operativo instalado en la instancia.
- **Apache2:** servidor web encargado de servir el contenido.
- **OpenSSL:** herramienta utilizada para generar el certificado autofirmado.
- **Git y GitHub:** herramientas utilizadas para gestionar y almacenar el proyecto.
- **HTTPS/TLS:** protocolo utilizado para establecer conexiones cifradas.
### Datos de configuración
 
| Elemento | Valor |
|---|---|
| Sistema operativo | Ubuntu Server|
| Tipo de instancia | t2.micro |
| Servidor web | Apache2 |
| Dominio | practica-https.test |
| Puerto HTTP | 80 |
| Puerto HTTPS | 443 |

 
## 3. Organización del repositorio
 
El repositorio contiene la siguiente estructura:
 
```
practica-01-04-jlp/
│
├── README.md
├── .gitignore
│
├── conf/
│   ├── 000-default.conf
│   └── practica-https-ssl.conf
│
└── scripts/
    ├── .env.example
    ├── install_apache.sh
    └── setup_selfsigned_certificate.sh
```
 
### Descripción de los archivos
 
- **README.md:** documentación del proyecto y explicación de las pruebas realizadas.
- **.gitignore:** impide subir al repositorio el .env real y las claves privadas.
- **conf/000-default.conf:** virtual host del puerto 80, que redirige todo a HTTPS.
- **conf/practica-https-ssl.conf:** virtual host del puerto 443, con las rutas del certificado y de la clave.
- **scripts/.env.example:** plantilla con todas las variables que necesita el script del certificado.
- **scripts/install_apache.sh:** instala Apache; si ya estaba instalado, avisa y no hace nada.
- **scripts/setup_selfsigned_certificate.sh:** genera el certificado y deja Apache configurado para HTTPS.
## 4. Creación y configuración de la instancia EC2
 
Se lanzó una instancia EC2 con la imagen oficial de Ubuntu Server LTS. En su grupo de seguridad se abrieron únicamente los puertos que hacen falta:
 
- **22 (SSH):** para conectarme y administrar la máquina.
- **80 (HTTP):** para comprobar la redirección.
- **443 (HTTPS):** para el acceso cifrado.
Después se le asoció una IP elástica, `34.194.11.140`, de forma que la dirección pública no cambia aunque la instancia se pare y se vuelva a arrancar.
 
Ya dentro de la máquina por SSH, se clonó el repositorio y se dieron permisos de ejecución a los scripts.
 
## 5. Instalación de Apache

Una vez conectados a la instancia, ejecutamos el script install_apache.sh.

### Evidencia 1: instalación y estado del servicio

```bash
sudo ./scripts/install_apache.sh
systemctl status apache2
```
 
La instalación se completa sin intervención y el servicio aparece como `active (running)` y `enabled`.
 
<img width="896" height="100" alt="image" src="https://github.com/user-attachments/assets/605bb058-1904-419e-856f-5013e1fb194e" />

<img width="896" height="90" alt="image" src="https://github.com/user-attachments/assets/11c2e4f9-1089-424e-b3b5-2b4c1fbf0351" />

<img width="895" height="357" alt="image" src="https://github.com/user-attachments/assets/5b263c66-bc07-4c89-88f0-a6ca13e8ada4" />

### Evidencia 2: segunda ejecución del script
 
```bash
sudo ./scripts/install_apache.sh
```
 
Al repetirlo, el script detecta Apache y solo muestra `Apache ya está instalado.`

<img width="894" height="93" alt="image" src="https://github.com/user-attachments/assets/5fd32e88-36c0-40d6-9eaa-f1dc0576a642" />

## 6. Creación del certificado
 
Todos los datos del certificado se leen de un archivo `scripts/.env`, que se crea copiando la plantilla y editando los valores (en mi caso, la IP elástica).



### Evidencia 3: datos del certificado
 
```bash
openssl x509 -in /etc/ssl/certs/apache-selfsigned.crt -noout -subject -dates -ext subjectAltName
```

Los pasos que hace el script son:
 
1. Comprueba que Apache está instalado.
2. Lee las variables del `.env`.
3. Genera el certificado y la clave con `openssl`.
4. Copia las configuraciones de `conf/` a Apache.
5. Activa los módulos y los sitios.
6. Comprueba la sintaxis y reinicia Apache.

Se ve el sujeto definido en el `.env`, las fechas de inicio y fin con 365 días de diferencia, y el dominio junto a la IP en el SAN.
 
<img width="967" height="155" alt="evidencia3" src="https://github.com/user-attachments/assets/f8a0798a-298f-4981-808a-584f1cbd56b1" />

## 7. Virtual hosts de Apache

Las dos plantillas de `conf/` definen cómo responde Apache en cada puerto.
 
**Puerto 443 (`practica-https-ssl.conf`).** Activa el motor TLS con `SSLEngine on` y apunta, con `SSLCertificateFile` y `SSLCertificateKeyFile`, al certificado y a la clave creados por el script.
 
**Puerto 80 (`000-default.conf`).** No sirve contenido: reenvía cualquier petición a la versión segura con esta regla.

### Evidencia 4: comprobación de sintaxis
 
```bash
sudo apache2ctl configtest
```
 
Devuelve `Syntax OK`, por lo que la configuración es válida.
 
<img width="965" height="98" alt="evidencia4" src="https://github.com/user-attachments/assets/22ae4811-7cf2-491f-b5ff-755aaa65a19e" />

### Evidencia 5: puertos en escucha
 
```bash
sudo ss -tlnp | grep apache2
```
 
Apache aparece escuchando en los puertos 80 y 443.
 
<img width="962" height="142" alt="evidencia5" src="https://github.com/user-attachments/assets/aeb48f37-250f-48f9-a90d-764cf08c8c0c" />

## 8. Pruebas desde mi ordenador
 
Mi equipo es Windows. Para que el dominio de pruebas se resuelva, he añadido esta línea al final de `C:\Windows\System32\drivers\etc\hosts` (editado con permisos de administrador):
 
```
34.194.11.140   practica-https.test
```
 
Las dos pruebas siguientes se hacen desde mi equipo y no desde la instancia, así que sirven también para confirmar que el grupo de seguridad deja pasar el tráfico. En PowerShell se usa `curl.exe`, porque `curl` a secas es un alias de otro comando.

### Evidencia 6: redirección de HTTP a HTTPS
 
```powershell
curl.exe -I http://practica-https.test
```
 
La respuesta es `HTTP/1.1 301`.
 
<img width="1097" height="202" alt="evidencia6" src="https://github.com/user-attachments/assets/298e5ac5-9d8e-47ca-a39c-27a5ca6caae4" />

### Evidencia 7: respuesta por HTTPS
 
```powershell
curl.exe -kI https://practica-https.test
```
 
El servidor contesta `HTTP/1.1 200 OK`. El parámetro `-k` es necesario para que `curl` acepte un certificado que no está firmado por una autoridad reconocida.
 
<img width="1101" height="274" alt="evidencia7" src="https://github.com/user-attachments/assets/26b193d2-2e37-4ac8-b858-770cb43585b0" />

## 9. Comprobación del cifrado TLS
 
### Evidencia 8: negociación TLS
 
```bash
openssl s_client -connect localhost:443 -servername practica-https.test < /dev/null
```
 
Esta prueba se lanza desde la propia instancia. Muestra la versión de TLS acordada, el cifrado elegido y el certificado que presenta el servidor. Aparece un aviso de certificado autofirmado, que es el comportamiento esperado.

<img width="968" height="403" alt="evidencia8 1" src="https://github.com/user-attachments/assets/20e0e539-1aaf-407e-b69a-94704b6c9f6a" />
<img width="968" height="419" alt="evidencia8 2" src="https://github.com/user-attachments/assets/cda06d69-7f14-4b3f-9370-8e1ba14f794c" />

## 10. Prueba en el navegador
 
### Evidencia 9: acceso con el navegador
 
Al abrir `https://practica-https.test` el navegador no reconoce quién firmó el certificado y lo indica con una pantalla de advertencia. Si se decide continuar, se carga la página de Apache; esa excepción solo vale para ese sitio y el certificado no se instala como de confianza en el sistema.
 
Pantalla de advertencia:
 
<img width="1638" height="937" alt="evidencia 9" src="https://github.com/user-attachments/assets/1ceaf8dd-cf36-4626-aa5b-143233a91013" />

 
Página de Apache tras continuar:
 
<img width="1653" height="677" alt="evidencia9 2" src="https://github.com/user-attachments/assets/4862f2a1-6356-4f7a-8b42-149d51167c71" />

## 11. Conclusiones
 
La práctica ha servido para montar de principio a fin un servidor con HTTPS: desde crear la máquina y abrir los puertos, hasta generar el certificado, configurar los virtual hosts y verificar el resultado desde fuera. Dejarlo todo en scripts hace que se pueda repetir en otra instancia sin errores manuales, y que se lea cada dato de un `.env` evita tener valores escritos a fuego en el código.
