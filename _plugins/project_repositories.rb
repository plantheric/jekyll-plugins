# Project repositories tag
#
# A Jekyll tag to generate a list of projects 
# The project list come from both bitbucket and github repositories
# and from a list in the data folder
#
# {% project_repositories user_name %}
#
# where the user_name is the user name in github and/or bitbucket
#
#
require 'json'
require 'net/http'
require 'uri'
require 'shellwords'

module Jekyll

  class ProjectRepositoriesTag < Liquid::Tag

    def initialize(tag_name, markup, tokens)
      super
      params = Shellwords.shellwords markup

      @user = params[0]
    end

    def render(context)
      site = context.registers[:site]
      config = site.config

      repos = []
      sort_order = (config['project_repositories'] && config['project_repositories']['sort_order']) || []

      # Get from Bitbucket
      bitbucket_repos = get_repos("https://api.bitbucket.org/2.0/repositories/#{@user}")
      unless bitbucket_repos.empty?
        bitbucket_repos['values'].each do |repo|
          repos << { name: repo['name'], link: repo['links']['html']['href'], 
                      language: pretty_language_name(repo['language']), description: repo['description'] }
        end
      end

      # Get from Github
      github_repos = get_repos("https://api.github.com/users/#{@user}/repos")
      github_repos.each do |repo|
        repos << { name: repo['name'], link: repo['html_url'], 
                    language: pretty_language_name(repo['language']), description: repo['description'] }
      end

      # Get from _data/bitbucket.yml
      site.data['project_repositories'].each do |repo|
        repos << { name: repo['name'], link: repo['link'], language: repo['language'], description: repo['description'] }
      end

      repos.uniq! { |repo| repo[:name] }
      repos.sort_by! { |repo| sort_order.index(repo[:name]) || 99 }

      # Build html
      output = "<div class='repo_blocks'>"

      repos.each do |repo|
        output += generate_repo_block(repo)
      end

      output += "</div>"
      output
    end
    
    def generate_repo_block(repo)
      description = repo[:description].gsub(/\n/, "<br>\n")
      output = "<div class='repo_block'>"
      output +=   "<a class='repo_name' href='#{repo[:link]}'>#{repo[:name]}</a>"
      output +=   "<div class='repo_language'>#{repo[:language]}</div>"
      output +=   "<div class='repo_descrition'>#{description}</div>"
      output += "</div>"
      output
    end
    
    def pretty_language_name(name)
      lang = {'c#' => 'C#', 'objective-c' => 'Objective-C', 'ruby' => 'Ruby'}
      name = lang[name] || name
    end
    
    def get_repos(url)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)
      
      JSON.parse((response.code == '200') ? response.body : '[]')
    end 
  end
end

Liquid::Template.register_tag('project_repositories', Jekyll::ProjectRepositoriesTag)
