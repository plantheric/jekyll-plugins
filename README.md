# Jekyll Plugins

## bitbucket_repositories

A Tag plugin to generate a list of bitbucket repositories

### Usage
	{% bitbucket_repositories user_name %}

By default the plugin will only list public repositories. 
If you want to include private repositories you must create a config file `_bitbucket.yml` at the root of your Jekyll site which should contain your bitbucket username and password.

	
	user: user_name
	password: user_password

If you want to include addition projects they can be specified in the file `_data\bitbucket.yml` with the following syntax

    - name: 
      link: 
      language: 
      description: 

## filters

Additional Liquid filters

###regex
	{{ original | regex: regexp, replacement }}

## http_include

A Tag plugin to include content downloaded from an http source

###Usage
	{% http_include url %}

Urls that have been generated with the Dropbox 'Share Link' feature will be adjusted so that the raw document is included

## make_pdf
A Tag plugin to generate a PDF file from markdown content. make_pdf requires Gimli to generate the pdf.

	gem install gimli

###Usage

	{% make_pdf content style_sheet pdf_file_path %}

Parameters:

	content       - either a string of markdown or a variable containing markdown
	stylesheet    - either a string of css or a variable containing css
	pdf_file_path - relative path for the generated PDF

The plugin will add the generated PDF to Jekyll's list of static files so that it gets copied to the `_site` folder.
