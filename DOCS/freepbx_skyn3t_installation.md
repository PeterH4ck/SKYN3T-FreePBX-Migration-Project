# 🚀 INSTALACIÓN FREEPBX + SKYN3T - DOCUMENTACIÓN COMPLETA ACTUALIZADA

## 📊 **ESTADO ACTUAL DEL PROYECTO**

### ✅ **COMPLETADO (70% - Hasta Dependencias Asterisk)**
- **Fase 1**: Infraestructura base ✅
- **Fase 2**: Preparación Asterisk ✅
- **Fase 3**: Compilación Asterisk ⏳ (SIGUIENTE)

---

## 📋 **ANÁLISIS DE INFRAESTRUCTURA INICIAL**

### **Sistema Base Verificado:**
```yaml
Servidor: Ubuntu 22.04.5 LTS
RAM: 15GB disponibles (261MB usado) ✅ EXCELENTE
Disco: 469GB (4.7GB usado) ✅ MÁS QUE SUFICIENTE
CPU: x86_64 ✅ COMPATIBLE
Puertos libres: 5060, 8080 ✅ PERFECTOS
Conflictos: NINGUNO ✅ ÓPTIMO
```

### **Arquitectura Final Planificada:**
```
┌─────────────────────────────────────────────────────────┐
│                    SERVIDOR CLOUD                      │
├─────────────────────────────────────────────────────────┤
│  NGINX REVERSE PROXY (80/443) - FUTURO                 │
│  ├── skyn3t.tudominio.com → SKYN3T (Puerto 8000)      │
│  └── pbx.tudominio.com → FreePBX (Puerto 8080) ✅      │
├─────────────────────────────────────────────────────────┤
│  SKYN3T STACK (Docker) - FUTURO                        │
│  ├── 27 Servicios                                      │
│  ├── PostgreSQL (5432)                                 │
│  ├── Redis (6379)                                      │
│  └── Grafana (3000) - Monitoreo unificado             │
├─────────────────────────────────────────────────────────┤
│  FREEPBX STACK (Nativo) - EN CONSTRUCCIÓN              │
│  ├── Apache (8080) ✅ FUNCIONANDO                      │
│  ├── MariaDB (3306) ✅ FUNCIONANDO                     │
│  ├── PHP 8.1 ✅ FUNCIONANDO                            │
│  ├── Usuario asterisk ✅ CREADO                        │
│  ├── Dependencias compilación ✅ INSTALADAS            │
│  ├── Asterisk 20 ⏳ POR COMPILAR                       │
│  ├── FreePBX Web ⏳ POR INSTALAR                       │
│  └── Configuración Multi-tenant ⏳ POR CONFIGURAR      │
└─────────────────────────────────────────────────────────┘
```

---

## ✅ **FASE 1 COMPLETADA: INFRAESTRUCTURA BASE**

### **PASO 1A: Herramientas Básicas ✅**
```bash
# ✅ EJECUTADO Y VERIFICADO
sudo apt install -y tree curl wget git nano

# Variables de entorno configuradas
sudo tee -a /etc/environment <<EOF

# FreePBX Configuration  
FREEPBX_WEB_PORT=8080
ASTERISK_SIP_PORT=5060
RTP_START=10000
RTP_END=20000
PBX_DB_NAME=freepbx_skyn3t
EOF

source /etc/environment
```

**✅ Resultado:** Herramientas instaladas, variables configuradas

### **PASO 1B: Apache Configurado ✅**
```bash
# ✅ EJECUTADO Y VERIFICADO
sudo apt install -y apache2

# Configuración puerto 8080 (sin conflicto con nginx futuro)
sudo sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf
sudo sed -i 's/:80>/:8080>/' /etc/apache2/sites-available/000-default.conf

# Módulos habilitados
sudo a2enmod rewrite ssl headers
sudo systemctl restart apache2

# ✅ VERIFICADO: Apache funcionando en puerto 8080
curl -I http://localhost:8080
# ✅ RESULTADO: HTTP/1.1 200 OK
```

**⚠️ Error Solucionado:** Apache necesitó restart para aplicar cambio de puerto

