class AddInterviewerFeedbackFieldsToInterviews < ActiveRecord::Migration[7.1]
  def change
    add_column :interviews, :interviewer_email, :string
    add_column :interviews, :feedback_token, :string
    add_column :interviews, :feedback_submitted_at, :datetime
    add_index :interviews, :feedback_token, unique: true
  end
end
