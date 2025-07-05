# 📱 GUÍA COMPLETA: CONFIGURACIÓN ZOIPER5 PARA SKYN3T

## 🎯 OBJETIVO
Configurar dispositivos Zoiper5 para conectarse al sistema SKYN3T Multi-Tenant usando SIP Registration.

---

## 📥 PASO 1: INSTALACIÓN ZOIPER5

### 1.1 Descargar Zoiper5

**URLs de descarga:**
- **Windows**: https://www.zoiper.com/en/voip-softphone/download/current
- **macOS**: https://www.zoiper.com/en/voip-softphone/download/current  
- **Android**: Google Play Store → "Zoiper5"
- **iOS**: App Store → "Zoiper5"

### 1.2 Instalación Básica
```bash
1. Descargar instalador para tu plataforma
2. Ejecutar instalador (privilegios de administrador)
3. Seguir wizard de instalación
4. Abrir Zoiper5
```

---

## ⚙️ PASO 2: CONFIGURACIÓN PRIMERA CUENTA

### 2.1 Iniciar Configuración de Cuenta

```bash
1. Abrir Zoiper5
2. En pantalla inicial → "Create account"
3. O en configuración → Settings → Accounts → Add Account
```

### 2.2 Datos de Configuración Base

**Información común para todas las cuentas SKYN3T:**
```yaml
Servidor SIP: skyn3t-communities.sip.twilio.com
Puerto: 5060
Transporte: UDP
STUN Server: stun.twilio.com:3478
Registro: ✅ SÍ habilitado
```

---

## 🏢 PASO 3: CONFIGURACIÓN POR TIPO DE CUENTA

### 3.1 Cuenta de Oficina (Office)

#### Datos Específicos
```bash
┌─────────────────────────────────────────────┐
│ CONFIGURACIÓN OFICINA                       │
├─────────────────────────────────────────────┤
│ Account Name: [COMUNIDAD] - Oficina        │
│ Username: +56XXXXXXXXX-office               │
│ Password: SKyn3t2025_[CODIGO]_Office!       │
│ Domain: skyn3t-communities.sip.twilio.com   │
│ Display Name: Oficina [COMUNIDAD]          │
└─────────────────────────────────────────────┘
```

#### Ejemplos por Comunidad
```yaml
Oficina Principal:
  Account Name: "Oficina Principal - Admin"
  Username: "+56229145248-office"
  Password: "SKyn3t2025_OFICINA_PRINCIPAL_Office!"
  Display Name: "Oficina Principal"

Valparaíso:
  Account Name: "Valparaíso - Admin"  
  Username: "+56987654321-office"
  Password: "SKyn3t2025_VALPARAISO_Office!"
  Display Name: "Oficina Valparaíso"
```

### 3.2 Cuenta de Conserjería (Security)

#### Datos Específicos
```bash
┌─────────────────────────────────────────────┐
│ CONFIGURACIÓN CONSERJERÍA                   │
├─────────────────────────────────────────────┤
│ Account Name: [COMUNIDAD] - Conserjería    │
│ Username: +56XXXXXXXXX-security             │
│ Password: SKyn3t2025_[CODIGO]_Security!     │
│ Domain: skyn3t-communities.sip.twilio.com   │
│ Display Name: Conserjería [COMUNIDAD]      │
└─────────────────────────────────────────────┘
```

---

## 🔧 PASO 4: CONFIGURACIÓN DETALLADA EN ZOIPER5

### 4.1 Configuración Básica

```bash
En Zoiper5 → Settings → Accounts → Add Account:

1. Account Type: SIP
2. Account Credentials:
   ┌─────────────────────────────────────────────┐
   │ Username: [según tipo de cuenta]            │
   │ Password: [según tipo de cuenta]            │
   └─────────────────────────────────────────────┘

3. Domain Settings:
   ┌─────────────────────────────────────────────┐
   │ Domain: skyn3t-communities.sip.twilio.com   │
   │ Outbound Proxy: (vacío)                     │
   └─────────────────────────────────────────────┘
```

### 4.2 Configuración Avanzada de Red

```bash
Network Settings:
┌─────────────────────────────────────────────┐
│ Transport Protocol: UDP                     │
│ Port: 5060                                  │
│ STUN Server: stun.twilio.com                │
│ STUN Port: 3478                            │
│ Enable STUN: ✅ Yes                        │
│ Keep Alive: 30 seconds                     │
└─────────────────────────────────────────────┘
```

### 4.3 Configuración de Autenticación

```bash
Authentication:
┌─────────────────────────────────────────────┐
│ Auth Username: [mismo que Username]         │
│ Register: ✅ Yes                           │
│ Register Expires: 1800 (30 minutos)        │
│ Subscribe for MWI: ❌ No                   │
└─────────────────────────────────────────────┘
```

### 4.4 Configuración de Audio

```bash
Audio Settings:
┌─────────────────────────────────────────────┐
│ Preferred Codecs:                           │
│ 1. PCMU (G.711µ)                           │
│ 2. PCMA (G.711a)                           │
│ 3. G722                                     │
│ DTMF Method: RFC 2833                      │
│ Echo Cancellation: ✅ Yes                  │
└─────────────────────────────────────────────┘
```

