require "../../src/stremio-addon-devkit/api/multi_block_handler"
require "./spec_helper"


Spectator.describe Stremio::Addon::DevKit::Api::ManifestHandler do
	alias Api = Stremio::Addon::DevKit::Api
  alias Conf = Stremio::Addon::DevKit::Conf

  let(manifest) { Conf::Manifest.build(
        id: "com.stremio.addon.example",
        name: "DemoAddon",
        description: "An example stremio addon",
        version: "0.0.1") do |conf|
          conf.catalogs << Conf::Catalog.new(
              type: Conf::ContentType::Movie,
              id: "movie4u",
              name: "Movies for you")
        end }

  let(catalog_request) {
      m = manifest
      Api::CatalogRequest.new(m, m.catalogs[0]) 
  }
  let(env) {
      request = HTTP::Request.new("GET", "/")
      response_text = IO::Memory.new(<<-EOL)
HTTP/1.1 200 OK
Date: Mon, 27 Jul 2009 12:28:53 GMT
Server: Apache/2.2.14 (Win32)
Last-Modified: Wed, 22 Jul 2009 19:15:56 GMT
Content-Length: 0
Content-Type: text/html
Connection: Closed
EOL
      response = HTTP::Server::Response.new(response_text)
      HTTP::Server::Context.new(request, response)
  }
  subject { Api::MultiBlockHandler.new }

  describe "#initialize" do
    it "will not raise an error" do
      expect do
        subject
      end.to_not raise_error
    end

    it "will fail of callbacks are not defined" do
      expect(subject.set_catalog_callback?).to eq(false)
      expect do
        subject.set_catalog_callback.call(env, catalog_request)
      end.to raise_error TypeCastError
    end
  end

  describe "#catalog" do
    it "is possible to replace the callback with a block" do
      accessed = false
      s = subject
      s.set_catalog_callback do
        accessed = true
      end
      expect(s.set_catalog_callback?).to eq(true)
      expect do
        s.set_catalog_callback.call(env, catalog_request)
      end.to_not raise_error
      expect(accessed).to eq(true)
    end

    it "is possible to replace the callback with a proc" do
      accessed = false
      proc = ->( env: HTTP::Server::Context, addon: Api::CatalogRequest) { accessed = true }

      s = subject
      s.set_catalog_callback &proc

      expect(s.set_catalog_callback?).to eq(true)
      expect do
        s.set_catalog_callback.call(env, catalog_request)
      end.to_not raise_error
      expect(accessed).to eq(true)
    end
  end
end
