module Api
  module V1
    class VehiclesController < BaseController
      include Pagy::Backend

      before_action :set_vehicle, only: [:show, :update, :destroy]

      def index
        @vehicles = filter_vehicles
        @pagy, @vehicles = pagy(@vehicles, limit: params[:per_page] || 20)

        render json: {
          vehicles: ActiveModelSerializers::SerializableResource.new(
            @vehicles,
            each_serializer: VehicleSerializer
          ),
          meta: pagy_metadata(@pagy)
        }
      end

      def show
        render json: @vehicle, serializer: VehicleSerializer, include_maintenance_services: true
      end

      def create
        @vehicle = Vehicle.new(vehicle_params)

        if @vehicle.save
          render json: @vehicle, serializer: VehicleSerializer, status: :created
        else
          render_validation_errors(@vehicle)
        end
      end

      def update
        if @vehicle.update(vehicle_params)
          render json: @vehicle, serializer: VehicleSerializer
        else
          render_validation_errors(@vehicle)
        end
      end

      def destroy
        @vehicle.destroy
        head :no_content
      end

      private

      def set_vehicle
        @vehicle = Vehicle.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          error: {
            code: 'NOT_FOUND',
            message: 'Vehicle not found'
          }
        }, status: :not_found
      end

      def vehicle_params
        params.require(:vehicle).permit(:vin, :plate, :brand, :model, :year, :status)
      end

      def render_validation_errors(vehicle)
        render json: {
          error: {
            code: 'VALIDATION_ERROR',
            message: 'Validation failed',
            details: vehicle.errors.full_messages
          }
        }, status: :unprocessable_content
      end

      def filter_vehicles
        vehicles = Vehicle.includes(:maintenance_services).all
        vehicles = vehicles.by_status(params[:status])
        vehicles = vehicles.by_brand(params[:brand])
        vehicles = vehicles.by_year(params[:year])
        vehicles = vehicles.by_year_range(params[:year_from], params[:year_to])
        vehicles = vehicles.search(params[:search])
        vehicles = vehicles.ordered(params[:sort_by], params[:sort_direction])
        vehicles
      end

      def pagy_metadata(pagy)
        {
          current_page: pagy.page,
          next_page: pagy.next,
          prev_page: pagy.prev,
          total_pages: pagy.pages,
          total_count: pagy.count,
          items_per_page: pagy.limit
        }
      end
    end
  end
end