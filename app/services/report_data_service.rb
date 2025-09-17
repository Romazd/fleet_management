class ReportDataService
  def initialize(from_date, to_date)
    @from_date = from_date
    @to_date = to_date
    @services = load_services
  end

  def summary_metrics
    {
      period: period_data,
      total_orders: @services.count,
      total_vehicles: @services.select(:vehicle_id).distinct.count,
      total_cost_cents: @services.sum(:cost_cents),
      average_cost_cents: @services.average(:cost_cents)&.to_i || 0
    }
  end

  def status_report
    MaintenanceService.statuses.keys.map do |status|
      filtered = @services.select { |s| s.status == status }
      {
        status: status,
        count: filtered.size,
        percentage: (@services.any? ? (filtered.size * 100.0 / @services.count).round(2) : 0),
        total_cost_cents: filtered.sum(&:cost_cents),
        average_cost_cents: filtered.any? ? (filtered.sum(&:cost_cents) / filtered.size) : 0
      }
    end
  end

  def priority_report
    MaintenanceService.priorities.keys.map do |priority|
      filtered = @services.select { |s| s.priority == priority }
      {
        priority: priority,
        count: filtered.size,
        percentage: (@services.any? ? (filtered.size * 100.0 / @services.count).round(2) : 0),
        total_cost_cents: filtered.sum(&:cost_cents),
        average_cost_cents: filtered.any? ? (filtered.sum(&:cost_cents) / filtered.size) : 0
      }
    end
  end

  def top_vehicles_report(limit = 10)
    @services
      .group_by(&:vehicle)
      .map do |vehicle, vehicle_services|
        {
          vehicle_id: vehicle.id,
          vin: vehicle.vin,
          plate: vehicle.plate,
          brand: vehicle.brand,
          model: vehicle.model,
          year: vehicle.year,
          services_count: vehicle_services.size,
          total_cost_cents: vehicle_services.sum(&:cost_cents),
          average_cost_cents: vehicle_services.sum(&:cost_cents) / vehicle_services.size
        }
      end
      .sort_by { |v| -v[:total_cost_cents] }
      .first(limit)
  end

  def vehicles_report
    @services.group_by(&:vehicle).map do |vehicle, vehicle_services|
      {
        vehicle_id: vehicle.id,
        vin: vehicle.vin,
        plate: vehicle.plate,
        brand: vehicle.brand,
        model: vehicle.model,
        year: vehicle.year,
        status: vehicle.status,
        total_services: vehicle_services.size,
        total_cost_cents: vehicle_services.sum(&:cost_cents),
        pending_count: vehicle_services.count { |s| s.status == 'pending' },
        in_progress_count: vehicle_services.count { |s| s.status == 'in_progress' },
        completed_count: vehicle_services.count { |s| s.status == 'completed' }
      }
    end.sort_by { |v| -v[:total_cost_cents] }
  end

  def services_report
    @services.order(date: :desc).map do |service|
      {
        date: service.date,
        vehicle_vin: service.vehicle.vin,
        vehicle_plate: service.vehicle.plate,
        vehicle_brand: service.vehicle.brand,
        vehicle_model: service.vehicle.model,
        vehicle_year: service.vehicle.year,
        description: service.description,
        status: service.status,
        priority: service.priority,
        cost_cents: service.cost_cents,
        completed_at: service.completed_at
      }
    end
  end

  private

  def load_services
    MaintenanceService
      .includes(:vehicle)
      .where(date: @from_date..@to_date)
  end

  def period_data
    {
      from: @from_date.to_s,
      to: @to_date.to_s
    }
  end
end