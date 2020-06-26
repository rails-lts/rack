# frozen_string_literal: true

require 'rack/session/abstract/id'

describe Rack::Session::Abstract::PersistedSecure::SecureSessionHash do

  def store
    Class.new do
      def load_session(req)
        [Rack::Session::SessionId.new("id"), { :foo => :bar, :baz => :qux }]
      end
      def session_exists?(req)
        true
      end
    end
  end

  def hash
    hash = Rack::Session::Abstract::PersistedSecure::SecureSessionHash.new(store.new, nil)

    # This is a bug fixed in 4fd82e8563a860029edc531500bd509720479e82 in newer versions of Rack
    hash.send(:load_for_read!)

    hash
  end

  it "returns keys" do
    hash.keys.sort.should.equal ["baz", "foo"]
  end

  it "returns values" do
    hash.values.sort_by(&:to_s).should.equal [:bar, :qux]
  end

  describe "#[]" do
    it "returns value for a matching key" do
      hash[:foo].should.equal :bar
    end

    it "returns value for a 'session_id' key" do
      hash['session_id'].should.equal "id"
    end

    it "returns nil value for missing 'session_id' key" do
      store_instance = store.new
      def store_instance.load_session(req)
        [nil, {}]
      end
      other_hash = Rack::Session::Abstract::PersistedSecure::SecureSessionHash.new(store_instance, nil)
      other_hash['session_id'].should.equal nil
    end
  end

  describe "#fetch" do
    it "returns value for a matching key" do
      hash.fetch(:foo).should.equal :bar
    end

    # This is only available in newer versions of Rack
    #
    # it "works with a default value" do
    #   hash.fetch(:unknown, :default).should.equal :default
    # end
    #
    # it "works with a block" do
    #   hash.fetch(:unkown) { :default }.should.equal :default
    # end
    #
    # it "it raises when fetching unknown keys without defaults" do
    #   lambda { hash.fetch(:unknown) }.should.raise(KeyError)
    # end
  end

  describe "#stringify_keys" do
    it "returns hash or session hash with keys stringified" do
      hash.send(:stringify_keys, hash).should.equal({ "foo" => :bar, "baz" => :qux })
    end
  end
end
