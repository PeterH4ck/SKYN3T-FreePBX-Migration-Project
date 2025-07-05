# 📖 GUÍA COMPLETA: CONFIGURACIÓN TWILIO SIP DOMAIN MULTI-TENANT

## 🎯 ARQUITECTURA DEL SISTEMA

### Concepto Multi-Tenant
```
SIP Domain Único: skyn3t-communities.sip.twilio.com
├── Comunidad 1: Oficina Principal
│   ├── +56229145248-office
│   └── +56229145248-security  
├── Comunidad 2: Oficina Valparaíso
│   ├── +56987654321-office
│   └── +56987654321-security
├── Comunidad 3: Edificio Laguna Sur
│   ├── +56912345678-office
│   └── +56912345678-security
└── Comunidad 4: Condominio Colina
    ├── +56976543210-office
    └── +56976543210-security
```

---

## 🚀 PASO 1: CONFIGURACIÓN INICIAL SIP DOMAIN

### 1.1 Crear SIP Domain Principal

**Navegación**: Twilio Console → Programmable Voice → SIP Domains

```bash
1. Click "Create a SIP Domain"
2. Configurar:
   ┌─────────────────────────────────────────────┐
   │ Domain Name: skyn3t-communities             │
   │ Friendly Name: SKYN3T Communities Platform  │
   │ Voice Configuration Request URL: (vacío)    │
   │ Voice Method: POST                          │
   │ SIP Registration: ✅ ENABLED               │
   └─────────────────────────────────────────────┘
3. Save Domain
```

**Resultado**: `skyn3t-communities.sip.twilio.com` activo

### 1.2 Configurar Autenticación Base

**En la página del SIP Domain creado:**

```bash
Voice Authentication:
├── IP ACCESS CONTROL LISTS: (vacío)
└── CREDENTIAL LISTS: (configurar por comunidad)

SIP Registration:
├── ENABLED: ✅ Yes
└── SIP Registration Authentication: (agregar credential lists)
```

---

## 📞 PASO 2: CONFIGURACIÓN POR COMUNIDAD

### 2.1 Template de Comunidad

Para cada nueva comunidad, seguir este template:

```yaml
Comunidad: [NOMBRE]
Número Principal: +56XXXXXXXXX
Dispositivos:
  office: 
    username: +56XXXXXXXXX-office
    password: SKyn3t2025_[CODIGO]_Office!
  security:
    username: +56XXXXXXXXX-security  
    password: SKyn3t2025_[CODIGO]_Security!
```

### 2.2 Crear Credential List por Comunidad

**Navegación**: SIP Domain → Voice Authentication → CREDENTIAL LISTS → "+"

```bash
1. Crear Credential List:
   ┌─────────────────────────────────────────────┐
   │ Friendly Name: [CODIGO]_Credentials         │
   │ Ejemplo: OFICINA_PRINCIPAL_Credentials      │
   └─────────────────────────────────────────────┘

2. Agregar Usuario Oficina:
   ┌─────────────────────────────────────────────┐
   │ Username: +56XXXXXXXXX-office               │
   │ Password: SKyn3t2025_[CODIGO]_Office!       │
   └─────────────────────────────────────────────┘

3. Agregar Usuario Conserjería:
   ┌─────────────────────────────────────────────┐
   │ Username: +56XXXXXXXXX-security             │
   │ Password: SKyn3t2025_[CODIGO]_Security!     │
   └─────────────────────────────────────────────┘
```

### 2.3 Asociar Credential List al Domain

```bash
1. En SIP Domain → Voice Authentication
2. CREDENTIAL LISTS dropdown → Seleccionar la nueva lista
3. Save configuration
```

---

## 🤖 PASO 3: CONFIGURACIÓN IVR POR COMUNIDAD

### 3.1 Crear TwiML Bins Personalizados

**Navegación**: Runtime → TwiML Bins

#### A. TwiML Bin Principal (por comunidad)
```bash
Friendly Name: [CODIGO]_Main_IVR
Ejemplo: OFICINA_PRINCIPAL_Main_IVR
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say voice="alice" language="es-MX">
        Bienvenido a [NOMBRE COMUNIDAD]. 
        Para oficina de administración, presione 1.
        Para conserjería, presione 2.
    </Say>
    
    <Gather numDigits="1" action="https://handler.twilio.com/twiml/[ROUTING_BIN_ID]" method="POST" timeout="10">
        <Say voice="alice" language="es-MX">
            Por favor, seleccione una opción.
        </Say>
    </Gather>
    
    <Say voice="alice" language="es-MX">
        No se detectó ninguna selección. Adiós.
    </Say>
    <Hangup/>
</Response>
```

#### B. TwiML Bin de Enrutamiento (por comunidad)
```bash
Friendly Name: [CODIGO]_Call_Routing
Ejemplo: OFICINA_PRINCIPAL_Call_Routing
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say voice="alice" language="es-MX">
        Conectando con oficina de administración.
    </Say>
    <Dial timeout="30" callerId="+56XXXXXXXXX">
        <Sip>sip:+56XXXXXXXXX-office@skyn3t-communities.sip.twilio.com</Sip>
    </Dial>
    <Say voice="alice" language="es-MX">
        No se pudo completar la conexión. Adiós.
    </Say>
    <Hangup/>
</Response>
```