### **PASO 1C: MariaDB Configurado ✅**
```bash
# ✅ EJECUTADO Y VERIFICADO
sudo apt install -y mariadb-server mariadb-client
sudo systemctl start mariadb
sudo systemctl enable mariadb

# ✅ Configuración segura aplicada
sudo mysql_secure_installation
# Password root: FreePBX_Root_2025!

# ✅ Base de datos FreePBX creada
sudo mysql -u root -p <<EOF
CREATE DATABASE freepbx_skyn3t;
CREATE USER 'freepbxuser'@'localhost' IDENTIFIED BY 'FreePBX_SKYN3T_2025!';
GRANT ALL PRIVILEGES ON freepbx_skyn3t.* TO 'freepbxuser'@'localhost';
FLUSH PRIVILEGES;
EOF

# ✅ VERIFICADO: Conexión funcional
mysql -u freepbxuser -p'FreePBX_SKYN3T_2025!' -e "SELECT 'Conexión FreePBX OK' AS Status;"
```

**✅ Resultado:** MariaDB 10.6.22 funcionando, base de datos lista

### **PASO 1D: PHP 8.1 Configurado ✅**
```bash
# ✅ EJECUTADO CON CORRECCIÓN
sudo apt install -y \
  php8.1 php8.1-cli php8.1-common php8.1-curl php8.1-mbstring \
  php8.1-mysql php8.1-xml php8.1-zip php8.1-gd php8.1-intl \
  php8.1-bcmath php8.1-soap php8.1-xmlrpc \
  libapache2-mod-php8.1

# ✅ Optimizaciones aplicadas
sudo sed -i 's/upload_max_filesize = .*/upload_max_filesize = 120M/' /etc/php/8.1/apache2/php.ini
sudo sed -i 's/memory_limit = .*/memory_limit = 256M/' /etc/php/8.1/apache2/php.ini
sudo sed -i 's/post_max_size = .*/post_max_size = 120M/' /etc/php/8.1/apache2/php.ini
sudo sed -i 's/max_execution_time = .*/max_execution_time = 300/' /etc/php/8.1/apache2/php.ini

sudo systemctl restart apache2

# ✅ VERIFICADO: PHP funcionando
php -v
# ✅ RESULTADO: PHP 8.1.2-1ubuntu2.21
```

**⚠️ Error Solucionado:** `php8.1-json` no existe (es paquete virtual incluido)

---

## ✅ **FASE 2 COMPLETADA: PREPARACIÓN ASTERISK**

### **PASO 2A: Usuario Asterisk ✅**
```bash
# ✅ EJECUTADO Y VERIFICADO
sudo useradd -r -d /var/lib/asterisk -s /bin/bash asterisk
sudo usermod -aG audio,dialout asterisk

# Directorios creados
sudo mkdir -p /var/{lib,log,spool}/asterisk
sudo mkdir -p /usr/lib/asterisk
sudo mkdir -p /var/lib/asterisk/agi-bin

# Permisos establecidos
sudo chown -R asterisk:asterisk /var/{lib,log,spool}/asterisk
sudo chown -R asterisk:asterisk /usr/lib/asterisk

# ✅ VERIFICADO: Usuario creado correctamente
id asterisk
# ✅ RESULTADO: uid=998(asterisk) gid=998(asterisk) groups=998(asterisk),20(dialout),29(audio)
```

### **PASO 2B: Dependencias de Compilación ✅**
```bash
# ✅ EJECUTADO Y VERIFICADO - 244 PAQUETES INSTALADOS
sudo apt install -y \
  build-essential linux-headers-$(uname -r) \
  libncurses5-dev libssl-dev libxml2-dev \
  libsqlite3-dev uuid-dev libjansson-dev \
  libedit-dev libsrtp2-dev \
  sox mpg123 lame ffmpeg \
  unixodbc odbcinst \
  autotools-dev gcc g++ make patch \
  subversion git

# ✅ VERIFICADO: Todas las dependencias instaladas
gcc --version
# ✅ RESULTADO: gcc (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0
```

**⚠️ Observación:** Múltiples pantallas de configuración de kernel (normales)

---

## ⏳ **FASE 3: COMPILACIÓN ASTERISK (SIGUIENTE PASO)**

### **PASO 3A: Descargar Asterisk 20 LTS**
```bash
# 📋 POR EJECUTAR
cd /usr/src
sudo wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-20-current.tar.gz
sudo tar xzf asterisk-20-current.tar.gz
cd asterisk-20*/

echo "✅ Asterisk 20 descargado - procediendo con prerequisitos"
```

