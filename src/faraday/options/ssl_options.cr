module Faraday
  class SSLOptions
    property verify : Bool?
    property verify_hostname : Bool?
    property ca_file : String?
    property ca_path : String?
    property client_cert : String?
    property client_key : String?
    property verify_depth : Int32?

    def initialize; end

    def verify? : Bool
      @verify != false
    end

    def disable? : Bool
      !verify?
    end

    def verify_hostname? : Bool
      @verify_hostname != false
    end

    def dup : SSLOptions
      copy = SSLOptions.new
      copy.verify = @verify
      copy.verify_hostname = @verify_hostname
      copy.ca_file = @ca_file
      copy.ca_path = @ca_path
      copy.client_cert = @client_cert
      copy.client_key = @client_key
      copy.verify_depth = @verify_depth
      copy
    end
  end
end
