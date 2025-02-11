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

      ::OpenAI::Client.instance_eval do
        remove_const(:URI_BASE) if const_defined?(:URI_BASE)
        const_set(:URI_BASE, "https://openai.oldpan.fun/".freeze)
      end

      # 实例化 Client
      @client = ::OpenAI::Client.new(access_token: SiteSetting.chatbot_open_ai_token)
    end

    def get_response(prompt)

      model_name = SiteSetting.chatbot_open_ai_model_custom ? SiteSetting.chatbot_open_ai_model_custom_name : SiteSetting.chatbot_open_ai_model

      if ["gpt-3.5-turbo", "gpt-3.5-turbo-16k", "gpt-4", "gpt-4-32k"].include?(SiteSetting.chatbot_open_ai_model) ||
      (SiteSetting.chatbot_open_ai_model_custom == true && SiteSetting.chatbot_open_ai_model_custom_type == "chat")
        response = @client.chat(
          parameters: {
              model: model_name,
              messages: prompt,
              max_tokens: SiteSetting.chatbot_max_response_tokens,
              temperature: SiteSetting.chatbot_request_temperature / 100.0,
              top_p: SiteSetting.chatbot_request_top_p / 100.0,
              frequency_penalty: SiteSetting.chatbot_request_frequency_penalty / 100.0,
              presence_penalty: SiteSetting.chatbot_request_presence_penalty / 100.0
          })

        if response.parsed_response["error"]
          begin
            raise StandardError, response.parsed_response["error"]["message"]
          rescue => e
            Rails.logger.error ("OpenAIBot: There was a problem: #{e}")
            I18n.t('chatbot.errors.general')
          end
        else
          response.dig("choices", 0, "message", "content")
        end
      elsif (SiteSetting.chatbot_open_ai_model_custom == true && SiteSetting.chatbot_open_ai_model_custom_type == "completions") ||
        ["text-davinci-003", "text-davinci-002"].include?(SiteSetting.chatbot_open_ai_model)

        response = @client.completions(
          parameters: {
              model: SiteSetting.chatbot_open_ai_model,
              prompt: prompt,
              max_tokens: SiteSetting.chatbot_max_response_tokens,
              temperature: SiteSetting.chatbot_request_temperature / 100.0,
              top_p: SiteSetting.chatbot_request_top_p / 100.0,
              frequency_penalty: SiteSetting.chatbot_request_frequency_penalty / 100.0,
              presence_penalty: SiteSetting.chatbot_request_presence_penalty / 100.0
          })

        if response.parsed_response["error"]
          begin
            raise StandardError, response.parsed_response["error"]["message"]
          rescue => e
            Rails.logger.error ("OpenAIBot: There was a problem: #{e}")
            I18n.t('chatbot.errors.general')
          end
        else
          response["choices"][0]["text"]
        end
      end
    end

    def ask(opts)
      super(opts)
    end
  end
end
