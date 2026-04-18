module Api
  module V1
    class MeController < Api::BaseController
      def show
        render json: {
          id:       current_resource_owner.id,
          email:    current_resource_owner.email,
          name:     current_resource_owner.name,
          image:    current_resource_owner.image,
          provider: current_resource_owner.provider
        }
      end
    end
  end
end
