class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :name, :created_at, :updated_at

  def created_at
    object.created_at.iso8601 if object.created_at
  end

  def updated_at
    object.updated_at.iso8601 if object.updated_at
  end
end