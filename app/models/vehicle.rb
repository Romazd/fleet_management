class Vehicle < ApplicationRecord
  # Associations
  has_many :maintenance_services, dependent: :destroy

  # Enums
  enum status: {
    active: 0,
    inactive: 1,
    in_maintenance: 2
  }

  # Scopes
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_brand, ->(brand) { where(brand: brand) if brand.present? }
  scope :by_year, ->(year) { where(year: year) if year.present? }
  scope :by_year_range, ->(from, to) { where(year: from..to) if from.present? && to.present? }
  scope :search, lambda { |query|
    if query.present?
      where('lower(vin) LIKE :q OR lower(plate) LIKE :q OR lower(brand) LIKE :q OR lower(model) LIKE :q',
            q: "%#{query.downcase}%")
    end
  }
  scope :ordered, ->(column = 'created_at', direction = 'desc') {
    column = %w[vin plate brand model year status created_at updated_at].include?(column.to_s) ? column : 'created_at'
    direction = %w[asc desc].include?(direction.to_s) ? direction : 'desc'
    order("#{column} #{direction}")
  }

  # Validations
  validates :vin, presence: true, uniqueness: { case_sensitive: false }
  validates :plate, presence: true, uniqueness: { case_sensitive: false }
  validates :brand, presence: true
  validates :model, presence: true
  validates :year, presence: true,
                   numericality: {
                     only_integer: true,
                     greater_than_or_equal_to: 1990,
                     less_than_or_equal_to: 2050
                   }

  # Callbacks
  before_validation :normalize_attributes

  def update_maintenance_status!
    has_pending_maintenance = maintenance_services.where(status: [:pending, :in_progress]).exists?

    if has_pending_maintenance && !in_maintenance?
      update!(status: :in_maintenance)
    elsif !has_pending_maintenance && in_maintenance?
      update!(status: :active)
    end
  end

  private

  def normalize_attributes
    self.vin = vin&.strip&.upcase
    self.plate = plate&.strip&.upcase
    self.brand = brand&.strip
    self.model = model&.strip
  end
end