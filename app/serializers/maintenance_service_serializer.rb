class MaintenanceServiceSerializer < ActiveModel::Serializer
  attributes :id, :description, :status, :date, :cost_cents, :priority,
             :completed_at, :created_at, :updated_at, :vehicle_id

  belongs_to :vehicle, if: :include_vehicle?

  def date
    object.date.to_s if object.date
  end

  def completed_at
    object.completed_at.iso8601 if object.completed_at
  end

  def created_at
    object.created_at.iso8601 if object.created_at
  end

  def updated_at
    object.updated_at.iso8601 if object.updated_at
  end

  def include_vehicle?
    @instance_options[:include_vehicle] == true
  end
end