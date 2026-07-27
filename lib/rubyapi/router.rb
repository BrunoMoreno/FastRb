module RubyAPI
  class Router
    attr_reader :routes, :current_prefix

    def initialize
      @routes = []
      @trie = TrieNode.new
      @current_prefix = ""
    end

    def add_route(method, path, **opts, &block)
      full_path = @current_prefix + path
      pattern = compile_pattern(full_path)
      param_names = extract_param_names(full_path)

      route = {
        method: method,
        path: full_path,
        pattern: pattern,
        param_names: param_names,
        block: block,
        params: opts[:params] || {},
        body: opts[:body]
      }

      @routes << route
      @trie.insert(full_path, route)
      route
    end

    def push_prefix(prefix)
      @current_prefix = @current_prefix + prefix
    end

    def pop_prefix(prefix)
      @current_prefix = @current_prefix[0...-prefix.length]
    end

    def find(method, path)
      route = @trie.search(path)
      return nil unless route
      return nil unless route[:method].to_s == method.to_s
      route
    end

    private

    def compile_pattern(path)
      segments = path.split("/")
      pattern_parts = segments.map do |seg|
        if seg.start_with?(":")
          "([^/]+)"
        elsif seg == "*"
          "(.+)"
        else
          Regexp.escape(seg)
        end
      end
      /\A#{pattern_parts.join("/")}\z/
    end

    def extract_param_names(path)
      path.split("/").select { |s| s.start_with?(":") }.map { |s| s[1..].to_sym }
    end
  end

  class TrieNode
    attr_accessor :children, :route

    def initialize
      @children = {}
      @route = nil
    end

    def insert(path, route)
      segments = path.split("/").reject(&:empty?)
      node = self
      segments.each do |seg|
        child_key = seg.start_with?(":") ? :__param__ : seg
        node.children[child_key] ||= TrieNode.new
        node = node.children[child_key]
      end
      node.route = route
    end

    def search(path)
      segments = path.split("/").reject(&:empty?)
      node = self
      segments.each do |seg|
        child = node.children[seg] || node.children[:__param__]
        return nil unless child
        node = child
      end
      node.route
    end
  end
end
