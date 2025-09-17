# Fleet Management API

Sistema integral de gestión de flotas vehiculares con API REST y vistas HTML. Permite administrar vehículos y sus servicios de mantenimiento con autenticación JWT.

## 🚀 Quick Start (5 minutos)

```bash
# 1. Clonar el repositorio
git clone https://github.com/Romazd/fleet_management.git
cd fleet_management

# 2. Instalar dependencias
bundle install

# 3. Configurar master.key para desarrollo
echo "a75f6f569a01b3182b99a09fe47e8e83" > config/master.key

# 4. Configurar base de datos
rails db:create db:migrate db:seed

# 5. Iniciar servidor
rails server

# ✅ Listo! La app está en http://localhost:3000
```

**Credenciales de prueba:**
- Email: `admin@fleet.com`
- Password: `password123`

**Probar API con Postman:**
1. Importar `Fleet_Management_API.postman_collection.json`
2. Importar `Fleet_Management_API.postman_environment.json`
3. ¡Listo! El auto-login está configurado

## 🎯 Características

- **API REST completa** con autenticación JWT
- **Vistas HTML** para administración sin autenticación
- **Gestión de vehículos** con estados dinámicos
- **Servicios de mantenimiento** con prioridades y costos
- **Reportes y estadísticas** agregadas
- **Internacionalización (I18n)** español/inglés
- **Paginación y filtros** avanzados
- **Callbacks automáticos** para actualización de estados

## 📋 Requisitos del Sistema

- Ruby 3.2.2
- Rails 7.1.5.2
- PostgreSQL 14+
- Bundler 2.4+

## 🔧 Instalación

### 1. Clonar el repositorio

```bash
git clone https://github.com/Romazd/fleet_management.git
cd fleet_management
```

### 2. Instalar dependencias

```bash
bundle install
```

### 3. Configurar base de datos

```bash
# Crear base de datos
rails db:create

# Ejecutar migraciones
rails db:migrate

# Cargar datos de prueba (IMPORTANTE: incluye usuario admin)
rails db:seed
```

### 4. Configurar credenciales (Rails Credentials)

#### Opción A: Usar credenciales existentes (RECOMENDADO)
El proyecto ya incluye credenciales encriptadas. Solo necesitas crear el archivo `master.key`:

```bash
# Crear archivo config/master.key con este contenido exacto:
echo "a75f6f569a01b3182b99a09fe47e8e83" > config/master.key
```

⚠️ **IMPORTANTE**: Este `master.key` es SOLO para desarrollo/pruebas. En producción debes generar uno nuevo.

#### Opción B: Generar nuevas credenciales
Si prefieres crear tus propias credenciales:

```bash
# Eliminar credenciales existentes
rm config/credentials.yml.enc

# Generar nuevas credenciales
EDITOR="code --wait" rails credentials:edit
```

Asegúrate de que las credenciales incluyan:
```yaml
secret_key_base: <generado-automaticamente>
```

### 5. Iniciar el servidor

```bash
rails server
```

La aplicación estará disponible en `http://localhost:3000`

## 🔐 Autenticación

### Usuario de Prueba
El seed crea un usuario administrador:
- **Email**: `admin@fleet.com`
- **Password**: `password123`

### Login (API)

```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@fleet.com",
    "password": "password123"
  }'
```

**Respuesta:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "admin@fleet.com",
    "name": "Admin User"
  }
}
```

### Usar el token en requests

```bash
curl -H "Authorization: Bearer <TOKEN>" \
  http://localhost:3000/api/v1/vehicles
