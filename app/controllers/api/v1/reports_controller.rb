class Api::V1::ReportsController < Api::V1::BaseController
  def maintenance_summary
    from_date = parse_date(params[:from])
    to_date = parse_date(params[:to])

    if from_date.nil? || to_date.nil?
      render json: { error: { code: 'INVALID_PARAMS', message: 'Both from and to dates are required' } },
             status: :bad_request
      return
    end

    if from_date > to_date
      render json: { error: { code: 'INVALID_DATE_RANGE', message: 'From date cannot be after to date' } },
             status: :bad_request
      return
    end

    services = MaintenanceService
               .includes(:vehicle)
               .where(date: from_date..to_date)

    render json: build_summary_report(services, from_date, to_date)
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
      report: {
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
end