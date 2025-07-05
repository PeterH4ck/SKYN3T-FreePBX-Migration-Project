# 🤖 TEMPLATES Y SCRIPTS DE AUTOMATIZACIÓN SKYN3T

## 🎯 OBJETIVO
Automatizar y estandarizar la configuración de nuevas comunidades mediante templates y scripts reutilizables.

---

## 📋 TEMPLATE DE CONFIGURACIÓN COMUNIDAD

### Variables de Configuración
```yaml
# CONFIGURACIÓN BASE COMUNIDAD
COMMUNITY_NAME: "[NOMBRE_COMPLETO]"
COMMUNITY_CODE: "[CODIGO_UNICO]"
PHONE_NUMBER: "+56XXXXXXXXX"
LOCATION: "[CIUDAD, REGIÓN]"
BUSINESS_TYPE: "[OFICINA|EDIFICIO|CONDOMINIO]"

# ROLES ESPECÍFICOS
OFFICE_ROLE_NAME: "[oficina|administración|recepción]"
SECURITY_ROLE_NAME: "[conserjería|seguridad|portería]"

# CONFIGURACIÓN TÉCNICA
SIP_DOMAIN: "skyn3t-communities.sip.twilio.com"
CREDENTIAL_LIST_NAME: "[CODIGO]_Credentials"
MAIN_IVR_BIN: "[CODIGO]_Main_IVR"
ROUTING_BIN: "[CODIGO]_Call_Routing"
```

---

## 🔐 GENERADOR DE CREDENCIALES

### Script de Generación de Passwords
```javascript
// generador_credenciales.js
function generateCommunityCredentials(communityCode, phoneNumber) {
    const credentials = {
        community_code: communityCode,
        phone_number: phoneNumber,
        office: {
            username: `${phoneNumber}-office`,
            password: `SKyn3t2025_${communityCode}_Office!`,
            display_name: `${communityCode} - Oficina`
        },
        security: {
            username: `${phoneNumber}-security`, 
            password: `SKyn3t2025_${communityCode}_Security!`,
            display_name: `${communityCode} - Conserjería`
        },
        credential_list_name: `${communityCode}_Credentials`
    };
    
    return credentials;
}

// Ejemplo de uso:
const credentials = generateCommunityCredentials("VALPARAISO", "+56322123456");
console.log(JSON.stringify(credentials, null, 2));
```

### Output Ejemplo:
```json
{
  "community_code": "VALPARAISO",
  "phone_number": "+56322123456",
  "office": {
    "username": "+56322123456-office",
    "password": "SKyn3t2025_VALPARAISO_Office!",
    "display_name": "VALPARAISO - Oficina"
  },
  "security": {
    "username": "+56322123456-security",
    "password": "SKyn3t2025_VALPARAISO_Security!",
    "display_name": "VALPARAISO - Conserjería"
  },
  "credential_list_name": "VALPARAISO_Credentials"
}
```

---

## 📞 TEMPLATES TWIML DINÁMICOS

### Template Main IVR
```xml
<!-- template_main_ivr.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say voice="alice" language="es-MX">
        Bienvenido a {{COMMUNITY_NAME}}. 
        Para {{OFFICE_ROLE_NAME}}, presione 1.
        Para {{SECURITY_ROLE_NAME}}, presione 2.
    </Say>
    
    <Gather numDigits="1" action="{{ROUTING_BIN_URL}}" method="POST" timeout="10">
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

### Template Call Routing
```xml
<!-- template_call_routing.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say voice="alice" language="es-MX">
        Conectando con {{OFFICE_ROLE_NAME}} de {{COMMUNITY_NAME}}.
    </Say>
    <Dial timeout="30" callerId="{{PHONE_NUMBER}}">
        <Sip>sip:{{PHONE_NUMBER}}-office@{{SIP_DOMAIN}}</Sip>
    </Dial>
    <Say voice="alice" language="es-MX">
        No se pudo completar la conexión con {{OFFICE_ROLE_NAME}}. Adiós.
    </Say>
    <Hangup/>
