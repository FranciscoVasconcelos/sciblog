module Jekyll
  class EnvCreate < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      # markup contains everything after the tag name
      args = markup.strip.split(/\s+/)
      @envname = args[0]
      @countby = args[1]
         
      # @label = args[0]
    end
    def render(context)
      envdict = {}
      envdict["countby"] = @countby.to_i
      
      # Add the enviornment name to the context
      context[@envname] = envdict

      # Add the env name to the list of envs
      context['envs'] ||= []
      context['envs'] << @envname
      
      # Add the default style 
      content = "<style>"
      content += load_replace('_includes/default.css',".#{@envname}-box")
      content += "</style>"


      return content
      end

  end
end

Liquid::Template.register_tag('envcreate', Jekyll::EnvCreate)

def load_replace(filename, replacement)
  # Read the file content
  content = File.read(filename)
  
  # Replace all occurrences of 'pretty-box' with the replacement string
  content.gsub('pretty-box', replacement)
rescue Errno::ENOENT
  puts "Error: File '#{filename}' not found"
  nil
rescue => e
  puts "Error reading file: #{e.message}"
  nil
end

