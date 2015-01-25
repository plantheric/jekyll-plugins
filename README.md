# Jekyll Plugins

## project_repositories

A Tag plugin to generate content containing a list of projects.

The plugin will generate content listing public repositories on github and bitbucket.

#### Usage
	{% project_repositories user_name %}

where the `user_name` is the user name for github and/or bitbucket.

The plugin will take `name`, `link`, `language` and `description` parameters from the API response. 
The plugin also will attempt to download a `Summary.md` file from the  project root. 
If this file exists it will be used for the project description.

The plugin can also list projects that are not in public github or bitbucket repositories. 
Addition projects can be listed in the file `_data\project_repositories.yml` with the following syntax.

	- name: 
	  link: 
	  language: 
	  description: 

The `description` field will be processed as markdown.

You can also specify the order the projects are sort in for display. In the `_config.yml` file add

	project_repositories:
	  sort_order: ['Project 1', 'My project']

## filters

Additional Liquid filters

###regex
	{{ original | regex: regexp, replacement }}

## http_include

A Tag plugin to include content downloaded from an http source

####Usage
	{% http_include url %}

Urls that have been generated with the Dropbox 'Share Link' feature will be adjusted so that the raw document is included

## make_pdf
A Tag plugin to generate a PDF file from markdown content.

PDF creatation is performed by `wkhtmltopdf` using `xvfb-run` to run it in an X server environment.
Running wkhtmltopdf without X server can result in horrible kerning issues in the generated PDF.

The make_pdf.rb plugin requires the following

	sudo apt-get install wkhtmltopdf
	sudo apt-get install libicu48
	sudo apt-get install xvfb

You will also need to have installed the fonts used in document. Start with the Microsoft Core Fonts.

	sudo apt-get install ttf-mscorefonts-installer

####Usage

	{% make_pdf content style_sheet pdf_file_path %}

Parameters:

	content       - either a string of markdown or a variable containing markdown
	stylesheet    - either a string of css or a variable containing css
	pdf_file_path - relative path for the generated PDF

The plugin will add the generated PDF to Jekyll's list of static files so that it gets copied to the `_site` folder.
