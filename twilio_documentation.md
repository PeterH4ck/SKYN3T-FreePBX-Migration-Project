# 📞 SKYN3T - GUÍA COMPLETA CONFIGURACIÓN TWILIO

## 🎯 INTRODUCCIÓN

Esta guía documenta paso a paso la configuración completa de Twilio para el sistema SKYN3T Multi-Tenant. El sistema permite gestionar múltiples comunidades (oficinas, edificios, condominios) desde una sola cuenta Twilio.

### **Arquitectura del Sistema**
- **SIP Domain único**: `skyn3t-communities.sip.twilio.com`
- **Multi-tenant**: Múltiples comunidades en una infraestructura
- **Credential Lists independientes** por comunidad
- **TwiML Bins personalizados** por comunidad
- **Números únicos** por comunidad

---

## 📋 REQUISITOS PREVIOS

### **Cuenta Twilio**
- ✅ Cuenta Twilio activa
- ✅ Saldo suficiente para números y llamadas
- ✅ Acceso a Twilio Console
- ✅ Permisos para crear SIP Domains

### **Información por Cliente**
```yaml
Datos requeridos por comunidad:
- Nombre de la comunidad
- Código único (sin espacios)
- Número de teléfono chileno
- Tipo de roles (oficina/conserjería)
```

---

## 🚀 CONFIGURACIÓN INICIAL - SIP DOMAIN

### **PASO 1: Crear SIP Domain Principal**

**Navegación**: `Twilio Console → Programmable Voice → SIP Domains`

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

**✅ Resultado**: SIP Domain `skyn3t-communities.sip.twilio.com` creado

### **PASO 2: Configurar Autenticación Base**

En la página del SIP Domain:
```bash
Voice Authentication:
├── IP ACCESS CONTROL LISTS: (vacío)
└── CREDENTIAL LISTS: (se configurarán por comunidad)

SIP Registration:
├── ENABLED: ✅ Yes
└── SIP Registration Authentication: (agregar credential lists por comunidad)
```

---

## 🏢 CONFIGURACIÓN POR COMUNIDAD

### **Template de Configuración**

Para cada nueva comunidad, usar este template:

```yaml
# EJEMPLO: OFICINA PRINCIPAL
Comunidad: Oficina Principal
Código: OFICINA_PRINCIPAL
Número: +56229145248
Dispositivos:
  office: 
    username: +56229145248-office
    password: SKyn3t2025_OFICINA_PRINCIPAL_Office!
  security:
    username: +56229145248-security
    password: SKyn3t2025_OFICINA_PRINCIPAL_Security!
```

### **PASO 1: Crear Credential List por Comunidad**

**Navegación**: `SIP Domain → Voice Authentication → CREDENTIAL LISTS → "+"`

#### **A. Crear Credential List:**
```bash
1. Click "Create new Credential List"
2. Friendly Name: [CODIGO]_Credentials
   Ejemplo: OFICINA_PRINCIPAL_Credentials
3. Save
```

#### **B. Agregar Usuario Oficina:**
```bash
1. En la Credential List creada, click "+"
2. Configurar:
   ┌─────────────────────────────────────────────┐
   │ Username: +56XXXXXXXXX-office               │
   │ Password: SKyn3t2025_[CODIGO]_Office!       │
   │ Ejemplo:                                    │
   │ Username: +56229145248-office               │
   │ Password: SKyn3t2025_OFICINA_PRINCIPAL_Office! │
   └─────────────────────────────────────────────┘
3. Create
```

#### **C. Agregar Usuario Conserjería:**
```bash
1. Click "+" nuevamente
2. Configurar:
   ┌─────────────────────────────────────────────┐
   │ Username: +56XXXXXXXXX-security             │
   │ Password: SKyn3t2025_[CODIGO]_Security!     │
   │ Ejemplo:                                    │
   │ Username: +56229145248-security             │
   │ Password: SKyn3t2025_OFICINA_PRINCIPAL_Security! │
   └─────────────────────────────────────────────┘
3. Create
```

#### **D. Asociar Credential List al SIP Domain:**
```bash
1. Volver a SIP Domain → Voice Authentication
2. En CREDENTIAL LISTS dropdown, seleccionar la nueva lista
3. Save configuration
```

---

## 🤖 CONFIGURACIÓN IVR POR COMUNIDAD

### **PASO 1: Crear TwiML Bins**

**Navegación**: `Runtime → TwiML Bins`

#### **A. TwiML Bin Principal (Main IVR):**

