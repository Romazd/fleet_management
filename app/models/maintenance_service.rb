class MaintenanceService < ApplicationRecord
  # Associations
  belongs_to :vehicle

  # Enums
  enum status: {
    pending: 0,
    in_progress: 1,
    completed: 2
  }

  enum priority: {
    low: 0,
    medium: 1,
    high: 2
  }

  # Validations
  validates :description, presence: true
  validates :date, presence: true
  validates :cost_cents, numericality: { greater_than_or_equal_to: 0 }

  # Custom validations
  validate :date_cannot_be_in_the_future
  validate :completed_status_requires_completed_at, unless: :setting_completed_at?

  # Callbacks
  before_validation :set_completed_at_when_completed, if: :status_changing_to_completed?

  private

  def date_cannot_be_in_the_future
    if date.present? && date > Date.current
      errors.add(:date, "can't be in the future")
    end
  end

  def completed_status_requires_completed_at
    if completed? && completed_at.blank?
      errors.add(:status, "can't be completed without completed_at timestamp")
    end
  end

  def set_completed_at_when_completed
    self.completed_at = Time.current if completed_at.blank?
  end

  def status_changing_to_completed?
    status_changed? && completed?
  end

  def setting_completed_at?
    status_changed? && completed? && completed_at.blank?
  end
end