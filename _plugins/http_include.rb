# Http include tag
#
# A Jekyll tag to include content from an http url
#
# {% http_include url %}
#
#
#
require 'net/http'
require 'uri'
require 'shellwords'

module Jekyll

  class HttpIncludeTag < Liquid::Tag

    def initialize(tag_name, markup, tokens)
      super
      params = Shellwords.shellwords markup

      @url = params[0]
      @url.gsub!('https://www.dropbox.com', 'https://dl.dropboxusercontent.com')
    end

    def render(context)

      uri = URI.parse(@url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri.request_uri)

      response = http.request(request)
      
      if (response.code != '200')
        raise "Error #{response.code} for url #{@url}"
      end

      response.body
    end
  end
end

Liquid::Template.register_tag('http_include', Jekyll::HttpIncludeTag)
