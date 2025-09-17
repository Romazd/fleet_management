require 'rails_helper'

RSpec.describe ReportDataService do
  let(:from_date) { Date.new(2025, 1, 1) }
  let(:to_date) { Date.new(2025, 12, 31) }
  let(:service) { described_class.new(from_date, to_date) }

  describe '#summary_metrics' do
    let!(:vehicle1) { create(:vehicle) }
    let!(:vehicle2) { create(:vehicle) }
    let!(:service1) { create(:maintenance_service, vehicle: vehicle1, date: Date.new(2025, 6, 1), cost_cents: 5000) }
    let!(:service2) { create(:maintenance_service, vehicle: vehicle1, date: Date.new(2025, 6, 15), cost_cents: 3000) }
    let!(:service3) { create(:maintenance_service, vehicle: vehicle2, date: Date.new(2025, 7, 1), cost_cents: 4000) }
    let!(:out_of_range) { create(:maintenance_service, vehicle: vehicle1, date: Date.new(2024, 12, 1), cost_cents: 1000) }

    it 'returns correct summary metrics' do
      result = service.summary_metrics

      expect(result[:period][:from]).to eq('2025-01-01')
      expect(result[:period][:to]).to eq('2025-12-31')
      expect(result[:total_orders]).to eq(3)
      expect(result[:total_vehicles]).to eq(2)
      expect(result[:total_cost_cents]).to eq(12000)
      expect(result[:average_cost_cents]).to eq(4000)
    end
  end

  describe '#status_report' do
    let!(:vehicle) { create(:vehicle) }
    let!(:pending_service) { create(:maintenance_service, vehicle: vehicle, status: 'pending', date: Date.new(2025, 6, 1), cost_cents: 2000) }
    let!(:in_progress_service) { create(:maintenance_service, vehicle: vehicle, status: 'in_progress', date: Date.new(2025, 6, 2), cost_cents: 3000) }
    let!(:completed_service1) { create(:maintenance_service, vehicle: vehicle, status: 'completed', date: Date.new(2025, 6, 3), cost_cents: 4000) }
    let!(:completed_service2) { create(:maintenance_service, vehicle: vehicle, status: 'completed', date: Date.new(2025, 6, 4), cost_cents: 5000) }

    it 'returns breakdown by status with percentages and averages' do
      result = service.status_report

      pending = result.find { |r| r[:status] == 'pending' }
      expect(pending[:count]).to eq(1)
      expect(pending[:percentage]).to eq(25.0)
      expect(pending[:total_cost_cents]).to eq(2000)
      expect(pending[:average_cost_cents]).to eq(2000)

      in_progress = result.find { |r| r[:status] == 'in_progress' }
      expect(in_progress[:count]).to eq(1)
      expect(in_progress[:percentage]).to eq(25.0)
      expect(in_progress[:total_cost_cents]).to eq(3000)
      expect(in_progress[:average_cost_cents]).to eq(3000)

      completed = result.find { |r| r[:status] == 'completed' }
      expect(completed[:count]).to eq(2)
      expect(completed[:percentage]).to eq(50.0)
      expect(completed[:total_cost_cents]).to eq(9000)
      expect(completed[:average_cost_cents]).to eq(4500)
    end
  end

  describe '#priority_report' do
    let!(:vehicle) { create(:vehicle) }
    let!(:low_service) { create(:maintenance_service, vehicle: vehicle, priority: 'low', date: Date.new(2025, 6, 1), cost_cents: 1000) }
    let!(:medium_service1) { create(:maintenance_service, vehicle: vehicle, priority: 'medium', date: Date.new(2025, 6, 2), cost_cents: 2000) }
    let!(:medium_service2) { create(:maintenance_service, vehicle: vehicle, priority: 'medium', date: Date.new(2025, 6, 3), cost_cents: 3000) }
    let!(:high_service) { create(:maintenance_service, vehicle: vehicle, priority: 'high', date: Date.new(2025, 6, 4), cost_cents: 10000) }

    it 'returns breakdown by priority with percentages and averages' do
      result = service.priority_report

      low = result.find { |r| r[:priority] == 'low' }
      expect(low[:count]).to eq(1)
      expect(low[:percentage]).to eq(25.0)
      expect(low[:total_cost_cents]).to eq(1000)
      expect(low[:average_cost_cents]).to eq(1000)

      medium = result.find { |r| r[:priority] == 'medium' }
      expect(medium[:count]).to eq(2)
      expect(medium[:percentage]).to eq(50.0)
      expect(medium[:total_cost_cents]).to eq(5000)
      expect(medium[:average_cost_cents]).to eq(2500)

      high = result.find { |r| r[:priority] == 'high' }
      expect(high[:count]).to eq(1)
      expect(high[:percentage]).to eq(25.0)
      expect(high[:total_cost_cents]).to eq(10000)
      expect(high[:average_cost_cents]).to eq(10000)
    end
  end

  describe '#top_vehicles_report' do
    let!(:vehicle1) { create(:vehicle, vin: 'VIN001', plate: 'ABC123') }
    let!(:vehicle2) { create(:vehicle, vin: 'VIN002', plate: 'DEF456') }
    let!(:vehicle3) { create(:vehicle, vin: 'VIN003', plate: 'GHI789') }

    before do
      # Vehicle 1: Total 10000
      create(:maintenance_service, vehicle: vehicle1, date: Date.new(2025, 6, 1), cost_cents: 6000)
      create(:maintenance_service, vehicle: vehicle1, date: Date.new(2025, 6, 2), cost_cents: 4000)

      # Vehicle 2: Total 15000
      create(:maintenance_service, vehicle: vehicle2, date: Date.new(2025, 6, 1), cost_cents: 8000)
      create(:maintenance_service, vehicle: vehicle2, date: Date.new(2025, 6, 2), cost_cents: 7000)

      # Vehicle 3: Total 5000
      create(:maintenance_service, vehicle: vehicle3, date: Date.new(2025, 6, 1), cost_cents: 5000)
    end

    it 'returns vehicles sorted by cost with limit' do
      result = service.top_vehicles_report(2)

      expect(result.length).to eq(2)
      expect(result[0][:vin]).to eq('VIN002')
      expect(result[0][:total_cost_cents]).to eq(15000)
      expect(result[0][:services_count]).to eq(2)
      expect(result[0][:average_cost_cents]).to eq(7500)

      expect(result[1][:vin]).to eq('VIN001')
      expect(result[1][:total_cost_cents]).to eq(10000)
      expect(result[1][:services_count]).to eq(2)
      expect(result[1][:average_cost_cents]).to eq(5000)
    end
  end

  describe '#vehicles_report' do
    let!(:vehicle) { create(:vehicle, vin: 'VIN123', status: 'active') }
    let!(:pending_service) { create(:maintenance_service, vehicle: vehicle, status: 'pending', date: Date.new(2025, 6, 1), cost_cents: 2000) }
    let!(:completed_service) { create(:maintenance_service, vehicle: vehicle, status: 'completed', date: Date.new(2025, 6, 2), cost_cents: 3000) }

    it 'returns vehicle details with service counts by status' do
      vehicle.reload

      result = service.vehicles_report

      expect(result.length).to eq(1)
      vehicle_data = result.first

      expect(vehicle_data[:vin]).to eq('VIN123')
      expect(vehicle_data[:status]).to eq('in_maintenance')
      expect(vehicle_data[:total_services]).to eq(2)
      expect(vehicle_data[:total_cost_cents]).to eq(5000)
      expect(vehicle_data[:pending_count]).to eq(1)
      expect(vehicle_data[:in_progress_count]).to eq(0)
      expect(vehicle_data[:completed_count]).to eq(1)
    end
  end

  describe '#services_report' do
    let!(:vehicle) { create(:vehicle, vin: 'VIN123', brand: 'Toyota', model: 'Corolla', year: 2020) }
    let!(:service1) do
      create(:maintenance_service,
        vehicle: vehicle,
        date: Date.new(2025, 6, 2),
        description: 'Oil change',
        status: 'completed',
        priority: 'low',
        cost_cents: 5000,
        completed_at: Date.new(2025, 6, 3)
      )
    end
    let!(:service2) do
      create(:maintenance_service,
        vehicle: vehicle,
        date: Date.new(2025, 6, 1),
        description: 'Brake inspection',
        status: 'pending',
        priority: 'high',
        cost_cents: 8000,
        completed_at: nil
      )
    end

    it 'returns services ordered by date desc with vehicle details' do
      result = service.services_report

      expect(result.length).to eq(2)

      expect(result[0][:date]).to eq(Date.new(2025, 6, 2))
      expect(result[0][:vehicle_vin]).to eq('VIN123')
      expect(result[0][:vehicle_brand]).to eq('Toyota')
      expect(result[0][:vehicle_model]).to eq('Corolla')
      expect(result[0][:vehicle_year]).to eq(2020)
      expect(result[0][:description]).to eq('Oil change')
      expect(result[0][:status]).to eq('completed')
      expect(result[0][:priority]).to eq('low')
      expect(result[0][:cost_cents]).to eq(5000)
      expect(result[0][:completed_at]).to eq(Date.new(2025, 6, 3))

      expect(result[1][:date]).to eq(Date.new(2025, 6, 1))
      expect(result[1][:completed_at]).to be_nil
    end
  end

  describe 'date filtering' do
    let!(:vehicle) { create(:vehicle) }
    let!(:in_range) { create(:maintenance_service, vehicle: vehicle, date: Date.new(2025, 6, 15)) }
    let!(:out_of_range_before) { create(:maintenance_service, vehicle: vehicle, date: Date.new(2024, 12, 31)) }

    it 'only includes services within date range' do
      result = service.services_report

      expect(result.length).to eq(1)
      expect(result[0][:date]).to eq(Date.new(2025, 6, 15))
    end

    it 'excludes services outside date range' do
      # Test with a smaller date range
      narrow_service = described_class.new(Date.new(2025, 6, 1), Date.new(2025, 6, 30))
      result = narrow_service.services_report

      expect(result.length).to eq(1)
      expect(result[0][:date]).to eq(Date.new(2025, 6, 15))
    end
  end
end