```

## 📮 Pruebas con Postman (RECOMENDADO)

### Instalación Rápida

1. **Importar archivos en Postman:**
   - `Fleet_Management_API.postman_collection.json` - Colección completa
   - `Fleet_Management_API.postman_environment.json` - Variables de entorno

2. **Seleccionar entorno:**
   - En Postman, selecciona "Fleet Management - Local" del dropdown superior derecho

3. **¡Listo!** No necesitas configurar nada más. La colección incluye:
   - ✅ Auto-login automático (no necesitas obtener token manual)
   - ✅ Renovación automática cuando expira
   - ✅ Tests automatizados en cada endpoint
   - ✅ Variables que se actualizan entre peticiones

### Características de la Colección

- **20+ endpoints** organizados por carpetas
- **Tests automáticos** que validan respuestas
- **Generación dinámica** de VINs y placas únicas
- **Encadenamiento** automático de IDs entre peticiones
- **Casos de error** para probar validaciones

### Flujo Recomendado

1. **Ejecutar toda la colección:**
   ```
   Click derecho en "Fleet Management API" → Run collection
   ```

2. **Probar endpoints individuales:**
   ```
   Autenticación → Login (se ejecuta automáticamente)
   Vehicles → Listar Vehículos
   Vehicles → Crear Vehículo
   Maintenance Services → Crear Servicio
   Reports → Reporte de Resumen
   ```

### Documentación Detallada
Ver [POSTMAN_COLLECTION.md](./POSTMAN_COLLECTION.md) para guía completa de uso.

## 📚 Documentación de API

### Endpoints de Vehículos

#### Listar vehículos con paginación y filtros

```bash
GET /api/v1/vehicles
```

**Parámetros opcionales:**
- `page`: Número de página (default: 1)
- `per_page`: Items por página (default: 20)
- `status`: Filtrar por estado (active, inactive, in_maintenance)
- `brand`: Filtrar por marca
- `year`: Filtrar por año específico
- `year_from`, `year_to`: Rango de años
- `search`: Búsqueda en VIN, placa, marca o modelo
- `sort_by`: Campo para ordenar
- `sort_direction`: asc o desc

**Ejemplo:**
```bash
curl -H "Authorization: Bearer <TOKEN>" \
  "http://localhost:3000/api/v1/vehicles?status=active&brand=Toyota&page=1&per_page=10"
```

#### Ver vehículo específico

```bash
GET /api/v1/vehicles/:id
```

#### Crear vehículo

```bash
POST /api/v1/vehicles
```

**Body:**
```json
{
  "vehicle": {
    "vin": "1HGBH41JXMN109186",
    "plate": "MEX-1234",
    "brand": "Toyota",
    "model": "Camry",
    "year": 2020,
    "status": "active"
  }
}
```

#### Actualizar vehículo

```bash
PUT/PATCH /api/v1/vehicles/:id
```

#### Eliminar vehículo

```bash
DELETE /api/v1/vehicles/:id
```

### Endpoints de Servicios de Mantenimiento

#### Listar servicios de un vehículo

```bash
GET /api/v1/vehicles/:vehicle_id/maintenance_services
```

#### Crear servicio de mantenimiento

```bash
POST /api/v1/vehicles/:vehicle_id/maintenance_services
```

**Body:**
```json
{
  "maintenance_service": {
    "description": "Cambio de aceite",
    "date": "2025-09-17",
    "status": "pending",
    "priority": "medium",
    "cost_cents": 150000
  }
}
```

#### Actualizar servicio

```bash
PUT/PATCH /api/v1/maintenance_services/:id
```

### Endpoint de Reportes

#### Resumen de mantenimientos

```bash
GET /api/v1/reports/maintenance_summary?from=2025-01-01&to=2025-12-31
```

**Respuesta:**
```json
{
  "period": {
    "from": "2025-01-01",
    "to": "2025-12-31"
  },
  "summary": {
    "total_orders": 15,
    "total_cost_cents": 3900000,
    "by_status": {
      "pending": 4,
      "in_progress": 1,
      "completed": 10
    },
    "by_vehicle": [...],
    "top_vehicles_by_cost": [...]
  }
}
```

## 🖥️ Vistas HTML

Las vistas HTML están disponibles sin autenticación:

### Vehículos
- **Listado**: `http://localhost:3000/vehicles`
- **Nuevo**: `http://localhost:3000/vehicles/new`
- **Ver**: `http://localhost:3000/vehicles/:id`
- **Editar**: `http://localhost:3000/vehicles/:id/edit`

### Servicios de Mantenimiento
- **Listado**: `http://localhost:3000/vehicles/:vehicle_id/maintenance_services`
- **Nuevo**: `http://localhost:3000/vehicles/:vehicle_id/maintenance_services/new`
- **Editar**: `http://localhost:3000/vehicles/:vehicle_id/maintenance_services/:id/edit`

