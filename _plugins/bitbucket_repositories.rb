# Bitbucket repositories tag
#
# A Jekyll tag to generate a list of bitbucket repositories
#
# {% bitbucket_repositories user_name %}
#
# If you want to show provate repositories you must create a config file at
# the root of your Jekyll site
#
# _bitbucket.yml
#  user: user_name
#  password: user_password
#
require 'json'
require 'net/http'
require 'uri'
require 'shellwords'

module Jekyll

  class BitbucketRepositoriesTag < Liquid::Tag

    CONFIGURATION_FILE = './_bitbucket.yml'

    def initialize(tag_name, markup, tokens)
      super
      params = Shellwords.shellwords markup

      @user = params[0]
      @config = {}
      if File.exists?(CONFIGURATION_FILE)
        @config = YAML.load(Erubis::Eruby.new(File.read(CONFIGURATION_FILE)).result)
      end
    end

    def render(context)

      uri = URI.parse("https://api.bitbucket.org/2.0/repositories/#{@user}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri.request_uri)
      if (@config and @config['user'] and @config['password'])
        request.basic_auth(@config['user'], @config['password'])
      end

      response = http.request(request)
      
      json = JSON.parse((response.code == '200') ? response.body : {})
      json['values'].sort!{|a,b| a['name'] <=> b['name']}
            
      output = "<div class='repo_blocks'>"

      # Data retrieved from bitbucket
      json['values'].each do |repo|
        output += genRepoBlock(repo['name'], repo['links']['html']['href'], prettyLanguageName(repo['language']), repo['description'])
      end

      # Data from data folder
      context.registers[:site].data['bitbucket'].each do |repo|
        output += genRepoBlock(repo['name'], repo['link'], repo['language'], repo['description'])
      end

      output += "</div>"
      output
    end
    
    def genRepoBlock(name, link, language, description)
      output = "<div class='repo_block'>"
      output +=   "<a class='repo_name' href='#{link}'>#{name}</a>"
      output +=   "<div class='repo_language'>#{language}</div>"
      output +=   "<div class='repo_descrition'>#{description}</div>"
      output += "</div>"
      output
    end
    
    def prettyLanguageName(name)
      l = {'c#' => 'C#', 'objective-c' => 'Objective-C'}
      name = l.has_key?(name) ? l[name] : name
    end
  end
end

Liquid::Template.register_tag('bitbucket_repositories', Jekyll::BitbucketRepositoriesTag)
