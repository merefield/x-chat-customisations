# frozen_string_literal: true

module ChatCustomisations
  module TenantReplayOneboxPreprocessor
    URL_PATTERN = %r{https?://[^\s<]+} if !const_defined?(:URL_PATTERN)
    TRAILING_PUNCTUATION_PATTERN = /[)\].,!?;:]+\z/ if !const_defined?(
      :TRAILING_PUNCTUATION_PATTERN,
    )

    def self.call(message)
      return message if !message.is_a?(String)
      return message if tenant_replay_url_regex.blank?

      in_fenced_code_block = false

      message
        .lines
        .map do |line|
          if line.match?(/\A\s*(```|~~~)/)
            in_fenced_code_block = !in_fenced_code_block
            next line
          end

          next line if in_fenced_code_block || skip_line?(line)

          isolate_tenant_replay_urls(line)
        end
        .join
    end

    def self.tenant_replay_url_regex
      return if !defined?(Onebox::Engine::PodplayPingpodReplayOnebox::REGEX)

      Onebox::Engine::PodplayPingpodReplayOnebox::REGEX
    end
    private_class_method :tenant_replay_url_regex

    def self.isolate_tenant_replay_urls(line)
      line.gsub(URL_PATTERN) do |matched_url|
        url_start = Regexp.last_match.begin(0)
        url = matched_url.sub(TRAILING_PUNCTUATION_PATTERN, "")
        trailing_punctuation = matched_url.delete_prefix(url)

        next matched_url if !tenant_replay_url_regex.match?(url)
        next matched_url if markdown_link_destination?(line, url_start)

        "\n\n#{url}\n\n#{trailing_punctuation}"
      end
    end
    private_class_method :isolate_tenant_replay_urls

    def self.skip_line?(line)
      stripped_line = line.strip

      stripped_line.start_with?("<") || stripped_line.start_with?("[") ||
        stripped_line.include?("`")
    end
    private_class_method :skip_line?

    def self.markdown_link_destination?(line, url_start)
      return false if url_start.zero?
      return false if line[url_start - 1] != "("

      opening_bracket_index = line.rindex("[", url_start)
      closing_bracket_index = line.rindex("]", url_start)
      opening_bracket_index.present? && closing_bracket_index.present? &&
        opening_bracket_index < closing_bracket_index
    end
    private_class_method :markdown_link_destination?
  end
end
