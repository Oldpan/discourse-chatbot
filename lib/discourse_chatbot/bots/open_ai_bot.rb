# frozen_string_literal: true
require "openai"

module ::DiscourseChatbot

  # class CustomOpenAIClient < ::OpenAI::Client
  #   NEW_URI_BASE = "https://openai.oldpan.fun/".freeze
  #   private_class_method def self.uri(path:)
  #     NEW_URI_BASE + OpenAI.configuration.api_version + path
  #   end
  # end

  class OpenAIBot < Bot

    def initialize

      # TODO add this in when support added via PR after "ruby-openai", '3.3.0'
      # OpenAI.configure do |config|
      #   config.request_timeout = 25
      # end

      # TODO consider other bot parameters
      # , params: {key: chatbot_api_key, cb_settings_tweak1: wackiness, cb_settings_tweak2: talkativeness, cb_settings_tweak3: attentiveness})

      ::OpenAI::Client.instance_eval do
        remove_const(:URI_BASE) if const_defined?(:URI_BASE)
        const_set(:URI_BASE, "https://openai.oldpan.fun/".freeze)
      end

      # 实例化 Client
      @client = ::OpenAI::Client.new(access_token: SiteSetting.chatbot_open_ai_token)

      # @client = CustomOpenAIClient.new(access_token: SiteSetting.chatbot_open_ai_token)

    end

    def get_response(prompt)
      if SiteSetting.chatbot_open_ai_model == "gpt-3.5-turbo"
        response = @client.chat(
          parameters: {
              model: "gpt-3.5-turbo",
              messages: prompt,
              temperature: SiteSetting.chatbot_request_temperature / 100.0
          })

          final_text = response.dig("choices", 0, "message", "content")
      else
        response = @client.completions(
          parameters: {
              model: SiteSetting.chatbot_open_ai_model,
              prompt: prompt,
              max_tokens: SiteSetting.chatbot_max_response_tokens,
              temperature: SiteSetting.chatbot_request_temperature / 100.0
          })

        if response.parsed_response["error"]
          raise StandardError, response.parsed_response["error"]["message"]
        end

        final_text = response["choices"][0]["text"]
      end
    end

    def ask(opts)
      super(opts)
    end
  end
end
