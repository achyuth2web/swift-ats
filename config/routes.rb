Rails.application.routes.draw do
  devise_for :users, controllers: { sessions: "users/sessions" }

  authenticated :user do
    root to: "dashboard#index", as: :authenticated_root
  end
  root to: redirect("/users/sign_in")

  # ── Sidekiq Web UI ────────────────────────────────────────────────────────
  require "sidekiq/web"
  require "sidekiq-scheduler/web"
  Sidekiq::Web.use(Rack::Auth::Basic) do |u, p|
    u == ENV.fetch("SIDEKIQ_USERNAME","admin") &&
    p == ENV.fetch("SIDEKIQ_PASSWORD","sidekiq_password")
  end
  mount Sidekiq::Web => "/sidekiq"

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
  get   "feedback/:token", to: "interview_feedbacks#show",   as: :interview_feedback
  patch "feedback/:token", to: "interview_feedbacks#update", as: :update_interview_feedback
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
  get  "/calendar_integrations",  to: "calendar_integrations#index",  as: :calendar_integrations
  get  "/calendar",  to: "calendars#index",  as: :calendar
  get  "/email_integrations",  to: "email_integrations#index",  as: :email_integrations

  resources :naukri_configurations, only: [:index, :create]

  resources :naukri_jobs do
    collection do
      post :import_csv
    end
  end

  resources :applications, only: [:show] do
    patch :assign, on: :member
    patch :update_status, on: :member
  end

  get "email_hub", to: "email_hub#index"
  post "email_hub/send_email", to: "email_hub#send_email", as: :send_email_hubs
  delete "email_hub/clear_log", to: "email_hub#clear_log", as: :email_hub_clear_log
  post "email_hub/confirm_application", to: "email_hub#confirm_application", as: :confirm_email_hub_application
  post "email_hub/reject_application", to: "email_hub#reject_application", as: :reject_email_hub_application
  post "email_hub/reply", to: "email_hub#reply", as: :email_hub_reply

  get "/auth/google_calendar/callback", to: "google_calendar#callback"
  delete "/google_calendar/disconnect", to: "google_calendar#disconnect", as: :disconnect_google_calendar

  get "/auth/google_gmail/callback", to: "gmail#callback"
  delete "/gmail/disconnect", to: "gmail#disconnect", as: :disconnect_gmail

  get "/auth/failure", to: "omniauth#failure"

  post "/webhooks/google_calendar", to: "google_calendar_webhooks#receive", as: :google_calendar_webhook

  get "/auth/microsoft_graph/callback", to: "outlook_calendar#callback"
  get "/auth/failure", to: "outlook_calendar#failure"
  delete "/outlook_calendar/disconnect", to: "outlook_calendar#disconnect", as: :disconnect_outlook_calendar

  get "/not_found", to: "errors#not_found"
  get "templates/candidate_import_template", to: "templates#candidate_import_template", as: :candidate_import_template

  match "*path",
      to: "errors#not_found",
      via: :all
end
