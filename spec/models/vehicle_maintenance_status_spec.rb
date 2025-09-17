require 'rails_helper'

RSpec.describe 'Vehicle Maintenance Status Business Rules', type: :model do
  let(:vehicle) { create(:vehicle, status: :active) }

  describe 'automatic status updates based on maintenance services' do
    context 'when creating a pending maintenance service' do
      it 'changes vehicle status to in_maintenance' do
        expect {
          create(:maintenance_service, vehicle: vehicle, status: :pending)
        }.to change { vehicle.reload.status }.from('active').to('in_maintenance')
      end

      it 'changes inactive vehicle to in_maintenance' do
        vehicle.update!(status: :inactive)
        expect {
          create(:maintenance_service, vehicle: vehicle, status: :pending)
        }.to change { vehicle.reload.status }.from('inactive').to('in_maintenance')
      end
    end

    context 'when creating an in_progress maintenance service' do
      it 'changes vehicle status to in_maintenance' do
        expect {
          create(:maintenance_service, vehicle: vehicle, status: :in_progress)
        }.to change { vehicle.reload.status }.from('active').to('in_maintenance')
      end
    end

    context 'when creating a completed maintenance service' do
      it 'does not change vehicle status' do
        expect {
          create(:maintenance_service, vehicle: vehicle, status: :completed, completed_at: Time.current)
        }.not_to change { vehicle.reload.status }
      end
    end

    context 'when updating maintenance service status' do
      let!(:service) { create(:maintenance_service, vehicle: vehicle, status: :pending) }

      before { vehicle.reload } # Vehicle should be in_maintenance after creating pending service

      it 'keeps vehicle in_maintenance when changing from pending to in_progress' do
        expect {
          service.update!(status: :in_progress)
        }.not_to change { vehicle.reload.status }
        expect(vehicle.status).to eq('in_maintenance')
      end

      it 'changes vehicle to active when completing the last pending service' do
        expect(vehicle.status).to eq('in_maintenance')
        expect {
          service.update!(status: :completed, completed_at: Time.current)
        }.to change { vehicle.reload.status }.from('in_maintenance').to('active')
      end

      it 'keeps vehicle in_maintenance when there are other pending services' do
        create(:maintenance_service, vehicle: vehicle, status: :pending)

        expect {
          service.update!(status: :completed, completed_at: Time.current)
        }.not_to change { vehicle.reload.status }
        expect(vehicle.status).to eq('in_maintenance')
      end
    end

    context 'when deleting maintenance services' do
      let!(:service1) { create(:maintenance_service, vehicle: vehicle, status: :pending) }
      let!(:service2) { create(:maintenance_service, vehicle: vehicle, status: :in_progress) }

      before { vehicle.reload } # Vehicle should be in_maintenance

      it 'keeps vehicle in_maintenance when deleting one of multiple pending services' do
        expect {
          service1.destroy
        }.not_to change { vehicle.reload.status }
        expect(vehicle.status).to eq('in_maintenance')
      end

      it 'changes vehicle to active when deleting the last pending service' do
        service1.destroy
        expect(vehicle.reload.status).to eq('in_maintenance')

        expect {
          service2.destroy
        }.to change { vehicle.reload.status }.from('in_maintenance').to('active')
      end
    end

    context 'with multiple services and status changes' do
      it 'handles complex workflow correctly' do
        # Start with active vehicle
        expect(vehicle.status).to eq('active')

        # Create pending service -> should change to in_maintenance
        service1 = create(:maintenance_service, vehicle: vehicle, status: :pending)
        expect(vehicle.reload.status).to eq('in_maintenance')

        # Add another pending service -> should stay in_maintenance
        service2 = create(:maintenance_service, vehicle: vehicle, status: :pending)
        expect(vehicle.reload.status).to eq('in_maintenance')

        # Complete one service -> should stay in_maintenance
        service1.update!(status: :completed, completed_at: Time.current)
        expect(vehicle.reload.status).to eq('in_maintenance')

        # Start progress on second service -> should stay in_maintenance
        service2.update!(status: :in_progress)
        expect(vehicle.reload.status).to eq('in_maintenance')

        # Complete second service -> should change to active
        service2.update!(status: :completed, completed_at: Time.current)
        expect(vehicle.reload.status).to eq('active')

        # Create new in_progress service -> should change to in_maintenance
        service3 = create(:maintenance_service, vehicle: vehicle, status: :in_progress)
        expect(vehicle.reload.status).to eq('in_maintenance')

        # Delete the in_progress service -> should change to active
        service3.destroy
        expect(vehicle.reload.status).to eq('active')
      end
    end

    context 'edge cases' do
      it 'does not update status if vehicle is already in correct state' do
        service = create(:maintenance_service, vehicle: vehicle, status: :pending)
        vehicle.reload
        expect(vehicle.status).to eq('in_maintenance')

        # Create another pending service - should not trigger update
        expect(vehicle).not_to receive(:update!)
        create(:maintenance_service, vehicle: vehicle, status: :pending)
      end

      it 'handles vehicle with no maintenance services correctly' do
        vehicle.update!(status: :in_maintenance)
        vehicle.update_maintenance_status!
        expect(vehicle.reload.status).to eq('active')
      end
    end
  end
end