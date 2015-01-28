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
require_relative 'project_repositories/repo'

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

      converter = @site.getConverterImpl(Jekyll::Converters::Markdown)

      # Build html
      output = "<div class='repo_blocks'>"

      repos.each do |repo|
        generate_project_page(repo)
        output += generate_repo_block(repo, converter)
      end

      output += "</div>"
      output
    end
    
    def generate_repo_block(repo, converter)
      if @format == "Summary"
        repo.html_list_output
      else
        repo.html_full_output(converter)
      end
    end

    def generate_project_page(repo)
      if @format == "ProjectPages"
        readme = repo.readme
        if (readme)
          path = "/#{repo.repo_id}.md"
          save_readme_file(readme, "[See this project on #{repo.host_name}](#{repo.repo_link}){: .repo_link}", path)
          page = Page.new(@site, "_cache/", "", "projects#{path}")
          page.render(@site.layouts, @site.site_payload)
          @site.pages << page
          repo.project_link = page.url
        end
      end
    end

    def get_repos(url)
      response = Net::HTTP.get_response(URI.parse(url))
      JSON.parse((response.code == '200') ? response.body : '[]')
    end

    def save_readme_file(content, subhead, path)
      content.sub!(/^(#[\w ]+)$/, "\\1  \n#{subhead}")
      front_matter = (@site.config['project_repositories'] && @site.config['project_repositories']['front_matter']) || {}
      file = File.new("#{@site.source}/_cache/projects#{path}", "w")
      file << "---\n"
      front_matter.each {|key,value| file << "#{key}: #{value}\n"}
      file << "---\n\n{% raw  %}\n#{content}\n{% endraw %}\n"
      file.close
    end
  end
end

Liquid::Template.register_tag('project_repositories', Jekyll::ProjectRepositoriesTag)

