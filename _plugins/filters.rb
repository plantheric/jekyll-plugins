# Additional Liquid filters

module Jekyll
  module Filters
    
    # Variant on the standard replace filter that will process regex
    def regex(input, regex, replacement='')
      input.to_s.gsub(Regexp.new(regex), replacement.to_s)
    end

  end
end
