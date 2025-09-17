require 'rails_helper'

RSpec.describe 'Api::V1::MaintenanceServices', type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }
  let!(:vehicle) { create(:vehicle) }

  describe 'GET /api/v1/vehicles/:vehicle_id/maintenance_services' do
    context 'when authenticated' do
      context 'when vehicle exists' do
        let!(:services) { create_list(:maintenance_service, 3, vehicle: vehicle) }
        let!(:other_vehicle_service) { create(:maintenance_service) }

        it 'returns maintenance services for the vehicle' do
          get "/api/v1/vehicles/#{vehicle.id}/maintenance_services", headers: headers

          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json.size).to eq(3)
        end

        it 'does not return services from other vehicles' do
          get "/api/v1/vehicles/#{vehicle.id}/maintenance_services", headers: headers

          json = JSON.parse(response.body)
          service_ids = json.map { |s| s['id'] }
          expect(service_ids).not_to include(other_vehicle_service.id)
        end

        it 'returns services ordered by date desc' do
          services[0].update(date: 3.days.ago)
          services[1].update(date: 1.day.ago)
          services[2].update(date: 2.days.ago)

          get "/api/v1/vehicles/#{vehicle.id}/maintenance_services", headers: headers

          json = JSON.parse(response.body)
          dates = json.map { |s| Date.parse(s['date']) }
          expect(dates).to eq(dates.sort.reverse)
        end
      end

      context 'when vehicle does not exist' do
        it 'returns not found' do
          get '/api/v1/vehicles/999999/maintenance_services', headers: headers

          expect(response).to have_http_status(:not_found)
          json = JSON.parse(response.body)
          expect(json['error']['code']).to eq('NOT_FOUND')
        end
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        get "/api/v1/vehicles/#{vehicle.id}/maintenance_services"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/vehicles/:vehicle_id/maintenance_services' do
    context 'when authenticated' do
      context 'with valid parameters' do
        let(:valid_params) do
          {
            maintenance_service: {
              description: 'Oil change and filter replacement',
              status: 'pending',
              date: Date.current,
              cost_cents: 15000,
              priority: 'high'
            }
          }
        end

        it 'creates a new maintenance service' do
          expect {
            post "/api/v1/vehicles/#{vehicle.id}/maintenance_services",
                 params: valid_params.to_json,
                 headers: headers
          }.to change(MaintenanceService, :count).by(1)

          expect(response).to have_http_status(:created)
        end

        it 'returns the created service' do
          post "/api/v1/vehicles/#{vehicle.id}/maintenance_services",
               params: valid_params.to_json,
               headers: headers

          json = JSON.parse(response.body)
          expect(json).to include(
            'description' => 'Oil change and filter replacement',
            'status' => 'pending',
            'cost_cents' => 15000,
            'priority' => 'high',
            'vehicle_id' => vehicle.id
          )
        end

        it 'automatically sets completed_at when status is completed' do
          params = valid_params.deep_dup
          params[:maintenance_service][:status] = 'completed'

          post "/api/v1/vehicles/#{vehicle.id}/maintenance_services",
               params: params.to_json,
               headers: headers

          json = JSON.parse(response.body)
          expect(json['status']).to eq('completed')
          expect(json['completed_at']).to be_present
        end
      end

      context 'with invalid parameters' do
        let(:invalid_params) do
          {
            maintenance_service: {
              description: '',
              date: 1.day.from_now,
              cost_cents: -100
            }
          }
        end

        it 'does not create a new service' do
          expect {
            post "/api/v1/vehicles/#{vehicle.id}/maintenance_services",
                 params: invalid_params.to_json,
                 headers: headers
          }.not_to change(MaintenanceService, :count)
        end

        it 'returns validation errors' do
          post "/api/v1/vehicles/#{vehicle.id}/maintenance_services",
               params: invalid_params.to_json,
               headers: headers

          expect(response).to have_http_status(:unprocessable_content)
          json = JSON.parse(response.body)
          expect(json['error']['code']).to eq('VALIDATION_ERROR')
          expect(json['error']['details']).to include("Description can't be blank")
          expect(json['error']['details']).to include("Date can't be in the future")
          expect(json['error']['details']).to include("Cost cents must be greater than or equal to 0")
        end
      end

      context 'when vehicle does not exist' do
        it 'returns not found' do
          post '/api/v1/vehicles/999999/maintenance_services',
               params: { maintenance_service: { description: 'Test' } }.to_json,
               headers: headers

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        post "/api/v1/vehicles/#{vehicle.id}/maintenance_services",
             params: { maintenance_service: { description: 'Test' } }.to_json,
             headers: { 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /api/v1/maintenance_services/:id' do
    let!(:service) { create(:maintenance_service, vehicle: vehicle, status: 'pending') }

    context 'when authenticated' do
      context 'with valid parameters' do
        let(:update_params) do
          {
            maintenance_service: {
              status: 'in_progress',
              cost_cents: 20000
            }
          }
        end

        it 'updates the maintenance service' do
          put "/api/v1/maintenance_services/#{service.id}",
              params: update_params.to_json,
              headers: headers

          expect(response).to have_http_status(:success)

          service.reload
          expect(service.status).to eq('in_progress')
          expect(service.cost_cents).to eq(20000)
        end

        it 'returns the updated service' do
          put "/api/v1/maintenance_services/#{service.id}",
              params: update_params.to_json,
              headers: headers

          json = JSON.parse(response.body)
          expect(json['status']).to eq('in_progress')
          expect(json['cost_cents']).to eq(20000)
        end

        it 'sets completed_at when changing to completed' do
          params = { maintenance_service: { status: 'completed' } }

          put "/api/v1/maintenance_services/#{service.id}",
              params: params.to_json,
              headers: headers

          json = JSON.parse(response.body)
          expect(json['completed_at']).to be_present

          service.reload
          expect(service.completed_at).to be_present
        end
      end

      context 'with invalid parameters' do
        let(:invalid_params) do
          {
            maintenance_service: {
              cost_cents: -500
            }
          }
        end

        it 'does not update the service' do
          original_cost = service.cost_cents

          put "/api/v1/maintenance_services/#{service.id}",
              params: invalid_params.to_json,
              headers: headers

          expect(response).to have_http_status(:unprocessable_content)

          service.reload
          expect(service.cost_cents).to eq(original_cost)
        end

        it 'returns validation errors' do
          put "/api/v1/maintenance_services/#{service.id}",
              params: invalid_params.to_json,
              headers: headers

          json = JSON.parse(response.body)
          expect(json['error']['code']).to eq('VALIDATION_ERROR')
          expect(json['error']['details']).to include('Cost cents must be greater than or equal to 0')
        end
      end

      context 'when service does not exist' do
        it 'returns not found' do
          put '/api/v1/maintenance_services/999999',
              params: { maintenance_service: { status: 'completed' } }.to_json,
              headers: headers

          expect(response).to have_http_status(:not_found)
          json = JSON.parse(response.body)
          expect(json['error']['message']).to eq('Maintenance service not found')
        end
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        put "/api/v1/maintenance_services/#{service.id}",
            params: { maintenance_service: { status: 'completed' } }.to_json,
            headers: { 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end