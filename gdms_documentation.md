# 🌐 SKYN3T - GUÍA COMPLETA CONFIGURACIÓN GDMS CLOUD

## 🎯 INTRODUCCIÓN

Esta guía documenta paso a paso la configuración completa de GDMS Cloud para el sistema SKYN3T Multi-Tenant. El sistema utiliza plantillas reutilizables para configurar dispositivos Grandstream que se conectan a la infraestructura Twilio SIP.

### **Arquitectura del Sistema**
- **Plantillas por modelo**: Configuraciones reutilizables
- **SIP Registration**: Conexión a `skyn3t-communities.sip.twilio.com`
- **Gestión centralizada**: Control remoto de dispositivos
- **Escalabilidad**: Aplicación masiva de configuraciones

---

## 📋 REQUISITOS PREVIOS

### **Cuenta GDMS Cloud**
- ✅ Cuenta GDMS Cloud activa
- ✅ Dispositivos Grandstream registrados
- ✅ Acceso a gestión de plantillas
- ✅ Permisos para configuración remota

### **Dispositivos Soportados**
```yaml
Oficina/Administración:
- GRP2601 (recomendado)
- GRP2614/2615/2616
- GXP serie (alternativo)

Conserjería/Seguridad:
- GHP621W (recomendado)
- GDS3710 (videoportero)
- GRP2601 (alternativo)
```

### **Información del Sistema Twilio**
```yaml
SIP Server: skyn3t-communities.sip.twilio.com
STUN Server: stun.twilio.com
Transport: UDP
Port: 5060
Códecs soportados: PCMU, PCMA, G.722
```

---

## 🚀 CONFIGURACIÓN INICIAL - PLANTILLAS BASE

### **PASO 1: Crear Plantilla para GRP2601 (Oficina)**

**Navegación**: `Plantilla → Por modelo → Agregar plantilla de modelo`

```bash
1. Click "Agregar plantilla de modelo"
2. Configurar:
   ┌─────────────────────────────────────────────┐
   │ Nombre: SKYN3T-Office-Template              │
   │ Modelo: GRP2601                             │
   │ Descripción: Plantilla SKYN3T para oficina │
   │ Proveer automáticamente: Todos los sitios   │
   └─────────────────────────────────────────────┘
3. Cargar archivo XML de configuración
4. Guardar
```

### **PASO 2: Crear Plantilla para GHP621 (Conserjería)**

```bash
1. Click "Agregar plantilla de modelo"
2. Configurar:
   ┌─────────────────────────────────────────────┐
   │ Nombre: SKYN3T-Security-Template            │
   │ Modelo: GHP621                              │
   │ Descripción: Plantilla SKYN3T para conserjería │
   │ Proveer automáticamente: Todos los sitios   │
   └─────────────────────────────────────────────┘
3. Cargar archivo XML de configuración
4. Guardar
```

---

## 📱 CONFIGURACIÓN PLANTILLA GRP2601 (OFICINA)

### **PASO 1: Establecer Parámetros Base**

#### **Account Settings → SIP Settings:**

```bash
Configuración SIP básica:
┌─────────────────────────────────────────────┐
│ SIP Server: skyn3t-communities.sip.twilio.com │
│ SIP User ID: +56XXXXXXXXX-office (placeholder) │
│ SIP Auth ID: +56XXXXXXXXX-office (placeholder) │
│ SIP Password: SKyn3t2025_CLIENT_CODE_Office! │
│ Outbound Proxy: (vacío)                     │
│ SIP Transport: UDP                          │
│ Local Port: 5060                            │
│ Register: ✅ Enabled                        │
│ Register Expiration: 1800                   │
└─────────────────────────────────────────────┘
```

#### **Account Settings → Account Registration:**

```bash
┌─────────────────────────────────────────────┐
│ Account Display: ✅ Enabled                 │
│ UNREGISTER on Reboot: No                    │
│ REGISTER Expiration: 1800                   │
│ SUBSCRIBE Expiration: 60                    │
│ Re-Register before Expiration: 60           │
│ Registration Retry Wait Time: 20            │
└─────────────────────────────────────────────┘
```

#### **Account Settings → Network Settings:**

```bash
┌─────────────────────────────────────────────┐
│ Failback Expiration (m): 60                 │
│ Maximum Number of SIP Request Retries: 2    │
│ Support Report (RFC 3581): ✅ Enabled       │
│ Use SBC: ✅ Enabled                         │
└─────────────────────────────────────────────┘
```

### **PASO 2: Phone Settings Configuration**

#### **Phone Settings → Codec Settings:**

