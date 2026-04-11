module Faraday
  class ConnectionOptions
    property request : RequestOptions
    property proxy : ProxyOptions?
    property ssl : SSLOptions
    property builder : RackBuilder?
    property url : String?
    property params : Hash(String, String)?
    property headers : Hash(String, String)?

    def initialize
      @request = RequestOptions.new
      @ssl = SSLOptions.new
    end

    def dup : ConnectionOptions
      copy = ConnectionOptions.new
      copy.request = @request.dup
      copy.proxy = @proxy
      copy.ssl = @ssl.dup
      copy.builder = @builder
      copy.url = @url
      copy.params = @params.dup
      copy.headers = @headers.dup
      copy
    end
  end
end