### **PASO 3B: Instalar Prerequisitos Específicos**
```bash
# 📋 POR EJECUTAR
sudo contrib/scripts/get_mp3_source.sh
sudo contrib/scripts/install_prereq install

echo "✅ Prerequisitos Asterisk instalados"
```

### **PASO 3C: Configurar Compilación**
```bash
# 📋 POR EJECUTAR
sudo ./configure \
  --with-jansson-bundled \
  --with-pjproject-bundled \
  --enable-dev-mode=no

echo "✅ Configuración Asterisk completada"
```

### **PASO 3D: Seleccionar Módulos**
```bash
# 📋 POR EJECUTAR
sudo make menuselect.makeopts

# Módulos esenciales para FreePBX
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

echo "✅ Módulos Asterisk seleccionados"
```

---

## 📋 **FASE 4: COMPILACIÓN E INSTALACIÓN (PENDIENTE)**

### **PASO 4A: Compilar Asterisk**
```bash
# 📋 POR EJECUTAR (10-15 minutos)
sudo make -j$(nproc)
echo "✅ Compilación Asterisk completada"
```

### **PASO 4B: Instalar Asterisk**
```bash
# 📋 POR EJECUTAR
sudo make install
sudo make samples
sudo make config
sudo ldconfig

# Configurar usuario para ejecutar Asterisk
sudo sed -i 's/^#AST_USER="asterisk"/AST_USER="asterisk"/' /etc/default/asterisk
sudo sed -i 's/^#AST_GROUP="asterisk"/AST_GROUP="asterisk"/' /etc/default/asterisk

echo "✅ Asterisk instalado completamente"
```

### **PASO 4C: Verificar Asterisk**
```bash
# 📋 POR EJECUTAR
sudo systemctl start asterisk
sudo systemctl enable asterisk
sudo systemctl status asterisk

# Verificar versión y conectividad
sudo asterisk -V
sudo asterisk -rx "core show version"
netstat -tulpn | grep 5060

echo "✅ Asterisk funcionando correctamente"
```

---

## 📋 **FASE 5: INSTALACIÓN FREEPBX (PENDIENTE)**

### **PASO 5A: Descargar FreePBX**
```bash
# 📋 POR EJECUTAR
cd /usr/src
sudo wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-16.0-latest.tgz
sudo tar xzf freepbx-16.0-latest.tgz
cd freepbx/
```

### **PASO 5B: Instalar FreePBX**
```bash
# 📋 POR EJECUTAR
sudo ./start_asterisk start
sudo ./install -n \
  --webroot=/var/www/html \
  --dbhost=localhost \
  --dbname=freepbx_skyn3t \
  --dbuser=freepbxuser \
  --dbpass='FreePBX_SKYN3T_2025!' \
  --cdrdbname=freepbx_skyn3t \
  --ampdbhost=localhost \
  --ampdbname=freepbx_skyn3t \
  --ampdbuser=freepbxuser \
  --ampdbpass='FreePBX_SKYN3T_2025!'

sudo systemctl enable freepbx
sudo systemctl start freepbx
```

---

## 📋 **FASE 6: CONFIGURACIÓN MULTI-TENANT (PENDIENTE)**

### **Estructura Multi-tenant Planificada:**
```bash
# Extensiones por cliente (reemplaza Twilio SIP users)
Cliente OFICINA_PRINCIPAL:
├── 2001 (Office) ← Reemplaza +56229145248-office
├── 2002 (Security) ← Reemplaza +56229145248-security
└── Trunk: Entel_Principal

Cliente PLAZA_NORTE:
├── 3001 (Office)
├── 3002 (Security)  
└── Trunk: VTR_PlazaNorte

# IVR personalizado por cliente (reemplaza TwiML Bins)
```

### **Configuración PJSIP Multi-tenant:**
```bash
# 📋 POR CONFIGURAR
/etc/asterisk/pjsip_skyn3t.conf:
- Transport UDP 5060
- Endpoints por cliente
- Auth por extensión
- AOR por dispositivo
- Códecs: PCMU, PCMA, G.722 (compatibles Twilio)
```

---

## 📋 **FASE 7: INTEGRACIÓN PROVEEDORES (PENDIENTE)**