```bash
⚠️ CONFIGURACIÓN CRÍTICA - Solo habilitar códecs compatibles:

┌─────────────────────────────────────────────┐
│ Preferred Vocoder Choice 1: ✅ PCMU         │
│ Preferred Vocoder Choice 2: ✅ PCMA         │
│ Preferred Vocoder Choice 3: ✅ G.722        │
│ Preferred Vocoder Choice 4: ❌ Disabled     │
│ Preferred Vocoder Choice 5: ❌ Disabled     │
│ Preferred Vocoder Choice 6: ❌ Disabled     │
│ Preferred Vocoder Choice 7: ❌ Disabled     │
│ Preferred Vocoder Choice 8: ❌ Disabled     │
└─────────────────────────────────────────────┘

Audio Settings:
┌─────────────────────────────────────────────┐
│ Codec Negotiation Priority: Callee          │
│ Use First Matching Vocoder in 200OK SDP: ✅ │
│ iLBC Frame Size: 30ms                       │
│ iLBC Payload Type: 98                       │
│ G.723 Rate: 5.3kbps encoding rate          │
└─────────────────────────────────────────────┘
```

#### **Phone Settings → Codec Settings (DTMF):**

```bash
⚠️ CONFIGURACIÓN CRÍTICA - DTMF para Twilio:

┌─────────────────────────────────────────────┐
│ Send DTMF In-audio: ❌ Disabled             │
│ Send DTMF via RTP(RFC2833): ✅ Enabled      │
│ Send DTMF via SIP INFO: ❌ Disabled         │
│ DTMF Payload Type: 101                      │
│ Inbound DTMF Volume: 18                     │
│ Enable Audio RED with FEC: ❌ Disabled      │
│ Audio FEC Payload Type: 121                 │
│ Audio RED Payload Type: 124                 │
│ Silence Suppression: ✅ Enabled             │
│ Jitter Buffer Type: Adaptive                │
│ Jitter Buffer Length: 300ms                 │
│ Voice Frames per TX: 2                      │
│ G.723 Rate: 5.3kbps encoding rate          │
└─────────────────────────────────────────────┘
```

### **PASO 3: Network Settings Configuration**

#### **Network Settings → Basic Settings:**

```bash
⚠️ CONFIGURACIÓN CRÍTICA - NAT/STUN para Twilio:

┌─────────────────────────────────────────────┐
│ Local RTP Port: 5004                        │
│ Local RTP Port Range: 200                   │
│ Use Random Port: ❌ Disabled                │
│ Keep-Alive Interval: 30                     │
│ STUN Server: ✅ stun.twilio.com             │
│ Use NAT IP: (vacío)                         │
│ Delay Registration: 0                       │
│ Enable Outbound Notification: ✅ Enabled    │
│ Clean User Data While Different Users Log In: ✅ │
└─────────────────────────────────────────────┘

Public Mode:
┌─────────────────────────────────────────────┐
│ Enable Public Mode: ✅ Enabled              │
│ Public Mode Username Prefix: (vacío)        │
│ Public Mode Username Suffix: (vacío)        │
│ Allow Multiple Accounts: ✅ Enabled         │
│ Enable Remote Synchronization: ✅ Enabled   │
│ Server Type: TFTP                           │
└─────────────────────────────────────────────┘
```

### **PASO 4: Call Settings Configuration**

#### **Phone Settings → Call Settings → General:**

```bash
┌─────────────────────────────────────────────┐
│ Key As Send: Pound (#)                      │
│ No Key Entry Timeout: 4                     │
│ Send Anonymous: ❌ Disabled                 │
│ Anonymous Call Rejection: ❌ Disabled        │
│ Enable Call Waiting: ✅ Yes                 │
│ RFC2543 Hold: ❌ Disabled                   │
│ Ring Timeout: 60                            │
│ Call Log: Log All Calls                     │
└─────────────────────────────────────────────┘

Auto Answer (para oficina):
┌─────────────────────────────────────────────┐
│ Auto Answer: ❌ Disabled (típicamente)       │
│ Auto Answer Numbers: (vacío)                │
└─────────────────────────────────────────────┘

Intercom:
┌─────────────────────────────────────────────┐
│ Play Warning Tone for Auto Answer Intercom: ✅ │
└─────────────────────────────────────────────┘
```

#### **Phone Settings → Call Settings → Incoming:**

