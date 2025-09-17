# Fleet Management API - Seeds
# Este archivo crea datos de prueba para desarrollo y demostración

puts "🧹 Limpiando base de datos..."
MaintenanceService.destroy_all
Vehicle.destroy_all
User.destroy_all

puts "\n👤 Creando usuario admin..."
admin = User.create!(
  email: 'admin@fleet.com',
  password: 'password123',
  name: 'Admin User'
)
puts "   ✓ Usuario creado: #{admin.email}"

puts "\n🚗 Creando vehículos..."

# Vehículo 1: Toyota activo con mantenimientos variados
vehicle1 = Vehicle.create!(
  vin: '1HGBH41JXMN109186',
  plate: 'MEX-1234',
  brand: 'Toyota',
  model: 'Camry',
  year: 2020,
  status: 'active'
)
puts "   ✓ #{vehicle1.brand} #{vehicle1.model} (#{vehicle1.plate})"

# Vehículo 2: Honda en mantenimiento
vehicle2 = Vehicle.create!(
  vin: '2HGFC2F59MH543210',
  plate: 'MEX-5678',
  brand: 'Honda',
  model: 'Civic',
  year: 2021,
  status: 'in_maintenance'
)
puts "   ✓ #{vehicle2.brand} #{vehicle2.model} (#{vehicle2.plate})"

# Vehículo 3: Ford activo con historial de mantenimientos
vehicle3 = Vehicle.create!(
  vin: '3FADP4BJ7LM123456',
  plate: 'MEX-9012',
  brand: 'Ford',
  model: 'Fusion',
  year: 2019,
  status: 'active'
)
puts "   ✓ #{vehicle3.brand} #{vehicle3.model} (#{vehicle3.plate})"

# Vehículo 4: Nissan inactivo
vehicle4 = Vehicle.create!(
  vin: '1N4AL3AP4DC295096',
  plate: 'MEX-3456',
  brand: 'Nissan',
  model: 'Altima',
  year: 2018,
  status: 'inactive'
)
puts "   ✓ #{vehicle4.brand} #{vehicle4.model} (#{vehicle4.plate})"

# Vehículo 5: Chevrolet activo nuevo
vehicle5 = Vehicle.create!(
  vin: '1G1ZD5ST7KF123789',
  plate: 'MEX-7890',
  brand: 'Chevrolet',
  model: 'Malibu',
  year: 2022,
  status: 'active'
)
puts "   ✓ #{vehicle5.brand} #{vehicle5.model} (#{vehicle5.plate})"

puts "\n🔧 Creando servicios de mantenimiento..."

# Servicios para Vehicle 1 (Toyota) - Historial variado
MaintenanceService.create!(
  vehicle: vehicle1,
  description: 'Cambio de aceite y filtro',
  status: 'completed',
  date: 2.months.ago,
  cost_cents: 150000, # $1,500
  priority: 'medium',
  completed_at: 2.months.ago
)

MaintenanceService.create!(
  vehicle: vehicle1,
  description: 'Rotación de llantas',
  status: 'completed',
  date: 1.month.ago,
  cost_cents: 80000, # $800
  priority: 'low',
  completed_at: 1.month.ago
)

MaintenanceService.create!(
  vehicle: vehicle1,
  description: 'Revisión de frenos - próximo servicio programado',
  status: 'pending',
  date: Date.current,
  cost_cents: 250000, # $2,500
  priority: 'high'
)

# Servicios para Vehicle 2 (Honda) - En mantenimiento actual
MaintenanceService.create!(
  vehicle: vehicle2,
  description: 'Reparación de transmisión',
  status: 'in_progress',
  date: 3.days.ago,
  cost_cents: 850000, # $8,500
  priority: 'high'
)

MaintenanceService.create!(
  vehicle: vehicle2,
  description: 'Cambio de batería',
  status: 'pending',
  date: Date.current,
  cost_cents: 200000, # $2,000
  priority: 'medium'
)

# Servicios para Vehicle 3 (Ford) - Historial completo
MaintenanceService.create!(
  vehicle: vehicle3,
  description: 'Servicio mayor 60,000 km',
  status: 'completed',
  date: 6.months.ago,
  cost_cents: 450000, # $4,500
  priority: 'high',
  completed_at: 6.months.ago
)