## 🧪 Testing

### Ejecutar todos los tests

```bash
bundle exec rspec
```

### Tests específicos

```bash
# Solo modelos
bundle exec rspec spec/models

# Solo requests
bundle exec rspec spec/requests

# Solo API
bundle exec rspec spec/requests/api
```

### Coverage

El proyecto incluye 172+ tests con cobertura completa de:
- Modelos y validaciones
- Endpoints API
- Vistas HTML
- Autenticación JWT
- Callbacks y reglas de negocio

## 🔄 Estados de Vehículos

Los estados se actualizan automáticamente según los servicios de mantenimiento:

- **active**: Sin servicios pendientes o en progreso
- **in_maintenance**: Tiene servicios pendientes o en progreso
- **inactive**: Estado manual para vehículos fuera de servicio

## 🌐 Internacionalización

La aplicación soporta español e inglés:

- **Producción/Desarrollo**: Español por defecto
- **Tests**: Inglés por defecto
- **Cambiar idioma**: Modificar `config.i18n.default_locale` en `config/application.rb`

## 📊 Datos de Prueba

Ejecutar seeds crea:
- 1 usuario admin (admin@fleet.com / password123)
- 5 vehículos de diferentes marcas
- 15 servicios de mantenimiento con diversos estados

```bash
rails db:seed
```

## 🏗️ Estructura del Proyecto

```
app/
├── controllers/
│   ├── api/v1/          # Controladores API
│   │   ├── auth_controller.rb
│   │   ├── base_controller.rb
│   │   ├── maintenance_services_controller.rb
│   │   ├── reports_controller.rb
│   │   └── vehicles_controller.rb
│   ├── concerns/
│   │   └── authenticable.rb
│   ├── maintenance_services_controller.rb  # HTML
│   └── vehicles_controller.rb              # HTML
├── models/
│   ├── maintenance_service.rb
│   ├── user.rb
│   └── vehicle.rb
├── serializers/
│   ├── maintenance_service_serializer.rb
│   ├── user_serializer.rb
│   └── vehicle_serializer.rb
├── services/
│   └── json_web_token.rb
└── views/
    ├── layouts/
    ├── maintenance_services/
    └── vehicles/
```

## ⚡ Optimizaciones

### Índices de Base de Datos

- Índices únicos case-insensitive para VIN y placa
- Índices en campos de búsqueda y filtrado
- Índice compuesto para vehicle_id + status

### Prevención de N+1 Queries

- Uso de `includes(:maintenance_services)` en listados
- Queries optimizados en reportes
- Eager loading donde sea necesario

## 🚀 Despliegue

### Variables de Entorno Requeridas

```bash
DATABASE_URL=postgresql://user:pass@host/dbname
RAILS_ENV=production
SECRET_KEY_BASE=<your-secret-key>
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
```

### Comandos de Producción

```bash
# Precompilar assets (si usas)
rails assets:precompile

# Ejecutar migraciones
rails db:migrate

# Iniciar servidor
rails server -e production
```

## 📝 Licencia

Este proyecto fue creado como parte de un desafío técnico.

## 👤 Autor

Fleet Management API - Desafío Técnico

## ⚠️ Notas de Seguridad

### Master Key
El `master.key` incluido en las instrucciones (`a75f6f569a01b3182b99a09fe47e8e83`) es **SOLO para desarrollo/pruebas locales**.

**Para producción:**
1. Genera nuevas credenciales con `rails credentials:edit`
2. Usa un `master.key` único y seguro
3. NUNCA commits el `master.key` real al repositorio
4. Usa variables de entorno o gestores de secretos

### Credenciales por Defecto
Las credenciales `admin@fleet.com / password123` son solo para desarrollo. En producción:
1. Cambia las credenciales inmediatamente
2. Usa contraseñas seguras
3. Implementa políticas de contraseña
4. Considera 2FA para producción

---

**Quick Test:**
```bash
# Test rápido de que todo funciona
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@fleet.com","password":"password123"}'
```

Si recibes un token JWT, ¡todo está funcionando! 🎉