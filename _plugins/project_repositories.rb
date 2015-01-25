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
      @format = params[1] || "Full"
      @maximum_listed = params[2] || 99
    end

    def render(context)
      @site = context.registers[:site]
      config = @site.config

      repos = []
      sort_order = (config['project_repositories'] && config['project_repositories']['sort_order']) || []
      exclude = (config['project_repositories'] && config['project_repositories']['exclude']) || []

      # Get from Bitbucket
      bitbucket_repos = get_repos("https://api.bitbucket.org/2.0/repositories/#{@user}")
      unless bitbucket_repos.empty?
        bitbucket_repos['values'].each do |repo|
          link = repo['links']['html']['href']
          description = get_summary(link, repo['scm']) || repo['description']
          repos << { name: repo['name'], link: link, language: pretty_language_name(repo['language']), description: description }
        end
      end

      # Get from Github
      github_repos = get_repos("https://api.github.com/users/#{@user}/repos")
      github_repos.each do |repo|
        repos << { name: repo['name'], link: repo['html_url'], 
                    language: pretty_language_name(repo['language']), description: repo['description'] }
      end

      # Get from _data/project_repositories.yml
      @site.data['project_repositories'].each do |repo|
        repos << { name: repo['name'], link: repo['link'], language: repo['language'], description: repo['description'] }
      end

      repos.delete_if { |repo| exclude.include?(repo[:name]) }
      repos.uniq! { |repo| repo[:name] }
      repos.sort_by! { |repo| sort_order.index(repo[:name]) || 99 }
      @maximum_listed = [@maximum_listed.to_i, repos.count].min
      repos = repos[0, @maximum_listed]

      # Build html
      output = "<div class='repo_blocks'>"

      repos.each do |repo|
        output += generate_repo_block(repo)
      end

      output += "</div>"
      output
    end
    
    def generate_repo_block(repo)
      converter = @site.getConverterImpl(Jekyll::Converters::Markdown)
      description = converter.convert(repo[:description])
      repo_id = repo[:name].gsub(/[^a-zA-Z][^\w:.-]*/,'')

      if @format == "Full" 
        output = <<-END
                    <div class='repo_block' id='#{repo_id}'>
                      <h2 class='repo_name'><a href='#{repo[:link]}'>#{repo[:name]}</a></h2>
                      <div class='repo_language'>#{repo[:language]}</div>
                      <div class='repo_description'>
                        #{description}
                      </div>
                    </div>
                  END
      else
        output = <<-END
                    <div class='repo_block'>
                      <a class='repo_name' href='Projects/##{repo_id}'>#{repo[:name]}</a>
                    </div>
                  END
        end
      output
    end
    
    def pretty_language_name(name)
      lang = {'c#' => 'C#', 'objective-c' => 'Objective-C', 'ruby' => 'Ruby', 'c++' => 'C++'}
      name = lang[name] || name
    end
    
    def get_repos(url)
      response = get_url_response(url)
      JSON.parse((response.code == '200') ? response.body : '[]')
    end
    
    def get_summary(url, scm)
      branch = scm == 'hg' ? 'tip' : 'HEAD'
      url += "/raw/#{branch}/Summary.md"
      response = get_url_response(url)
      (response.code == '200') ? response.body : nil
    end
    
    def get_url_response(url)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)
    end
  end
end

Liquid::Template.register_tag('project_repositories', Jekyll::ProjectRepositoriesTag)
