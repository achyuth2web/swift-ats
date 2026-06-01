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

ActiveRecord::Schema[7.1].define(version: 2024_01_01_000008) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "activity_logs", force: :cascade do |t|
    t.string "message", null: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_activity_logs_on_user_id"
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
    t.integer "experience_years", default: 0
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
    t.index ["job_id"], name: "index_candidates_on_job_id"
    t.index ["recruiter_id"], name: "index_candidates_on_recruiter_id"
  end

  create_table "interviews", force: :cascade do |t|
    t.bigint "candidate_id", null: false
    t.string "round_name", null: false
    t.integer "round_number", default: 1
    t.string "interviewer"
    t.datetime "scheduled_at"
    t.string "status", default: "Scheduled"
    t.string "outcome"
    t.text "feedback"
    t.integer "rating"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_id"], name: "index_interviews_on_candidate_id"
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
    t.integer "experience_years", default: 0
    t.string "ctc_budget"
    t.string "naukri_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "activity_logs", "users"
  add_foreign_key "candidate_status_histories", "candidates"
  add_foreign_key "candidate_status_histories", "users"
  add_foreign_key "candidates", "jobs"
  add_foreign_key "candidates", "users", column: "recruiter_id"
  add_foreign_key "interviews", "candidates"
  add_foreign_key "job_recruiters", "jobs"
  add_foreign_key "job_recruiters", "users"
  add_foreign_key "job_status_histories", "jobs"
  add_foreign_key "job_status_histories", "users"
end
