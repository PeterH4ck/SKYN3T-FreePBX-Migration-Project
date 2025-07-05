# 🚀 INSTALACIÓN FREEPBX - COMANDOS PASO A PASO

## 📦 **PASO 1: INSTALACIÓN DE DEPENDENCIAS**

### **A. Herramientas básicas**
```bash
# Instalar tree y herramientas útiles
sudo apt install -y tree curl wget git nano

# Verificar estructura creada
tree /opt/freepbx

# Configurar variables de entorno
sudo tee -a /etc/environment <<EOF

# FreePBX Configuration
FREEPBX_WEB_PORT=8080
ASTERISK_SIP_PORT=5060
RTP_START=10000
RTP_END=20000
PBX_DB_NAME=freepbx_skyn3t
EOF

source /etc/environment
echo "Variables configuradas correctamente"
```

### **B. Instalar Apache en puerto 8080**
```bash
# Instalar Apache
sudo apt install -y apache2

# Configurar Apache para puerto 8080 (no interferir con nginx futuro)
sudo sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf
sudo sed -i 's/:80>/:8080>/' /etc/apache2/sites-available/000-default.conf

# Habilitar módulos necesarios
sudo a2enmod rewrite ssl headers

# Iniciar Apache
sudo systemctl start apache2
sudo systemctl enable apache2

# Verificar Apache en puerto 8080
curl -I http://localhost:8080
echo "Apache configurado en puerto 8080 ✅"
```

### **C. Instalar MariaDB**
```bash
# Instalar MariaDB
sudo apt install -y mariadb-server mariadb-client

# Iniciar MariaDB
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Configuración segura de MariaDB
sudo mysql_secure_installation
```

**IMPORTANTE**: Cuando ejecutes `mysql_secure_installation`, responde:
- Switch to unix_socket authentication: **N**
- Change root password: **Y** (usa: `FreePBX_Root_2025!`)
- Remove anonymous users: **Y**
- Disallow root login remotely: **Y**
- Remove test database: **Y**
- Reload privilege tables: **Y**

### **D. Crear base de datos FreePBX**
```bash
# Crear base de datos y usuario para FreePBX
sudo mysql -u root -p <<EOF
CREATE DATABASE freepbx_skyn3t;
CREATE USER 'freepbxuser'@'localhost' IDENTIFIED BY 'FreePBX_SKYN3T_2025!';
GRANT ALL PRIVILEGES ON freepbx_skyn3t.* TO 'freepbxuser'@'localhost';
FLUSH PRIVILEGES;
SHOW DATABASES;
EXIT;
EOF

echo "Base de datos FreePBX creada ✅"
```

### **E. Instalar PHP 8.1 y extensiones**
```bash
# Instalar PHP y todas las extensiones necesarias
sudo apt install -y \
  php8.1 php8.1-cli php8.1-common php8.1-curl php8.1-mbstring \
  php8.1-mysql php8.1-xml php8.1-zip php8.1-gd php8.1-intl \
  php8.1-bcmath php8.1-json php8.1-soap php8.1-xmlrpc \
  libapache2-mod-php8.1

# Configurar PHP para FreePBX
sudo sed -i 's/upload_max_filesize = .*/upload_max_filesize = 120M/' /etc/php/8.1/apache2/php.ini
sudo sed -i 's/memory_limit = .*/memory_limit = 256M/' /etc/php/8.1/apache2/php.ini
sudo sed -i 's/post_max_size = .*/post_max_size = 120M/' /etc/php/8.1/apache2/php.ini
sudo sed -i 's/max_execution_time = .*/max_execution_time = 300/' /etc/php/8.1/apache2/php.ini

# Reiniciar Apache para aplicar cambios PHP
sudo systemctl restart apache2

echo "PHP 8.1 configurado para FreePBX ✅"
```

## 🔧 **PASO 2: PREPARACIÓN PARA ASTERISK**

### **A. Crear usuario asterisk**
```bash
# Crear usuario y grupos para Asterisk
sudo useradd -r -d /var/lib/asterisk -s /bin/bash asterisk
sudo usermod -aG audio,dialout asterisk

# Crear directorios para Asterisk
sudo mkdir -p /var/{lib,log,spool}/asterisk
sudo mkdir -p /usr/lib/asterisk
sudo mkdir -p /var/lib/asterisk/agi-bin

# Establecer permisos
sudo chown -R asterisk:asterisk /var/{lib,log,spool}/asterisk
sudo chown -R asterisk:asterisk /usr/lib/asterisk

echo "Usuario asterisk configurado ✅"
```

### **B. Instalar dependencias para compilación**
```bash
# Instalar herramientas de desarrollo y dependencias
sudo apt install -y \
  build-essential linux-headers-$(uname -r) \
  libncurses5-dev libssl-dev libxml2-dev \
  libsqlite3-dev uuid-dev libjansson-dev \
  libedit-dev libsrtp2-dev \
  sox mpg123 lame ffmpeg \
  unixodbc odbcinst \
  autotools-dev gcc g++ make patch \
  subversion git wget

echo "Dependencias de compilación instaladas ✅"
```

