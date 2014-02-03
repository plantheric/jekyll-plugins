# jekyll-bitbucket-repositories

A Jekyll plugin to generate a list of bitbucket repositories

##Usage
	{% bitbucket_repositories user_name %}

By default the plugin will only list public repositories. 
If you want to include private repositories you must create a config file `_bitbucket.yml` at the root of your Jekyll site which should contain your bitbucket username and password.

	
	user: user_name
	password: user_password