</Response>
```

---

## 🛠️ GENERADOR DE TWIML

### Script JavaScript para Generar TwiML
```javascript
// twiml_generator.js
function generateTwiMLs(config) {
    const mainIVR = `<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say voice="alice" language="es-MX">
        Bienvenido a ${config.COMMUNITY_NAME}. 
        Para ${config.OFFICE_ROLE_NAME}, presione 1.
        Para ${config.SECURITY_ROLE_NAME}, presione 2.
    </Say>
    
    <Gather numDigits="1" action="${config.ROUTING_BIN_URL}" method="POST" timeout="10">
        <Say voice="alice" language="es-MX">
            Por favor, seleccione una opción.
        </Say>
    </Gather>
    
    <Say voice="alice" language="es-MX">
        No se detectó ninguna selección. Adiós.
    </Say>
    <Hangup/>
</Response>`;

    const callRouting = `<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say voice="alice" language="es-MX">
        Conectando con ${config.OFFICE_ROLE_NAME} de ${config.COMMUNITY_NAME}.
    </Say>
    <Dial timeout="30" callerId="${config.PHONE_NUMBER}">
        <Sip>sip:${config.PHONE_NUMBER}-office@${config.SIP_DOMAIN}</Sip>
    </Dial>
    <Say voice="alice" language="es-MX">
        No se pudo completar la conexión. Adiós.
    </Say>
    <Hangup/>
</Response>`;

    return {
        mainIVR: mainIVR,
        callRouting: callRouting
    };
}

// Configuración ejemplo
const config = {
    COMMUNITY_NAME: "Oficina Valparaíso",
    OFFICE_ROLE_NAME: "oficina regional", 
    SECURITY_ROLE_NAME: "seguridad",
    PHONE_NUMBER: "+56322123456",
    SIP_DOMAIN: "skyn3t-communities.sip.twilio.com",
    ROUTING_BIN_URL: "https://handler.twilio.com/twiml/EH[ROUTING_BIN_ID]"
};

const twiml = generateTwiMLs(config);
console.log("=== MAIN IVR ===");
console.log(twiml.mainIVR);
console.log("\n=== CALL ROUTING ===");
console.log(twiml.callRouting);
```

---

## 📝 CHECKLIST AUTOMATIZADO

### Template de Verificación
```markdown
# CHECKLIST CONFIGURACIÓN: {{COMMUNITY_NAME}}

## Pre-Configuración
- [ ] Número de teléfono comprado: {{PHONE_NUMBER}}
- [ ] Código de comunidad definido: {{COMMUNITY_CODE}}
- [ ] Roles definidos: {{OFFICE_ROLE_NAME}} / {{SECURITY_ROLE_NAME}}

## Configuración Twilio
- [ ] Credential List creada: {{CREDENTIAL_LIST_NAME}}
- [ ] Usuario office agregado: {{PHONE_NUMBER}}-office  
- [ ] Usuario security agregado: {{PHONE_NUMBER}}-security
- [ ] Credential List asociada al SIP Domain
- [ ] TwiML Bin Main IVR creado: {{MAIN_IVR_BIN}}
- [ ] TwiML Bin Call Routing creado: {{ROUTING_BIN}}
- [ ] TwiML Bins vinculados correctamente
- [ ] Número configurado → Main IVR

## Testing
- [ ] Registro SIP exitoso (office)
- [ ] Registro SIP exitoso (security)  
- [ ] Llamada externa → IVR funciona
- [ ] Opción "1" → conecta con office
- [ ] Audio bidireccional correcto
- [ ] Sin errores en logs de Twilio

## Post-Configuración  
- [ ] Documentación actualizada
- [ ] Credenciales compartidas con responsables
- [ ] Configuración Zoiper5 validada
- [ ] Sistema en producción

