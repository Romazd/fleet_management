require 'rails_helper'

RSpec.describe 'Api::V1::Vehicles Filters and Pagination', type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }

  describe 'GET /api/v1/vehicles with filters' do
    before do
      # Create test data
      create(:vehicle, brand: 'Toyota', model: 'Camry', year: 2020, status: 'active', vin: 'TOY001', plate: 'ABC-001')
      create(:vehicle, brand: 'Toyota', model: 'Corolla', year: 2021, status: 'active', vin: 'TOY002', plate: 'ABC-002')
      create(:vehicle, brand: 'Honda', model: 'Civic', year: 2020, status: 'inactive', vin: 'HON001', plate: 'XYZ-001')
      create(:vehicle, brand: 'Honda', model: 'Accord', year: 2022, status: 'in_maintenance', vin: 'HON002', plate: 'XYZ-002')
      create(:vehicle, brand: 'Ford', model: 'F150', year: 2019, status: 'active', vin: 'FOR001', plate: 'DEF-001')
    end

    context 'filtering by status' do
      it 'returns only active vehicles' do
        get '/api/v1/vehicles', params: { status: 'active' }, headers: headers

        json = JSON.parse(response.body)
        expect(json['vehicles'].size).to eq(3)
        expect(json['vehicles'].map { |v| v['status'] }.uniq).to eq(['active'])
      end

      it 'returns only inactive vehicles' do
        get '/api/v1/vehicles', params: { status: 'inactive' }, headers: headers

        json = JSON.parse(response.body)
        expect(json['vehicles'].size).to eq(1)
        expect(json['vehicles'].first['status']).to eq('inactive')
      end
    end

    context 'filtering by brand' do
      it 'returns only Toyota vehicles' do
        get '/api/v1/vehicles', params: { brand: 'Toyota' }, headers: headers

        json = JSON.parse(response.body)
        expect(json['vehicles'].size).to eq(2)
        expect(json['vehicles'].map { |v| v['brand'] }.uniq).to eq(['Toyota'])
      end
    end

    context 'filtering by year' do
      it 'returns vehicles from specific year' do
        get '/api/v1/vehicles', params: { year: 2020 }, headers: headers

        json = JSON.parse(response.body)
        expect(json['vehicles'].size).to eq(2)
        expect(json['vehicles'].map { |v| v['year'] }.uniq).to eq([2020])
      end
    end

    context 'filtering by year range' do
      it 'returns vehicles within year range' do
        get '/api/v1/vehicles', params: { year_from: 2020, year_to: 2021 }, headers: headers

        json = JSON.parse(response.body)
        expect(json['vehicles'].size).to eq(3)
        years = json['vehicles'].map { |v| v['year'] }.uniq.sort
        expect(years).to eq([2020, 2021])
      end
    end

    context 'searching' do
      it 'searches by VIN' do
        get '/api/v1/vehicles', params: { search: 'TOY' }, headers: headers

        json = JSON.parse(response.body)
        expect(json['vehicles'].size).to eq(2)
      end

      it 'searches by plate' do
        get '/api/v1/vehicles', params: { search: 'XYZ' }, headers: headers

        json = JSON.parse(response.body)
        expect(json['vehicles'].size).to eq(2)
      end

      it 'searches by model' do
        get '/api/v1/vehicles', params: { search: 'civic' }, headers: headers

        json = JSON.parse(response.body)
        expect(json['vehicles'].size).to eq(1)
        expect(json['vehicles'].first['model']).to eq('Civic')
      end

      it 'is case-insensitive' do
        get '/api/v1/vehicles', params: { search: 'TOYOTA' }, headers: headers

        json = JSON.parse(response.body)
        expect(json['vehicles'].size).to eq(2)
      end
    end

    context 'combining filters' do
      it 'combines status and brand filters' do
        get '/api/v1/vehicles', params: { status: 'active', brand: 'Toyota' }, headers: headers

        json = JSON.parse(response.body)
        expect(json['vehicles'].size).to eq(2)
        expect(json['vehicles'].map { |v| v['brand'] }.uniq).to eq(['Toyota'])
        expect(json['vehicles'].map { |v| v['status'] }.uniq).to eq(['active'])
      end

      it 'combines search with filters' do
        get '/api/v1/vehicles', params: { search: 'Honda', status: 'inactive' }, headers: headers

        json = JSON.parse(response.body)
        expect(json['vehicles'].size).to eq(1)
        expect(json['vehicles'].first['brand']).to eq('Honda')
        expect(json['vehicles'].first['status']).to eq('inactive')
      end
    end

    context 'sorting' do
      it 'sorts by year ascending' do
        get '/api/v1/vehicles', params: { sort_by: 'year', sort_direction: 'asc' }, headers: headers

        json = JSON.parse(response.body)
        years = json['vehicles'].map { |v| v['year'] }
        expect(years).to eq(years.sort)
      end

      it 'sorts by brand descending' do
        get '/api/v1/vehicles', params: { sort_by: 'brand', sort_direction: 'desc' }, headers: headers

        json = JSON.parse(response.body)
        brands = json['vehicles'].map { |v| v['brand'] }
        expect(brands).to eq(brands.sort.reverse)
      end

      it 'defaults to created_at desc when invalid sort column' do
        get '/api/v1/vehicles', params: { sort_by: 'invalid_column' }, headers: headers

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET /api/v1/vehicles with pagination' do
    before do
      create_list(:vehicle, 30)
    end

    it 'paginates results with default per_page' do
      get '/api/v1/vehicles', headers: headers

      json = JSON.parse(response.body)
      expect(json['vehicles'].size).to eq(20) # default per_page
      expect(json['meta']).to include(
        'current_page' => 1,
        'total_pages' => 2,
        'total_count' => 30,
        'items_per_page' => 20
      )
    end

    it 'respects custom per_page parameter' do
      get '/api/v1/vehicles', params: { per_page: 10 }, headers: headers

      json = JSON.parse(response.body)
      expect(json['vehicles'].size).to eq(10)
      expect(json['meta']['items_per_page']).to eq(10)
      expect(json['meta']['total_pages']).to eq(3)
    end

    it 'navigates to specific page' do
      get '/api/v1/vehicles', params: { page: 2, per_page: 10 }, headers: headers

      json = JSON.parse(response.body)
      expect(json['meta']['current_page']).to eq(2)
      expect(json['meta']['prev_page']).to eq(1)
      expect(json['meta']['next_page']).to eq(3)
    end

    it 'returns empty array for page beyond total' do
      get '/api/v1/vehicles', params: { page: 100 }, headers: headers

      json = JSON.parse(response.body)
      expect(json['vehicles']).to be_empty
      expect(json['meta']['current_page']).to eq(100)
    end

    context 'pagination with filters' do
      before do
        Vehicle.destroy_all
        create_list(:vehicle, 15, status: 'active')
        create_list(:vehicle, 10, status: 'inactive')
      end

      it 'paginates filtered results' do
        get '/api/v1/vehicles', params: { status: 'active', per_page: 10 }, headers: headers

        json = JSON.parse(response.body)
        expect(json['vehicles'].size).to eq(10)
        expect(json['meta']['total_count']).to eq(15)
        expect(json['meta']['total_pages']).to eq(2)
      end
    end
  end
end