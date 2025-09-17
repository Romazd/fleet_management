class ReportsController < ApplicationController
  def show
    @from_date = parse_date(params[:from]) || 30.days.ago.to_date
    @to_date = parse_date(params[:to]) || Date.current

    respond_to do |format|
      format.html # Muestra el formulario
      format.csv do
        if params[:from].blank? || params[:to].blank?
          redirect_to report_path, alert: 'Las fechas desde y hasta son requeridas'
          return
        end

        if @from_date > @to_date
          redirect_to report_path, alert: 'La fecha desde no puede ser posterior a la fecha hasta'
          return
        end

        services = MaintenanceService
                    .includes(:vehicle)
                    .where(date: @from_date..@to_date)

        report_data = build_summary_report(services, @from_date, @to_date)
        send_data generate_csv(services, report_data), filename: "reporte_mantenimiento_#{@from_date}_#{@to_date}.csv"
      end
    end
  end

  private

  def parse_date(date_string)
    return nil if date_string.blank?
    Date.parse(date_string)
  rescue ArgumentError
    nil
  end

  def build_summary_report(services, from_date, to_date)
    {
      period: {
        from: from_date.to_s,
        to: to_date.to_s
      },
      summary: {
        total_orders: services.count,
        total_cost_cents: services.sum(:cost_cents),
        average_cost_cents: services.average(:cost_cents)&.to_i || 0
      },
      by_status: build_status_breakdown(services),
      by_vehicle: build_vehicle_breakdown(services),
      by_priority: build_priority_breakdown(services),
      top_vehicles_by_cost: build_top_vehicles(services)
    }
  end

  def build_status_breakdown(services)
    MaintenanceService.statuses.keys.map do |status|
      filtered = services.select { |s| s.status == status }
      {
        status: status,
        count: filtered.size,
        total_cost_cents: filtered.sum(&:cost_cents)
      }
    end
  end

  def build_vehicle_breakdown(services)
    services.group_by(&:vehicle).map do |vehicle, vehicle_services|
      {
        vehicle_id: vehicle.id,
        vin: vehicle.vin,
        plate: vehicle.plate,
        brand: vehicle.brand,
        model: vehicle.model,
        total_services: vehicle_services.size,
        total_cost_cents: vehicle_services.sum(&:cost_cents),
        services_by_status: build_vehicle_status_breakdown(vehicle_services)
      }
    end.sort_by { |v| -v[:total_cost_cents] }
  end

  def build_vehicle_status_breakdown(services)
    MaintenanceService.statuses.keys.each_with_object({}) do |status, hash|
      count = services.count { |s| s.status == status }
      hash[status] = count if count > 0
    end
  end

  def build_priority_breakdown(services)
    MaintenanceService.priorities.keys.map do |priority|
      filtered = services.select { |s| s.priority == priority }
      {
        priority: priority,
        count: filtered.size,
        total_cost_cents: filtered.sum(&:cost_cents)
      }
    end
  end

  def build_top_vehicles(services, limit = 3)
    services
      .group_by(&:vehicle)
      .map do |vehicle, vehicle_services|
        {
          vehicle_id: vehicle.id,
          vin: vehicle.vin,
          plate: vehicle.plate,
          brand: vehicle.brand,
          model: vehicle.model,
          total_cost_cents: vehicle_services.sum(&:cost_cents),
          services_count: vehicle_services.size
        }
      end
      .sort_by { |v| -v[:total_cost_cents] }
      .first(limit)
  end

  def generate_csv(services, report_data)
    require 'csv'

    CSV.generate(headers: true) do |csv|
      # Encabezados
      csv << ['Reporte de Mantenimiento']
      csv << ["Período: #{report_data[:period][:from]} al #{report_data[:period][:to]}"]
      csv << []

      # Resumen
      csv << ['Resumen']
      csv << ['Total de Órdenes', report_data[:summary][:total_orders]]
      csv << ['Costo Total', format_currency(report_data[:summary][:total_cost_cents])]
      csv << ['Costo Promedio', format_currency(report_data[:summary][:average_cost_cents])]
      csv << []

      # Por Estado
      csv << ['Desglose por Estado']
      csv << ['Estado', 'Cantidad', 'Costo Total']
      report_data[:by_status].each do |status|
        csv << [
          translate_status(status[:status]),
          status[:count],
          format_currency(status[:total_cost_cents])
        ]
      end
      csv << []

      # Por Prioridad
      csv << ['Desglose por Prioridad']
      csv << ['Prioridad', 'Cantidad', 'Costo Total']
      report_data[:by_priority].each do |priority|
        csv << [
          translate_priority(priority[:priority]),
          priority[:count],
          format_currency(priority[:total_cost_cents])
        ]
      end
      csv << []

      # Top Vehículos
      csv << ['Top 3 Vehículos por Costo']
      csv << ['VIN', 'Placa', 'Marca', 'Modelo', 'Cantidad de Servicios', 'Costo Total']
      report_data[:top_vehicles_by_cost].each do |vehicle|
        csv << [
          vehicle[:vin],
          vehicle[:plate],
          vehicle[:brand],
          vehicle[:model],
          vehicle[:services_count],
          format_currency(vehicle[:total_cost_cents])
        ]
      end
      csv << []

      # Detalle de Todos los Vehículos
      csv << ['Detalle de Todos los Vehículos']
      csv << ['VIN', 'Placa', 'Marca', 'Modelo', 'Total de Servicios', 'Costo Total', 'Pendientes', 'En Progreso', 'Completados']
      report_data[:by_vehicle].each do |vehicle|
        csv << [
          vehicle[:vin],
          vehicle[:plate],
          vehicle[:brand],
          vehicle[:model],
          vehicle[:total_services],
          format_currency(vehicle[:total_cost_cents]),
          vehicle[:services_by_status]['pending'] || 0,
          vehicle[:services_by_status]['in_progress'] || 0,
          vehicle[:services_by_status]['completed'] || 0
        ]
      end
      csv << []

      # Detalle de Servicios Individuales
      csv << ['Detalle de Servicios']
      csv << ['Fecha', 'VIN del Vehículo', 'Placa del Vehículo', 'Descripción', 'Estado', 'Prioridad', 'Costo']
      services.order(date: :desc).each do |service|
        csv << [
          service.date,
          service.vehicle.vin,
          service.vehicle.plate,
          service.description,
          translate_status(service.status),
          translate_priority(service.priority),
          format_currency(service.cost_cents)
        ]
      end
    end
  end

  def format_currency(cents)
    "$#{'%.2f' % (cents / 100.0)}"
  end

  def translate_status(status)
    {
      'pending' => 'Pendiente',
      'in_progress' => 'En Progreso',
      'completed' => 'Completado'
    }[status] || status
  end

  def translate_priority(priority)
    {
      'low' => 'Baja',
      'medium' => 'Media',
      'high' => 'Alta'
    }[priority] || priority
  end
end