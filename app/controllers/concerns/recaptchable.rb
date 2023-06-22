require "net/http"

# Recaptchable module is a mixin for working with the Google Recaptcha service API.
module Recaptchable
  extend ActiveSupport::Concern

  RECAPTCHA_SITEVERIFY_URL = "https://www.google.com/recaptcha/api/siteverify".freeze
  NET_HTTP_ERRORS = [
    Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
    Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError,
    Errno::ECONNREFUSED, IOError, OpenSSL::SSL::SSLError
  ]

  class ConfigurationError < StandardError
  end

  # Recaptcha siteverify API call
  # https://developers.google.com/recaptcha/docs/verify
  def recaptcha_valid?
    client_token = params["g-recaptcha-response"]
    remoteip = request.remote_ip

    unless Rails.application.credentials.dig(:recaptcha, :secret_key).present?
      raise Recaptchable::ConfigurationError, "missing Recaptcha secret key"
    end

    Rails.logger.debug { "RECAPTCHA TOKEN: #{client_token}; REMOTEIP: #{remoteip}" }
    uri = URI(RECAPTCHA_SITEVERIFY_URL)
    data = {
      secret: Rails.application.credentials.dig(:recaptcha, :secret_key),
      response: client_token
    }
    data[:remoteip] = remoteip if remoteip.present?
    response = Net::HTTP.post_form(uri, data) # application/x-www-form-urlencoded
    response_json = JSON.parse(response.body)
    Rails.logger.debug { "RECAPTCHA VALIDATION: #{response_json}" }

    if response_json["success"]
      Rails.logger.debug { "RECAPTCHA SUCCESS" }
      return true
    else
      Rails.logger.error { "RECAPTCHA ERROR" }
      (response_json["error-codes"] || []).each do |error_code|
        Rails.logger.error { error_code }
      end
      return false
    end
  rescue *NET_HTTP_ERRORS => e
    Rails.logger.error { e.message }
    Rails.logger.error { e.backtrace.join("\n") }
    false
  end
end
