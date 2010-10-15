require 'rubygems'
require 'test/unit'
require 'mocha'
require 'proxy'
require 'uri'

class TestProxy < Test::Unit::TestCase
  def setup
    @expected_credentials = {
      :host => 'my.server.com',
      :username => 'arthur',
      :password => 'gwenevere'
    }
  end

  def test_correct_login_credentials_are_found
    YAML.expects(:load).once.returns([@expected_credentials])
    proxy = ProxyServer.new(:logfile => '/dev/null')
    returned_credentials = proxy.get_credentials_for_host('my.server.com')
    assert_equal(returned_credentials, @expected_credentials)
  end

  def test_incorrect_login_credentials_are_not_found
    YAML.expects(:load).once.returns([@expected_credentials])
    proxy = ProxyServer.new(:logfile => '/dev/null')
    returned_credentials = proxy.get_credentials_for_host('another.server.com')
    assert_nil(returned_credentials)
  end
end
