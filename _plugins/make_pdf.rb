# Make PDF tag
#
# A Jekyll tag to generate a PDF file from markdown content
#
# {% make_pdf content stylesheet pdf_file_path %}
#
# content       - either a string of markdown or a variable containing markdown
# stylesheet    - either a string of css or a variable containing css
# pdf_file_path - relative path for the generated PDF
#
require 'shellwords'
require 'tempfile'
require 'fileutils'

module Jekyll

  class MakePdfTag < Liquid::Tag

    def initialize(tag_name, markup, tokens)
      super
      @params = Shellwords.shellwords markup
    end

    def render(context)
      site = context.registers[:site]

      md_content = parse_param(@params[0], context)
      stylesheet = parse_param(@params[1], context)
      file_path  = parse_param(@params[2], context)

      converter = site.getConverterImpl(Jekyll::Converters::Markdown)
      html_content = converter.convert(md_content)
            
      content_file = save_temp_file(html_content, '.html')
      style_sheet_file = save_temp_file(stylesheet, '.css')
      output_file = File.join(site.source, file_path)

      cmd = "xvfb-run wkhtmltopdf --user-style-sheet #{style_sheet_file}  --encoding UTF8 #{content_file}  #{output_file}"
      system (cmd)

      static_file = Jekyll::StaticFile.new(site, site.source, '', file_path)
      site.static_files << static_file
      ""
    end

    def save_temp_file(content, extension)
      temp_file = Tempfile.new(['wkhtmltopdf_convert_', extension])
      temp_file << content
      temp_file.close
      temp_file.path
    end
    
    def parse_param (param, context)
      parsed = ''
      begin
        parsed = Liquid::Template.parse('{{ '+param+' }}').render(context)
      rescue
      end
      parsed.strip.empty? ? param : parsed
    end
  end
end

Liquid::Template.register_tag('make_pdf', Jekyll::MakePdfTag)
