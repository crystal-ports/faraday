module Faraday
  # Request represents an outgoing HTTP request being built.
  class Request
    property http_method : Symbol
    property path : String
    property params : Utils::ParamsHash
    property headers : HTTP::Headers
    property body : JSON::Any | String | Nil
    property options : RequestOptions

    def initialize(@http_method : Symbol = :get)
      @path = ""
      @params = Utils::ParamsHash.new
      @headers = HTTP::Headers.new
      @options = RequestOptions.new
    end

    def self.create(method : Symbol) : Request
      req = new(method)
      yield req
      req
    end

    def url(path : String, extra_params : Hash? = nil)
      anchor_index = path.index('#')
      path = path[0, anchor_index] if anchor_index

      query : String? = nil
      if (q_idx = path.index('?'))
        query = path[q_idx + 1..]
        path = path[0, q_idx]
      end

      @path = path
      @params.merge_query(query) if query
      @params.update(extra_params) if extra_params
    end

    def [](key : String) : String
      @headers[key]
    end

    def []=(key : String, value : String)
      @headers[key] = value
    end
  end
end

require "./request/url_encoded"
