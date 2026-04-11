struct HTTP::Headers
  # Parse a raw HTTP response header string (handles aggregated multi-response headers).
  # When multiple HTTP status lines are present (e.g. after a redirect), only the
  # headers from the last response block are retained.
  def parse(headers_string : String)
    current = {} of String => String
    headers_string.split("\r\n").each do |line|
      if line.starts_with?("HTTP/")
        current.clear
      elsif (idx = line.index(':'))
        key = line[0, idx].strip
        value = line[idx + 1..-1].strip
        current[key] = value unless key.empty?
      end
    end
    current.each { |k, v| self[k] = v }
  end

  # fetch(key) without default: raises KeyError if missing.
  def fetch(key : String) : String
    if (v = self[key]?)
      v
    else
      raise KeyError.new("Missing HTTP header: #{key}")
    end
  end

  # fetch(key, default) with any default type (not just String?).
  def fetch(key : String, default : V) forall V
    if (v = self[key]?)
      v
    else
      default
    end
  end

  # fetch(key) { |k| ... } block version.
  def fetch(key : String, &block : String -> U) forall U
    if (v = self[key]?)
      v
    else
      block.call(key)
    end
  end

  # Case-insensitive includes? for String keys (HTTP::Headers uses Key objects internally).
  def includes?(key : String) : Bool
    @hash.has_key?(wrap(key))
  end
end

module Faraday
  module Utils
    # Case-insensitive HTTP headers. Delegates to HTTP::Headers.
    alias Headers = HTTP::Headers
  end
end
