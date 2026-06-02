# app/controllers/naukri_jobs_controller.rb

class NaukriJobsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_naukri_job,
                only: [:edit, :update, :destroy]

  def new
    @naukri_job = NaukriJob.new

    render partial: "form",
           locals: { naukri_job: @naukri_job }
  end

  def create
    config = NaukriConfiguration.first

    @naukri_job =
      config.naukri_jobs.build(job_params)

    if @naukri_job.save
      redirect_to naukri_configurations_path,
                  notice: "Job added"
    else
      render :new
    end
  end

  def edit
    @naukri_job = NaukriJob.find(params[:id])

    render partial: "form",
           locals: { naukri_job: @naukri_job }
  end

  def update
    if @naukri_job.update(job_params)
      redirect_to naukri_configurations_path,
                  notice: "Job updated"
    else
      render :edit
    end
  end

  def destroy
    @naukri_job.destroy

    redirect_to naukri_configurations_path,
                notice: "Job removed"
  end

	require "csv"

	def import_csv
		file = params[:file]
		job_id = params[:job_id]

		imported = 0

		CSV.foreach(
				file.path,
				headers: true
		) do |row|

				Candidate.create!(
				name: row["Name"],
				email: row["Email"],
				phone: row["Phone"],
				experience: row["Experience"],
				source: "Naukri",
				status: "New",
				job_id: job_id
				)

				imported += 1
		end

		redirect_to naukri_configurations_path,
								notice: "#{imported} candidates imported"
	end

  private

  def set_naukri_job
    @naukri_job = NaukriJob.find(params[:id])
  end

  def job_params
    params.require(:naukri_job)
          .permit(
            :title,
            :location,
            :external_id,
            :posted_on,
            :url,
            :notes,
            :job_id
          )
  end
end