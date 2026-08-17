# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_08_14_113155) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "activity_logs", force: :cascade do |t|
    t.string "message", null: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_activity_logs_on_user_id"
  end

  create_table "calendar_integrations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "provider", null: false
    t.string "email"
    t.string "calendar_id"
    t.text "access_token"
    t.text "refresh_token"
    t.datetime "token_expires_at"
    t.string "sync_token"
    t.string "subscription_id"
    t.datetime "subscription_expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "provider"], name: "index_calendar_integrations_on_user_id_and_provider", unique: true
    t.index ["user_id"], name: "index_calendar_integrations_on_user_id"
  end

  create_table "candidate_status_histories", force: :cascade do |t|
    t.bigint "candidate_id", null: false
    t.string "status", null: false
    t.string "note"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_id"], name: "index_candidate_status_histories_on_candidate_id"
    t.index ["user_id"], name: "index_candidate_status_histories_on_user_id"
  end

  create_table "candidates", force: :cascade do |t|
    t.string "name", null: false
    t.string "email"
    t.string "phone"
    t.string "role"
    t.string "department"
    t.string "designation"
    t.string "skills_list"
    t.string "experience_years", default: "0"
    t.string "status", default: "New"
    t.integer "score", default: 0
    t.string "source"
    t.string "ctc_current"
    t.string "ctc_expected"
    t.string "ctc_unit", default: "LPA"
    t.string "notice_period"
    t.text "notes"
    t.date "hire_date"
    t.string "resume_filename"
    t.text "resume_text"
    t.bigint "job_id"
    t.bigint "recruiter_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.string "resume_file_key"
    t.string "referral_type"
    t.string "employee_name"
    t.string "employee_code"
    t.string "employee_company"
    t.string "other_referrals"
    t.index ["discarded_at"], name: "index_candidates_on_discarded_at"
    t.index ["job_id"], name: "index_candidates_on_job_id"
    t.index ["recruiter_id"], name: "index_candidates_on_recruiter_id"
  end

  create_table "email_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "candidate_id"
    t.string "recipient_email"
    t.string "subject"
    t.string "template_name"
    t.string "status", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "cc_email"
    t.text "body"
    t.string "error_message"
    t.index ["candidate_id"], name: "index_email_logs_on_candidate_id"
    t.index ["user_id"], name: "index_email_logs_on_user_id"
  end

  create_table "interviews", force: :cascade do |t|
    t.bigint "candidate_id", null: false
    t.string "round_name", null: false
    t.string "round_number"
    t.string "interviewer"
    t.datetime "scheduled_at"
    t.string "status", default: "Scheduled"
    t.string "outcome"
    t.text "feedback"
    t.integer "rating"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.string "interviewer_email"
    t.string "feedback_token"
    t.datetime "feedback_submitted_at"
    t.bigint "calendar_integration_id"
    t.string "calendar_provider"
    t.string "external_event_id"
    t.string "calendar_id"
    t.string "meeting_url"
    t.string "calendar_sync_status"
    t.index ["calendar_integration_id"], name: "index_interviews_on_calendar_integration_id"
    t.index ["calendar_provider", "external_event_id"], name: "index_interviews_on_calendar_provider_and_external_event_id", unique: true
    t.string "mode_of_interview"
    t.index ["candidate_id"], name: "index_interviews_on_candidate_id"
    t.index ["discarded_at"], name: "index_interviews_on_discarded_at"
    t.index ["feedback_token"], name: "index_interviews_on_feedback_token", unique: true
  end

  create_table "job_openings", force: :cascade do |t|
    t.bigint "job_id"
    t.integer "sequence_no"
    t.date "closed_date"
    t.date "onboarded_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_job_openings_on_job_id"
  end

  create_table "job_recruiters", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id", "user_id"], name: "index_job_recruiters_on_job_id_and_user_id", unique: true
    t.index ["job_id"], name: "index_job_recruiters_on_job_id"
    t.index ["user_id"], name: "index_job_recruiters_on_user_id"
  end

  create_table "job_status_histories", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "status", null: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_job_status_histories_on_job_id"
    t.index ["user_id"], name: "index_job_status_histories_on_user_id"
  end

  create_table "jobs", force: :cascade do |t|
    t.string "title", null: false
    t.string "company", default: "Spritle Software"
    t.string "department"
    t.string "hiring_manager"
    t.string "position_type", default: "New"
    t.string "replacing_employee"
    t.integer "openings", default: 1
    t.string "status", default: "Open"
    t.date "open_date"
    t.date "close_date"
    t.date "reopen_date"
    t.date "hire_date"
    t.text "description"
    t.string "skills_list"
    t.string "experience_years", default: "0"
    t.string "ctc_budget"
    t.string "naukri_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.string "job_type", default: "Full-Time"
    t.string "stipend"
    t.text "closing_notes"
    t.text "onhold_notes"
    t.string "interview_type"
    t.index ["discarded_at"], name: "index_jobs_on_discarded_at"
  end

  create_table "naukri_configurations", force: :cascade do |t|
    t.string "email", null: false
    t.string "company"
    t.boolean "connected", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_naukri_configurations_on_email"
  end

  create_table "naukri_jobs", force: :cascade do |t|
    t.bigint "naukri_configuration_id", null: false
    t.bigint "job_id"
    t.string "title", null: false
    t.string "location"
    t.string "external_id"
    t.date "posted_on"
    t.string "url"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_naukri_jobs_on_external_id"
    t.index ["job_id"], name: "index_naukri_jobs_on_job_id"
    t.index ["naukri_configuration_id"], name: "index_naukri_jobs_on_naukri_configuration_id"
    t.index ["title"], name: "index_naukri_jobs_on_title"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "role", default: "recruiter", null: false
    t.boolean "active", default: true, null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "activity_logs", "users"
  add_foreign_key "calendar_integrations", "users"
  add_foreign_key "candidate_status_histories", "candidates"
  add_foreign_key "candidate_status_histories", "users"
  add_foreign_key "candidates", "jobs"
  add_foreign_key "candidates", "users", column: "recruiter_id"
  add_foreign_key "interviews", "calendar_integrations"
  add_foreign_key "interviews", "candidates"
  add_foreign_key "job_openings", "jobs"
  add_foreign_key "job_recruiters", "jobs"
  add_foreign_key "job_recruiters", "users"
  add_foreign_key "job_status_histories", "jobs"
  add_foreign_key "job_status_histories", "users"
  add_foreign_key "naukri_jobs", "jobs"
  add_foreign_key "naukri_jobs", "naukri_configurations"
end