```bash
1. Click "Create new TwiML Bin"
2. Friendly Name: [CODIGO]_Main_IVR
   Ejemplo: OFICINA_PRINCIPAL_Main_IVR
3. TwiML Code:
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say voice="alice" language="es-MX">
        Bienvenido a [NOMBRE COMUNIDAD]. 
        Para oficina de administración, presione 1.
        Para conserjería, presione 2.
    </Say>
    
    <Gather numDigits="1" action="[URL_ROUTING_BIN]" method="POST" timeout="10">
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

```bash
4. Save (temporalmente sin URL de routing)
```

#### **B. TwiML Bin de Enrutamiento (Call Routing):**

```bash
1. Click "Create new TwiML Bin"
2. Friendly Name: [CODIGO]_Call_Routing
   Ejemplo: OFICINA_PRINCIPAL_Call_Routing
3. TwiML Code:
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

```bash
4. Reemplazar +56XXXXXXXXX con el número real
5. Save
6. Copiar la URL del TwiML Bin
```

#### **C. Vincular TwiML Bins:**

```bash
1. Editar el Main IVR TwiML Bin
2. Reemplazar [URL_ROUTING_BIN] con la URL real del Call Routing
3. Save
```

---

## 📱 CONFIGURACIÓN NÚMEROS DE TELÉFONO

### **PASO 1: Comprar/Configurar Número**

**Navegación**: `Phone Numbers → Manage → Active Numbers`

```bash
1. Si no tienes el número, ir a "Buy a Number"
2. Seleccionar número chileno
3. Purchase
```

### **PASO 2: Configurar Número**

```bash
1. Click en el número adquirido
2. Voice Configuration:
   ┌─────────────────────────────────────────────┐
   │ Configure with: TwiML Bin                   │
   │ TwiML Bin: [CODIGO]_Main_IVR               │
   │ Ejemplo: OFICINA_PRINCIPAL_Main_IVR        │
   └─────────────────────────────────────────────┘
3. Save Configuration
```

---

## 🔍 VERIFICACIÓN Y TESTING

### **PASO 1: Verificar Registros SIP**

**Navegación**: `SIP Domains → skyn3t-communities → Registrations`

```bash
Verificar que aparezcan los usuarios registrados:
✅ +56229145248-office [ONLINE]
✅ +56229145248-security [ONLINE]
```

### **PASO 2: Testing Básico**

```bash
1. Llamar al número principal desde celular
2. Escuchar el IVR personalizado
3. Presionar "1" para oficina
4. Verificar que conecte con el dispositivo
5. Confirmar audio bidireccional
6. Terminar llamada correctamente
```

### **PASO 3: Verificar Logs**

**Navegación**: `Monitor → Logs → Calls`

```bash
Verificar que las llamadas muestren:
✅ Status: Completed
✅ To: sip:+56XXXXXXXXX-office@skyn3t-communities.sip.twilio.com
✅ Duration: > 0 segundos
❌ NO debe haber errores 4xx o 5xx
```

---

## 📊 CONFIGURACIONES MÚLTIPLES CLIENTES

### **Matriz de Configuración**

| Cliente | Código | Número | Credential List | Main IVR | Call Routing |
|---------|--------|--------|-----------------|----------|--------------|
| Oficina Principal | OFICINA_PRINCIPAL | +56229145248 | OFICINA_PRINCIPAL_Credentials | OFICINA_PRINCIPAL_Main_IVR | OFICINA_PRINCIPAL_Call_Routing |
| Edificio Plaza Norte | PLAZA_NORTE | +56223456789 | PLAZA_NORTE_Credentials | PLAZA_NORTE_Main_IVR | PLAZA_NORTE_Call_Routing |
| Condominio Las Flores | LAS_FLORES | +56234567890 | LAS_FLORES_Credentials | LAS_FLORES_Main_IVR | LAS_FLORES_Call_Routing |

### **Patrón de Nomenclatura**

```bash
Credential Lists: [CODIGO]_Credentials
TwiML Bins IVR: [CODIGO]_Main_IVR
TwiML Bins Routing: [CODIGO]_Call_Routing
Usuarios SIP: +56XXXXXXXXX-office / +56XXXXXXXXX-security
Passwords: SKyn3t2025_[CODIGO]_[ROLE]!
```

---

## 🛠️ PROCEDIMIENTO PARA AGREGAR CLIENTE NUEVO

### **Checklist Completo (15 minutos por cliente)**