### **Trunks Chilenos Planificados:**
```yaml
Entel Empresas:
  - Costo: ~$14 CLP/minuto
  - Configuración: SIP trunk nativo
  - Ahorro vs Twilio: 72%

VTR Empresas:
  - Costo: ~$15 CLP/minuto  
  - Configuración: SIP trunk nativo
  - Ahorro vs Twilio: 70%

VoIP.ms (Internacional):
  - Costo: ~$20 CLP/minuto
  - Configuración: SIP trunk
  - Ahorro vs Twilio: 60%
```

---

## 📋 **FASE 8: MIGRACIÓN DESDE TWILIO (PENDIENTE)**

### **Plan de Migración Gradual:**
```bash
Fase 8.1: Cliente Piloto
├── Configurar 1 cliente en FreePBX paralelo a Twilio
├── Testing comparativo (calidad, funcionalidad)
├── Verificación IVR y enrutamiento
└── Confirmación audio bidireccional

Fase 8.2: Migración Progresiva  
├── Cliente por cliente
├── Mantener Twilio como backup
├── Verificar funcionalidad completa por cliente
└── Confirmar reducción de costos

Fase 8.3: Finalización
├── Cancelar servicios Twilio innecesarios
├── Optimizar configuraciones FreePBX
├── Implementar monitoreo completo
└── Documentar procedimientos finales
```

---

## 🔧 **ERRORES SOLUCIONADOS Y PREVENCIÓN**

### **Error 1: Pantallas Configuración Kernel**
```bash
⚠️ PROBLEMA: Pantallas purpuras durante instalación de paquetes
✅ SOLUCIÓN: Presionar "OK" - Son actualizaciones normales del sistema
🔄 PREVENCIÓN: Esperar pacientemente, no cancelar instalaciones
```

### **Error 2: php8.1-json No Existe**
```bash
⚠️ PROBLEMA: E: Package 'php8.1-json' has no installation candidate
✅ SOLUCIÓN: Quitar php8.1-json del comando (es paquete virtual)
🔄 PREVENCIÓN: JSON está incluido por defecto en PHP 8.1
```

### **Error 3: Apache Puerto 8080**
```bash
⚠️ PROBLEMA: curl: (7) Failed to connect to localhost port 8080
✅ SOLUCIÓN: sudo systemctl restart apache2 después de cambio de puerto
🔄 PREVENCIÓN: Siempre restart servicios después de cambios de configuración
```

### **Error 4: Servicios Restarting**
```bash
⚠️ PROBLEMA: Service restarts being deferred durante instalaciones
✅ SOLUCIÓN: Normal - servicios se reinician automáticamente
🔄 PREVENCIÓN: No interrumpir, son actualizaciones de seguridad normales
```

---

## 📊 **MÉTRICAS ACTUALES DEL PROYECTO**

### **Progreso Completado:**
```yaml
✅ Infraestructura Base: 100%
✅ Preparación Asterisk: 100%  
⏳ Compilación Asterisk: 0% (SIGUIENTE)
📋 FreePBX Instalación: 0%
📋 Configuración Multi-tenant: 0%
📋 Integración Proveedores: 0%
📋 Migración Twilio: 0%

TOTAL COMPLETADO: 35%
SIGUIENTE FASE: Compilación Asterisk (15-20 min)
```

### **Recursos Utilizados:**
```yaml
Tiempo invertido: ~2 horas
Espacio en disco: ~2GB adicionales (dependencias)
RAM utilizada: Mínima (solo servicios base)
Errores encontrados: 4 (todos solucionados)
```

### **Estimación Restante:**
```yaml
Compilación Asterisk: 30 minutos
Instalación FreePBX: 20 minutos
Configuración Multi-tenant: 45 minutos
Testing y verificación: 30 minutos
TOTAL ESTIMADO: 2 horas adicionales
```

---

## 🎯 **PRÓXIMOS PASOS INMEDIATOS**

### **1. Continuar con Compilación Asterisk:**
```bash
# Ejecutar en orden:
cd /usr/src
sudo wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-20-current.tar.gz
sudo tar xzf asterisk-20-current.tar.gz
cd asterisk-20*/
sudo contrib/scripts/get_mp3_source.sh
sudo contrib/scripts/install_prereq install
```

