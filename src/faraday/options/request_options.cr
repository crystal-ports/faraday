module Faraday
  class RequestOptions
    property params_encoder : Nil
    property proxy : ProxyOptions?
    property timeout : Int32?
    property open_timeout : Int32?
    property read_timeout : Int32?
    property write_timeout : Int32?
    property boundary : String?
    property context : Hash(Symbol, String)?
    property on_data : (String, Int32, Env ->)?

    def initialize; end

    def stream_response? : Bool
      !@on_data.nil?
    end

    def dup : RequestOptions
      copy = RequestOptions.new
      copy.params_encoder = @params_encoder
      copy.proxy = @proxy
      copy.timeout = @timeout
      copy.open_timeout = @open_timeout
      copy.read_timeout = @read_timeout
      copy.write_timeout = @write_timeout
      copy.boundary = @boundary
      copy.context = @context
      copy.on_data = @on_data
      copy
    end
  end
end
