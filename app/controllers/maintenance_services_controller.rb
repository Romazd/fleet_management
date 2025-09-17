class MaintenanceServicesController < ApplicationController
  include Pagy::Backend

  before_action :set_vehicle
  before_action :set_maintenance_service, only: [:edit, :update, :destroy]

  def index
    @pagy, @maintenance_services = pagy(@vehicle.maintenance_services.order(date: :desc), limit: params[:per_page] || 10)
  end

  def new
    @maintenance_service = @vehicle.maintenance_services.build
  end

  def create
    @maintenance_service = @vehicle.maintenance_services.build(maintenance_service_params)

    if @maintenance_service.save
      redirect_to vehicle_path(@vehicle), notice: I18n.t('maintenance_services.created')
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @maintenance_service.update(maintenance_service_params)
      redirect_to vehicle_path(@vehicle), notice: I18n.t('maintenance_services.updated')
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @maintenance_service.destroy
    redirect_to vehicle_path(@vehicle), notice: I18n.t('maintenance_services.destroyed')
  end

  private

  def set_vehicle
    @vehicle = Vehicle.find(params[:vehicle_id])
  end

  def set_maintenance_service
    @maintenance_service = @vehicle.maintenance_services.find(params[:id])
  end

  def maintenance_service_params
    params.require(:maintenance_service).permit(:description, :status, :date, :cost_cents, :priority, :completed_at)
  end
end