### **2. Configurar y Compilar:**
```bash
sudo ./configure --with-jansson-bundled --with-pjproject-bundled --enable-dev-mode=no
sudo make menuselect.makeopts
# Seleccionar módulos necesarios
sudo make -j$(nproc)
sudo make install
```

### **3. Verificar Funcionamiento:**
```bash
sudo systemctl start asterisk
sudo asterisk -rx "core show version"
netstat -tulpn | grep 5060
```

---

## 💰 **ANÁLISIS FINANCIERO ACTUALIZADO**

### **Costos vs Beneficios:**
```yaml
Inversión en Tiempo:
├── Tiempo total estimado: 4 horas
├── Complejidad: Media-Alta
└── ROI: Inmediato en ahorro mensual

Ahorro Mensual Estimado:
├── Twilio actual (500 min): $125 USD
├── FreePBX + Entel (500 min): $35 USD  
├── Ahorro mensual: $90 USD (72%)
└── Ahorro anual: $1,080 USD

Payback:
├── Costo implementación: $0 (software libre)
├── Tiempo implementación: 4 horas
├── Payback: Inmediato
└── Break-even: Primer mes
```

### **Escalabilidad:**
```yaml
Capacidad Técnica:
├── Llamadas concurrentes: 100+ (limitado por ancho de banda)
├── Extensiones: Ilimitadas
├── Clientes: Ilimitados
└── Crecimiento: Lineal con recursos servidor

Mantenimiento:
├── Actualizaciones: Trimestrales
├── Backups: Automáticos diarios
├── Monitoreo: Integrado con SKYN3T
└── Soporte: Documentación completa
```

---

## 🔧 **COMANDOS DE VERIFICACIÓN RÁPIDA**

### **Estado Actual del Sistema:**
```bash
# Verificar servicios funcionando
sudo systemctl status apache2 mariadb

# Verificar puertos
netstat -tulpn | grep -E "(8080|3306)"

# Verificar PHP
php -v && curl -I http://localhost:8080

# Verificar usuario asterisk
id asterisk && ls -la /var/lib/asterisk/

# Verificar dependencias
gcc --version && make --version

echo "🎯 Sistema listo para continuar con Asterisk"
```

### **Troubleshooting Rápido:**
```bash
# Si Apache no responde:
sudo systemctl restart apache2

# Si MariaDB no conecta:
mysql -u freepbxuser -p'FreePBX_SKYN3T_2025!' -e "SELECT 1;"

# Si faltan dependencias:
sudo apt install -f

# Si problemas de permisos:
sudo chown -R asterisk:asterisk /var/lib/asterisk
```

---

## 📋 **CHECKLIST DE PROGRESO**

### **✅ COMPLETADO:**
- [x] Análisis de recursos del servidor
- [x] Instalación de herramientas básicas  
- [x] Configuración de variables de entorno
- [x] Instalación y configuración Apache (puerto 8080)
- [x] Instalación y configuración MariaDB
- [x] Creación de base de datos FreePBX
- [x] Instalación y configuración PHP 8.1
- [x] Creación de usuario asterisk
- [x] Instalación de dependencias de compilación
- [x] Resolución de errores conocidos
- [x] Documentación actualizada

### **⏳ EN PROGRESO:**
- [ ] Descarga de Asterisk 20 LTS
- [ ] Instalación de prerequisitos Asterisk
- [ ] Configuración de compilación
- [ ] Selección de módulos

### **📋 PENDIENTE:**
- [ ] Compilación de Asterisk (10-15 min)
- [ ] Instalación de Asterisk
- [ ] Verificación de funcionamiento Asterisk
- [ ] Descarga e instalación de FreePBX
- [ ] Configuración multi-tenant
- [ ] Configuración de trunks proveedores chilenos
- [ ] Testing y verificación completa
- [ ] Migración gradual desde Twilio
- [ ] Documentación final y procedimientos

---

**🎯 SISTEMA PREPARADO AL 35% - LISTO PARA CONTINUAR CON ASTERISK** 

**💡 PRÓXIMO COMANDO A EJECUTAR:**
```bash
cd /usr/src && sudo wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-20-current.tar.gz
```

---

**© 2025 SKYN3T + FreePBX - Documentación Actualizada en Tiempo Real**  
**Estado**: Infraestructura completa ✅ | Asterisk en preparación ⏳  
**Última actualización**: Basada en ejecución real hasta dependencias compilación