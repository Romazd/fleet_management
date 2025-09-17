require 'rails_helper'

RSpec.describe 'Api::V1::Vehicles', type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }

  describe 'GET /api/v1/vehicles' do
    context 'when authenticated' do
      context 'with vehicles' do
        let!(:vehicles) { create_list(:vehicle, 3) }

        it 'returns all vehicles' do
          get '/api/v1/vehicles', headers: headers

          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json.size).to eq(3)
        end

        it 'returns vehicles with correct attributes' do
          vehicle = vehicles.first
          get '/api/v1/vehicles', headers: headers

          json = JSON.parse(response.body)
          first_vehicle = json.first

          expect(first_vehicle).to include(
            'id' => vehicle.id,
            'vin' => vehicle.vin,
            'plate' => vehicle.plate,
            'brand' => vehicle.brand,
            'model' => vehicle.model,
            'year' => vehicle.year,
            'status' => vehicle.status
          )
        end
      end

      context 'without vehicles' do
        it 'returns empty array' do
          get '/api/v1/vehicles', headers: headers

          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json).to eq([])
        end
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        get '/api/v1/vehicles'

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to include('code' => 'UNAUTHORIZED')
      end

      it 'returns unauthorized with invalid token' do
        get '/api/v1/vehicles', headers: invalid_auth_headers

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns unauthorized with expired token' do
        get '/api/v1/vehicles', headers: expired_auth_headers(user)

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']['message']).to include('expired')
      end
    end
  end

  describe 'GET /api/v1/vehicles/:id' do
    context 'when authenticated' do
      context 'when vehicle exists' do
        let!(:vehicle) { create(:vehicle) }
        let!(:maintenance_services) { create_list(:maintenance_service, 2, vehicle: vehicle) }

        it 'returns the vehicle' do
          get "/api/v1/vehicles/#{vehicle.id}", headers: headers

          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)

          expect(json).to include(
            'id' => vehicle.id,
            'vin' => vehicle.vin,
            'plate' => vehicle.plate,
            'brand' => vehicle.brand,
            'model' => vehicle.model,
            'year' => vehicle.year,
            'status' => vehicle.status
          )
        end
      end

      context 'when vehicle does not exist' do
        it 'returns not found' do
          get '/api/v1/vehicles/999999', headers: headers

          expect(response).to have_http_status(:not_found)
          json = JSON.parse(response.body)

          expect(json['error']).to include(
            'code' => 'NOT_FOUND',
            'message' => 'Vehicle not found'
          )
        end
      end

      context 'with invalid id format' do
        it 'returns not found' do
          get '/api/v1/vehicles/invalid', headers: headers

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context 'when not authenticated' do
      let!(:vehicle) { create(:vehicle) }

      it 'returns unauthorized' do
        get "/api/v1/vehicles/#{vehicle.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/vehicles' do
    context 'when authenticated' do
      let(:valid_params) do
        {
          vehicle: {
            vin: 'WBADT43452G296972',
            plate: 'ABC-1234',
            brand: 'Toyota',
            model: 'Camry',
            year: 2020,
            status: 'active'
          }
        }
      end

      context 'with valid parameters' do

        it 'creates a new vehicle' do
          expect {
            post '/api/v1/vehicles', params: valid_params.to_json, headers: headers
          }.to change(Vehicle, :count).by(1)

          expect(response).to have_http_status(:created)
        end

        it 'returns the created vehicle' do
          post '/api/v1/vehicles', params: valid_params.to_json, headers: headers

          json = JSON.parse(response.body)
          expect(json).to include(
            'vin' => 'WBADT43452G296972',
            'plate' => 'ABC-1234',
            'brand' => 'Toyota',
            'model' => 'Camry',
            'year' => 2020
          )
        end

        it 'normalizes VIN and plate to uppercase' do
          params = valid_params.deep_dup
          params[:vehicle][:vin] = 'wbadt43452g296972'
          params[:vehicle][:plate] = 'abc-1234'

          post '/api/v1/vehicles', params: params.to_json, headers: headers

          json = JSON.parse(response.body)
          expect(json['vin']).to eq('WBADT43452G296972')
          expect(json['plate']).to eq('ABC-1234')
        end
      end

      context 'with invalid parameters' do
        let(:invalid_params) do
          {
            vehicle: {
              vin: '',
              plate: '',
              brand: '',
              model: '',
              year: 1980
            }
          }
        end

        it 'does not create a new vehicle' do
          expect {
            post '/api/v1/vehicles', params: invalid_params.to_json, headers: headers
          }.not_to change(Vehicle, :count)
        end

        it 'returns validation errors' do
          post '/api/v1/vehicles', params: invalid_params.to_json, headers: headers

          expect(response).to have_http_status(:unprocessable_content)
          json = JSON.parse(response.body)

          expect(json['error']).to include(
            'code' => 'VALIDATION_ERROR',
            'message' => 'Validation failed'
          )
          expect(json['error']['details']).to be_an(Array)
          expect(json['error']['details']).to include(
            "Vin can't be blank",
            "Plate can't be blank",
            "Brand can't be blank",
            "Model can't be blank"
          )
        end

        it 'validates year range' do
          params = valid_params.deep_dup
          params[:vehicle][:year] = 1980

          post '/api/v1/vehicles', params: params.to_json, headers: headers

          expect(response).to have_http_status(:unprocessable_content)
          json = JSON.parse(response.body)
          expect(json['error']['details']).to include('Year must be greater than or equal to 1990')
        end

        it 'prevents duplicate VIN' do
          existing_vehicle = create(:vehicle, vin: 'WBADT43452G296972')

          post '/api/v1/vehicles', params: valid_params.to_json, headers: headers

          expect(response).to have_http_status(:unprocessable_content)
          json = JSON.parse(response.body)
          expect(json['error']['details']).to include('Vin has already been taken')
        end

        it 'prevents duplicate plate' do
          existing_vehicle = create(:vehicle, plate: 'ABC-1234')

          post '/api/v1/vehicles', params: valid_params.to_json, headers: headers

          expect(response).to have_http_status(:unprocessable_content)
          json = JSON.parse(response.body)
          expect(json['error']['details']).to include('Plate has already been taken')
        end
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        post '/api/v1/vehicles', params: { vehicle: { vin: 'TEST' } }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /api/v1/vehicles/:id' do
    let!(:vehicle) { create(:vehicle) }

    context 'when authenticated' do
      context 'with valid parameters' do
        let(:update_params) do
          {
            vehicle: {
              brand: 'Honda',
              model: 'Civic',
              status: 'inactive'
            }
          }
        end

        it 'updates the vehicle' do
          put "/api/v1/vehicles/#{vehicle.id}", params: update_params.to_json, headers: headers

          expect(response).to have_http_status(:success)

          vehicle.reload
          expect(vehicle.brand).to eq('Honda')
          expect(vehicle.model).to eq('Civic')
          expect(vehicle.status).to eq('inactive')
        end

        it 'returns the updated vehicle' do
          put "/api/v1/vehicles/#{vehicle.id}", params: update_params.to_json, headers: headers

          json = JSON.parse(response.body)
          expect(json).to include(
            'brand' => 'Honda',
            'model' => 'Civic',
            'status' => 'inactive'
          )
        end
      end

      context 'with invalid parameters' do
        let(:invalid_update_params) do
          {
            vehicle: {
              year: 1980
            }
          }
        end

        it 'does not update the vehicle' do
          original_year = vehicle.year

          put "/api/v1/vehicles/#{vehicle.id}", params: invalid_update_params.to_json, headers: headers

          expect(response).to have_http_status(:unprocessable_content)
          vehicle.reload
          expect(vehicle.year).to eq(original_year)
        end

        it 'returns validation errors' do
          put "/api/v1/vehicles/#{vehicle.id}", params: invalid_update_params.to_json, headers: headers

          json = JSON.parse(response.body)
          expect(json['error']['code']).to eq('VALIDATION_ERROR')
          expect(json['error']['details']).to include('Year must be greater than or equal to 1990')
        end
      end

      context 'when vehicle does not exist' do
        it 'returns not found' do
          put '/api/v1/vehicles/999999', params: { vehicle: { brand: 'Test' } }.to_json, headers: headers

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        put "/api/v1/vehicles/#{vehicle.id}", params: { vehicle: { brand: 'Test' } }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/vehicles/:id' do
    let!(:vehicle) { create(:vehicle) }

    context 'when authenticated' do
      it 'deletes the vehicle' do
        expect {
          delete "/api/v1/vehicles/#{vehicle.id}", headers: headers
        }.to change(Vehicle, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end

      it 'returns no content' do
        delete "/api/v1/vehicles/#{vehicle.id}", headers: headers

        expect(response.body).to be_empty
      end

      it 'deletes associated maintenance services' do
        create_list(:maintenance_service, 2, vehicle: vehicle)

        expect {
          delete "/api/v1/vehicles/#{vehicle.id}", headers: headers
        }.to change(MaintenanceService, :count).by(-2)
      end

      context 'when vehicle does not exist' do
        it 'returns not found' do
          delete '/api/v1/vehicles/999999', headers: headers

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        delete "/api/v1/vehicles/#{vehicle.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end