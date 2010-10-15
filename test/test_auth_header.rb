require 'test/unit'
require 'auth_header'
require 'uri'

require 'rubygems'
require 'mocha'

class TestAuthHeader < Test::Unit::TestCase
  def setup
    url = URI.parse('http://www.anthonychaves.net/tests.xml')
    @request_uri = url.path
  end

  def self.scrub_nonce(nonce)
    # The chain gave our request an Authorization header with client-generated values and derivatives.
    # They should be scrubbed before comparing to the expected result because they change
    # on each invokation
    nonce.gsub!(/cnonce=\"\w+?\"/, "cnonce=\"scrubbed_cnonce\"")
    nonce.gsub!(/response=\"\w+?\"/, "response=\"scrubbed_response\"")
    nonce
  end

  def test_digest_auth_without_iis
    digest = %Q!Digest realm="www.anthonychaves.net", qop="auth", algorithm=MD5, nonce="NTI0NTEyMTYyNjo0ZTY2MjhlZWMyZmM1ZjA0M2Y1Njc1MGU0YTA2MWY5OQ==", opaque="9f455d4e71e8d46a6d3aaef8bf8b0d9e"!
    actual_authorization = TestAuthHeader.scrub_nonce(AuthHeader.generate_digest_auth('anthony', 'password', @request_uri, 'GET', digest))
    expected_authorization = %Q!Digest username="anthony", qop=auth, uri="/tests.xml", algorithm="MD5", opaque="9f455d4e71e8d46a6d3aaef8bf8b0d9e", nonce="NTI0NTEyMTYyNjo0ZTY2MjhlZWMyZmM1ZjA0M2Y1Njc1MGU0YTA2MWY5OQ==", realm="www.anthonychaves.net", nc=00000001, cnonce="scrubbed_cnonce", response="scrubbed_response"!
    assert_equal(expected_authorization, actual_authorization)
  end

  def test_digest_auth_with_iis
    digest = %Q!Digest realm="www.anthonychaves.net", qop="auth", algorithm=MD5, nonce="MTI0NTEyMTYyNjo0ZTY2MjhlZWMyZmM1ZjA0M2Y1Njc1MGU0YTA2MWY5OQ==", opaque="9f455d4e71e8d46a6d3aaef8bf8b0d9e"!
    actual_authorization = TestAuthHeader.scrub_nonce(AuthHeader.generate_digest_auth('anthony', 'password', @request_uri, 'GET', digest, true))
    expected_authorization = %Q!Digest username="anthony", qop="auth", uri="/tests.xml", algorithm="MD5", opaque="9f455d4e71e8d46a6d3aaef8bf8b0d9e", nonce="MTI0NTEyMTYyNjo0ZTY2MjhlZWMyZmM1ZjA0M2Y1Njc1MGU0YTA2MWY5OQ==", realm="www.anthonychaves.net", nc=00000001, cnonce="scrubbed_cnonce", response="scrubbed_response"!
    assert_equal(expected_authorization, actual_authorization)
  end

  def test_basic_auth
    actual_authorization_header = AuthHeader.generate_basic_auth('Aladdin', 'open sesame')
    expected_authorization_header = 'Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ=='
    assert_equal(expected_authorization_header, expected_authorization_header)
  end

  def test_basic_auth_gets_selected_when_appropriate
    authenticate_header = 'Basic'
    AuthHeader.expects(:generate_basic_auth).once
    AuthHeader.generate('user', 'pass', '/path.html', 'GET', 'Basic', 'Apache')
  end

  def test_digest_auth_without_iis_gets_selected_when_appropriate
    args = ['user', 'pass', '/path.html', 'GET', 'Digest']
    AuthHeader.expects(:generate_digest_auth).with(*(args + [false])).once
    AuthHeader.generate(*(args + ['Apache']))
  end

  def test_digest_auth_with_iis_gets_selected_when_appropriate
    args = ['user', 'pass', '/path.html', 'GET', 'Digest']
    AuthHeader.expects(:generate_digest_auth).with(*(args + [true])).once
    AuthHeader.generate(*(args + ['Microsoft-IIS']))
  end
end