```bash
□ 1. Definir datos del cliente (nombre, código, número)
□ 2. Comprar número de teléfono (si es necesario)
□ 3. Crear Credential List: [CODIGO]_Credentials
□ 4. Agregar usuario office: +56XXXXXXXXX-office
□ 5. Agregar usuario security: +56XXXXXXXXX-security
□ 6. Asociar Credential List al SIP Domain
□ 7. Crear TwiML Bin Main IVR personalizado
□ 8. Crear TwiML Bin Call Routing personalizado
□ 9. Vincular Main IVR → Call Routing (action URL)
□ 10. Configurar número de teléfono → Main IVR
□ 11. Testing básico de llamadas
□ 12. Verificar registros SIP en GDMS/dispositivos
```

---

## 🔧 TROUBLESHOOTING COMÚN

### **Problema: Usuarios no se registran**

```bash
Verificar:
✅ Credential List asociada al SIP Domain
✅ Username exacto: +56XXXXXXXXX-office
✅ Password exacto: SKyn3t2025_[CODIGO]_Office!
✅ SIP Server: skyn3t-communities.sip.twilio.com
```

### **Problema: Llamadas no conectan (Error 488)**

```bash
Causa: Códecs incompatibles
Solución: En dispositivos, habilitar solo:
✅ PCMU (G.711µ)
✅ PCMA (G.711a)
✅ G.722
❌ Deshabilitar: G.729, G.726, iLBC, otros
```

### **Problema: IVR no funciona**

```bash
Verificar:
✅ Número configurado → Main IVR TwiML Bin
✅ Main IVR action URL → Call Routing TwiML Bin
✅ Call Routing Sip URI correcto
✅ TwiML sintaxis válida
```

### **Problema: Audio de un solo sentido**

```bash
Solución en dispositivos:
✅ STUN Server: stun.twilio.com
✅ NAT Traversal: Habilitado
✅ Symmetric RTP: Habilitado
```

---

## 💰 ANÁLISIS DE COSTOS

### **Costos por Cliente/Mes (USD)**

```yaml
Número de teléfono: $1.00
Minutos promedio (100 min): $3.00
Total por cliente: ~$4.00/mes

SIP Domain: $0.00 (incluido)
Infraestructura compartida: $0.00
Total sistema 10 clientes: ~$40.00/mes
```

### **Escalabilidad**

```bash
Capacidad técnica: Ilimitada
Concurrent calls: Según plan Twilio
Gestión: Centralizada desde una cuenta
Crecimiento: Lineal por cliente
```

---

## 📈 MÉTRICAS DE ÉXITO

### **KPIs del Sistema**

```bash
✅ Tiempo setup nuevo cliente: < 15 minutos
✅ Registro SIP: < 30 segundos
✅ Conexión llamadas: > 95%
✅ Calidad audio: Sin quejas
✅ Disponibilidad: > 99.9%
```

### **Monitoreo Continuo**

```bash
Revisar semanalmente:
- Call Logs en Twilio Console
- SIP Registrations activos
- Errores 4xx/5xx en logs
- Duración promedio llamadas
- Costos por cliente
```

---

## 🎯 SIGUIENTES PASOS

### **Optimizaciones Futuras**

```bash
1. Implementar Call Routing avanzado (oficina + conserjería)
2. Agregar grabación de llamadas
3. Implementar webhooks para notificaciones
4. Dashboard de métricas en tiempo real
5. API para gestión automatizada de clientes
```

### **Integración con GDMS Cloud**

```bash
Esta configuración Twilio debe sincronizarse con:
- Plantillas GDMS Cloud por modelo de dispositivo
- Configuración automática de credenciales SIP
- Aplicación masiva a dispositivos por cliente
```

---

## 📋 CHECKLIST FINAL

### **Configuración Base Completada**

```bash
□ ✅ SIP Domain: skyn3t-communities.sip.twilio.com
□ ✅ Autenticación SIP configurada
□ ✅ Sistema multi-tenant funcional
□ ✅ Procedimiento estandarizado para nuevos clientes
□ ✅ Testing básico completado
□ ✅ Documentación actualizada
```

### **Sistema Listo para Producción**

```bash
✅ Escalable a múltiples clientes
✅ Configuración estandarizada
✅ Costos optimizados
✅ Gestión centralizada
✅ Troubleshooting documentado
```

---

**© 2025 SKYN3T - Sistema Multi-Tenant de Comunicaciones**

**Versión**: 1.0  
**Fecha**: Julio 2025  
**Autor**: Sistema SKYN3T  
**Estado**: Producción

---

## 📞 CONTACTO SOPORTE

Para soporte técnico con esta configuración:
- **Documentación**: Guía completa Twilio SKYN3T
- **Testing**: Procedimientos verificados
- **Escalabilidad**: Sistema probado en producción