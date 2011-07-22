#!/usr/bin/env ruby

$: << File.expand_path(File.dirname(__FILE__))

require 'addons'
require 'webrick/httpproxy'
require 'yaml'
require 'auth_header'

class ProxyServer
  def initialize(options = {:logfile => $stdout})
    @options = options
    @authinfo = YAML.load(File.read(File.join(File.dirname(__FILE__), '..', 'config', 'authinfo.yml')))
    @authinfo.each {|element| element.symbolize_keys! }
    @server_auth_types = {}
  end

  def get_credentials_for_host(host)
    @authinfo.detect {|e| e[:host] == host }
  end

  def store_server_auth_type(res)
    uri = res.request_uri
    authenticate_header = res.header['www-authenticate']
    server = res.header['server']
    @server_auth_types[uri.host] = [authenticate_header, server]
  end

  def pre_handler(req, res)
    add_authorization_header(req, res)
  end

  def add_authorization_header(req, res)   # add authorization header for recognized hosts
    uri = req.request_uri
    if @server_auth_types[uri.host]
      authenticate_header, server = @server_auth_types[uri.host]
      credentials = get_credentials_for_host(uri.host)
      authorization_header = AuthHeader.generate(credentials[:username],
                                                 credentials[:password],
                                                 uri.path,
                                                 req.request_method,
                                                 authenticate_header,
                                                 server)
      req.header.merge!('Authorization' => [authorization_header])
      @server.logger.log(WEBrick::Log::INFO, "AuthProxy added Authorization header for recognized host \"#{uri.host}\"")
    end
  end

  def post_handler(req, res)
    # check for protected pages and attempt authentication where applicable
    if res.status == 401  # unauthorized
      credentials = get_credentials_for_host(res.request_uri.host)
      if credentials
        store_server_auth_type(res)
        add_authorization_header(req, res)
        @server.proxy_service(req, res)  # replay request
      end
    end
  end

  def start
    @server = WEBrick::HTTPProxyServer.new(
      :Port => '9090',
      :Logger => WEBrick::BasicLog.new(@options[:logfile]),
      :BindAddress => "0.0.0.0",
      :RequestCallback => method(:pre_handler),
      :ProxyContentHandler => method(:post_handler)
    )
    @server.start
  end

  def stop
    @server.shutdown
  end
end

if __FILE__ == $0
  ps = ProxyServer.new

  # check for unix-like platform and daemonize if so
  NIX = File.exist?('/dev/null') and !File.exist?('/NUL')
  %w[INT HUP].each { |signal| trap(signal) { ps.stop } } if NIX
  
  ps.start
end