### 3.2 Vincular TwiML Bins

```bash
1. Copiar URL del Routing Bin
2. Pegar en el "action" del Main IVR
3. Save ambos bins
```

---

## 📱 PASO 4: CONFIGURACIÓN NÚMEROS DE TELÉFONO

### 4.1 Comprar/Configurar Número por Comunidad

**Navegación**: Phone Numbers → Manage → Active Numbers

```bash
1. Comprar número chileno
2. Click en el número
3. Voice Configuration:
   ┌─────────────────────────────────────────────┐
   │ Configure with: TwiML Bin                   │
   │ TwiML Bin: [CODIGO]_Main_IVR               │
   │ Ejemplo: OFICINA_PRINCIPAL_Main_IVR        │
   └─────────────────────────────────────────────┘
4. Save Configuration
```

---

## 🏗️ CONFIGURACIONES ESPECÍFICAS POR COMUNIDAD

### Comunidad 1: Oficina Principal
```yaml
Número: +56229145248 (YA CONFIGURADO ✅)
Código: OFICINA_PRINCIPAL
Credential List: OFICINA_PRINCIPAL_Credentials
Users:
  - +56229145248-office / SKyn3t2025_OFICINA_PRINCIPAL_Office!
  - +56229145248-security / SKyn3t2025_OFICINA_PRINCIPAL_Security!
TwiML Bins:
  - OFICINA_PRINCIPAL_Main_IVR
  - OFICINA_PRINCIPAL_Call_Routing
```

### Comunidad 2: Oficina Valparaíso
```yaml
Número: +56987654321 (POR CONFIGURAR)
Código: VALPARAISO
Credential List: VALPARAISO_Credentials
Users:
  - +56987654321-office / SKyn3t2025_VALPARAISO_Office!
  - +56987654321-security / SKyn3t2025_VALPARAISO_Security!
TwiML Bins:
  - VALPARAISO_Main_IVR
  - VALPARAISO_Call_Routing
```

### Comunidad 3: Edificio Laguna Sur
```yaml
Número: +56912345678 (POR CONFIGURAR)
Código: LAGUNA_SUR
Credential List: LAGUNA_SUR_Credentials
Users:
  - +56912345678-office / SKyn3t2025_LAGUNA_SUR_Office!
  - +56912345678-security / SKyn3t2025_LAGUNA_SUR_Security!
TwiML Bins:
  - LAGUNA_SUR_Main_IVR
  - LAGUNA_SUR_Call_Routing
```

### Comunidad 4: Condominio Colina
```yaml
Número: +56976543210 (POR CONFIGURAR)
Código: COLINA
Credential List: COLINA_Credentials
Users:
  - +56976543210-office / SKyn3t2025_COLINA_Office!
  - +56976543210-security / SKyn3t2025_COLINA_Security!
TwiML Bins:
  - COLINA_Main_IVR
  - COLINA_Call_Routing
```

---

## ⚙️ PROCEDIMIENTO PARA AGREGAR NUEVA COMUNIDAD

### Checklist Completo
```bash
□ 1. Definir código y número de la comunidad
□ 2. Comprar número de teléfono en Twilio
□ 3. Crear Credential List para la comunidad
□ 4. Agregar 2 usuarios (office + security)
□ 5. Asociar Credential List al SIP Domain
□ 6. Crear TwiML Bin Main IVR personalizado
□ 7. Crear TwiML Bin Call Routing personalizado
□ 8. Vincular ambos TwiML Bins
□ 9. Configurar número → Main IVR
□ 10. Probar con Zoiper5
```

### Tiempo Estimado por Comunidad
- **Configuración**: 15 minutos
- **Testing**: 10 minutos
- **Total**: 25 minutos por comunidad

---

## 📊 ESTADO ACTUAL DEL SISTEMA

### Configuraciones Completadas
- ✅ **SIP Domain**: skyn3t-communities.sip.twilio.com
- ✅ **Oficina Principal**: 100% funcional
- ⏳ **Valparaíso**: Pendiente
- ⏳ **Laguna Sur**: Pendiente  
- ⏳ **Colina**: Pendiente

### Próximos Pasos
1. **Completar comunidades restantes**
2. **Configurar teléfonos IP físicos**
3. **Implementar dashboard de administración**
4. **Sistema de monitoreo en tiempo real**

---

## 🔍 VERIFICACIÓN Y TESTING

### Test Básico por Comunidad
```bash
1. Llamar al número principal
2. Escuchar saludo personalizado
3. Presionar "1" → debe conectar con office
4. Verificar audio bidireccional
5. Llamada debe terminar correctamente
```

### Métricas de Éxito
- ✅ Registro SIP exitoso
- ✅ IVR responde correctamente
- ✅ Enrutamiento funcional
- ✅ Audio de calidad
- ✅ Sin errores en logs

---

**Esta guía proporciona la base completa para escalar el sistema SKYN3T a múltiples comunidades de forma estandarizada y eficiente.**