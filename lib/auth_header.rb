require 'base64'
require 'digest/md5'

class AuthHeader
  @@nonce_count = Hash.new(0)
  CNONCE = Digest::MD5.hexdigest("%x" % (Time.now.to_i + rand(65535)))

  def self.generate_basic_auth(username, password)
    'Basic ' + Base64::encode64("#{username}:#{password}").strip + '='
  end

  def self.generate_digest_auth(username, password, request_uri, method, authenticate_header, is_iis = false)
    authenticate_header =~ /^(\w+) (.*)/

    params = {}
    $2.gsub(/(\w+)=("[^"]*"|[^,]*)/) {
      params[$1] = $2.gsub(/^"/, '').gsub(/"$/, '')
    }

    @@nonce_count[params['nonce']] += 1

    a_1 = "#{username}:#{params['realm']}:#{password}"
    a_2 = "#{method}:#{request_uri}"
    request_digest = ''
    request_digest << Digest::MD5.hexdigest(a_1)
    request_digest << ':' << params['nonce']
    request_digest << ':' << ('%08x' % @@nonce_count[params['nonce']])
    request_digest << ':' << CNONCE
    request_digest << ':' << params['qop']
    request_digest << ':' << Digest::MD5.hexdigest(a_2)

    header = ''
    header << "Digest username=\"#{username}\", "
    if is_iis then
      header << "qop=\"#{params['qop']}\", "
    else
      header << "qop=#{params['qop']}, "
    end
    header << "uri=\"#{request_uri}\", "
    header << %w{ algorithm opaque nonce realm }.map { |field|
      next unless params[field]
      "#{field}=\"#{params[field]}\""
    }.compact.join(', ')

    header << ", nc=#{'%08x' % @@nonce_count[params['nonce']]}, "
    header << "cnonce=\"#{CNONCE}\", "
    header << "response=\"#{Digest::MD5.hexdigest(request_digest)}\""
    header
  end

  def self.generate(username, password, request_uri, method, authenticate_header, server)
    if authenticate_header =~ /Digest/i
      is_iis = ((server =~ /Microsoft-IIS/i) != nil)
      generate_digest_auth(username, password, request_uri, method, authenticate_header, is_iis)
    else
      generate_basic_auth(username, password)
    end
  end

end