```bash
┌─────────────────────────────────────────────┐
│ Enable Incoming Call Popup: ✅ Enabled      │
│ Enable Missed Call Notification: ✅ Enabled │
│ Return Code When Refusing Incoming Call: Busy (486) │
│ Allow Incoming Call Before Ringing: ❌      │
│ Enable Call Waiting: ✅ Enabled             │
│ Enable Call Waiting Tone: ❌ Disabled       │
│ Ring for Call Waiting: ❌ Disabled          │
└─────────────────────────────────────────────┘
```

### **PASO 5: System Settings Configuration**

#### **System Settings → Time and Language:**

```bash
Date and Time (Chile):
┌─────────────────────────────────────────────┐
│ NTP Server: ntp.shoa.cl                     │
│ Secondary NTP Server: (vacío)               │
│ Enable Authenticated NTP: ❌ Disabled       │
│ Authenticated NTP Key ID: 1                 │
│ Authenticated NTP Key: (vacío)              │
│ NTP Update Interval: 1440                   │
│ Allow DHCP Option 42 to Override NTP Server: ✅ │
│ Time Zone: Self-Defined Time Zone           │
│ Allow DHCP Option 2 to Override Time Zone Setting: ✅ │
│ Self-Defined Time Zone: CLT+4CLST+3,M9.1.6,M4.1.6 │
│ Date Display Format: yyyy-mm-dd             │
│ Time Display Format: 12 Hour                │
└─────────────────────────────────────────────┘

Language:
┌─────────────────────────────────────────────┐
│ Display Language: Automatic                 │
└─────────────────────────────────────────────┘
```

#### **System Settings → Security Settings:**

```bash
┌─────────────────────────────────────────────┐
│ Web Access Mode: Both (HTTP+HTTPS)          │
│ Web Access Control: None                     │
│ Web Access Control List: (vacío)            │
│ Web Session Timeout: 10                     │
│ Enable User Web Access: ✅ Enabled          │
│ Validate Server Certificates: ✅ Enabled    │
│ Web/Restrict mode Lockout Duration: 5       │
│ Web Access Attempt Limit: 5                 │
└─────────────────────────────────────────────┘

User Info Management:
┌─────────────────────────────────────────────┐
│ Test Password Strength: ✅ Enabled          │
│ User Password: skyn3t123                     │
│ New Password: SKYN3T2025!                    │
└─────────────────────────────────────────────┘

Client Certificate:
┌─────────────────────────────────────────────┐
│ Minimum TLS Version: TLS 1.0                │
│ Maximum TLS Version: Unlimited               │
│ Enable LEGACY_SERVER_CONNECT: ❌ Disabled   │
│ Enable/Disable Weak Cipher Suites: Enable Weak TLS Ciphers Suites │
└─────────────────────────────────────────────┘
```

---

## 🛡️ CONFIGURACIÓN PLANTILLA GHP621 (CONSERJERÍA)

### **Diferencias Específicas para Conserjería**

La configuración del GHP621 es **idéntica** al GRP2601 con estas **excepciones**:

#### **Account Settings:**
```bash
┌─────────────────────────────────────────────┐
│ SIP User ID: +56XXXXXXXXX-security          │
│ SIP Auth ID: +56XXXXXXXXX-security          │
│ SIP Password: SKyn3t2025_CLIENT_CODE_Security! │
│ Display Name: [CLIENTE] - Conserjería       │
└─────────────────────────────────────────────┘
```

#### **Call Settings (Auto-Answer):**
```bash
┌─────────────────────────────────────────────┐
│ Auto Answer: ✅ Enabled (para conserjería)   │
│ Auto Answer Numbers: (configurar números específicos) │
└─────────────────────────────────────────────┘
```

#### **Resto de configuraciones:**
```bash
✅ Códecs: Idénticos (PCMU, PCMA, G.722)
✅ STUN Server: Idéntico (stun.twilio.com)
✅ Network Settings: Idénticos
✅ DTMF: Idéntico (RFC2833)
✅ Timezone: Idéntico (Chile)
```

---

## 🔧 APLICACIÓN DE PLANTILLAS A DISPOSITIVOS

### **PASO 1: Aplicar Plantilla a Dispositivo GRP2601**

**Navegación**: `Dispositivos VoIP → [Seleccionar GRP2601]`

```bash
1. Click en el dispositivo GRP2601 target
2. Pestaña "Maintenance"
3. Sección "Apply Template"
4. Seleccionar: SKYN3T-Office-Template
5. Click "Apply"
6. Esperar reinicio automático (~2 minutos)
```

### **PASO 2: Personalizar Credenciales por Cliente**

**Después de aplicar plantilla:**

