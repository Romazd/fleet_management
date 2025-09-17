class VehicleSerializer < ActiveModel::Serializer
  attributes :id, :vin, :plate, :brand, :model, :year, :status, :created_at, :updated_at

  has_many :maintenance_services, if: :include_maintenance_services?

  def created_at
    object.created_at.iso8601 if object.created_at
  end

  def updated_at
    object.updated_at.iso8601 if object.updated_at
  end

  def include_maintenance_services?
    @instance_options[:include_maintenance_services] == true
  end
end