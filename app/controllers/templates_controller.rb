class TemplatesController < ApplicationController
  def candidate_import_template
    file_path = Rails.root.join("public", "templates", "candidate_import_template.xlsx")

    if File.exist?(file_path)
      send_file file_path,
                filename: "candidate_import_template.xlsx",
                type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                disposition: "attachment"
    else
      render plain: "Template not found", status: :not_found
    end
  end
end