require 'rails_helper'

RSpec.describe "MaintenanceServices HTML Views", type: :request do
  let!(:vehicle) { create(:vehicle) }
  let!(:maintenance_service) { create(:maintenance_service, vehicle: vehicle) }

  describe "GET /vehicles/:vehicle_id/maintenance_services" do
    it "returns http success and displays maintenance services" do
      get vehicle_maintenance_services_path(vehicle)
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Maintenance Services for')
      expect(response.body).to include(vehicle.brand)
      expect(response.body).to include(maintenance_service.description)
    end

    it "displays a link to create a new service" do
      get vehicle_maintenance_services_path(vehicle)
      expect(response.body).to include('New Service')
    end
  end

  describe "GET /vehicles/:vehicle_id/maintenance_services/new" do
    it "returns http success and displays the form" do
      get new_vehicle_maintenance_service_path(vehicle)
      expect(response).to have_http_status(:success)
      expect(response.body).to include('New Maintenance Service')
      expect(response.body).to include(vehicle.brand)
    end
  end

  describe "GET /vehicles/:vehicle_id/maintenance_services/:id/edit" do
    it "returns http success and displays the edit form" do
      get edit_vehicle_maintenance_service_path(vehicle, maintenance_service)
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Edit Maintenance Service')
      expect(response.body).to include(maintenance_service.description)
    end
  end

  describe "POST /vehicles/:vehicle_id/maintenance_services" do
    context "with valid parameters" do
      let(:valid_params) do
        {
          maintenance_service: {
            description: 'Oil change and filter replacement',
            date: Date.current,
            status: 'pending',
            priority: 'high',
            cost_cents: 5000
          }
        }
      end

      it "creates a new maintenance service and redirects" do
        expect {
          post vehicle_maintenance_services_path(vehicle), params: valid_params
        }.to change(MaintenanceService, :count).by(1)

        expect(response).to redirect_to(vehicle_path(vehicle))
        follow_redirect!
        expect(response.body).to include('Maintenance service was successfully created')
        expect(response.body).to include('Oil change and filter replacement')
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          maintenance_service: {
            description: '',
            date: Date.tomorrow,
            cost_cents: -100
          }
        }
      end

      it "does not create a maintenance service and shows errors" do
        expect {
          post vehicle_maintenance_services_path(vehicle), params: invalid_params
        }.not_to change(MaintenanceService, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('error')
      end
    end
  end

  describe "PATCH /vehicles/:vehicle_id/maintenance_services/:id" do
    context "with valid parameters" do
      it "updates the maintenance service and redirects" do
        patch vehicle_maintenance_service_path(vehicle, maintenance_service),
              params: { maintenance_service: { description: 'Updated description' } }

        maintenance_service.reload
        expect(maintenance_service.description).to eq('Updated description')
        expect(response).to redirect_to(vehicle_path(vehicle))
        follow_redirect!
        expect(response.body).to include('Maintenance service was successfully updated')
      end
    end

    context "with invalid parameters" do
      it "does not update the maintenance service and shows errors" do
        patch vehicle_maintenance_service_path(vehicle, maintenance_service),
              params: { maintenance_service: { date: Date.tomorrow } }

        maintenance_service.reload
        expect(maintenance_service.date).not_to eq(Date.tomorrow)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /vehicles/:vehicle_id/maintenance_services/:id" do
    it "deletes the maintenance service and redirects" do
      expect {
        delete vehicle_maintenance_service_path(vehicle, maintenance_service)
      }.to change(MaintenanceService, :count).by(-1)

      expect(response).to redirect_to(vehicle_path(vehicle))
      follow_redirect!
      expect(response.body).to include('Maintenance service was successfully deleted')
    end
  end

  describe "Vehicle show page integration" do
    it "displays maintenance services with action links" do
      get vehicle_path(vehicle)
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Maintenance Services')
      expect(response.body).to include('Add Service')
      expect(response.body).to include('View All')
      expect(response.body).to include('Edit')
      expect(response.body).to include(maintenance_service.description)
    end
  end
end