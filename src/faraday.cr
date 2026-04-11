require "http/client"
require "json"
require "uri"
require "base64"

require "./faraday/version"
require "./faraday/methods"
require "./faraday/error"
require "./faraday/encoders/flat_params_encoder"
require "./faraday/encoders/nested_params_encoder"
require "./faraday/utils"
require "./faraday/options/request_options"
require "./faraday/options/ssl_options"
require "./faraday/options/proxy_options"
require "./faraday/handler"

# Forward declare Response before Env (Env references Response, Response references Env)
module Faraday
  class Response; end
end

require "./faraday/options/env"
require "./faraday/options/connection_options"
require "./faraday/options"
require "./faraday/response"
require "./faraday/middleware_registry"
require "./faraday/adapter_registry"
require "./faraday/middleware"
require "./faraday/adapter"
require "./faraday/request"
require "./faraday/request/json"
require "./faraday/request/authorization"
require "./faraday/response/raise_error"
require "./faraday/response/json"
require "./faraday/rack_builder"
require "./faraday/connection"

module Faraday
  CONTENT_TYPE = "Content-Type"

  @@default_adapter : Symbol = :net_http
  @@default_adapter_options : Hash(Symbol, String) = {} of Symbol => String
  @@ignore_env_proxy : Bool = false
  @@default_connection : Connection? = nil
  @@default_connection_options : ConnectionOptions? = nil

  def self.default_adapter : Symbol
    @@default_adapter
  end

  def self.default_adapter=(adapter : Symbol)
    @@default_connection = nil
    @@default_adapter = adapter
  end

  def self.default_adapter_options : Hash(Symbol, String)
    @@default_adapter_options
  end

  def self.ignore_env_proxy? : Bool
    @@ignore_env_proxy
  end

  def self.ignore_env_proxy=(val : Bool)
    @@ignore_env_proxy = val
  end

  def self.new(url : String? = nil, options : ConnectionOptions = ConnectionOptions.new) : Connection
    Connection.new(url, options)
  end

  def self.new(url : String? = nil, options : ConnectionOptions = ConnectionOptions.new, &block : Connection ->) : Connection
    Connection.new(url, options, &block)
  end

  def self.default_connection : Connection
    @@default_connection ||= Connection.new(default_connection_options)
  end

  def self.default_connection_options : ConnectionOptions
    @@default_connection_options ||= ConnectionOptions.new
  end

  def self.default_connection_options=(options : ConnectionOptions)
    @@default_connection = nil
    @@default_connection_options = options
  end

  def self.get(url : String, params = nil, headers = nil) : Response
    default_connection.get(url, params, headers)
  end

  def self.post(url : String, body : String? = nil, headers = nil) : Response
    default_connection.post(url, body, headers)
  end

  def self.put(url : String, body : String? = nil, headers = nil) : Response
    default_connection.put(url, body, headers)
  end

  def self.delete(url : String, params = nil, headers = nil) : Response
    default_connection.delete(url, params, headers)
  end

  def self.head(url : String, params = nil, headers = nil) : Response
    default_connection.head(url, params, headers)
  end
end
