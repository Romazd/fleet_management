require 'rails_helper'

RSpec.describe MaintenanceService, type: :model do
  describe 'associations' do
    it { should belong_to(:vehicle) }
  end

  describe 'validations' do
    subject { build(:maintenance_service) }

    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:date) }
    it { should validate_numericality_of(:cost_cents).is_greater_than_or_equal_to(0) }

    context 'date validations' do
      it 'does not allow future dates' do
        service = build(:maintenance_service, date: Date.tomorrow)
        expect(service).not_to be_valid
        expect(service.errors[:date]).to include("can't be in the future")
      end

      it 'allows current date' do
        service = build(:maintenance_service, date: Date.current)
        expect(service).to be_valid
      end

      it 'allows past dates' do
        service = build(:maintenance_service, date: 1.day.ago)
        expect(service).to be_valid
      end
    end

    context 'completed status validations' do
      it 'automatically sets completed_at when creating with completed status' do
        service = build(:maintenance_service, status: :completed, completed_at: nil)
        expect(service).to be_valid
        expect(service.completed_at).to be_present
      end

      it 'is valid when completed with completed_at' do
        service = build(:maintenance_service, status: :completed, completed_at: Time.current)
        expect(service).to be_valid
      end

      it 'prevents bypassing completed_at requirement' do
        service = create(:maintenance_service, :completed)
        service.completed_at = nil
        expect(service).not_to be_valid
        expect(service.errors[:status]).to include("can't be completed without completed_at timestamp")
      end
    end
  end

  describe 'enums' do
    it { should define_enum_for(:status)
          .with_values(pending: 0, in_progress: 1, completed: 2) }

    it { should define_enum_for(:priority)
          .with_values(low: 0, medium: 1, high: 2) }
  end

  describe 'callbacks' do
    describe '#set_completed_at_when_completed' do
      context 'when changing status to completed' do
        it 'automatically sets completed_at if not provided' do
          service = create(:maintenance_service, status: :pending)
          expect(service.completed_at).to be_nil

          service.update(status: :completed)
          expect(service.completed_at).to be_present
          expect(service.completed_at).to be_within(2.seconds).of(Time.current)
        end

        it 'does not override completed_at if already provided' do
          service = create(:maintenance_service, status: :pending)
          specific_time = 2.days.ago

          service.update(status: :completed, completed_at: specific_time)
          expect(service.completed_at).to be_within(1.second).of(specific_time)
        end
      end

      context 'when status is not changing to completed' do
        it 'does not set completed_at for pending status' do
          service = create(:maintenance_service, status: :pending)
          service.update(description: 'Updated description')
          expect(service.completed_at).to be_nil
        end

        it 'does not set completed_at for in_progress status' do
          service = create(:maintenance_service, status: :in_progress)
          expect(service.completed_at).to be_nil
        end
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:maintenance_service)).to be_valid
    end

    it 'has valid traits' do
      expect(build(:maintenance_service, :pending)).to be_valid
      expect(build(:maintenance_service, :in_progress)).to be_valid
      expect(build(:maintenance_service, :completed)).to be_valid
      expect(build(:maintenance_service, :low_priority)).to be_valid
      expect(build(:maintenance_service, :high_priority)).to be_valid
      expect(build(:maintenance_service, :expensive)).to be_valid
      expect(build(:maintenance_service, :cheap)).to be_valid
      expect(build(:maintenance_service, :past)).to be_valid
    end
  end

  describe 'cost_cents' do
    it 'accepts zero cost' do
      service = build(:maintenance_service, cost_cents: 0)
      expect(service).to be_valid
    end

    it 'accepts positive cost' do
      service = build(:maintenance_service, cost_cents: 10000)
      expect(service).to be_valid
    end

    it 'rejects negative cost' do
      service = build(:maintenance_service, cost_cents: -100)
      expect(service).not_to be_valid
      expect(service.errors[:cost_cents]).to include('must be greater than or equal to 0')
    end
  end
end