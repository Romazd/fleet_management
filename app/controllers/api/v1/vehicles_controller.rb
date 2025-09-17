module Api
  module V1
    class VehiclesController < BaseController
      before_action :set_vehicle, only: [:show, :update, :destroy]

      # GET /api/v1/vehicles
      def index
        @vehicles = Vehicle.all
        render json: @vehicles
      end

      # GET /api/v1/vehicles/:id
      def show
        render json: @vehicle
      end

      # POST /api/v1/vehicles
      def create
        @vehicle = Vehicle.new(vehicle_params)

        if @vehicle.save
          render json: @vehicle, status: :created
        else
          render_validation_errors(@vehicle)
        end
      end

      # PUT/PATCH /api/v1/vehicles/:id
      def update
        if @vehicle.update(vehicle_params)
          render json: @vehicle
        else
          render_validation_errors(@vehicle)
        end
      end

      # DELETE /api/v1/vehicles/:id
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
    end
  end
end