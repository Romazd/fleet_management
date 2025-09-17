require 'rails_helper'

RSpec.describe 'Reports', type: :request do
  let!(:vehicle) { create(:vehicle) }
  let!(:service1) { create(:maintenance_service, vehicle: vehicle, date: Date.new(2025, 6, 1), cost_cents: 5000, status: 'pending') }
  let!(:service2) { create(:maintenance_service, vehicle: vehicle, date: Date.new(2025, 6, 15), cost_cents: 3000, status: 'completed') }

  describe 'GET /report' do
    context 'HTML format' do
      it 'returns successful response' do
        get report_path

        expect(response).to have_http_status(:success)
        expect(response.content_type).to match(/text\/html/)
      end

      it 'renders the form with date fields' do
        get report_path

        expect(response.body).to include('Fecha Desde')
        expect(response.body).to include('Fecha Hasta')
        expect(response.body).to include('Tipo de Reporte')
      end

      it 'displays report type options' do
        get report_path

        expect(response.body).to include('Detalle de Servicios')
        expect(response.body).to include('Detalle de Vehículos')
        expect(response.body).to include('Resumen General')
      end
    end

    context 'CSV format' do
      context 'services report' do
        it 'downloads CSV file with correct filename' do
          get report_path(format: :csv), params: { from: '2025-06-01', to: '2025-06-30', report_type: 'services' }

          expect(response).to have_http_status(:success)
          expect(response.content_type).to eq('text/csv')
          expect(response.headers['Content-Disposition']).to include('reporte_de_servicios_2025-06-01_2025-06-30.csv')
        end

        it 'includes service data in CSV' do
          get report_path(format: :csv), params: { from: '2025-06-01', to: '2025-06-30', report_type: 'services' }

          csv_data = CSV.parse(response.body)
          expect(csv_data[0]).to include('Fecha', 'VIN', 'Placa', 'Estado', 'Costo')
          expect(csv_data.size).to be >= 2 # Headers + at least one row
        end
      end

      context 'vehicles report' do
        it 'downloads vehicles report CSV' do
          get report_path(format: :csv), params: { from: '2025-06-01', to: '2025-06-30', report_type: 'vehicles' }

          expect(response).to have_http_status(:success)
          expect(response.headers['Content-Disposition']).to include('reporte_de_vehiculos_2025-06-01_2025-06-30.csv')
        end
      end

      context 'summary metrics report' do
        it 'downloads summary metrics CSV' do
          get report_path(format: :csv), params: { from: '2025-06-01', to: '2025-06-30', report_type: 'summary_metrics' }

          expect(response).to have_http_status(:success)
          expect(response.headers['Content-Disposition']).to include('reporte_de_resumen_general_2025-06-01_2025-06-30.csv')
        end
      end

      context 'status report' do
        it 'downloads status report CSV' do
          get report_path(format: :csv), params: { from: '2025-06-01', to: '2025-06-30', report_type: 'status' }

          expect(response).to have_http_status(:success)
          expect(response.headers['Content-Disposition']).to include('reporte_de_por_estado_2025-06-01_2025-06-30.csv')
        end
      end

      context 'priority report' do
        it 'downloads priority report CSV' do
          get report_path(format: :csv), params: { from: '2025-06-01', to: '2025-06-30', report_type: 'priority' }

          expect(response).to have_http_status(:success)
          expect(response.headers['Content-Disposition']).to include('reporte_de_por_prioridad_2025-06-01_2025-06-30.csv')
        end
      end

      context 'top vehicles report' do
        it 'downloads top vehicles report CSV' do
          get report_path(format: :csv), params: { from: '2025-06-01', to: '2025-06-30', report_type: 'top_vehicles' }

          expect(response).to have_http_status(:success)
          expect(response.headers['Content-Disposition']).to include('reporte_de_vehiculos_top_2025-06-01_2025-06-30.csv')
        end
      end

      context 'validations' do
        it 'requires from and to dates for CSV download' do
          get report_path(format: :csv), params: { report_type: 'services' }

          expect(response).to redirect_to(report_path)
          expect(flash[:alert]).to eq('Las fechas desde y hasta son requeridas')
        end

        it 'validates from date is not after to date' do
          get report_path(format: :csv), params: { from: '2025-06-30', to: '2025-06-01', report_type: 'services' }

          expect(response).to redirect_to(report_path)
          expect(flash[:alert]).to eq('La fecha desde no puede ser posterior a la fecha hasta')
        end
      end

      context 'unknown report type' do
        it 'defaults to services report' do
          get report_path(format: :csv), params: { from: '2025-06-01', to: '2025-06-30', report_type: 'unknown' }

          expect(response).to have_http_status(:success)
          csv_data = CSV.parse(response.body)
          expect(csv_data[0]).to include('Fecha', 'VIN', 'Placa') # Services report headers
        end
      end
    end
  end

  describe 'date filtering' do
    let!(:out_of_range_service) { create(:maintenance_service, vehicle: vehicle, date: Date.new(2024, 12, 1), cost_cents: 10000) }

    it 'only includes services within specified date range' do
      get report_path(format: :csv), params: { from: '2025-06-01', to: '2025-06-30', report_type: 'services' }

      csv_data = CSV.parse(response.body)
      # Headers + 2 services in range (out_of_range_service should not be included)
      expect(csv_data.size).to eq(3)
    end
  end

  describe 'report content verification' do
    it 'generates correct summary metrics' do
      get report_path(format: :csv), params: { from: '2025-06-01', to: '2025-06-30', report_type: 'summary_metrics' }

      csv_data = CSV.parse(response.body)
      expect(csv_data[1][2]).to eq('2') # Total orders
      expect(csv_data[1][3]).to eq('1') # Total vehicles
    end

    it 'generates correct status breakdown' do
      get report_path(format: :csv), params: { from: '2025-06-01', to: '2025-06-30', report_type: 'status' }

      csv_data = CSV.parse(response.body)

      # Find pending and completed rows
      pending_row = csv_data.find { |row| row[0] == 'Pendiente' }
      completed_row = csv_data.find { |row| row[0] == 'Completado' }

      expect(pending_row[1]).to eq('1') # 1 pending service
      expect(completed_row[1]).to eq('1') # 1 completed service
    end
  end
end