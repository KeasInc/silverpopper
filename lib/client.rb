# The silverpop client to initialize and make XMLAPI or Transact API requests
# through.  Handles authentication, and many silverpop commands.
class Silverpopper::Client
  include Silverpopper::TransactApi
  include Silverpopper::XmlApi
  include Silverpopper::Ftp
  include Silverpopper::Common

  # user_name to log into silverpop with
  attr_reader :user_name, :ftp_host, :proxy_url, :https, :api_url, :transact_url

  # pod to use, this should be a number and is used to build the url
  # to make api calls to
  attr_reader :pod

  # Initialize a Silverpopper Client
  #
  # expects a hash with string keys: 'user_name', 'password', 'pod'.
  # pod argument is defaulted to 5
  def initialize(options={})
    @https = options['https']
    protocol = @https ? 'https' : 'http'
    @user_name    = options['user_name']
    @password     = options['password']
    @pod          = options['pod'] || 5
    @api_url      = options.has_key?('api_url')      ? options['api_url']       : "#{protocol}://api#{@pod}.silverpop.com"
    @proxy_url    = options['proxy_url']             ? URI.parse(options['proxy_url']) : nil
    @ftp_host     = options.has_key?('ftp_host')     ? options['ftp_host']     : "transfer#{@pod}.silverpop.com"
    @transact_url = options.has_key?('transact_url') ? options['transact_url'] : "#{protocol}://transact#{@pod}.silverpop.com"
    @debug        = !!options['debug']
  end

  def debug?
    @debug
  end

  protected
  # password to use to log into silverpop with
  attr_reader :password

end