---

## ➕ PASO 5: AGREGAR MÚLTIPLES CUENTAS

### 5.1 Configuración Multi-Cuenta

Para probar multiple comunidades o roles:

```bash
1. Settings → Accounts → Add Account
2. Repetir configuración con diferentes credenciales
3. Cada cuenta aparecerá como línea separada
4. Cambiar entre cuentas desde la interfaz principal
```

### 5.2 Ejemplo: Configurar 2 Cuentas Simultáneas

#### Cuenta 1: Oficina Principal
```yaml
Account Name: "Oficina Principal"
Username: "+56229145248-office"
Password: "SKyn3t2025_OFICINA_PRINCIPAL_Office!"
Status: [Debe mostrar "Registered" ✅]
```

#### Cuenta 2: Oficina Valparaíso  
```yaml
Account Name: "Valparaíso"
Username: "+56987654321-office"  
Password: "SKyn3t2025_VALPARAISO_Office!"
Status: [Debe mostrar "Registered" ✅]
```

---

## ✅ PASO 6: VERIFICACIÓN DE CONFIGURACIÓN

### 6.1 Verificar Estado de Registro

```bash
Indicadores de Éxito:
├── Status: "Registered" (verde)
├── Icono de conectividad: Verde/Activo
├── Sin errores en logs
└── Puede hacer/recibir llamadas
```

### 6.2 Verificar en Twilio Console

```bash
1. Twilio Console → SIP Domains
2. Click en "skyn3t-communities"
3. Tab "Registrations"
4. Debe aparecer tu usuario registrado:
   - +56XXXXXXXXX-office [ONLINE]
   - IP address actual
   - Timestamp reciente
```

---

## 🧪 PASO 7: TESTING BÁSICO

### 7.1 Test de Llamada Entrante

```bash
1. Desde tu celular personal:
2. Llamar al número de la comunidad
   Ejemplo: +56229145248
3. Debe escuchar:
   "Bienvenido a [COMUNIDAD]..."
4. Presionar "1" para oficina
5. Zoiper5 debe sonar
6. Contestar y verificar audio
```

### 7.2 Test de Llamada Saliente

```bash
1. Desde Zoiper5:
2. Marcar tu número celular
   Formato: +56912345678
3. Tu celular debe sonar
4. Caller ID debe mostrar el número principal
5. Verificar audio bidireccional
```

### 7.3 Test de Comunicación Interna

```bash
1. Con 2 cuentas Zoiper configuradas:
2. Desde cuenta 1, marcar cuenta 2:
   Ejemplo: +56229145248-security
3. Cuenta 2 debe sonar
4. Verificar comunicación interna
```

---

## 🛠️ TROUBLESHOOTING COMÚN

### Error: "Registration Failed"

**Posibles causas:**
```bash
□ Username/password incorrectos
□ Domain mal configurado  
□ Firewall bloqueando puerto 5060
□ Problema de internet/conectividad
```

**Soluciones:**
```bash
1. Verificar credenciales exactas
2. Verificar dominio: skyn3t-communities.sip.twilio.com
3. Probar desde otra red (datos móviles)
4. Revisar logs de Zoiper5
```

### Error: "No Audio" 

**Soluciones:**
```bash
1. Verificar STUN server: stun.twilio.com
2. Verificar códecs habilitados
3. Probar con auriculares
4. Verificar configuración de micrófono/altavoz
```

### Error: "Cannot Connect"

**Soluciones:**
```bash
1. Verificar conectividad internet
2. Probar ping a skyn3t-communities.sip.twilio.com
3. Verificar firewall/antivirus
4. Reiniciar aplicación Zoiper5
```

---

## 📋 PLANTILLAS DE CONFIGURACIÓN

### Template Oficina
```ini
[ACCOUNT_OFFICE]
account_name = [COMUNIDAD] - Oficina
username = +56XXXXXXXXX-office
password = SKyn3t2025_[CODIGO]_Office!
domain = skyn3t-communities.sip.twilio.com
port = 5060
transport = UDP
stun_server = stun.twilio.com:3478
register = true
```

### Template Conserjería
```ini
[ACCOUNT_SECURITY]
account_name = [COMUNIDAD] - Conserjería
username = +56XXXXXXXXX-security
password = SKyn3t2025_[CODIGO]_Security!
domain = skyn3t-communities.sip.twilio.com
port = 5060
transport = UDP
stun_server = stun.twilio.com:3478
register = true
```

---

## 📊 CHECKLIST DE CONFIGURACIÓN

### Por cada cuenta nueva:
```bash
□ Credenciales verificadas en Twilio
□ Cuenta creada en Zoiper5
□ Status "Registered" en Zoiper5
□ Aparece en Twilio Console Registrations
□ Test llamada entrante exitoso
□ Test llamada saliente exitoso
□ Audio bidireccional funcional
□ Sin errores en logs
```

### Para múltiples cuentas:
```bash
□ Todas las cuentas registradas
□ Puede cambiar entre cuentas
□ Llamadas internas funcionan
□ Cada cuenta responde a su IVR
□ No conflictos entre registros
```

---

**Esta guía permite configurar tantas cuentas Zoiper5 como sea necesario para el sistema SKYN3T multi-tenant.**