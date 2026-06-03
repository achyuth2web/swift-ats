# app/controllers/errors_controller.rb

class ErrorsController < ApplicationController
  layout "devise"
  skip_before_action :authenticate_user!, raise: false

  def not_found
    render status: :not_found
  end
end