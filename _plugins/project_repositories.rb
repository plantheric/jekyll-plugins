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

      # Get from Github
      github_repos = get_repos(GithubRepo.api_url(@user))
      repos.concat github_repos.map { |r| GithubRepo.new(r) }

      # Get from Bitbucket
      bitbucket_repos = get_repos(BitbucketRepo.api_url(@user))
      repos.concat bitbucket_repos['values'].map { |r| BitbucketRepo.new(r) } unless bitbucket_repos.empty?

      # Get from _data/project_repositories.yml
      repos.concat @site.data['project_repositories'].map { |r| Repo.new(r) }

      repos.delete_if { |repo| exclude.include?(repo.name) }
      repos.uniq! { |repo| repo.name }
      repos.sort_by! { |repo| sort_order.index(repo.name) || 99 }
      @maximum_listed = [@maximum_listed.to_i, repos.count].min
      repos = repos[0, @maximum_listed]

      # Build html
      output = "<div class='repo_blocks'>"

      converter = @site.getConverterImpl(Jekyll::Converters::Markdown)
      repos.each do |repo|
        output += generate_repo_block(repo, converter)
      end

      output += "</div>"
      output
    end
    
    def generate_repo_block(repo, converter)
      if @format == "Full" 
        repo.html_full_output(converter)
      else
        repo.html_list_output
      end
    end

    def get_repos(url)
      response = Net::HTTP.get_response(URI.parse(url))
      JSON.parse((response.code == '200') ? response.body : '[]')
    end

  end
end

Liquid::Template.register_tag('project_repositories', Jekyll::ProjectRepositoriesTag)

class Repo
  def initialize(repo)
    @repo = repo
  end
  
  def name
    @repo['name']
  end

  def link
    @repo['link']
  end

  def description
    if (summary_url)
      response = Net::HTTP.get_response(URI.parse(summary_url))
      (response.code == '200') ? response.body : @repo['description']
    else
      @repo['description']
    end
  end

  def summary_url
  end

  def repo_id
    name.gsub(/[^a-zA-Z][^\w:.-]*/,'')
  end
  
  def language
    langs = {'c#' => 'C#', 'objective-c' => 'Objective-C', 'ruby' => 'Ruby', 'c++' => 'C++'}
    langs[@repo['language']] || @repo['language']
  end
  
  def html_full_output(converter)
    <<-END
        <div class='repo_block' id='#{repo_id}'>
          <h2 class='repo_name'><a href='#{link}'>#{name}</a></h2>
          <div class='repo_language'>#{language}</div>
          <div class='repo_description'>
            #{converter.convert(description)}
          </div>
        </div>
      END
  end

  def html_list_output
    <<-END
        <div class='repo_block'>
          <a class='repo_name' href='Projects/##{repo_id}'>#{name}</a>
        </div>
      END
  end
end

class BitbucketRepo < Repo
  def link
    @repo['links']['html']['href']
  end
  
  def summary_url
    link + "/raw/#{@repo['scm'] == 'hg' ? 'tip' : 'HEAD'}/Summary.md"
  end
  
  def self.api_url(user)
    "https://api.bitbucket.org/2.0/repositories/#{user}"
  end
end

class GithubRepo < Repo
  def link
    @repo['html_url']
  end

  def summary_url
    url = link + "/raw/master/Summary.md"
    response = Net::HTTP.get_response(URI.parse(url))         # Github redirect content
    (response.code == '200') ? url : response.header['location']
  end

  def self.api_url(user)
    "https://api.github.com/users/#{user}/repos"
  end
end
