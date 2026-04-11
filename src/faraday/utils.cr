require "./encoders/flat_params_encoder"
require "./encoders/nested_params_encoder"
require "./utils/headers"
require "./utils/params_hash"

module Faraday
  module Utils
    extend self

    def build_query(params : Hash) : String
      FlatParamsEncoder.encode(params)
    end

    def build_nested_query(params : Hash) : String
      NestedParamsEncoder.encode(params)
    end

    @@default_space_encoding : String = "+"

    def default_space_encoding : String
      @@default_space_encoding
    end

    def default_space_encoding=(val : String)
      @@default_space_encoding = val
    end

    def escape(str) : String
      URI.encode_www_form(str.to_s)
    end

    def unescape(str) : String
      URI.decode_www_form(str.to_s)
    end

    def parse_query(query : String?) : Hash(String, String)
      FlatParamsEncoder.decode(query)
    end

    def parse_nested_query(query : String?) : Hash(String, String)
      NestedParamsEncoder.decode(query)
    end

    @@default_params_encoder = FlatParamsEncoder

    def default_params_encoder
      @@default_params_encoder
    end

    def default_params_encoder=(encoder)
      @@default_params_encoder = encoder
    end

    def basic_header_from(login : String, pass : String) : String
      value = Base64.strict_encode("#{login}:#{pass}")
      "Basic #{value}"
    end

    # Parse or pass-through a URI.
    def parse_uri(url : ::URI) : ::URI
      url
    end

    def parse_uri(url : String) : ::URI
      ::URI.parse(url)
    end

    def normalize_path(url : String) : String
      uri = ::URI.parse(url)
      path = uri.path.empty? ? "/" : uri.path
      path = "/#{path}" unless path.starts_with?("/")
      if (q = uri.query)
        "#{path}?#{sort_query_params(q)}"
      else
        path
      end
    end

    def sort_query_params(query : String) : String
      query.split("&").sort.join("&")
    end

    def deep_merge!(target : Hash, other : Hash) : Hash
      other.each do |key, value|
        if value.is_a?(Hash) && target[key]?.is_a?(Hash)
          target[key] = deep_merge(target[key].as(Hash), value)
        else
          target[key] = value
        end
      end
      target
    end

    def deep_merge(source : Hash, other : Hash) : Hash
      deep_merge!(source.dup, other)
    end
  end
end
