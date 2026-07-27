module RubyAPI
  module Plugins
    class Cache < Plugin
      option :store, {}
      option :default_ttl, 3600

      def self.store
        options[:store]
      end

      def self.get(key)
        entry = store[key]
        return nil unless entry
        return nil if Time.now > entry[:expires_at]
        entry[:value]
      end

      def self.set(key, value, ttl: nil)
        ttl ||= options[:default_ttl]
        store[key] = {
          value: value,
          expires_at: Time.now + ttl
        }
      end

      def self.delete(key)
        store.delete(key)
      end

      def self.clear
        store.clear
      end

      def self.on_load(app)
        app.before do |ctx|
          ctx.set(:cache, self)
        end
      end
    end
  end
end
