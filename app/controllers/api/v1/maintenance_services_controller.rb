module Api
  module V1
    class MaintenanceServicesController < BaseController
      before_action :set_vehicle, only: [:index, :create]
      before_action :set_maintenance_service, only: [:update]

      def index
        @services = @vehicle.maintenance_services.order(date: :desc)
        render json: @services, each_serializer: MaintenanceServiceSerializer
      end

      def create
        @service = @vehicle.maintenance_services.build(maintenance_service_params)

        if @service.save
          render json: @service, serializer: MaintenanceServiceSerializer, status: :created
        else
          render_validation_errors(@service)
        end
      end

      def update
        if @service.update(maintenance_service_params)
          render json: @service, serializer: MaintenanceServiceSerializer
        else
          render_validation_errors(@service)
        end
      end

      private

      def set_vehicle
        @vehicle = Vehicle.find(params[:vehicle_id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          error: {
            code: 'NOT_FOUND',
            message: 'Vehicle not found'
          }
        }, status: :not_found
      end

      def set_maintenance_service
        @service = MaintenanceService.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          error: {
            code: 'NOT_FOUND',
            message: 'Maintenance service not found'
          }
        }, status: :not_found
      end

      def maintenance_service_params
        params.require(:maintenance_service).permit(:description, :status, :date, :cost_cents, :priority, :completed_at)
      end

      def render_validation_errors(service)
        render json: {
          error: {
            code: 'VALIDATION_ERROR',
            message: 'Validation failed',
            details: service.errors.full_messages
          }
        }, status: :unprocessable_content
      end
    end
  end
end