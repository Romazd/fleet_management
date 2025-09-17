require 'rails_helper'
require 'csv'

RSpec.describe CsvGeneratorService do
  describe '.generate_summary_metrics_csv' do
    let(:data) do
      {
        period: { from: '2025-01-01', to: '2025-12-31' },
        total_orders: 10,
        total_vehicles: 5,
        total_cost_cents: 50000,
        average_cost_cents: 5000
      }
    end

    it 'generates CSV with correct headers and data' do
      csv = described_class.generate_summary_metrics_csv(data)
      rows = CSV.parse(csv)

      expect(rows[0]).to eq(['Fecha Desde', 'Fecha Hasta', 'Total Órdenes', 'Total Vehículos', 'Costo Total', 'Costo Promedio'])
      expect(rows[1]).to eq(['2025-01-01', '2025-12-31', '10', '5', '$500.00', '$50.00'])
    end
  end

  describe '.generate_status_csv' do
    let(:data) do
      [
        { status: 'pending', count: 5, percentage: 50.0, total_cost_cents: 10000, average_cost_cents: 2000 },
        { status: 'completed', count: 5, percentage: 50.0, total_cost_cents: 20000, average_cost_cents: 4000 }
      ]
    end

    it 'generates CSV with status breakdown' do
      csv = described_class.generate_status_csv(data)
      rows = CSV.parse(csv)

      expect(rows[0]).to eq(['Estado', 'Cantidad', 'Porcentaje', 'Costo Total', 'Costo Promedio'])
      expect(rows[1]).to eq(['Pendiente', '5', '50.0%', '$100.00', '$20.00'])
      expect(rows[2]).to eq(['Completado', '5', '50.0%', '$200.00', '$40.00'])
    end
  end

  describe '.generate_priority_csv' do
    let(:data) do
      [
        { priority: 'low', count: 3, percentage: 30.0, total_cost_cents: 3000, average_cost_cents: 1000 },
        { priority: 'high', count: 7, percentage: 70.0, total_cost_cents: 21000, average_cost_cents: 3000 }
      ]
    end

    it 'generates CSV with priority breakdown' do
      csv = described_class.generate_priority_csv(data)
      rows = CSV.parse(csv)

      expect(rows[0]).to eq(['Prioridad', 'Cantidad', 'Porcentaje', 'Costo Total', 'Costo Promedio'])
      expect(rows[1]).to eq(['Baja', '3', '30.0%', '$30.00', '$10.00'])
      expect(rows[2]).to eq(['Alta', '7', '70.0%', '$210.00', '$30.00'])
    end
  end

  describe '.generate_top_vehicles_csv' do
    let(:data) do
      [
        { vehicle_id: 1, vin: 'VIN001', plate: 'ABC123', brand: 'Toyota', model: 'Corolla', year: 2020, services_count: 5, total_cost_cents: 25000, average_cost_cents: 5000 },
        { vehicle_id: 2, vin: 'VIN002', plate: 'DEF456', brand: 'Honda', model: 'Civic', year: 2021, services_count: 3, total_cost_cents: 15000, average_cost_cents: 5000 }
      ]
    end

    it 'generates CSV with vehicle ranking' do
      csv = described_class.generate_top_vehicles_csv(data)
      rows = CSV.parse(csv)

      expect(rows[0]).to eq(['Ranking', 'VIN', 'Placa', 'Marca', 'Modelo', 'Año', 'Cantidad Servicios', 'Costo Total', 'Costo Promedio'])
      expect(rows[1]).to eq(['1', 'VIN001', 'ABC123', 'Toyota', 'Corolla', '2020', '5', '$250.00', '$50.00'])
      expect(rows[2]).to eq(['2', 'VIN002', 'DEF456', 'Honda', 'Civic', '2021', '3', '$150.00', '$50.00'])
    end
  end

  describe '.generate_vehicles_csv' do
    let(:data) do
      [
        {
          vin: 'VIN001',
          plate: 'ABC123',
          brand: 'Toyota',
          model: 'Corolla',
          year: 2020,
          status: 'active',
          total_services: 5,
          pending_count: 2,
          in_progress_count: 1,
          completed_count: 2,
          total_cost_cents: 10000
        }
      ]
    end

    it 'generates CSV with vehicle details' do
      csv = described_class.generate_vehicles_csv(data)
      rows = CSV.parse(csv)

      expect(rows[0]).to eq(['VIN', 'Placa', 'Marca', 'Modelo', 'Año', 'Estado', 'Total Servicios', 'Pendientes', 'En Progreso', 'Completados', 'Costo Total'])
      expect(rows[1]).to eq(['VIN001', 'ABC123', 'Toyota', 'Corolla', '2020', 'Activo', '5', '2', '1', '2', '$100.00'])
    end
  end

  describe '.generate_services_csv' do
    let(:data) do
      [
        {
          date: Date.new(2025, 6, 15),
          vehicle_vin: 'VIN001',
          vehicle_plate: 'ABC123',
          vehicle_brand: 'Toyota',
          vehicle_model: 'Corolla',
          vehicle_year: 2020,
          description: 'Oil change',
          status: 'completed',
          priority: 'low',
          cost_cents: 5000,
          completed_at: Date.new(2025, 6, 16)
        },
        {
          date: Date.new(2025, 6, 10),
          vehicle_vin: 'VIN002',
          vehicle_plate: 'DEF456',
          vehicle_brand: 'Honda',
          vehicle_model: 'Civic',
          vehicle_year: 2021,
          description: 'Brake inspection',
          status: 'pending',
          priority: 'high',
          cost_cents: 8000,
          completed_at: nil
        }
      ]
    end

    it 'generates CSV with service details' do
      csv = described_class.generate_services_csv(data)
      rows = CSV.parse(csv)

      expect(rows[0]).to eq(['Fecha', 'VIN', 'Placa', 'Marca', 'Modelo', 'Año', 'Descripción', 'Estado', 'Prioridad', 'Costo', 'Completado En'])
      expect(rows[1][0]).to eq('2025-06-15')
      expect(rows[1][1]).to eq('VIN001')
      expect(rows[1][6]).to eq('Oil change')
      expect(rows[1][7]).to eq('Completado')
      expect(rows[1][8]).to eq('Baja')
      expect(rows[1][9]).to eq('$50.00')
      expect(rows[1][10]).to eq('2025-06-16')

      expect(rows[2][0]).to eq('2025-06-10')
      expect(rows[2][1]).to eq('VIN002')
      expect(rows[2][7]).to eq('Pendiente')
      expect(rows[2][8]).to eq('Alta')
      expect(rows[2][10]).to eq('')
    end
  end

  describe 'helper methods' do
    describe '.format_currency' do
      it 'formats cents to currency string' do
        expect(described_class.send(:format_currency, 10000)).to eq('$100.00')
        expect(described_class.send(:format_currency, 5550)).to eq('$55.50')
        expect(described_class.send(:format_currency, 99)).to eq('$0.99')
      end
    end

    describe '.translate_status' do
      it 'translates status to Spanish' do
        expect(described_class.send(:translate_status, 'pending')).to eq('Pendiente')
        expect(described_class.send(:translate_status, 'in_progress')).to eq('En Progreso')
        expect(described_class.send(:translate_status, 'completed')).to eq('Completado')
      end
    end

    describe '.translate_priority' do
      it 'translates priority to Spanish' do
        expect(described_class.send(:translate_priority, 'low')).to eq('Baja')
        expect(described_class.send(:translate_priority, 'medium')).to eq('Media')
        expect(described_class.send(:translate_priority, 'high')).to eq('Alta')
      end
    end

    describe '.translate_vehicle_status' do
      it 'translates vehicle status to Spanish' do
        expect(described_class.send(:translate_vehicle_status, 'active')).to eq('Activo')
        expect(described_class.send(:translate_vehicle_status, 'inactive')).to eq('Inactivo')
        expect(described_class.send(:translate_vehicle_status, 'in_maintenance')).to eq('En Mantenimiento')
      end
    end
  end
end