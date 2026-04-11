module Faraday
  module FlatParamsEncoder
    def self.encode(params : Hash) : String
      return "" if params.empty?
      params.flat_map do |key, value|
        if value.is_a?(Array)
          value.map { |v| "#{URI.encode_www_form(key.to_s)}=#{URI.encode_www_form(v.to_s)}" }
        else
          ["#{URI.encode_www_form(key.to_s)}=#{URI.encode_www_form(value.to_s)}"]
        end
      end.join("&")
    end

    def self.decode(query : String?) : Hash(String, String)
      result = {} of String => String
      return result unless query && !query.empty?
      query.split(/[&;]/).each do |part|
        next if part.empty?
        idx = part.index('=')
        if idx
          key = URI.decode_www_form(part[0, idx])
          val = URI.decode_www_form(part[idx + 1..])
        else
          key = URI.decode_www_form(part)
          val = ""
        end
        result[key] = val
      end
      result
    end
  end
end
