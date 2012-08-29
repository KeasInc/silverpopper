# Set of methods that are used by both XMLAPI and Transact API
module Silverpopper::Common

  # Dispatch an API call to the given url, with content headers
  # set appropriately.  Raise unless successful and return the
  # raw response body
  def send_request(markup, url, api_host)
    log "[silverpopper] Sending request: "
    log markup

    resp = HTTParty.post(url, :body => markup, :headers => {
      'Content-type' => 'text/xml;charset=UTF-8',
      'X-Intended-Host' => api_host + @pod.to_s
    })
    raise "Request Failed" unless resp.code == 200 || resp.code == 201

    log "[silverpopper] Got response: "
    log resp.body

    return resp.body
  end

  def log(msg)
    if debug?
      if defined?(Rails)
        Rails.logger.info(msg)
      else
        puts msg
      end
    end
  end
end