```bash
1. Pestaña "Account" → "SIP Settings"
2. Personalizar campos específicos:
   ┌─────────────────────────────────────────────┐
   │ SIP User ID: +56229145248-office            │
   │ SIP Auth ID: +56229145248-office            │
   │ SIP Password: SKyn3t2025_OFICINA_PRINCIPAL_Office! │
   │ Display Name: Oficina Principal - Administración │
   └─────────────────────────────────────────────┘
3. Guardar configuración
4. Aplicar cambios al dispositivo
```

### **PASO 3: Verificar Estado de Registro**

**En GDMS Cloud:**
```bash
Dispositivos VoIP → Estado de cuenta:
✅ Debe mostrar "Registrado"
✅ IP Address actual del dispositivo
✅ Última conexión reciente
```

**En Twilio Console:**
```bash
SIP Domains → skyn3t-communities → Registrations:
✅ +56229145248-office [ONLINE]
```

---

## 🧪 TESTING Y VERIFICACIÓN

### **PASO 1: Testing Registro SIP**

```bash
Verificaciones inmediatas:
1. GDMS Cloud → Dispositivo → Estado: "Registrado" ✅
2. Twilio Console → SIP Registrations → Usuario online ✅
3. Dispositivo físico → Pantalla → Sin errores de red ✅
4. IP connectivity → Ping a stun.twilio.com ✅
```

### **PASO 2: Testing Llamadas Entrantes**

```bash
Proceso de testing:
1. Desde celular personal: Llamar +56229145248
2. Escuchar IVR: "Bienvenido a [CLIENTE]..."
3. Presionar "1" para oficina
4. Dispositivo GRP2601 debe sonar ✅
5. Contestar llamada
6. Verificar audio bidireccional ✅
7. Terminar llamada correctamente ✅
```

### **PASO 3: Testing Llamadas Salientes**

```bash
Proceso de testing:
1. Desde GRP2601: Marcar número celular
2. Verificar Caller ID = +56229145248 ✅
3. Celular debe sonar ✅
4. Contestar y verificar audio ✅
5. Terminar llamada ✅
```

### **PASO 4: Testing Comunicación Interna**

```bash
Si hay 2 dispositivos configurados:
1. Desde GRP2601: Marcar +56229145248-security
2. GHP621 debe sonar ✅
3. Verificar comunicación interna ✅
4. Sin cargos (tráfico interno SIP) ✅
```

---

## 🔧 TROUBLESHOOTING GDMS CLOUD

### **Problema: Dispositivo no se registra**

#### **Verificar en GDMS Cloud:**
```bash
1. Estado cuenta → "No registrado"/"Error de red"
2. Account → SIP Settings → Verificar:
   ✅ SIP Server: skyn3t-communities.sip.twilio.com
   ✅ SIP User ID exacto
   ✅ SIP Password exacto
   ✅ Register: Enabled
```

#### **Verificar configuración de red:**
```bash
Network Settings → Basic Settings:
✅ STUN Server: stun.twilio.com
✅ Keep-Alive Interval: 30
✅ Enable Outbound Notification: Enabled
```

### **Problema: Llamadas no conectan**

#### **Error 488 "Not Acceptable Here":**
```bash
Causa: Códecs incompatibles
Solución: Phone Settings → Codec Settings
✅ Solo habilitar: PCMU, PCMA, G.722
❌ Deshabilitar: G.729, G.726, iLBC, Opus
```

#### **Verificar DTMF:**
```bash
Phone Settings → Codec Settings:
✅ Send DTMF via RTP(RFC2833): Enabled
✅ DTMF Payload Type: 101
❌ Send DTMF In-audio: Disabled
❌ Send DTMF via SIP INFO: Disabled
```

### **Problema: Audio de un solo sentido**

#### **Verificar configuración NAT:**
```bash
Network Settings → Basic Settings:
✅ STUN Server: stun.twilio.com
✅ Use Random Port: Disabled
✅ Local RTP Port: 5004
✅ Local RTP Port Range: 200
```

#### **Verificar códecs de audio:**
```bash
Phone Settings → Codec Settings:
✅ Silence Suppression: Enabled
✅ Jitter Buffer Type: Adaptive
✅ Voice Frames per TX: 2
```

### **Problema: Dispositivo pierde registro**

#### **Verificar configuración de registro:**
```bash
Account → SIP Settings:
✅ Register Expiration: 1800
✅ Re-register before Expiration: 60
✅ Registration Retry Wait Time: 20
```

#### **Verificar keep-alive:**
```bash
Network Settings:
✅ Keep-Alive Interval: 30
✅ Enable Outbound Notification: Enabled
```

---

## 📊 GESTIÓN MASIVA DE DISPOSITIVOS

