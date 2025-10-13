def gen_and_save_ref(context,level,envcounter,anchor)
  # Create a label and an url and save it in the context
  
  page = context.registers[:page]
  site = context.registers[:site]

  url  = page['url']
  acronym = page['acronym']    
  
  number_str = get_number_from_context(context,level)
  label_str = acronym + "-" + number_str + (envcounter == -1 ? "" : envcounter.to_s)
  
  # If the reference anchor is empty
  if anchor == "math-ref-"
    # Set a unique anchor from the label string
    anchor = "math-ref-#{label_str}"
  end

  equrl = url + "\#" + anchor
  
  save_ref(equrl,label_str,anchor,site)
  return number_str,anchor
end

def gen_and_save_ref_II(context,envname,label)
  context[envname]["counter"] ||= 1
  envcounter = context[envname]["counter"]
  anchor = "math-ref-#{label}"
  
  # If label is empty or nil autogenerate the anchor
  _,anchor = gen_and_save_ref(context,context[envname]["countby"],envcounter,anchor)
  return anchor
  
end


def save_ref(url,label,key,site)
  ref = {"url"=> url,"label"=>label}

  # Store ref in the global config
  site.config["ref"] ||= {}
  site.config["ref"][key] = ref
end

def get_url_label_from_config(context,key)
  site = context.registers[:site]
  return site.config["ref"][key]["url"],site.config["ref"][key]["label"]
end


def get_url_label(acronym,number,counter,url,anchor)

  label_str = acronym + "-" + number + counter.to_s
  equrl = url + "\#" + anchor

  return label_str,equrl
end


def get_number_from_context(context,level)
  # This function generates a number from the section counter 
  # It extracts the counter until a section level
  
  number_str = ""
  context["section"]["counter"].each_with_index do |element,index|
    break if index > level
    if element == nil
      context["section"]["counter"][index] = 0
    end
    # append the counter number to the string
    number_str += context["section"]["counter"][index].to_s + "." 
  end

  return number_str
end


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



module Jekyll
  class EnvLabel < Liquid::Block
    def initialize(tag_name, markup, tokens)
      super
      # markup contains everything after the tag name
      args = markup.strip.split(/\s+/)
      @envname = args[0]
      @label = args[1]
      @proof = args[2].downcase == "true"
    end
    def render(context)
      page = context.registers[:page]
      site = context.registers[:site]

      url  = page['url']
      acronym = page['acronym']
      
      anchor = "math-ref-#{@label}"

      context[@envname]["counter"] ||= 1
      envcounter = context[@envname]["counter"]
      
      # Create a label and an url and save it in the context
      number_str = get_number_from_context(context,context[@envname]["countby"])
      label_str,equrl = get_url_label(acronym,number_str,envcounter,url,anchor)
      save_ref(equrl,label_str,anchor,site)

      id = "#{@envname}#{number_str.gsub('.','_')}" # Define a unique id

      linkproof = ""
      if @proof 
        proofname = context[@envname]['proofname']
        linkproof = 
        <<~HTML
        See #{proofname} <a href="#{equrl}:proof">here</a>.
        HTML
      end

      # Iterate config 
      context[@envname]["counter"] += 1
      content = super
          
      # Render any Liquid inside it
      template = Liquid::Template.parse(content)
      rendered = template.render(context)

      # The content with a toggle button inside
      <<~HTML
      <div class="#{@envname}-box user-#{@envname}-box" id="#{anchor}">
      <div class='box'>
        <div class="header user-header">
            #{@envname.capitalize}<a href="#{equrl}">&nbsp;#{label_str}</a>
        </div>
        <button class="hide-button user-hide-button" onclick="toggleContent#{id}()"></button>
        <div class="content user-content">
            #{rendered}
            #{linkproof}
        </div>
        </div>
      </div>

      <script>
        function toggleContent#{id}() {
            const content = document.getElementById('#{anchor}');
            content.style.display = 'none';
        }
      </script>
      HTML

    end
  end
end

module Jekyll
  class Sectioning < Liquid::Tag
    def initialize(tag_name,text,tokens)
      super

      args = text.split(' ')
      @header = args[0] || ""
      @level = args[1].to_i || 0
      @ref = args[2] || ""
    end

    def render(context)

      context["section"] ||= {}
      # Create counter for each section level
      context["section"]["counter"] ||= Array.new
      
      # Initialize counter if empty
      context["section"]["counter"][@level] ||= 0
      
      # increment counter
      context["section"]["counter"][@level] += 1
      
      # Iterate over envs
      context["envs"].each do |env|
        # Reset env counter when at specified level
        if @level == context[env]["countby"]
          context[env]["counter"] = 1
        end
      end
      
      number_str,_ = gen_and_save_ref(context,@level,-1,"math-ref-#{@ref}")

      if @ref != ""
        @ref = "{\#math-ref-#{@ref}}"
      end
      return "\#"*(@level+1) + " " + number_str + " #{@header}" + " " + @ref

    end
  end
