module Faraday
  module Utils
    # A Hash with stringified keys that handles URL query parameters.
    class ParamsHash < Hash(String, String)
      def []=(key, value : String)
        super(key.to_s, value)
      end

      def [](key) : String
        super(key.to_s)
      end

      def []?(key) : String?
        super(key.to_s)
      end

      def delete(key)
        super(key.to_s)
      end

      def has_key?(key) : Bool
        super(key.to_s)
      end

      def update(other : Hash)
        other.each { |k, v| self[k.to_s] = v.to_s }
        self
      end

      def merge(other : Hash) : ParamsHash
        dup.update(other)
      end

      def replace(other : Hash)
        clear
        update(other)
      end

      def dup : ParamsHash
        copy = ParamsHash.new
        each { |k, v| copy[k] = v }
        copy
      end

      def merge_query(query : String?, encoder = nil) : ParamsHash
        return self unless query && !query.empty?
        decoded = (encoder || FlatParamsEncoder).decode(query)
        update(decoded)
        self
      end

      def to_query(encoder = nil) : String
        (encoder || FlatParamsEncoder).encode(self)
      end
    end
  end
end
