class ReportsController < ApplicationController
  def show
    @from_date = parse_date(params[:from]) || 30.days.ago.to_date
    @to_date = parse_date(params[:to]) || Date.current
    @report_type = params[:report_type] || 'summary'

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

        csv_data = generate_csv_for_type(@report_type, @from_date, @to_date)
        filename = report_filename(@report_type, @from_date, @to_date)

        send_data csv_data, filename: filename, type: 'text/csv'
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

  def generate_csv_for_type(report_type, from_date, to_date)
    report_service = ReportDataService.new(from_date, to_date)

    case report_type
    when 'summary_metrics'
      data = report_service.summary_metrics
      CsvGeneratorService.generate_summary_metrics_csv(data)
    when 'status'
      data = report_service.status_report
      CsvGeneratorService.generate_status_csv(data)
    when 'priority'
      data = report_service.priority_report
      CsvGeneratorService.generate_priority_csv(data)
    when 'top_vehicles'
      data = report_service.top_vehicles_report
      CsvGeneratorService.generate_top_vehicles_csv(data)
    when 'vehicles'
      data = report_service.vehicles_report
      CsvGeneratorService.generate_vehicles_csv(data)
    when 'services'
      data = report_service.services_report
      CsvGeneratorService.generate_services_csv(data)
    else
      # Por defecto, genera servicios
      data = report_service.services_report
      CsvGeneratorService.generate_services_csv(data)
    end
  end

  def report_filename(report_type, from_date, to_date)
    type_names = {
      'summary_metrics' => 'resumen_general',
      'status' => 'por_estado',
      'priority' => 'por_prioridad',
      'top_vehicles' => 'vehiculos_top',
      'vehicles' => 'vehiculos',
      'services' => 'servicios'
    }

    name = type_names[report_type] || 'reporte'
    "reporte_de_#{name}_#{from_date}_#{to_date}.csv"
  end
end