### **Aplicación Masiva de Plantillas**

```bash
Para múltiples dispositivos del mismo modelo:
1. Seleccionar múltiples GRP2601
2. Actions → Apply Template
3. Seleccionar: SKYN3T-Office-Template
4. Apply to Selected Devices
5. Personalizar credenciales individualmente
```

### **Sincronización de Configuraciones**

```bash
Para aplicar cambios a dispositivos activos:
1. Modificar plantilla base
2. Dispositivos VoIP → Seleccionar dispositivos
3. Actions → Sync Configuration
4. Confirmar aplicación
```

### **Monitoreo de Estado**

```bash
Dashboard GDMS Cloud:
- Dispositivos online/offline
- Estado de registro SIP
- Versiones de firmware
- Última sincronización
- Alertas de conectividad
```

---

## 🎯 PROCEDIMIENTO CLIENTE NUEVO

### **Checklist Aplicación Cliente Nuevo (10 minutos)**

```bash
□ 1. Verificar que dispositivos estén online en GDMS
□ 2. Aplicar plantilla correspondiente:
      - GRP2601 → SKYN3T-Office-Template
      - GHP621 → SKYN3T-Security-Template
□ 3. Personalizar credenciales SIP:
      - User ID: +56XXXXXXXXX-office/security
      - Password: SKyn3t2025_[CODIGO]_[ROLE]!
      - Display Name: [CLIENTE] - [ROLE]
□ 4. Aplicar configuración al dispositivo
□ 5. Verificar estado "Registrado"
□ 6. Testing básico de llamadas
□ 7. Verificar audio bidireccional
□ 8. Confirmar comunicación interna (si aplica)
```

---

## 📈 OPTIMIZACIÓN Y MANTENIMIENTO

### **Actualizaciones de Firmware**

```bash
Mantenimiento programado:
1. Verificar actualizaciones disponibles
2. Programar actualización en horario de baja demanda
3. Aplicar por lotes (por sitio/cliente)
4. Verificar funcionalidad post-actualización
```

### **Backup de Configuraciones**

```bash
Backup automático:
1. GDMS Cloud mantiene historial de configuraciones
2. Exportar plantillas periódicamente
3. Documentar cambios en configuración
4. Mantener versiones funcionales
```

### **Monitoreo Proactivo**

```bash
Alertas configurar:
- Dispositivos offline > 5 minutos
- Fallos de registro SIP
- Errores de conectividad
- Actualizaciones de firmware disponibles
```

---

## 💰 ANÁLISIS OPERACIONAL

### **Eficiencia Operacional**

```bash
Tiempo de configuración:
- Cliente nuevo: 10 minutos
- Cambio de credenciales: 2 minutos
- Aplicación masiva: 5 minutos (múltiples dispositivos)
- Troubleshooting promedio: 15 minutos
```

### **Escalabilidad**

```bash
Capacidad GDMS Cloud:
- Dispositivos gestionables: Ilimitado
- Configuración simultánea: 50+ dispositivos
- Plantillas: Ilimitadas
- Sitios: Ilimitados
```

---

## 📋 CHECKLIST FINAL

### **Sistema GDMS Cloud Configurado**

```bash
□ ✅ Plantilla GRP2601 (Office) creada y probada
□ ✅ Plantilla GHP621 (Security) creada
□ ✅ Configuraciones optimizadas para Twilio
□ ✅ Códecs compatibles configurados
□ ✅ STUN/NAT configurado correctamente
□ ✅ DTMF RFC2833 configurado
□ ✅ Timezone Chile configurado
□ ✅ Credenciales de acceso configuradas
□ ✅ Procedimiento de aplicación documentado
□ ✅ Testing completado exitosamente
□ ✅ Troubleshooting documentado
```

### **Sistema Listo para Producción**

```bash
✅ Plantillas reutilizables
✅ Configuración estandarizada
✅ Aplicación masiva funcional
✅ Gestión centralizada
✅ Monitoreo en tiempo real
✅ Escalabilidad probada
```

---

**© 2025 SKYN3T - Sistema Multi-Tenant de Comunicaciones**

**Versión**: 1.0  
**Fecha**: Julio 2025  
**Autor**: Sistema SKYN3T  
**Estado**: Producción

---

## 🔧 CONTACTO SOPORTE TÉCNICO

Para soporte con configuración GDMS Cloud:
- **Documentación**: Guía completa GDMS Cloud SKYN3T
- **Plantillas**: Verificadas y probadas en producción
- **Procedimientos**: Documentados paso a paso
- **Escalabilidad**: Sistema probado multi-cliente