## 📞 **PASO 3: DESCARGAR Y COMPILAR ASTERISK**

### **A. Descargar Asterisk 20 LTS**
```bash
# Ir al directorio de fuentes
cd /usr/src

# Descargar Asterisk 20 (LTS)
sudo wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-20-current.tar.gz

# Extraer
sudo tar xzf asterisk-20-current.tar.gz
cd asterisk-20*/

echo "Asterisk 20 descargado ✅"
```

### **B. Instalar dependencias MP3 y prerequisitos**
```bash
# Instalar soporte MP3
sudo contrib/scripts/get_mp3_source.sh

# Instalar prerequisitos automáticamente
sudo contrib/scripts/install_prereq install

echo "Prerequisitos de Asterisk instalados ✅"
```

### **C. Configurar compilación optimizada**
```bash
# Configurar build optimizado para FreePBX
sudo ./configure \
  --with-jansson-bundled \
  --with-pjproject-bundled \
  --enable-dev-mode=no

# Verificar que la configuración sea exitosa
echo "Configuración de Asterisk completada ✅"
```

### **D. Seleccionar módulos necesarios**
```bash
# Generar menuselect
sudo make menuselect.makeopts

# Seleccionar módulos esenciales para FreePBX
sudo menuselect/menuselect \
  --enable chan_pjsip \
  --enable res_pjsip \
  --enable res_pjsip_session \
  --enable app_dial \
  --enable app_queue \
  --enable app_voicemail \
  --enable res_musiconhold \
  --enable res_parking \
  --enable codec_ulaw \
  --enable codec_alaw \
  --enable codec_g722 \
  --disable chan_sip \
  menuselect.makeopts

echo "Módulos Asterisk seleccionados ✅"
```

## 🔨 **PASO 4: COMPILAR E INSTALAR ASTERISK**

### **A. Compilación (tomará 10-15 minutos)**
```bash
# Compilar Asterisk (usa todos los cores disponibles)
sudo make -j$(nproc)

echo "Compilación de Asterisk completada ✅"
```

### **B. Instalar Asterisk**
```bash
# Instalar binarios
sudo make install

# Instalar archivos de configuración de ejemplo
sudo make samples

# Instalar script de inicio
sudo make config

# Actualizar librerías del sistema
sudo ldconfig

echo "Asterisk instalado completamente ✅"
```

### **C. Configurar permisos finales**
```bash
# Establecer permisos correctos para asterisk
sudo chown -R asterisk:asterisk /etc/asterisk
sudo chown -R asterisk:asterisk /var/{lib,log,spool}/asterisk
sudo chown -R asterisk:asterisk /usr/lib/asterisk

# Configurar Asterisk para correr como usuario asterisk
sudo sed -i 's/^#AST_USER="asterisk"/AST_USER="asterisk"/' /etc/default/asterisk
sudo sed -i 's/^#AST_GROUP="asterisk"/AST_GROUP="asterisk"/' /etc/default/asterisk

echo "Permisos de Asterisk configurados ✅"
```

## ⚡ **PASO 5: PRIMER ARRANQUE DE ASTERISK**

### **A. Iniciar Asterisk**
```bash
# Iniciar Asterisk por primera vez
sudo systemctl start asterisk
sudo systemctl enable asterisk

# Verificar que Asterisk esté corriendo
sudo systemctl status asterisk

# Verificar versión de Asterisk
sudo asterisk -V

# Conectar a la CLI de Asterisk
sudo asterisk -r
```

**En la CLI de Asterisk, ejecuta:**
```
core show version
core show channels
pjsip show endpoints
exit
```

### **B. Verificar puertos Asterisk**
```bash
# Verificar que Asterisk esté escuchando en puerto 5060
netstat -tulpn | grep 5060

echo "Si ves 5060, Asterisk está corriendo correctamente ✅"
```

---

## 🎯 **CHECKPOINT - ASTERISK FUNCIONAL**

Antes de continuar con FreePBX, necesito que ejecutes estos comandos y me confirmes que:

1. ✅ Apache responde en puerto 8080
2. ✅ MariaDB acepta conexiones
3. ✅ Asterisk está corriendo y escuchando en puerto 5060
4. ✅ PHP está funcionando correctamente

**¿Podrías ejecutar esta verificación rápida?**

```bash
echo "=== VERIFICACIÓN CHECKPOINT ==="
echo "1. Apache puerto 8080:"
curl -I http://localhost:8080

echo "2. MariaDB:"
mysql -u freepbxuser -p'FreePBX_SKYN3T_2025!' -e "SELECT 'MySQL OK';"

echo "3. Asterisk:"
sudo asterisk -rx "core show version"

echo "4. Puertos activos:"
netstat -tulpn | grep -E "(8080|3306|5060)"
```

Una vez que confirmes que todo funciona, procederemos con la **instalación de FreePBX** sobre esta base sólida de Asterisk.
