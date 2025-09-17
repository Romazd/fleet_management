require 'csv'

class CsvGeneratorService
  def self.generate_summary_metrics_csv(data)
    CSV.generate(headers: true) do |csv|
      csv << ['Fecha Desde', 'Fecha Hasta', 'Total Órdenes', 'Total Vehículos', 'Costo Total', 'Costo Promedio']
      csv << [
        data[:period][:from],
        data[:period][:to],
        data[:total_orders],
        data[:total_vehicles],
        format_currency(data[:total_cost_cents]),
        format_currency(data[:average_cost_cents])
      ]
    end
  end

  def self.generate_status_csv(data)
    CSV.generate(headers: true) do |csv|
      csv << ['Estado', 'Cantidad', 'Porcentaje', 'Costo Total', 'Costo Promedio']

      data.each do |status|
        csv << [
          translate_status(status[:status]),
          status[:count],
          "#{status[:percentage]}%",
          format_currency(status[:total_cost_cents]),
          format_currency(status[:average_cost_cents])
        ]
      end
    end
  end

  def self.generate_priority_csv(data)
    CSV.generate(headers: true) do |csv|
      csv << ['Prioridad', 'Cantidad', 'Porcentaje', 'Costo Total', 'Costo Promedio']

      data.each do |priority|
        csv << [
          translate_priority(priority[:priority]),
          priority[:count],
          "#{priority[:percentage]}%",
          format_currency(priority[:total_cost_cents]),
          format_currency(priority[:average_cost_cents])
        ]
      end
    end
  end

  def self.generate_top_vehicles_csv(data)
    CSV.generate(headers: true) do |csv|
      csv << ['Ranking', 'VIN', 'Placa', 'Marca', 'Modelo', 'Año', 'Cantidad Servicios', 'Costo Total', 'Costo Promedio']

      data.each_with_index do |vehicle, index|
        csv << [
          index + 1,
          vehicle[:vin],
          vehicle[:plate],
          vehicle[:brand],
          vehicle[:model],
          vehicle[:year],
          vehicle[:services_count],
          format_currency(vehicle[:total_cost_cents]),
          format_currency(vehicle[:average_cost_cents])
        ]
      end
    end
  end

  def self.generate_vehicles_csv(data)
    CSV.generate(headers: true) do |csv|
      csv << ['VIN', 'Placa', 'Marca', 'Modelo', 'Año', 'Estado', 'Total Servicios',
              'Pendientes', 'En Progreso', 'Completados', 'Costo Total']

      data.each do |vehicle|
        csv << [
          vehicle[:vin],
          vehicle[:plate],
          vehicle[:brand],
          vehicle[:model],
          vehicle[:year],
          translate_vehicle_status(vehicle[:status]),
          vehicle[:total_services],
          vehicle[:pending_count],
          vehicle[:in_progress_count],
          vehicle[:completed_count],
          format_currency(vehicle[:total_cost_cents])
        ]
      end
    end
  end

  def self.generate_services_csv(data)
    CSV.generate(headers: true) do |csv|
      csv << ['Fecha', 'VIN', 'Placa', 'Marca', 'Modelo', 'Año',
              'Descripción', 'Estado', 'Prioridad', 'Costo', 'Completado En']

      data.each do |service|
        csv << [
          service[:date],
          service[:vehicle_vin],
          service[:vehicle_plate],
          service[:vehicle_brand],
          service[:vehicle_model],
          service[:vehicle_year],
          service[:description],
          translate_status(service[:status]),
          translate_priority(service[:priority]),
          format_currency(service[:cost_cents]),
          service[:completed_at]&.strftime('%Y-%m-%d') || ''
        ]
      end
    end
  end

  private

  def self.format_currency(cents)
    "$#{'%.2f' % (cents / 100.0)}"
  end

  def self.translate_status(status)
    {
      'pending' => 'Pendiente',
      'in_progress' => 'En Progreso',
      'completed' => 'Completado'
    }[status] || status
  end

  def self.translate_priority(priority)
    {
      'low' => 'Baja',
      'medium' => 'Media',
      'high' => 'Alta'
    }[priority] || priority
  end

  def self.translate_vehicle_status(status)
    {
      'active' => 'Activo',
      'inactive' => 'Inactivo',
      'in_maintenance' => 'En Mantenimiento'
    }[status] || status
  end
end