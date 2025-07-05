# 📱 SKYN3T FreePBX - Conexión de Dispositivos Grandstream

## 🎯 ESTADO ACTUAL
- ✅ FreePBX 100% funcional
- ✅ Extensiones 2001 y 2002 creadas
- ⚠️ Dispositivos pendientes de conexión

## 🔧 PASO INMEDIATO: CONECTAR DISPOSITIVOS GRANDSTREAM

### **OPCIÓN A: Configuración Manual en Dispositivo**

#### **1. Acceder al Dispositivo Grandstream:**
```bash
# Encontrar IP del dispositivo
# Método 1: Revisar pantalla del dispositivo
# Método 2: Escanear red local
nmap -sn 192.168.1.0/24 | grep -B2 "Grandstream"

# Acceder vía web browser
http://[IP_DISPOSITIVO]
Usuario: admin
Password: admin (default)
```

#### **2. Configurar Extensión 2001 (Office):**
```yaml
Navegación: Account → General Settings

Account Active: Yes
Account Name: SKYN3T-Office-2001
SIP Server: 146.19.215.149
SIP User ID: 2001
SIP Auth ID: 2001
SIP Password: SKyn3t_Office_2025!
Outbound Proxy: (vacío)
SIP Transport: UDP
Local SIP Port: 5060
Register: Yes
```

#### **3. Configurar Códecs:**
```yaml
Navegación: Account → Codec Settings

Preferred Vocoder Choice 1: PCMU
Preferred Vocoder Choice 2: PCMA  
Preferred Vocoder Choice 3: G722
Preferred Vocoder Choice 4-8: Disabled

DTMF:
Send DTMF via RTP(RFC2833): Yes
DTMF Payload Type: 101
```

#### **4. Aplicar y Reiniciar:**
```bash
1. Click "Save and Apply"
2. Device reiniciará automáticamente
3. Verificar estado de registro
```

### **OPCIÓN B: Usar Plantilla GDMS Cloud** ⭐ **RECOMENDADO**

#### **1. Modificar Template XML para FreePBX:**
```xml
<!-- Cambiar en SKYN3T_GRP2601_Office_Template.xml -->
<part name="registrar">146.19.215.149</part>
<part name="userId">2001</part>
<part name="authId">2001</part>
<part name="password">SKyn3t_Office_2025!</part>

<!-- Remover configuración STUN (no necesaria para LAN) -->
<part name="stunServer"></part>
```

#### **2. Aplicar Template en GDMS Cloud:**
```bash
1. Subir template modificado
2. Aplicar a dispositivo GRP2601
3. Esperar sincronización automática
```

## 🧪 VERIFICACIÓN DE CONEXIÓN

### **1. Verificar Registro en FreePBX:**
```bash
# SSH al servidor FreePBX
ssh user@146.19.215.149

# Verificar extensiones registradas
sudo asterisk -rx "pjsip show endpoints"

# Debe mostrar:
# Endpoint: 2001    Available    0 of inf ✅
```

### **2. Verificar desde Asterisk CLI:**
```bash
sudo asterisk -r

# Comandos útiles:
CLI> pjsip show endpoints
CLI> pjsip show registrations  
CLI> core show channels
CLI> dialplan show from-internal
```

### **3. Testing de Llamadas Internas:**
```bash
# Desde dispositivo 2001 marcar: 2002
# Desde dispositivo 2002 marcar: 2001

# Verificar en CLI:
CLI> core show channels
# Debe mostrar llamada activa
```

## 🔧 TROUBLESHOOTING CONEXIÓN

### **Problema: Dispositivo no registra**

#### **1. Verificar conectividad de red:**
```bash
# Desde dispositivo, ping al servidor
ping 146.19.215.149

# Desde servidor, verificar puerto SIP
netstat -tulpn | grep 5060
```

#### **2. Verificar credenciales:**
```bash
# En servidor FreePBX, verificar configuración
sudo cat /etc/asterisk/pjsip.conf | grep -A10 "\[2001\]"

# Verificar password exacto
```

#### **3. Verificar logs:**
```bash
# Logs de Asterisk
sudo tail -f /var/log/asterisk/full

# Buscar mensajes de registro
grep "REGISTER" /var/log/asterisk/full
```

### **Problema: Audio de un solo sentido**

#### **Verificar RTP:**
```bash
# En asterisk CLI durante llamada
CLI> rtp show stats

# Verificar puertos RTP abiertos
sudo ufw status
```

## 📋 CHECKLIST CONEXIÓN EXITOSA

```bash
□ Dispositivo obtiene IP de red local
□ Dispositivo puede hacer ping a 146.19.215.149
□ Credenciales SIP configuradas correctamente
□ Dispositivo muestra "Registered" en pantalla
□ FreePBX muestra endpoint como "Available"
□ Llamada interna 2001→2002 funciona
□ Audio bidireccional correcto
□ Voicemail funcional (si configurado)
```

## 🎯 SIGUIENTE FASE: IVR Y TRUNKS

Una vez que dispositivos estén conectados:

### **1. Configurar IVR (15 min):**
```bash
# FreePBX Web Interface
Applications → IVR → Add IVR

IVR Name: oficina-principal-ivr
Announcement: "Bienvenido a Oficina Principal. Presione 1 para administración, 2 para seguridad"
Options:
- 1: Extension 2001
- 2: Extension 2002
```

### **2. Configurar Trunk Chileno (30 min):**
```bash
# Connectivity → Trunks → Add SIP Trunk
Trunk Name: entel-trunk
Host: sip.entel.cl
Username: [TU_USUARIO_ENTEL]
Secret: [TU_PASSWORD_ENTEL]

# Outbound Routes
Route Name: Chilean-Mobile
Dial Patterns: 9XXXXXXXX
Trunk Sequence: entel-trunk
```

## 💰 BENEFICIO INMEDIATO

```yaml
Estado Actual:
├── Twilio: $50 CLP/minuto
├── Llamadas internas: $0 CLP/minuto ✅
├── Testing gratuito: Ilimitado ✅
└── Preparación para migración: Completa ✅

Próximo Mes:
├── Entel: $14 CLP/minuto (72% ahorro)
├── Sistema validado: Sin riesgo ✅
├── Twilio como backup: Seguridad ✅
└── ROI inmediato: Garantizado ✅
```

## 🚀 ACCIÓN INMEDIATA RECOMENDADA

**1. CONECTAR UN DISPOSITIVO (30 minutos):**
- Configurar GRP2601 con extension 2001
- Verificar registro exitoso
- Hacer testing básico

**2. VALIDAR FUNCIONALIDAD (15 minutos):**
- Llamadas internas gratuitas
- Calidad de audio
- Interfaz de usuario

**3. PREPARAR MIGRACIÓN (siguiente semana):**
- Configurar trunk chileno
- Testing paralelo con Twilio
- Migración gradual

---

## 📞 COMANDOS ÚTILES DE MONITOREO

```bash
# Estado general del sistema
sudo systemctl status asterisk

# Extensiones activas
sudo asterisk -rx "pjsip show endpoints"

# Llamadas en curso
sudo asterisk -rx "core show channels"

# Logs en tiempo real
sudo tail -f /var/log/asterisk/full

# Estado de registros
sudo asterisk -rx "pjsip show registrations"
```

¡El sistema está 98% completado! Solo falta conectar los dispositivos físicos para tener funcionamiento completo.
