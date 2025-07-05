# 📱 FreePBX Multi-Tenant Extensions Configuration - SKYN3T

**PRÓXIMO PASO RECOMENDADO**: Configurar extensiones que reemplacen los usuarios SIP de Twilio

## 🎯 PLAN DE EXTENSIONES MULTI-TENANT

### **Cliente OFICINA_PRINCIPAL (Reemplaza +56229145248)**
```yaml
Extension 2001 (Office):
├── User Extension: 2001
├── Display Name: "Oficina Principal - Office"
├── Secret: SKyn3t_Office_2025!
├── Email: oficina.principal@skyn3t.com
├── Context: from-internal
├── Voicemail: Enabled
└── CID Num Alias: +56229145248

Extension 2002 (Security):
├── User Extension: 2002
├── Display Name: "Oficina Principal - Security" 
├── Secret: SKyn3t_Security_2025!
├── Email: seguridad.principal@skyn3t.com
├── Context: from-internal
├── Voicemail: Enabled
└── CID Num Alias: +56229145248
```

### **Cliente PLAZA_NORTE (Reemplaza +56954783299)**
```yaml
Extension 3001 (Office):
├── User Extension: 3001
├── Display Name: "Plaza Norte - Office"
├── Secret: SKyn3t_PlazaNorte_2025!
├── Email: plaza.norte@skyn3t.com
├── Context: from-internal
├── Voicemail: Enabled
└── CID Num Alias: +56954783299

Extension 3002 (Security):
├── User Extension: 3002
├── Display Name: "Plaza Norte - Security"
├── Secret: SKyn3t_PlazaNorte_Sec_2025!
├── Email: seguridad.plaza@skyn3t.com
├── Context: from-internal
├── Voicemail: Enabled
└── CID Num Alias: +56954783299
```

## 🖥️ CONFIGURACIÓN PASO A PASO

### **PASO 1: Acceder a FreePBX**
```bash
# URL: http://146.19.215.149:8080/admin/
# Usuario: admin_skyn3t
# Password: SKyn3t_FreePBX_2025!
```

### **PASO 2: Crear Primera Extensión (2001)**
1. **Navegar**: Applications → Extensions → Add Extension → Add PJSIP Extension
2. **Configurar campos básicos**:
   ```yaml
   User Extension: 2001
   Display Name: Oficina Principal - Office
   Outbound CID: 2001
   Extension Options:
   ├── Emergency CID: +56229145248
   ├── Ring Time: 20
   ├── Call Waiting: Enabled
   └── Call Screening: Disabled
   ```

3. **Device Options**:
   ```yaml
   Secret: SKyn3t_Office_2025!
   DTMF Mode: RFC2833
   Disallowed Codecs: all
   Allowed Codecs: ulaw,alaw,g722
   ```

4. **Voicemail**: 
   ```yaml
   Status: Enabled
   Voicemail Password: 2001
   Email Address: oficina.principal@skyn3t.com
   Email Attachment: Yes
   Delete Voicemail: No
   ```

### **PASO 3: Crear Extensiones Restantes**
Repetir el proceso para:
- **2002** (Oficina Principal - Security)
- **3001** (Plaza Norte - Office)  
- **3002** (Plaza Norte - Security)

## 🔧 COMANDOS DE VERIFICACIÓN

### **Verificar Extensiones Creadas**
```bash
# Acceder a Asterisk CLI
sudo asterisk -r

# Verificar extensiones PJSIP
pjsip show endpoints

# Verificar configuración
dialplan show
```

### **Testing Interno Inmediato**
```bash
# Desde Asterisk CLI, simular llamada
originate PJSIP/2001 extension 2002@from-internal

# Verificar registro de extensiones
pjsip show registrations
```

## 📞 CONFIGURACIÓN DISPOSITIVOS GDMS

### **Nueva Plantilla FreePBX (Reemplaza Twilio)**
```yaml
ANTES (Twilio):
├── SIP Server: skyn3t-communities.sip.twilio.com
├── SIP User ID: +56229145248-office
├── SIP Password: SKyn3t2025_OFICINA_PRINCIPAL_Office!
└── Port: 5060

DESPUÉS (FreePBX):
├── SIP Server: 146.19.215.149
├── SIP User ID: 2001
├── SIP Password: SKyn3t_Office_2025!
└── Port: 5060
```

### **Crear Nueva Plantilla GDMS**
1. **GDMS Cloud** → Plantilla → Por modelo → Agregar plantilla
2. **Configuración**:
   ```yaml
   Nombre: SKYN3T-FreePBX-Office-Template
   Modelo: GRP2601
   SIP Server: 146.19.215.149
   SIP User ID: {{EXTENSION}} (ej: 2001)
   SIP Password: {{PASSWORD}} (ej: SKyn3t_Office_2025!)
   SIP Port: 5060
   Transport: UDP
   Códecs: PCMU, PCMA, G.722
   DTMF: RFC2833
   ```

## ✅ VENTAJAS INMEDIATAS

### **Testing Sin Costo**
- ✅ Llamadas internas gratuitas (2001 ↔ 2002)
- ✅ Testing de calidad de audio
- ✅ Verificación de funcionalidades
- ✅ Prueba de dispositivos Grandstream

### **Preparación para Migración**
- ✅ Base lista para proveedores chilenos
- ✅ Estructura multi-tenant funcional
- ✅ Dispositivos listos para reconfiguración
- ✅ Sistema validado antes de cambiar proveedores

## 🎯 PRÓXIMOS PASOS DESPUÉS DE EXTENSIONES

### **Fase 14: IVR (20 min)**
- Configurar IVR por cliente
- Reemplazar TwiML Bins de Twilio
- Testing de navegación telefónica

### **Fase 15: Proveedores Chilenos (45 min)**
- Configurar trunk Entel (72% ahorro)
- Testing llamadas salientes
- Comparar calidad vs Twilio

### **Fase 16: Migración Gradual (1-2 semanas)**
- Cliente piloto (Oficina Principal)
- Migración progresiva
- Cancelación servicios Twilio

## 🚨 CONSIDERACIONES IMPORTANTES

### **Backup Antes de Cambios**
```bash
# Backup FreePBX
sudo -u asterisk fwconsole backup --backup

# Backup base de datos
mysqldump -u root -p'FreePBX_Root_2025!' freepbx_skyn3t > backup_before_extensions.sql
```

### **Testing Progresivo**
1. **Extensiones internas** (sin costo, sin riesgo)
2. **IVR interno** (sin costo, sin riesgo)  
3. **Proveedor chileno piloto** (bajo costo, bajo riesgo)
4. **Migración completa** (máximo ahorro)

## 💰 AHORRO ESPERADO

### **Después de Migración Completa**
```yaml
Escenario Conservador (300 min/mes):
├── Twilio actual: $75 USD/mes
├── FreePBX + Entel: $21 USD/mes
├── Ahorro mensual: $54 USD (72%)
└── Ahorro anual: $648 USD

Escenario Medio (500 min/mes):
├── Twilio actual: $125 USD/mes
├── FreePBX + Entel: $35 USD/mes
├── Ahorro mensual: $90 USD (72%)
└── Ahorro anual: $1,080 USD
```

---

**🎯 RECOMENDACIÓN**: Empezar AHORA con las extensiones. Es la base fundamental y te permite testing inmediato sin costo ni riesgo.