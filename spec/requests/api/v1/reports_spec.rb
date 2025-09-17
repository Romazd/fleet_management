require 'rails_helper'

RSpec.describe 'Api::V1::Reports', type: :request do
  include AuthHelper

  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }

  describe 'GET /api/v1/reports/maintenance_summary' do
    let!(:vehicle1) { create(:vehicle, brand: 'Toyota', model: 'Corolla') }
    let!(:vehicle2) { create(:vehicle, brand: 'Honda', model: 'Civic') }
    let!(:vehicle3) { create(:vehicle, brand: 'Ford', model: 'Focus') }

    # Services within date range
    let!(:service1) do
      create(:maintenance_service,
             vehicle: vehicle1,
             date: '2024-01-15',
             cost_cents: 50000,
             status: :pending,
             priority: :high)
    end

    let!(:service2) do
      create(:maintenance_service,
             vehicle: vehicle1,
             date: '2024-01-20',
             cost_cents: 30000,
             status: :completed,
             priority: :medium,
             completed_at: '2024-01-21')
    end

    let!(:service3) do
      create(:maintenance_service,
             vehicle: vehicle2,
             date: '2024-01-18',
             cost_cents: 70000,
             status: :in_progress,
             priority: :high)
    end

    let!(:service4) do
      create(:maintenance_service,
             vehicle: vehicle2,
             date: '2024-01-25',
             cost_cents: 20000,
             status: :completed,
             priority: :low,
             completed_at: '2024-01-26')
    end

    let!(:service5) do
      create(:maintenance_service,
             vehicle: vehicle3,
             date: '2024-01-22',
             cost_cents: 45000,
             status: :pending,
             priority: :medium)
    end

    # Service outside date range
    let!(:service_outside) do
      create(:maintenance_service,
             vehicle: vehicle3,
             date: '2024-02-01',
             cost_cents: 100000,
             status: :pending,
             priority: :high)
    end

    context 'with valid date range' do
      it 'returns maintenance summary report' do
        get '/api/v1/reports/maintenance_summary',
            params: { from: '2024-01-01', to: '2024-01-31' },
            headers: headers

        expect(response).to have_http_status(:success)

        json = JSON.parse(response.body)
        report = json['report']

        # Period
        expect(report['period']['from']).to eq('2024-01-01')
        expect(report['period']['to']).to eq('2024-01-31')

        # Summary
        expect(report['summary']['total_orders']).to eq(5)
        expect(report['summary']['total_cost_cents']).to eq(215000)
        expect(report['summary']['average_cost_cents']).to eq(43000)

        # By Status
        status_breakdown = report['by_status']
        pending = status_breakdown.find { |s| s['status'] == 'pending' }
        in_progress = status_breakdown.find { |s| s['status'] == 'in_progress' }
        completed = status_breakdown.find { |s| s['status'] == 'completed' }

        expect(pending['count']).to eq(2)
        expect(pending['total_cost_cents']).to eq(95000)

        expect(in_progress['count']).to eq(1)
        expect(in_progress['total_cost_cents']).to eq(70000)

        expect(completed['count']).to eq(2)
        expect(completed['total_cost_cents']).to eq(50000)

        # By Priority
        priority_breakdown = report['by_priority']
        high = priority_breakdown.find { |p| p['priority'] == 'high' }
        medium = priority_breakdown.find { |p| p['priority'] == 'medium' }
        low = priority_breakdown.find { |p| p['priority'] == 'low' }

        expect(high['count']).to eq(2)
        expect(high['total_cost_cents']).to eq(120000)

        expect(medium['count']).to eq(2)
        expect(medium['total_cost_cents']).to eq(75000)

        expect(low['count']).to eq(1)
        expect(low['total_cost_cents']).to eq(20000)

        # Top vehicles by cost
        top_vehicles = report['top_vehicles_by_cost']
        expect(top_vehicles.size).to eq(3)
        expect(top_vehicles[0]['vehicle_id']).to eq(vehicle2.id)
        expect(top_vehicles[0]['total_cost_cents']).to eq(90000)
        expect(top_vehicles[1]['vehicle_id']).to eq(vehicle1.id)
        expect(top_vehicles[1]['total_cost_cents']).to eq(80000)
        expect(top_vehicles[2]['vehicle_id']).to eq(vehicle3.id)
        expect(top_vehicles[2]['total_cost_cents']).to eq(45000)

        # By Vehicle
        vehicle_breakdown = report['by_vehicle']
        expect(vehicle_breakdown.size).to eq(3)

        vehicle1_data = vehicle_breakdown.find { |v| v['vehicle_id'] == vehicle1.id }
        expect(vehicle1_data['total_services']).to eq(2)
        expect(vehicle1_data['total_cost_cents']).to eq(80000)
        expect(vehicle1_data['services_by_status']).to eq({ 'pending' => 1, 'completed' => 1 })
      end
    end

    context 'with no services in date range' do
      it 'returns empty report' do
        get '/api/v1/reports/maintenance_summary',
            params: { from: '2023-01-01', to: '2023-12-31' },
            headers: headers

        expect(response).to have_http_status(:success)

        json = JSON.parse(response.body)
        report = json['report']

        expect(report['summary']['total_orders']).to eq(0)
        expect(report['summary']['total_cost_cents']).to eq(0)
        expect(report['by_vehicle']).to eq([])
        expect(report['top_vehicles_by_cost']).to eq([])
      end
    end

    context 'with missing parameters' do
      it 'returns error when from is missing' do
        get '/api/v1/reports/maintenance_summary',
            params: { to: '2024-01-31' },
            headers: headers

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']['code']).to eq('INVALID_PARAMS')
      end

      it 'returns error when to is missing' do
        get '/api/v1/reports/maintenance_summary',
            params: { from: '2024-01-01' },
            headers: headers

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']['code']).to eq('INVALID_PARAMS')
      end

      it 'returns error when both dates are missing' do
        get '/api/v1/reports/maintenance_summary',
            headers: headers

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']['code']).to eq('INVALID_PARAMS')
      end
    end

    context 'with invalid date format' do
      it 'returns error for invalid from date' do
        get '/api/v1/reports/maintenance_summary',
            params: { from: 'invalid-date', to: '2024-01-31' },
            headers: headers

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']['code']).to eq('INVALID_PARAMS')
      end

      it 'returns error for invalid to date' do
        get '/api/v1/reports/maintenance_summary',
            params: { from: '2024-01-01', to: 'not-a-date' },
            headers: headers

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']['code']).to eq('INVALID_PARAMS')
      end
    end

    context 'with invalid date range' do
      it 'returns error when from is after to' do
        get '/api/v1/reports/maintenance_summary',
            params: { from: '2024-12-31', to: '2024-01-01' },
            headers: headers

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']['code']).to eq('INVALID_DATE_RANGE')
        expect(json['error']['message']).to eq('From date cannot be after to date')
      end
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        get '/api/v1/reports/maintenance_summary',
            params: { from: '2024-01-01', to: '2024-01-31' }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with more than 3 vehicles' do
      let!(:vehicle4) { create(:vehicle, brand: 'Nissan', model: 'Sentra') }
      let!(:service6) do
        create(:maintenance_service,
               vehicle: vehicle4,
               date: '2024-01-10',
               cost_cents: 150000,
               status: :pending)
      end

      it 'returns only top 3 vehicles in top_vehicles_by_cost' do
        get '/api/v1/reports/maintenance_summary',
            params: { from: '2024-01-01', to: '2024-01-31' },
            headers: headers

        json = JSON.parse(response.body)
        top_vehicles = json['report']['top_vehicles_by_cost']

        expect(top_vehicles.size).to eq(3)
        expect(top_vehicles[0]['vehicle_id']).to eq(vehicle4.id)
        expect(top_vehicles[0]['total_cost_cents']).to eq(150000)
        expect(top_vehicles[1]['vehicle_id']).to eq(vehicle2.id)
        expect(top_vehicles[2]['vehicle_id']).to eq(vehicle1.id)

        # But by_vehicle should include all 4
        expect(json['report']['by_vehicle'].size).to eq(4)
      end
    end
  end
end