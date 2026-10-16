class EmailJobMatcher
  STOP_WORDS = %w[
    a an the for to in at of and or with is are
    applying application job position role
  ].freeze

  def initialize(email_message)
    @email_message = email_message
  end

  def matched_jobs
    email_text = normalize(
      "#{@email_message.subject} #{@email_message.body}"
    )

    Job.where(status: "Open").select do |job|
      title_words = normalize(job.title)
                    .split
                    .reject { |word| STOP_WORDS.include?(word) }
                    .uniq

      next false if title_words.empty?

      matched_words = title_words.count do |word|
        email_text.match?(/\b#{Regexp.escape(word)}\b/)
      end

      matched_words.to_f / title_words.size >= 0.5
    end
  end

  private

  def normalize(text)
    text.to_s.downcase
        .gsub(/[^a-z0-9\s]/, " ")
        .squeeze(" ")
        .strip
  end
end
