# Fleet Management API - Extended Seeds
# Genera 50 vehículos con 200+ servicios de mantenimiento para pruebas completas

require 'faker'

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

# Configuración
VEHICLE_COUNT = 50
MIN_SERVICES_PER_VEHICLE = 0  # Algunos vehículos sin servicios
MAX_SERVICES_PER_VEHICLE = 10 # Algunos con muchos servicios

# Arrays de datos para variedad
BRANDS = ['Toyota', 'Honda', 'Ford', 'Chevrolet', 'Nissan', 'Mazda', 'Volkswagen',
          'BMW', 'Mercedes-Benz', 'Audi', 'Hyundai', 'Kia', 'Subaru', 'Mitsubishi',
          'Dodge', 'Ram', 'Jeep', 'GMC', 'Volvo', 'Tesla']

MODELS = {
  'Toyota' => ['Camry', 'Corolla', 'RAV4', 'Highlander', 'Tacoma', 'Prius'],
  'Honda' => ['Civic', 'Accord', 'CR-V', 'Pilot', 'Odyssey', 'Ridgeline'],
  'Ford' => ['F-150', 'Explorer', 'Escape', 'Focus', 'Fusion', 'Mustang'],
  'Chevrolet' => ['Silverado', 'Malibu', 'Equinox', 'Tahoe', 'Suburban', 'Camaro'],
  'Nissan' => ['Altima', 'Sentra', 'Rogue', 'Pathfinder', 'Frontier', 'Maxima'],
  'Default' => ['Sport', 'Sedan', 'SUV', 'Truck', 'Van', 'Coupe']
}

SERVICE_DESCRIPTIONS = [
  'Cambio de aceite y filtro',
  'Rotación de llantas',
  'Revisión de frenos',
  'Cambio de batería',
  'Alineación y balanceo',
  'Cambio de filtro de aire',
  'Cambio de bujías',
  'Revisión de transmisión',
  'Cambio de líquido de frenos',
  'Servicio mayor 30,000 km',
  'Servicio mayor 60,000 km',
  'Servicio mayor 90,000 km',
  'Reparación de motor',
  'Reparación de transmisión',
  'Cambio de amortiguadores',
  'Cambio de correa de distribución',
  'Diagnóstico eléctrico',
  'Reparación de aire acondicionado',
  'Cambio de limpiaparabrisas',
  'Pulido de faros',
  'Cambio de escape',
  'Reparación de radiador',
  'Cambio de termostato',
  'Revisión de suspensión',
  'Cambio de embrague'
]

puts "\n🚗 Creando #{VEHICLE_COUNT} vehículos..."

vehicles = []
vehicle_stats = { active: 0, inactive: 0, in_maintenance: 0 }

VEHICLE_COUNT.times do |i|
  # Generar VIN único
  vin = Faker::Vehicle.vin.upcase

  # Generar placa única mexicana
  plate = "MEX-#{rand(1000..9999)}"

  # Seleccionar marca y modelo
  brand = BRANDS.sample
  model = (MODELS[brand] || MODELS['Default']).sample

  # Año entre 2015 y 2024
  year = rand(2015..2024)

  # Determinar estado inicial (será actualizado por callbacks si tiene servicios pendientes)
  # 70% active, 20% inactive, 10% será in_maintenance después de agregar servicios
  status_random = rand(100)
  status = if status_random < 70
    'active'
  elsif status_random < 90
    'inactive'
  else
    'active' # Será cambiado por callbacks si tiene servicios pendientes
  end

  vehicle = Vehicle.create!(
    vin: vin,
    plate: plate,
    brand: brand,
    model: model,
    year: year,
    status: status
  )

  vehicles << vehicle

  # Mostrar progreso cada 10 vehículos
  if (i + 1) % 10 == 0
    print "   ✓ #{i + 1} vehículos creados...\n"
  end
end

puts "   ✓ Total: #{vehicles.count} vehículos creados"

puts "\n🔧 Creando servicios de mantenimiento..."

total_services = 0
services_by_status = { pending: 0, in_progress: 0, completed: 0 }

