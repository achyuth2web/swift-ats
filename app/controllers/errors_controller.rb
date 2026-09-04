class ErrorsController < ApplicationController
  layout "devise"
  skip_before_action :authenticate_user!, raise: false

  def not_found
    respond_to do |format|
      format.html { render status: :not_found }
      format.json { render json: { error: "Not Found" }, status: :not_found }
    end
  end
end