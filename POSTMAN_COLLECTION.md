# 📮 Colección de Postman - Fleet Management API

## 📋 Descripción

Esta colección de Postman contiene todos los endpoints de la API de gestión de flotas, con autenticación JWT automatizada, tests y variables de entorno preconfiguradas.

## 🚀 Instalación

### 1. Importar en Postman

#### Opción A: Importar archivos
1. Abre Postman
2. Click en "Import" (botón en la parte superior izquierda)
3. Arrastra o selecciona estos dos archivos:
   - `Fleet_Management_API.postman_collection.json`
   - `Fleet_Management_API.postman_environment.json`

#### Opción B: Importar por URL (si está en un repositorio)
1. Click en "Import" → "Link"
2. Pega la URL del archivo JSON de la colección

### 2. Configurar el entorno
1. En Postman, selecciona el entorno "Fleet Management - Local" del dropdown superior derecho
2. Verifica que las variables estén configuradas:
   - `baseUrl`: http://localhost:3000
   - `adminEmail`: admin@fleet.com
   - `adminPassword`: password123

## 🔑 Autenticación Automática

La colección incluye **auto-login inteligente**:
- Se ejecuta automáticamente antes de cada petición
- Obtiene un nuevo token si:
  - No existe token
  - El token ha expirado (24 horas)
- No necesitas hacer login manual

### Login Manual (opcional)
Si prefieres hacer login manual:
1. Ve a la carpeta "Autenticación"
2. Ejecuta "Login"
3. El token se guardará automáticamente

## 📁 Estructura de la Colección

```
Fleet Management API/
├── 🔐 Autenticación
│   ├── Login
│   └── Login - Credenciales Inválidas
├── 🚗 Vehicles
│   ├── Listar Vehículos (con filtros)
│   ├── Crear Vehículo
│   ├── Ver Vehículo
│   ├── Actualizar Vehículo
│   └── Eliminar Vehículo
├── 🔧 Maintenance Services
│   ├── Listar Servicios de un Vehículo
│   ├── Crear Servicio de Mantenimiento
│   └── Actualizar Servicio de Mantenimiento
├── 📊 Reports
│   ├── Reporte de Resumen de Mantenimiento
│   └── Reporte - Error sin fechas
└── ❌ Casos de Error
    ├── Petición sin Token
    ├── Vehículo No Encontrado
    └── Crear Vehículo - Validación
```

## 🧪 Tests Automatizados

Cada endpoint incluye tests automáticos que verifican:
- Status HTTP correcto
- Estructura de respuesta
- Datos esperados
- Guardado de variables para usar en siguientes peticiones

### Ejecutar todos los tests
1. Click derecho en la colección
2. Selecciona "Run collection"
3. Click en "Run Fleet Management API"

## 🔄 Flujo de Trabajo Recomendado

### 1. Operaciones básicas con vehículos
```
1. Listar Vehículos → guarda vehicleId
2. Ver Vehículo → usa vehicleId guardado
3. Actualizar Vehículo
4. Eliminar Vehículo
```

### 2. Gestión de mantenimientos
```
1. Crear Vehículo → guarda vehicleId
2. Crear Servicio → usa vehicleId, guarda serviceId
3. Actualizar Servicio → usa serviceId
4. Listar Servicios del Vehículo
```

### 3. Reportes
```
1. Crear datos de prueba (vehículos y servicios)
2. Ejecutar Reporte de Resumen
3. Verificar agregaciones y cálculos
```

## 📝 Variables Disponibles

### Variables de Entorno
- `{{baseUrl}}` - URL base de la API
- `{{adminEmail}}` - Email del admin
- `{{adminPassword}}` - Password del admin

### Variables Dinámicas (se actualizan automáticamente)
- `{{token}}` - JWT token actual
- `{{tokenExpiry}}` - Timestamp de expiración
- `{{vehicleId}}` - ID del último vehículo usado
- `{{serviceId}}` - ID del último servicio usado

### Variables de Petición (generadas on-the-fly)
- `{{randomVin}}` - VIN único para crear vehículos
- `{{randomPlate}}` - Placa única
- `{{currentDate}}` - Fecha actual
- `{{fromDate}}` - Fecha inicio para reportes
- `{{toDate}}` - Fecha fin para reportes

## 🎯 Casos de Uso

### Probar filtros y paginación
1. Ve a "Listar Vehículos"
2. En la pestaña "Params", activa los filtros que quieras:
   - `status`: active, inactive, in_maintenance
   - `brand`: Toyota, Ford, etc.
   - `search`: búsqueda por VIN o placa
   - `page`: número de página
   - `per_page`: items por página

### Probar validaciones
1. Ve a "Casos de Error"
2. Ejecuta las peticiones para ver respuestas de error
3. Verifica formato consistente de errores

### Generar reporte
1. Crea algunos vehículos y servicios
2. Ve a "Reports" → "Reporte de Resumen"
3. Se configuran automáticamente fechas de últimos 30 días
4. Verifica estructura del reporte

## 🐛 Troubleshooting

### "Missing token" error
- El auto-login debería manejarlo automáticamente
- Si persiste, ejecuta manualmente "Login"

### "Vehicle not found"
- Ejecuta primero "Listar Vehículos" para obtener un ID válido
- O crea un nuevo vehículo

### Tests fallando
- Verifica que el servidor Rails esté corriendo
- Confirma que la base de datos tenga seeds: `rails db:seed`
- Revisa que el puerto sea 3000

## 💡 Tips

1. **Usa el Runner de Postman** para ejecutar toda la colección y ver un reporte completo
2. **Duplica peticiones** para crear variaciones sin perder la original
3. **Revisa la consola de Postman** (View → Show Postman Console) para debugging
4. **Exporta resultados** del Runner para documentación

## 🔄 Actualización

Si la API cambia:
1. Actualiza los endpoints en la colección
2. Ajusta los tests según nuevas respuestas
3. Exporta la colección actualizada
4. Commitea los cambios

---

**Última actualización:** 2025-09-17
**Versión de la API:** v1
**Compatible con:** Postman v10.0+