MaintenanceService.create!(
  vehicle: vehicle3,
  description: 'Cambio de aceite y filtro',
  status: 'completed',
  date: 3.months.ago,
  cost_cents: 150000, # $1,500
  priority: 'medium',
  completed_at: 3.months.ago
)

MaintenanceService.create!(
  vehicle: vehicle3,
  description: 'Alineación y balanceo',
  status: 'completed',
  date: 1.month.ago,
  cost_cents: 120000, # $1,200
  priority: 'low',
  completed_at: 1.month.ago
)

MaintenanceService.create!(
  vehicle: vehicle3,
  description: 'Cambio de filtro de aire',
  status: 'completed',
  date: 2.weeks.ago,
  cost_cents: 50000, # $500
  priority: 'low',
  completed_at: 2.weeks.ago
)

# Servicios para Vehicle 4 (Nissan) - Vehículo inactivo con historial
MaintenanceService.create!(
  vehicle: vehicle4,
  description: 'Reparación de motor - daño mayor',
  status: 'completed',
  date: 4.months.ago,
  cost_cents: 1200000, # $12,000
  priority: 'high',
  completed_at: 4.months.ago
)

MaintenanceService.create!(
  vehicle: vehicle4,
  description: 'Diagnóstico de fallas eléctricas',
  status: 'completed',
  date: 3.months.ago,
  cost_cents: 100000, # $1,000
  priority: 'medium',
  completed_at: 3.months.ago
)

# Servicios para Vehicle 5 (Chevrolet) - Vehículo nuevo con mantenimientos preventivos
MaintenanceService.create!(
  vehicle: vehicle5,
  description: 'Primer servicio - 5,000 km',
  status: 'completed',
  date: 1.month.ago,
  cost_cents: 180000, # $1,800
  priority: 'medium',
  completed_at: 1.month.ago
)

MaintenanceService.create!(
  vehicle: vehicle5,
  description: 'Revisión de garantía',
  status: 'pending',
  date: Date.current,
  cost_cents: 0, # Cubierto por garantía
  priority: 'low'
)

# Servicios adicionales para mayor variedad
MaintenanceService.create!(
  vehicle: vehicle1,
  description: 'Cambio de limpiaparabrisas',
  status: 'completed',
  date: 2.weeks.ago,
  cost_cents: 40000, # $400
  priority: 'low',
  completed_at: 2.weeks.ago
)

MaintenanceService.create!(
  vehicle: vehicle2,
  description: 'Diagnóstico de ruidos en suspensión',
  status: 'pending',
  date: Date.current,
  cost_cents: 80000, # $800
  priority: 'medium'
)

puts "\n📊 Resumen de datos creados:"
puts "   • Usuarios: #{User.count}"
puts "   • Vehículos: #{Vehicle.count}"
puts "   • Servicios de mantenimiento: #{MaintenanceService.count}"
puts "     - Pendientes: #{MaintenanceService.pending.count}"
puts "     - En progreso: #{MaintenanceService.in_progress.count}"
puts "     - Completados: #{MaintenanceService.completed.count}"

puts "\n💰 Estadísticas de costos:"
total_cost = MaintenanceService.sum(:cost_cents) / 100.0
puts "   • Costo total de mantenimientos: $#{total_cost.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
puts "   • Costo promedio por servicio: $#{(total_cost / MaintenanceService.count).round(2)}"

vehicles_with_pending = Vehicle.joins(:maintenance_services)
                              .where(maintenance_services: { status: ['pending', 'in_progress'] })
                              .distinct
puts "\n🚦 Estado de la flota:"
puts "   • Vehículos activos: #{Vehicle.active.count}"
puts "   • Vehículos en mantenimiento: #{Vehicle.in_maintenance.count}"
puts "   • Vehículos inactivos: #{Vehicle.inactive.count}"
puts "   • Vehículos con mantenimientos pendientes: #{vehicles_with_pending.count}"

puts "\n✅ Seeds ejecutados exitosamente!"
puts "\n📝 Credenciales de acceso:"
puts "   Email: admin@fleet.com"
puts "   Password: password123"