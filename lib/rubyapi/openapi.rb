require "json"

module RubyAPI
  class OpenAPI
    def initialize(app)
      @app = app
    end

    def generate
      {
        openapi: "3.0.0",
        info: {
          title: "RubyAPI App",
          version: "0.1.0"
        },
        paths: generate_paths
      }
    end

    def to_json
      JSON.pretty_generate(generate)
    end

    private

    def generate_paths
      paths = {}
      @app.router.routes.each do |route|
        path = route[:path]
        method = route[:method].downcase
        paths[path] ||= {}
        paths[path][method] = {
          summary: "#{method.upcase} #{path}",
          parameters: route[:param_names].map do |name|
            {
              name: name,
              in: "path",
              required: true,
              schema: { type: "string" }
            }
          end,
          responses: {
            "200" => { description: "Success" }
          }
        }
      end
      paths
    end
  end
end
