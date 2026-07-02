Rails.application.routes.draw do
  devise_for :users, controllers: { sessions: "users/sessions" }

  authenticated :user do
    root to: "dashboard#index", as: :authenticated_root
  end
  root to: redirect("/users/sign_in")

  get  "/dashboard",              to: "dashboard#index",          as: :dashboard
  resources :jobs do
    member { patch :update_status }
  end
  resources :candidates do
    member { patch :update_status }
    collection do
      post :import
      get :export
    end
  end
  resources :interviews
  get  "/pipeline",               to: "pipeline#index",           as: :pipeline
  get  "/reports",                to: "reports#index",            as: :reports
  get  "/upload",                 to: "upload#index",             as: :upload
  post "/upload/parse",           to: "upload#parse",             as: :upload_parse
  post "/upload/save",            to: "upload#create",            as: :upload_save
  get  "/jd-match",               to: "jd_match#index",           as: :jd_match
  post "/jd-match/match",         to: "jd_match#match",           as: :jd_match_match
  get  "/interview-gen",          to: "interview_gen#index",      as: :interview_gen
  post "/interview-gen/generate", to: "interview_gen#generate",   as: :interview_gen_generate
  resources :users do
    member { patch :toggle_active }
  end
  get  "/settings",               to: "settings#index",           as: :settings

  resources :naukri_configurations, only: [:index, :create]

  resources :naukri_jobs do
    collection do
      post :import_csv
    end
  end

  get "email_hub", to: "email_hub#index"
  post "email_hub/send_email", to: "email_hub#send_email", as: :send_email_hubs
  delete "email_hub/clear_log", to: "email_hub#clear_log"

  get "/not_found", to: "errors#not_found"
  get "templates/candidate_import_template", to: "templates#candidate_import_template", as: :candidate_import_template

  match "*path",
      to: "errors#not_found",
      via: :all
end
