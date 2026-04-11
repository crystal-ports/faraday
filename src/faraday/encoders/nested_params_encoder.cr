module Faraday
  # NestedParamsEncoder supports nested hash params like Rails-style `foo[bar]=baz`.
  module NestedParamsEncoder
    def self.encode(params : Hash) : String
      FlatParamsEncoder.encode(params)
    end

    def self.decode(query : String?) : Hash(String, String)
      result = {} of String => String
      return result unless query && !query.empty?
      query.split(/[&;]/).each do |part|
        next if part.empty?
        idx = part.index('=')
        key, val = if idx
          {URI.decode_www_form(part[0, idx]), URI.decode_www_form(part[idx + 1..])}
        else
          {URI.decode_www_form(part), ""}
        end
        if (bracket_idx = key.index('['))
          outer_key = key[0, bracket_idx]
          inner = key[bracket_idx + 1..]
          inner = inner[0..-2] if inner.ends_with?(']')
          result[outer_key] = inner.empty? ? val : "#{inner}=#{val}"
        else
          result[key] = val
        end
      end
      result
    end
  end
end