vehicles.each_with_index do |vehicle, index|
  # Determinar número de servicios para este vehículo
  # 10% sin servicios, 20% con muchos servicios (7-10), resto normal (1-6)
  services_random = rand(100)
  num_services = if services_random < 10
    0 # Sin servicios
  elsif services_random < 30
    rand(7..MAX_SERVICES_PER_VEHICLE) # Muchos servicios
  else
    rand(1..6) # Normal
  end

  num_services.times do |service_index|
    # Fechas escalonadas hacia atrás
    base_date = Date.current - (service_index * rand(30..90)).days

    # Determinar estado del servicio
    # Para servicios más antiguos, mayor probabilidad de estar completados
    status_random = rand(100)
    if service_index > 3 # Servicios más antiguos
      status = status_random < 80 ? 'completed' : 'pending'
    else # Servicios recientes
      status = if status_random < 40
        'completed'
      elsif status_random < 75
        'pending'
      else
        'in_progress'
      end
    end

    # Determinar prioridad
    priority_random = rand(100)
    priority = if priority_random < 50
      'low'
    elsif priority_random < 85
      'medium'
    else
      'high'
    end

    # Costo en centavos (entre $200 y $15,000 pesos)
    cost_cents = rand(20000..1500000)

    # Crear el servicio
    service = MaintenanceService.create!(
      vehicle: vehicle,
      description: SERVICE_DESCRIPTIONS.sample + (rand(100) < 20 ? " - #{Faker::Lorem.sentence(word_count: 3)}" : ""),
      status: status,
      date: base_date,
      cost_cents: cost_cents,
      priority: priority,
      completed_at: status == 'completed' ? base_date + rand(1..7).days : nil
    )

    total_services += 1
    services_by_status[status.to_sym] += 1
  end

  # Mostrar progreso cada 10 vehículos
  if (index + 1) % 10 == 0
    print "   ✓ Servicios creados para #{index + 1} vehículos...\n"
  end
end

puts "   ✓ Total: #{total_services} servicios creados"

# Actualizar estadísticas finales de vehículos
Vehicle.all.each do |v|
  vehicle_stats[v.status.to_sym] += 1
end

puts "\n📊 Resumen de datos creados:"
puts "   • Usuarios: #{User.count}"
puts "   • Vehículos: #{Vehicle.count}"
puts "   • Servicios de mantenimiento: #{MaintenanceService.count}"
puts "     - Pendientes: #{MaintenanceService.pending.count}"
puts "     - En progreso: #{MaintenanceService.in_progress.count}"
puts "     - Completados: #{MaintenanceService.completed.count}"

puts "\n💰 Estadísticas de costos:"
if MaintenanceService.any?
  total_cost = MaintenanceService.sum(:cost_cents) / 100.0
  avg_cost = total_cost / MaintenanceService.count
  max_cost = MaintenanceService.maximum(:cost_cents) / 100.0
  min_cost = MaintenanceService.minimum(:cost_cents) / 100.0

  puts "   • Costo total: $#{total_cost.round(2).to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  puts "   • Costo promedio: $#{avg_cost.round(2)}"
  puts "   • Costo máximo: $#{max_cost.round(2)}"
  puts "   • Costo mínimo: $#{min_cost.round(2)}"
end

puts "\n🚦 Estado de la flota:"
puts "   • Vehículos activos: #{vehicle_stats[:active]}"
puts "   • Vehículos en mantenimiento: #{vehicle_stats[:in_maintenance]}"
puts "   • Vehículos inactivos: #{vehicle_stats[:inactive]}"

puts "\n📈 Distribución de servicios por vehículo:"
vehicles_without_services = Vehicle.left_joins(:maintenance_services)
                                  .where(maintenance_services: { id: nil })
                                  .count
vehicles_with_many_services = Vehicle.joins(:maintenance_services)
                                    .group('vehicles.id')
                                    .having('COUNT(maintenance_services.id) >= 7')
                                    .count.size

puts "   • Vehículos sin servicios: #{vehicles_without_services}"
puts "   • Vehículos con 7+ servicios: #{vehicles_with_many_services}"
puts "   • Promedio de servicios por vehículo: #{(total_services.to_f / Vehicle.count).round(2)}"

# Información sobre paginación
puts "\n📄 Información para pruebas de paginación:"
puts "   • Total de vehículos: #{Vehicle.count}"
puts "   • Páginas con 20 items: #{(Vehicle.count / 20.0).ceil}"
puts "   • Páginas con 10 items: #{(Vehicle.count / 10.0).ceil}"

# Top marcas
top_brands = Vehicle.group(:brand).count.sort_by { |_, count| -count }.first(5)
puts "\n🏆 Top 5 marcas:"
top_brands.each_with_index do |(brand, count), index|
  puts "   #{index + 1}. #{brand}: #{count} vehículos"
end

puts "\n✅ Seeds extendidos ejecutados exitosamente!"
puts "\n📝 Credenciales de acceso:"
puts "   Email: admin@fleet.com"
puts "   Password: password123"
puts "\n💡 Tips para testing:"
puts "   • Usa ?per_page=10 para ver más páginas"
puts "   • Prueba filtros por marca: #{BRANDS.first(5).join(', ')}"
puts "   • Años disponibles: 2015-2024"
puts "   • Estados: active, inactive, in_maintenance"