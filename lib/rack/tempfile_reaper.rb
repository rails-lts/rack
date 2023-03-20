require 'rack/body_proxy'

module Rack

  # Middleware tracks and cleans Tempfiles created throughout a request (i.e. Rack::Multipart)
  # Ideas/strategy based on posts by Eric Wong and Charles Oliver Nutter
  # https://groups.google.com/forum/#!searchin/rack-devel/temp/rack-devel/brK8eh-MByw/sw61oJJCGRMJ
  class TempfileReaper
    def initialize(app)
      @app = app
    end

    def call(env)
      env['rack.tempfiles'] ||= []

      begin
        status, headers, body = @app.call(env)
      rescue Exception
        close_tempfiles(env)
        raise
      end

      body_proxy = BodyProxy.new(body) do
        close_tempfiles(env)
      end
      [status, headers, body_proxy]
    end

    private

    def close_tempfiles(env)
      env['rack.tempfiles'].each(&:close!) unless env['rack.tempfiles'].nil?
    end
  end
end
