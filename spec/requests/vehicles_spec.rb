require 'rails_helper'

RSpec.describe "Vehicles HTML Views", type: :request do
  let!(:vehicle) { create(:vehicle, brand: 'Toyota', model: 'Camry', year: 2020) }

  describe "GET /vehicles" do
    it "returns http success and displays vehicles" do
      get vehicles_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Toyota')
      expect(response.body).to include('Camry')
    end

    it "displays a link to create a new vehicle" do
      get vehicles_path
      expect(response.body).to include('New Vehicle')
    end
  end

  describe "GET /vehicles/:id" do
    it "returns http success and displays vehicle details" do
      get vehicle_path(vehicle)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(vehicle.vin)
      expect(response.body).to include(vehicle.plate)
      expect(response.body).to include('Vehicle Details')
    end

    it "displays maintenance services section" do
      get vehicle_path(vehicle)
      expect(response.body).to include('Maintenance Services')
    end
  end

  describe "GET /vehicles/new" do
    it "returns http success and displays the form" do
      get new_vehicle_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('New Vehicle')
      expect(response.body).to include('form')
    end
  end

  describe "GET /vehicles/:id/edit" do
    it "returns http success and displays the edit form" do
      get edit_vehicle_path(vehicle)
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Edit Vehicle')
      expect(response.body).to include(vehicle.vin)
    end
  end

  describe "POST /vehicles" do
    context "with valid parameters" do
      let(:valid_params) do
        {
          vehicle: {
            vin: '1HGBH41JXMN100001',
            plate: 'NEW-001',
            brand: 'Honda',
            model: 'Civic',
            year: 2021,
            status: 'active'
          }
        }
      end

      it "creates a new vehicle and redirects" do
        expect {
          post vehicles_path, params: valid_params
        }.to change(Vehicle, :count).by(1)

        expect(response).to redirect_to(vehicle_path(Vehicle.last))
        follow_redirect!
        expect(response.body).to include('Vehicle was successfully created')
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          vehicle: {
            vin: '',
            plate: '',
            brand: 'Honda'
          }
        }
      end

      it "does not create a vehicle and shows errors" do
        expect {
          post vehicles_path, params: invalid_params
        }.not_to change(Vehicle, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('error')
      end
    end
  end

  describe "PATCH /vehicles/:id" do
    context "with valid parameters" do
      it "updates the vehicle and redirects" do
        patch vehicle_path(vehicle), params: { vehicle: { brand: 'Updated Brand' } }

        vehicle.reload
        expect(vehicle.brand).to eq('Updated Brand')
        expect(response).to redirect_to(vehicle_path(vehicle))
        follow_redirect!
        expect(response.body).to include('Vehicle was successfully updated')
      end
    end

    context "with invalid parameters" do
      it "does not update the vehicle and shows errors" do
        patch vehicle_path(vehicle), params: { vehicle: { year: 1800 } }

        vehicle.reload
        expect(vehicle.year).not_to eq(1800)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /vehicles/:id" do
    it "deletes the vehicle and redirects to index" do
      expect {
        delete vehicle_path(vehicle)
      }.to change(Vehicle, :count).by(-1)

      expect(response).to redirect_to(vehicles_url)
      follow_redirect!
      expect(response.body).to include('Vehicle was successfully destroyed')
    end
  end
end