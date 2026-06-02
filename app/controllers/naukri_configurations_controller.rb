# app/controllers/naukri_configurations_controller.rb

class NaukriConfigurationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @configuration =
      NaukriConfiguration.first_or_initialize

    @naukri_jobs = @configuration.naukri_jobs
    @jobs = Job.all
  end

  def create
    @configuration =
      NaukriConfiguration.first_or_initialize

    if @configuration.update(configuration_params)
      redirect_to naukri_configurations_path,
                  notice: "Configuration saved"
    else
      render :index
    end
  end

  private

  def configuration_params
    params.require(:naukri_configuration)
          .permit(
            :email,
            :company,
            :connected
          )
  end
end