module Faraday
  class ProxyOptions
    property uri : URI?
    property user : String?
    property password : String?

    def initialize; end

    def initialize(@uri : URI?, @user : String? = nil, @password : String? = nil); end

    def self.from(value : String) : ProxyOptions?
      return nil if value.empty?
      value = "http://#{value}" unless value.includes?("://")
      opts = new
      opts.uri = URI.parse(value)
      opts.user = opts.uri.try(&.user)
      opts.password = opts.uri.try(&.password)
      opts
    end

    def self.from(value : URI) : ProxyOptions
      opts = new
      opts.uri = value
      opts.user = value.user
      opts.password = value.password
      opts
    end

    def self.from(value : Hash) : ProxyOptions?
      return nil if value.empty?
      opts = new
      if (uri_val = value[:uri]? || value["uri"]?)
        opts.uri = uri_val.is_a?(URI) ? uri_val : URI.parse(uri_val.to_s)
      end
      opts.user = (value[:user]? || value["user"]?).try(&.to_s)
      opts.password = (value[:password]? || value["password"]?).try(&.to_s)
      opts
    end

    def self.from(value : Nil) : Nil
      nil
    end

    def scheme : String?
      @uri.try(&.scheme)
    end

    def host : String?
      @uri.try(&.host)
    end

    def port : Int32?
      @uri.try(&.port)
    end

    def path : String
      @uri.try(&.path) || ""
    end
  end
end
