class Repo
  attr_writer :project_link
  
  def initialize(repo)
    @repo = repo
  end
  
  def name
    @repo['name']
  end

  def project_link
    @project_link or repo_link
  end

  def repo_link
    @repo['link']
  end

  def description
    get_contents (summary_url) or @repo['description']
  end

  def readme
    get_contents (readme_url)
  end

  def summary_url
    repo_file_url "Summary.md"
  end
  
  def readme_url
    check_url(repo_file_url "README.md") or check_url(repo_file_url "ReadMe.md")
  end
  
  def repo_file_url(file_name)
  end

  def repo_id
    name.gsub(/[^a-zA-Z0-9][^\w:.-]*/,'')
  end
  
  def language
    langs = {'c#' => 'C#', 'objective-c' => 'Objective-C', 'ruby' => 'Ruby', 'c++' => 'C++'}
    langs[@repo['language']] || @repo['language']
  end
  
  def html_full_output(converter)
    <<-END
        <div class='repo_block' id='#{repo_id}'>
          <h2 class='repo_name'><a href='#{project_link}'>#{name}</a></h2>
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
  
  def check_url(url)
    response = Net::HTTP.get_response(URI.parse(url)) unless url.nil?
    (response.code == '200') ? url : nil unless response.nil?
  end
  
  def get_contents(url)
      response = Net::HTTP.get_response(URI.parse(url)) unless url.nil?
      (response.code == '200') ? response.body : nil unless response.nil?
  end
end

class BitbucketRepo < Repo
  def repo_link
    @repo['links']['html']['href']
  end
  
  def repo_file_url(file_name)
    puts "repo_file_url(#{file_name})"
    repo_link + "/raw/#{@repo['scm'] == 'hg' ? 'tip' : 'master'}/#{file_name}"
  end
  
  def self.api_url(user)
    "https://api.bitbucket.org/2.0/repositories/#{user}"
  end
end

class GithubRepo < Repo
  def repo_link
    @repo['html_url']
  end

  def repo_file_url(file_name)
    puts "repo_file_url(#{file_name})"
    url = repo_link + "/raw/master/#{file_name}"
    response = Net::HTTP.get_response(URI.parse(url))         # Github redirect content
    (response.code == '200') ? url : response.header['location']
  end

  def self.api_url(user)
    "https://api.github.com/users/#{user}/repos"
  end
end