end

module Jekyll
  class Reference < Liquid::Tag
    def initialize(tag_name,markup,tokens)
      super

      args = markup.strip.split(/\s+/)
      @label = args[0]
    end

    def render(context)
      
      <<~HTML
      <mathlabel>math-ref-#{@label}</mathlabel>
      HTML

    end
  end
end

module Jekyll
  class EnvProof < Liquid::Block
    def initialize(tag_name, markup, tokens)
      super
      # markup contains everything after the tag name
      args = markup.strip.split(/\s+/)
      @envname = args[0]
      @label = args[1]
    end
    def render(context)
      page = context.registers[:page]
      site = context.registers[:site]

      url  = page['url']
      acronym = page['acronym']
    
      anchor = "math-ref-#{@label}"
      
      # The pre text for the box title
      append_title = "#{context[@envname]['proofname'].capitalize} of"

      # Get ref from the global config
      ref = site.config["ref"][anchor]
      
      envurl = ref['url']
      label_str = ref['label']
 
      id = "#{@envname}#{label_str.gsub('.','_').gsub('-','_')}_proof" # Define a unique id
      content = super 

      # The content with a toggle button inside
      <<~HTML
      <div class="#{@envname}-box" id="#{anchor}:proof">
      <div class='box'>
        <div class="header">
            #{append_title} #{@envname}<a href="#{envurl}">&nbsp;#{label_str}</a>
        </div>
        <button class="hide-button" onclick="toggleContent#{id}()"></button>
        <div class="content">
            #{content}
        </div>
        </div>
      </div>

      <script>
        function toggleContent#{id}() {
            const content = document.getElementById('#{anchor}:proof');
            content.style.display = 'none';
        }
      </script>
      HTML

    end
  end
end

module Jekyll
  class EnvCreate < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      # markup contains everything after the tag name
      args = markup.strip.split(/\s+/)
      @envname = args[0]
      @countby = args[1] || 0
      @proofname = args[2] || 'proof'
         
    end

    def render(context)
      envdict = {}
      envdict["countby"] = @countby.to_i
      envdict["proofname"] = @proofname

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

module Jekyll
  class EquationLabel < Liquid::Block
    def initialize(tag_name, markup, tokens)
      super
      # markup contains everything after the tag name
      args = markup.strip.split(/\s+/)
      @label = args[0]
      # @envname = "equation"
    end
    def render(context)
      
      # Count equations by section
      context["equation"] ||= {}
      context["equation"]["countby"] ||= 0
      
      # Generate and save the url and label in the context
      anchor = gen_and_save_ref_II(context,"equation",@label)
      
      # Get the url and label 
      equrl,label_str = get_url_label_from_config(context,anchor)

      label_str_p = "(#{label_str})"

      context["equation"]["counter"] += 1
      content = super
      
      <<~HTML
      <div id="#{anchor}" style="display:flex; align-items:center; justify-content:space-between; gap:1em;">
      <div class="mathjax-eq">$$#{content}\\notag$$</div>
      <a href="#{equrl}" style="color:green;">#{label_str_p}</a>
      </div>
      HTML

    end
  end
end

module Jekyll
  class EnvOptions < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      # markup contains everything after the tag name
      args = markup.strip.split(/\s+/)
      @envname = args[0]
      @countby = args[1]
    end

    def render(context)
      context[@envname] ||= {}
      context[@envname]["countby"] = (@countby || 0).to_i
      super
    end
  end
end




Liquid::Template.register_tag('section',Jekyll::Sectioning)
Liquid::Template.register_tag('envlabel', Jekyll::EnvLabel)
Liquid::Template.register_tag('ref',Jekyll::Reference)
Liquid::Template.register_tag('envproof', Jekyll::EnvProof)
Liquid::Template.register_tag('envcreate', Jekyll::EnvCreate)
Liquid::Template.register_tag('envoptions', Jekyll::EnvOptions)
Liquid::Template.register_tag('equation', Jekyll::EquationLabel)



# This hook runs after each page/post has been fully rendered (Liquid + layout)
Jekyll::Hooks.register [:pages, :documents], :post_render do |item|
  # Look for mathlabel elements and transform them into links
  # It uses the stored links in the config['ref']

  html = item.output
  site = item.site
  config = site.config
  ref = config['ref']

  html = html.gsub(/<mathlabel>(.*?)<\/mathlabel>/m) do
    inner = Regexp.last_match(1).strip
    # Check if inner key exists
    if ref.key?(inner)
      equrl = ref[inner]['url']
      label = "#{ref[inner]['label']}"
      # Return an anchor link
      %(<a style="color:blue" href="#{equrl}">#{label}</a>)
    end
  end
  
  item.output = html

  # Optional: log what’s happening (appears in build output)
  Jekyll.logger.info "PostRender:", "Processed #{item.relative_path}"
end




