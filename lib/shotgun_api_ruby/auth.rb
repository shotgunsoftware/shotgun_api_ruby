# frozen_string_literal: true

module ShotgunApiRuby
  class Auth < Faraday::Middleware
    module Validator
      def self.valid?(auth)
        (auth[:client_id] && auth[:client_secret]) ||
          (auth[:password] && auth[:username]) || auth[:session_token] ||
          auth[:refresh_token]
      end
    end

    def initialize(app = nil, options = {})
      raise 'missing auth' unless options[:auth]
      raise 'missing site_url' unless options[:site_url]
      raise 'Auth not valid' unless Validator.valid?(options[:auth])

      super(app)

      @site_url = options[:site_url]
      @client_id = options[:auth][:client_id]
      @client_secret = options[:auth][:client_secret]
      @username = options[:auth][:username]
      @password = options[:auth][:password]
      @session_token = options[:auth][:session_token]
      @refresh_token = options[:auth][:refresh_token]
    end

    attr_reader :client_id,
                :client_secret,
                :site_url,
                :username,
                :password,
                :session_token,
                :refresh_token

    def auth_type
      @auth_type ||=
        begin
          if client_id
            'client_credentials'
          elsif username
            'password'
          elsif session_token
            'session_token'
          elsif refresh_token
            'refresh_token'
          end
        end
    end

    def call(request_env)
      request_env[:request_headers].merge!(std_headers)

      @app.call(request_env)
    end

    private

    def auth_params
      @auth_params ||=
        begin
          case auth_type
          when 'client_credentials'
            "client_id=#{client_id}&client_secret=#{
              client_secret
            }&grant_type=client_credentials"
          when 'password'
            "username=#{username}&password=#{password}&grant_type=password"
          when 'session_token'
            "session_token=#{session_token}&grant_type=session_token"
          when 'refresh_token'
            "refresh_token=#{refresh_token}&grant_type=refresh_token"
          else
            raise 'Not a valid/implemented auth type'
          end
        end
    end

    def auth_url
      @auth_url ||= "#{site_url}/auth/access_token?#{auth_params}"
    end

    def access_token
      ((@access_token && Time.now < @token_expiry) || sign_in) && @access_token
    end

    def sign_in
      resp =
        Faraday.post(auth_url) do |req|
          req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
          req.headers['Accept'] = 'application/json'
        end
      resp_body = JSON.parse(resp.body)

      raise "Can't login: #{resp_body['errors']}" if resp.status >= 300

      @access_token = resp_body['access_token']
      @token_expiry = Time.now + resp_body['expires_in']
      @refresh_token = resp_body['refresh_token']
    end

    def std_headers
      {
        'Accept' => 'application/json',
        'Authorization' => "Bearer #{access_token}",
      }
    end
  end
end