**Configurado por:** [NOMBRE]
**Fecha:** [FECHA]
**Tiempo total:** [XX minutos]
```

---

## 🔧 CONFIGURACIONES DE ZOIPER5

### Template de Configuración Zoiper Office
```ini
[ZOIPER_CONFIG_OFFICE]
account_name={{COMMUNITY_NAME}} - {{OFFICE_ROLE_NAME}}
username={{PHONE_NUMBER}}-office
password={{OFFICE_PASSWORD}}
domain=skyn3t-communities.sip.twilio.com
port=5060
transport=UDP
stun_server=stun.twilio.com:3478
stun_port=3478
register=true
register_expires=1800
auth_username={{PHONE_NUMBER}}-office
display_name={{COMMUNITY_NAME}} Office
```

### Template de Configuración Zoiper Security  
```ini
[ZOIPER_CONFIG_SECURITY]
account_name={{COMMUNITY_NAME}} - {{SECURITY_ROLE_NAME}}
username={{PHONE_NUMBER}}-security
password={{SECURITY_PASSWORD}}
domain=skyn3t-communities.sip.twilio.com
port=5060
transport=UDP
stun_server=stun.twilio.com:3478
stun_port=3478
register=true
register_expires=1800
auth_username={{PHONE_NUMBER}}-security
display_name={{COMMUNITY_NAME}} Security
```

---

## 📊 DASHBOARD DE CONFIGURACIÓN

### Template HTML para Dashboard Interno
```html
<!DOCTYPE html>
<html>
<head>
    <title>SKYN3T - Configuración Comunidades</title>
    <style>
        .community { border: 1px solid #ccc; margin: 10px; padding: 15px; }
        .configured { background-color: #d4edda; }
        .pending { background-color: #fff3cd; }
        .error { background-color: #f8d7da; }
    </style>
</head>
<body>
    <h1>🏢 SKYN3T - Estado de Comunidades</h1>
    
    <div class="community configured">
        <h3>✅ Oficina Principal</h3>
        <p><strong>Número:</strong> +56229145248</p>
        <p><strong>Estado:</strong> Configurada y Operativa</p>
        <p><strong>Usuarios:</strong> 2 registrados</p>
        <p><strong>Última llamada:</strong> Hace 5 minutos</p>
    </div>
    
    <div class="community pending">
        <h3>⏳ Oficina Valparaíso</h3>
        <p><strong>Número:</strong> Por asignar</p>
        <p><strong>Estado:</strong> Pendiente configuración</p>
        <p><strong>Progreso:</strong> 0% completado</p>
    </div>
    
    <div class="community pending">
        <h3>⏳ Edificio Laguna Sur</h3>
        <p><strong>Número:</strong> Por asignar</p>
        <p><strong>Estado:</strong> Pendiente configuración</p>
        <p><strong>Progreso:</strong> 0% completado</p>
    </div>
    
    <div class="community pending">
        <h3>⏳ Condominio Colina</h3>
        <p><strong>Número:</strong> Por asignar</p>
        <p><strong>Estado:</strong> Pendiente configuración</p>
        <p><strong>Progreso:</strong> 0% completado</p>
    </div>
</body>
</html>
```

---

## 🎯 SCRIPT DE CONFIGURACIÓN RÁPIDA

### Configurador Express (Pseudocódigo)
```javascript
// quick_setup.js
async function configureNewCommunity(config) {
    console.log(`🏗️ Configurando comunidad: ${config.COMMUNITY_NAME}`);
    
    // Paso 1: Generar credenciales
    console.log("1️⃣ Generando credenciales...");
    const credentials = generateCommunityCredentials(
        config.COMMUNITY_CODE, 
        config.PHONE_NUMBER
    );
    
    // Paso 2: Crear TwiML Bins
    console.log("2️⃣ Generando TwiML Bins...");
    const twimlBins = generateTwiMLs(config);
    
    // Paso 3: Generar configuraciones Zoiper
    console.log("3️⃣ Generando configuraciones Zoiper...");
    const zoiperConfigs = generateZoiperConfigs(credentials, config);
    
    // Paso 4: Generar checklist
    console.log("4️⃣ Generando checklist...");
    const checklist = generateChecklist(config);
    
    // Paso 5: Mostrar resumen
    console.log("✅ Configuración generada exitosamente!");
    console.log("\n📋 SIGUIENTE PASOS:");
    console.log("1. Comprar número de teléfono en Twilio");
    console.log("2. Crear Credential List en Twilio Console");
    console.log("3. Crear TwiML Bins con el código generado");
    console.log("4. Configurar Zoiper5 con las credenciales");
    console.log("5. Probar sistema completo");
    
    return {
        credentials,
        twimlBins,
        zoiperConfigs,
        checklist
    };
}

// Configuración de ejemplo
const valparaisoConfig = {
    COMMUNITY_NAME: "Oficina Valparaíso",
    COMMUNITY_CODE: "VALPARAISO",
    PHONE_NUMBER: "+56322123456",
    LOCATION: "Valparaíso, Chile",
    BUSINESS_TYPE: "OFICINA",
    OFFICE_ROLE_NAME: "oficina regional",
    SECURITY_ROLE_NAME: "seguridad",
    SIP_DOMAIN: "skyn3t-communities.sip.twilio.com"
};

// Ejecutar configuración
configureNewCommunity(valparaisoConfig);
```

---

## 📋 TEMPLATES DE DOCUMENTACIÓN

### Template README por Comunidad
```markdown
# 📞 {{COMMUNITY_NAME}} - SKYN3T

## 📊 Información General
- **Código:** {{COMMUNITY_CODE}}
- **Número Principal:** {{PHONE_NUMBER}}
- **Ubicación:** {{LOCATION}}
- **Tipo:** {{BUSINESS_TYPE}}

## 🔐 Credenciales de Acceso

### {{OFFICE_ROLE_NAME}}
- **Usuario:** {{PHONE_NUMBER}}-office
- **Contraseña:** {{OFFICE_PASSWORD}}
- **Zoiper5:** [Link a configuración]

### {{SECURITY_ROLE_NAME}}  
- **Usuario:** {{PHONE_NUMBER}}-security
- **Contraseña:** {{SECURITY_PASSWORD}}
- **Zoiper5:** [Link a configuración]

## 📞 Uso del Sistema

### Para llamar desde exterior:
1. Marcar: {{PHONE_NUMBER}}
2. Escuchar menú de opciones
3. Presionar "1" para {{OFFICE_ROLE_NAME}}
4. Presionar "2" para {{SECURITY_ROLE_NAME}}

### Para llamadas internas:
- {{OFFICE_ROLE_NAME}} → {{SECURITY_ROLE_NAME}}: Marcar {{PHONE_NUMBER}}-security
- {{SECURITY_ROLE_NAME}} → {{OFFICE_ROLE_NAME}}: Marcar {{PHONE_NUMBER}}-office

## 🛠️ Soporte Técnico
- **Sistema:** SKYN3T Multi-Tenant
- **Documentación:** [Link a docs completas]
- **Contacto técnico:** [Email/Teléfono]

---
**Configurado:** {{DATE}}
**Versión:** 1.0
```

---

## ⚡ PROCESO DE CONFIGURACIÓN EXPRESS

### Tiempo Estimado: 15 minutos por comunidad

```bash
┌─────────────────────────────────────────────┐
│ PROCESO EXPRESS DE CONFIGURACIÓN           │
├─────────────────────────────────────────────┤
│ 1. Ejecutar script generador (2 min)       │
│ 2. Comprar número en Twilio (2 min)        │
│ 3. Crear Credential List (3 min)           │  
│ 4. Crear TwiML Bins (5 min)                │
│ 5. Configurar número → IVR (1 min)         │
│ 6. Testing básico (2 min)                  │
├─────────────────────────────────────────────┤
│ TOTAL: ~15 minutos por comunidad            │
└─────────────────────────────────────────────┘
```

---

**Estos templates y scripts permiten configurar nuevas comunidades SKYN3T de forma rápida, consistente y sin errores.**