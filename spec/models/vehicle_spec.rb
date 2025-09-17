require 'rails_helper'

RSpec.describe Vehicle, type: :model do
  describe 'validations' do
    subject { build(:vehicle) }

    it { should validate_presence_of(:vin) }
    it { should validate_presence_of(:plate) }
    it { should validate_presence_of(:brand) }
    it { should validate_presence_of(:model) }
    it { should validate_presence_of(:year) }

    it { should validate_uniqueness_of(:vin).case_insensitive }
    it { should validate_uniqueness_of(:plate).case_insensitive }

    it { should validate_numericality_of(:year)
          .only_integer
          .is_greater_than_or_equal_to(1990)
          .is_less_than_or_equal_to(2050) }
  end

  describe 'enums' do
    it { should define_enum_for(:status)
          .with_values(active: 0, inactive: 1, in_maintenance: 2) }
  end

  describe 'callbacks' do
    describe '#normalize_attributes' do
      let(:vehicle) do
        build(:vehicle,
              vin: '  abc123def  ',
              plate: '  mex-001  ',
              brand: '  Toyota  ',
              model: '  Corolla  ')
      end

      before { vehicle.valid? }

      it 'normalizes vin to uppercase and strips spaces' do
        expect(vehicle.vin).to eq('ABC123DEF')
      end

      it 'normalizes plate to uppercase and strips spaces' do
        expect(vehicle.plate).to eq('MEX-001')
      end

      it 'strips spaces from brand' do
        expect(vehicle.brand).to eq('Toyota')
      end

      it 'strips spaces from model' do
        expect(vehicle.model).to eq('Corolla')
      end
    end
  end

  describe 'case-insensitive uniqueness' do
    context 'for vin' do
      let!(:existing_vehicle) { create(:vehicle, vin: 'ABC123') }

      it 'prevents duplicate with different case' do
        new_vehicle = build(:vehicle, vin: 'abc123')
        expect(new_vehicle).not_to be_valid
        expect(new_vehicle.errors[:vin]).to include('has already been taken')
      end

      it 'prevents duplicate with mixed case' do
        new_vehicle = build(:vehicle, vin: 'aBc123')
        expect(new_vehicle).not_to be_valid
      end
    end

    context 'for plate' do
      let!(:existing_vehicle) { create(:vehicle, plate: 'MEX-123') }

      it 'prevents duplicate with different case' do
        new_vehicle = build(:vehicle, plate: 'mex-123')
        expect(new_vehicle).not_to be_valid
        expect(new_vehicle.errors[:plate]).to include('has already been taken')
      end

      it 'prevents duplicate with mixed case' do
        new_vehicle = build(:vehicle, plate: 'MeX-123')
        expect(new_vehicle).not_to be_valid
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:vehicle)).to be_valid
    end

    it 'has valid traits' do
      expect(build(:vehicle, :inactive)).to be_valid
      expect(build(:vehicle, :in_maintenance)).to be_valid
      expect(build(:vehicle, :old)).to be_valid
      expect(build(:vehicle, :new)).to be_valid
    end
  end
end