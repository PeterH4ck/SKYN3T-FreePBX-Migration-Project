# 🏗️ ARQUITECTURA SKYN3T CON ASTERISK PBX

## 📊 **Comparación de Costos (Por minuto a celular chileno)**

| Proveedor | Costo/minuto | Costo mensual 500 min | Ahorro vs Twilio |
|-----------|--------------|----------------------|------------------|
| **Twilio actual** | $50 CLP (~$0.05 USD) | $25,000 CLP | - |
| **Entel Empresas** | $14 CLP | $7,000 CLP | **72% ahorro** |
| **VTR Empresas** | $15 CLP | $7,500 CLP | **70% ahorro** |
| **VoIP.ms** | $20 CLP (~$0.02 USD) | $10,000 CLP | **60% ahorro** |

## 🏗️ **Nueva Arquitectura Propuesta**

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Dispositivos  │    │   Asterisk PBX   │    │  Proveedores    │
│   Grandstream   │◄──►│  (Tu servidor)   │◄──►│   SIP Trunk     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
    ┌────▼────┐             ┌────▼────┐             ┌────▼────┐
    │ GRP2601 │             │ FreePBX │             │  Entel  │
    │ GHP621  │             │   GUI   │             │   VTR   │
    │ (Office)│             │ (Web)   │             │VoIP.ms  │
    └─────────┘             └─────────┘             └─────────┘
```

## 🔧 **Configuración del Sistema**

### **1. Servidor Base (Ubuntu 22.04 LTS)**
```bash
# Instalar FreePBX (Asterisk + GUI web)
wget http://downloads.freepbxdistro.org/SNG7-FPBX-64bit-2305-2.iso
# O usar script de instalación automática
curl -O http://downloads.freepbxdistro.org/install_scripts/install_freepbx.sh
chmod +x install_freepbx.sh
./install_freepbx.sh
```

### **2. Configuración Multi-Tenant**
```bash
# Extensiones por cliente (reemplaza SIP users de Twilio)
Oficina Principal:
├── 2001 (Office)
├── 2002 (Security)
└── Trunk: Entel_Principal

Plaza Norte:
├── 3001 (Office)  
├── 3002 (Security)
└── Trunk: VTR_PlazaNorte
```

### **3. Configuración de Trunks**
```bash
# Ejemplo: Trunk Entel
[entel-out]
type=endpoint
transport=transport-udp
context=from-trunk-entel
aors=entel-aor
auth=entel-auth
allow=ulaw,alaw,g722

[entel-auth]
type=auth
auth_type=userpass
username=TU_USUARIO_ENTEL
password=TU_PASSWORD_ENTEL

[entel-aor]
type=aor
contact=sip:sip.entel.cl
```

## 📱 **Migración desde Twilio**

### **Paso 1: Configurar Asterisk/FreePBX**
- ✅ Instalar en tu servidor cloud
- ✅ Configurar extensiones (reemplazar usuarios SIP de Twilio)
- ✅ Configurar trunk con proveedor chileno
- ✅ Configurar IVR (reemplazar TwiML Bins)

### **Paso 2: Reconfigurar dispositivos GDMS**
```bash
# Cambiar en plantillas GDMS:
SIP Server: skyn3t-communities.sip.twilio.com
          ↓
SIP Server: TU_IP_SERVIDOR:5060

SIP User ID: +56229145248-office
           ↓  
SIP User ID: 2001

SIP Password: SKyn3t2025_OFICINA_PRINCIPAL_Office!
            ↓
SIP Password: office123
```

### **Paso 3: Configurar enrutamiento**
```bash
# Dialplan para llamadas salientes (extensions.conf)
[from-internal]
; Llamadas a celulares (9 + 8 dígitos)
exten => _9XXXXXXXX,1,Set(CALLERID(num)=${EXTEN:1})
exten => _9XXXXXXXX,n,Dial(SIP/entel-out/56${EXTEN:1},60)
exten => _9XXXXXXXX,n,Hangup()

; Llamadas internas (extensión a extensión)
exten => _[2-3]XXX,1,Dial(SIP/${EXTEN},20)
exten => _[2-3]XXX,n,VoiceMail(${EXTEN}@default)
```

## 💰 **Análisis Financiero**

### **Costos mensuales estimados (10 clientes):**
```
Servidor cloud (4GB RAM): $20 USD/mes
Números DID chilenos (10): $15 USD/mes  
Trunk Entel (500 min): $70 USD/mes
Total: $105 USD/mes

vs Twilio actual: $200+ USD/mes
Ahorro: ~$95 USD/mes (47%)
```

### **ROI Implementación:**
- Tiempo implementación: 1-2 semanas
- Costo setup inicial: $0 (FreePBX es gratis)
- Payback: Inmediato

## 🔄 **Plan de Migración Gradual**

### **Fase 1: Instalación paralela (Semana 1)**
- ✅ Instalar FreePBX en servidor
- ✅ Configurar 1 cliente piloto
- ✅ Testing básico

### **Fase 2: Migración progresiva (Semana 2)**
- ✅ Migrar cliente por cliente
- ✅ Mantener Twilio como backup
- ✅ Verificar funcionalidad completa

### **Fase 3: Optimización (Semana 3)**
- ✅ Cancelar servicios Twilio innecesarios
- ✅ Optimizar configuraciones
- ✅ Monitoreo y ajustes

## 🛡️ **Ventajas del Sistema Asterisk**

### **Funcionalidades adicionales:**
- ✅ **Grabación de llamadas** (incluida)
- ✅ **Reportes detallados** (CDR)
- ✅ **Cola de llamadas** 
- ✅ **Conferencias** (gratuitas)
- ✅ **Buzón de voz** (incluido)
- ✅ **Control total** del sistema

### **Flexibilidad:**
- ✅ Cambiar proveedores fácilmente
- ✅ Negociar mejores tarifas
- ✅ Múltiples trunks simultáneos
- ✅ Failover automático

## ⚠️ **Consideraciones importantes**

### **Desventajas vs Twilio:**
- ❌ Requiere más administración técnica
- ❌ Necesitas contratar DID numbers separadamente
- ❌ Sin SMS nativo (requiere gateway)
- ❌ Responsabilidad de uptime/backups

### **Requisitos técnicos:**
- ✅ Servidor con IP pública
- ✅ Ancho de banda: 100kbps por llamada concurrente  
- ✅ Firewall configurado (puertos 5060, 10000-20000)
- ✅ Monitoreo 24/7

## 🎯 **Recomendación Final**

**Sí, Asterisk te servirá** para reducir significativamente los costos, pero debes entender que:

1. **No elimina costos**, los reduce ~70%
2. **Requiere gestión técnica** adicional
3. **Mejor ROI** a partir de 300+ minutos/mes
4. **Flexibilidad total** vs dependencia de Twilio

**¿Proceder con la implementación?** El ahorro justifica el esfuerzo técnico.
