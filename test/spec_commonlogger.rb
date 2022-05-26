require 'rack/commonlogger'
require 'rack/lint'
require 'rack/mock'

describe Rack::CommonLogger do
  obj = 'foobar'
  length = obj.size

  app = Rack::Lint.new lambda { |env|
    [200,
     {"Content-Type" => "text/html", "Content-Length" => length.to_s},
     [obj]]}
  app_without_length = Rack::Lint.new lambda { |env|
    [200,
     {"Content-Type" => "text/html"},
     []]}
  app_with_zero_length = Rack::Lint.new lambda { |env|
    [200,
     {"Content-Type" => "text/html", "Content-Length" => "0"},
     []]}
  app_without_lint = lambda { |env|
    [200,
     { "content-type" => "text/html", "content-length" => length.to_s },
     [obj]]}

  should "log to rack.errors by default" do
    res = Rack::MockRequest.new(Rack::CommonLogger.new(app)).get("/")

    res.errors.should.not.be.empty
    res.errors.should =~ /"GET \/ " 200 #{length} /
  end

  should "log to anything with +write+" do
    log = StringIO.new
    Rack::MockRequest.new(Rack::CommonLogger.new(app, log)).get("/")

    log.string.should =~ /"GET \/ " 200 #{length} /
  end

  should "log - content length if header is missing" do
    res = Rack::MockRequest.new(Rack::CommonLogger.new(app_without_length)).get("/")

    res.errors.should.not.be.empty
    res.errors.should =~ /"GET \/ " 200 - /
  end

  should "log - content length if header is zero" do
    res = Rack::MockRequest.new(Rack::CommonLogger.new(app_with_zero_length)).get("/")

    res.errors.should.not.be.empty
    res.errors.should =~ /"GET \/ " 200 - /
  end

  should "escape non printable characters except newline" do
    log = StringIO.new
    Rack::MockRequest.new(Rack::CommonLogger.new(app_without_lint, log)).request("GET\b\x10", "/hello")

    log.string.should.match(/GET\\x08\\x10 \/hello/)
  end

  def length
    123
  end

  def self.obj
    "hello world"
  end
end
