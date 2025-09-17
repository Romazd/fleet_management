class VehiclesController < ApplicationController
  before_action :set_vehicle, only: [:show, :edit, :update, :destroy]

  def index
    @vehicles = Vehicle.ordered
  end

  def show
    @maintenance_services = @vehicle.maintenance_services.order(date: :desc)
  end

  def new
    @vehicle = Vehicle.new
  end

  def edit
  end

  def create
    @vehicle = Vehicle.new(vehicle_params)

    if @vehicle.save
      redirect_to @vehicle, notice: I18n.t('vehicles.created')
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @vehicle.update(vehicle_params)
      redirect_to @vehicle, notice: I18n.t('vehicles.updated')
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @vehicle.destroy
    redirect_to vehicles_url, notice: I18n.t('vehicles.destroyed')
  end

  private

  def set_vehicle
    @vehicle = Vehicle.find(params[:id])
  end

  def vehicle_params
    params.require(:vehicle).permit(:vin, :plate, :brand, :model, :year, :status)
  end
end