require 'shellwords'

def unique_acronym(strings)
  unique_strings = []
  strings.each do |s|
    candidate = s.dup
    while unique_strings.include?(candidate)
      # change last letter cyclically
      if candidate[-1].match?(/[A-Z]/)
        candidate[-1] = ((candidate[-1].ord - 'A'.ord + 1) % 26 + 'A'.ord).chr
      else
        # if last char is not a letter, replace it with 'a'
        candidate[-1] = 'A'
      end
    end
    unique_strings << candidate
  end
  return unique_strings
end

# Parses tag arguments into positional and named parameters.
def parse_params(text)
  args = Shellwords.split(text.strip)
  positional = []
  named = {}
  
  args.each do |arg|
    if arg.include?('=')
      key, value = arg.split('=', 2)
      named[key] = value
    else
      positional << arg
    end
  end
  [positional, named]
end

# Validates that parameters follow Python's convention where all positional
# arguments must come before any named arguments.
def valid_param_order?(text)
  positional = Shellwords.split(text.strip)
  seen_named = false
  
  positional.each do |arg|
    if arg.include?('=')
      seen_named = true
    elsif seen_named
      # Found a positional argument after a named one
      return false
    end
  end
  
  return true
end

# Counts the number of consecutive "sub" prefixes before "section".
def count_sub_prefixes(str)
  # Use regex to match: zero or more "sub", followed by "section" at the end
  return nil unless str != nil
  match = str.match(/^((?:sub)*)section$/)
  return nil unless match
  
  # Count how many times "sub" appears in the captured group
  match[1].scan(/sub/).length
end


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
  
  # Check if key exists 
  if site.config['ref'].key?(key)
    # Get existing url and labels from dict
    elabel = site.config['ref']["label"]
    eurl = site.config['ref']["url"]

    # If it is a the same label and url ignore 
    return if (eurl == url) && (elabel == label)
    # else return error
    raise "Key '#{key}' already exists"
  end
  # Raise error if key already exists
  # raise "Key '#{key}' already exists" if site.config['ref'].key?(key)

  site.config["ref"][key] = ref
end

def get_url_label_from_config(context,key)
  site = context.registers[:site]
  return site.config["ref"][key]["url"],site.config["ref"][key]["label"]
end

# Get reference from site. Raise error if key not found
def getRef(site,key)
  if (site.config["ref"] == nil) || site.config["ref"][key] == nil
    raise "Key '#{key}' not found!"
  end
  return site.config["ref"][key]["url"],site.config["ref"][key]["label"]
end

# Get reference from site. Raise error if key not found
def getRefRef(ref,key)
  if (ref == nil) || ref[key] == nil
    raise "Key '#{key}' not found!"
  end
  return ref[key]["url"],ref[key]["label"]
end

def get_url_label(acronym,number,counter,url,anchor)

  label_str = acronym + "-" + number + counter.to_s
  equrl = url + "\#" + anchor

  return label_str,equrl
end


def get_number_from_context(context,level)
  # This function generates a number from the section counter 
  # It extracts the counter until a section level
  
  context["section"] ||= {}
  context["section"]["counter"] ||= []

  number_str = ""
  # Loop until level
  for index in 0..level
    element = context["section"]["counter"][index]
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
    
      unless valid_param_order?(markup)
        raise SyntaxError, 
          "Positional arguments must come before named arguments"
      end
      

      positional, named = parse_params(markup)

      @envname = named['envname'] || positional[0]
      @label = named['label'] || positional[1]
      @proof = (named['showproof'] || positional[2]).downcase == 'true' 

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
        See #{proofname} <mathlabel>#{anchor}:proof</mathlabel>
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
    def initialize(tag_name,markup,tokens)
      super
   
      unless valid_param_order?(markup)
        raise SyntaxError, 
          "Positional arguments must come before named arguments"
      end
      
      positional, named = parse_params(markup)
      
      @header = named['header'] || positional[0]
      type = named['by'] || positional[1]
      @level = (count_sub_prefixes(type) || named['level'] || 0).to_i
      @ref = named['label'] || positional[2] || ""
      
      # Give error if @header is nil or empty

    end

    def render(context)
      
      page = context.registers[:page]

      context["section"] ||= {}

      context["section"]["withacronym"] ||= page["section_with_acronym"] || false
      
      # Create counter for each section level
      context["section"]["counter"] ||= Array.new
      
      # Initialize counter if empty
      context["section"]["counter"][@level] ||= 0
      
      # increment counter
      context["section"]["counter"][@level] += 1
      
      # Iterate over envs
      if context["envs"] != nil 
        context["envs"].each do |env|
          # Reset env counter when at specified level
          if @level == context[env]["countby"]
            context[env]["counter"] = 1
          end
        end
      end
      
      number_str,anchor = gen_and_save_ref(context,@level,-1,"math-ref-#{@ref}")
      
      acronym = ""
      if context["section"]["withacronym"]
        acronym = "#{page["acronym"]}-"
      end

      return "\#"*(@level+1) + " **#{acronym}#{number_str}** #{@header} {\##{anchor}}"

    end
  end
end

module Jekyll
  class Reference < Liquid::Tag
    def initialize(tag_name,markup,tokens)
      super
        
      unless valid_param_order?(markup)
        raise SyntaxError, 
          "Positional arguments must come before named arguments"
      end

      positional, named = parse_params(markup)
      @label = positional[0] || named["label"]

      # Must give error if @label is nil
    end

    def render(context)
     
      <<~HTML
      <mathlabel>math-ref-#{@label}</mathlabel>
      HTML

    end
  end
end

module Jekyll
  class Repeat < Liquid::Tag
    def initialize(tag_name,markup,tokens)
      super
        
      unless valid_param_order?(markup)
        raise SyntaxError, 
          "Positional arguments must come before named arguments"
      end

      positional, named = parse_params(markup)
      @label = positional[0] || named["label"]

      # Must give error if @label is nil
    end

    def render(context)
  
      <<~HTML
      <repeat-element>math-ref-#{@label}</repeat-element>
      HTML

    end
  end
end



module Jekyll
  class EnvProof < Liquid::Block
    def initialize(tag_name, markup, tokens)
      super

      unless valid_param_order?(markup)
        raise SyntaxError, 
          "Positional arguments must come before named arguments"
      end
      
      positional, named = parse_params(markup)

      @envname = named['envname'] || positional[0]
      @label = named['label'] || positional[1]
      
      # Give error if @label or @envname are nil or empty 
    end
    def render(context)
      page = context.registers[:page]
      site = context.registers[:site]

      url = page['url']
      acronym = page['acronym']

      # Counter for proof as if it were a normal env
      context["proof"] = {}
      context["proof"]["counter"] ||= 1
      envcounter = context["proof"]["counter"]
    
      anchor = "math-ref-#{@label}"
      envurl = "#{url}\##{anchor}:proof"

      # Create a label and an url and save it in the context
      number_str = get_number_from_context(context,context[@envname]["countby"])
      label_str,equrl = get_url_label(acronym,number_str,envcounter,url,anchor)

      save_ref(envurl,"here","#{anchor}:proof",site)
      # Get url and label from site.config
      # envurl,label_str = getRef(site,anchor)
      # # Get ref from the global config
      # ref = site.config["ref"][anchor]
      #
      # envurl = ref['url']
      # label_str = ref['label']
      #
      # The pre text for the box title
      append_title = %(<a href="#{envurl}" style="color:blue">#{context[@envname]['proofname'].capitalize}</a> of)
 
      id = "#{@envname}#{label_str.gsub('.','_').gsub('-','_')}_proof" # Define a unique id
      content = super 

      # The content with a toggle button inside
      <<~HTML
      <div class="#{@envname}-box" id="#{anchor}:proof">
      <div class='box'>
        <div class="header">
            #{append_title} #{@envname} <mathlabel>#{anchor}</mathlabel>
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

      unless valid_param_order?(markup)
        raise SyntaxError, 
          "Positional arguments must come before named arguments"
      end
      
      positional, named = parse_params(markup)

      @envname = named['envname'] || positional[0]
      @label = named['label'] || positional[1]
      @countby = named['countby'] || positional[2] || 0
      @proofname = named['proofname'] || positional[3] || 'proof'         
      # Give error if @label or @envname are nil or empty 
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
      content += load_replace('_plugins/extra/default.css',".#{@envname}-box")
      content += "</style>"

      return content
      end

  end
end

module Jekyll
  class EquationLabel < Liquid::Block
    def initialize(tag_name, markup, tokens)
      super
      
      unless valid_param_order?(markup)
        raise SyntaxError, 
          "Positional arguments must come before named arguments"
      end
      
      positional, named = parse_params(markup)

      @label = named['label'] || positional[0]
      # Give error if @label is nil or empty 
    end
    def render(context)
      
      # Count equations by section by default
      context["equation"] ||= {}
      context["equation"]["countby"] ||= 0
      
      # Generate and save the url and label in the context
      anchor = gen_and_save_ref_II(context,"equation",@label)
      
      # Get the url and label 
      equrl,label_str = get_url_label_from_config(context,anchor)

      label_str_p = "(#{label_str})"

      puts label_str_p


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

      unless valid_param_order?(markup)
        raise SyntaxError, 
          "Positional arguments must come before named arguments"
      end
      
      positional, named = parse_params(markup)

      @envname = named['envname'] || positional[0]
      @countby = named['countby'] || positional[1] || 0
      # Give error if @envname is nil or empty 

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
Liquid::Template.register_tag('repeat', Jekyll::Repeat)

def pre_render_acronyms(site)
  puts "Executing pre render hook for acronyms"
  strings = []
  site.posts.docs.each do |post|
    # Auto generates an acronym if not defined
    if post.data['acronym'] == nil
      post.data['acronym'] = post.data['title'].split.map { |word| word[0] }.join.upcase
    end
    strings << post.data['acronym']
  end
  unique_strings = unique_acronym(strings)
  
  # Replace the repeated strings
  site.posts.docs.each_with_index do |post, index|
    post.data['acronym'] = unique_strings[index]
  end
end

def appendPostsUrlVar(site,filename)
  posts_links = site.posts.docs.map { |post| post.url }.to_json
  # Read your main JavaScript file
  plugin_dir = File.expand_path("extra", __dir__)
  js_content = File.read(File.join(plugin_dir, filename))
  
  # Create the complete script with posts data
  <<~HTML
  <script>
    const postsLinks = #{posts_links};
    
    #{js_content}
  </script>
  HTML

end

def inject_script(site,filename)
  # Build the posts links array
  posts_links = site.posts.docs.map { |post| post.url }.to_json
  
  # Read your main JavaScript file
  plugin_dir = File.expand_path("extra", __dir__)
  js_content = File.read(File.join(plugin_dir, filename))
  
  # Create the complete script with posts data
  complete_script = <<~JS
    const postsLinks = #{posts_links};
    
    #{js_content}
  JS
  
    # site.pages.each do |page|
  #   if page.output_ext == ".html"
  #     page.output.sub!(/<\/body>/, "<script>#{complete_script}</script></body>")
  #   end
  # end
  
  # Inject into all HTML posts
  site.posts.docs.each do |post|
    if post.output_ext == ".html"
      post.output.sub!(/<\/body>/, "<script>#{complete_script}</script></body>")
    end
  end
end

def injectAtEndBody(post,content)
  if post.output_ext == ".html"
      post.output.sub!(/<\/body>/, "#{content}</body>")
      return true
  end
  return false
end



# Ensures that the acronyms are unique and autogenerates from title
Jekyll::Hooks.register :site, :pre_render do |site|
  pre_render_acronyms(site)
end

# Gets label string of the env of some proof
def proofCheck(ref,key)
  if key.end_with?(":proof")
    keyenv = key[0..-7]
    if ref.key?(keyenv)
      equrl,label = getRefRef(ref,keyenv)
      return equrl,label
    end
  end
  return nil,nil
end

def refProof(proofurl,envurl,label)
  <<~HTML
  <a style="color:red" href=#{proofurl}>proof</a> of <a href=#{envurl}>#{label}</a>
  HTML
end

def linkProof(ref,key)
  envurl,label = proofCheck(ref,key)
  return nil if envurl == nil
  
  proofurl,_ = getRefRef(ref,key)
  refProof(proofurl,envurl,label)
end

def setRepeat(post,ref)
  html = post.output
  html = html.gsub(/<repeat-element>(.*?)<\/repeat-element>/m) do
    key = Regexp.last_match(1).strip

    # Check if inner key exists
    if ref.key?(key)
      equrl = ref[key]['url']
      label = "#{ref[key]['label']}"

      # Return a repeat-element with url
      %(<repeat-element style="display:none" url="#{equrl}">#{label}</repeat-element>)
    else
      raise "Key #{key} does not exist"
    end
  end 

  post.output = html
end

def setReference(post,ref)
  html = post.output
  html = html.gsub(/<mathlabel>(.*?)<\/mathlabel>/m) do
    key = Regexp.last_match(1).strip
    
    # Diferent link when proof
    html = linkProof(ref,key)
    if(html)
      html
    else
      # Check if key exists
      if ref.key?(key)
        equrl = ref[key]['url']
        label = "#{ref[key]['label']}"

        # Return an anchor link
        %(<a style="color:blue" href="#{equrl}">#{label}</a>) 
      else
        raise "Key #{key} does not exist"
      end
    end
  end
  post.output = html
end

def getContentExtra()
  plugin_dir = File.expand_path("extra", __dir__)
  
  css_content = File.read(File.join(plugin_dir, "link-highlight.css"))
  js_content = File.read(File.join(plugin_dir, "box.js"))
  html_content = File.read(File.join(plugin_dir, "mathjax.html"))
  
  <<~HTML
  <script>#{js_content}</script>
  <style>#{css_content}</style>
  #{html_content}
  HTML
end



Jekyll::Hooks.register :site, :post_render do |site|
  js_content  = appendPostsUrlVar(site,"repeat.js")
  extra_content = getContentExtra()
  ref = site.config['ref']
  # inject_script(site,"repeat.js")
  # Iterate over all posts
  site.posts.docs.each do |post|
    if post.output_ext == ".html"
      setRepeat(post,ref)
      setReference(post,ref)
      injectAtEndBody(post,js_content)
      injectAtEndBody(post,extra_content)
    end
  end
end

# puts site.config['ref']
# puts site.posts.docs.map
# post.output.sub!(/<\/body>/, "<script>#{complete_script}</script></body>")

# This hook runs after each page/post has been fully rendered (Liquid + layout)
# Jekyll::Hooks.register [:posts,:documents], :post_render do |item|
#   # Look for mathlabel elements and transform them into links
#   # It uses the stored links in the config['ref']
#
#   html = item.output
#   site = item.site
#   config = site.config
#   ref = config['ref']
#
#   html = html.gsub(/<mathlabel>(.*?)<\/mathlabel>/m) do
#     inner = Regexp.last_match(1).strip
#
#     # Check if inner key exists
#     if ref.key?(inner)
#       equrl = ref[inner]['url']
#       label = "#{ref[inner]['label']}"
#
#       # Return an anchor link
#       %(<a style="color:blue" href="#{equrl}">#{label}</a>)
#     end
#   end
#
#   html = html.gsub(/<repeat-element>(.*?)<\/repeat-element>/m) do
#     key = Regexp.last_match(1).strip
#
#     # Check if inner key exists
#     if ref.key?(key)
#       equrl = ref[key]['url']
#       label = "#{ref[key]['label']}"
#
#       # Return a repeat-element with url
#       %(<repeat-element style="display:none" url="#{equrl}">#{label}</repeat-element>)
#     end
#   end 
#
#   item.output = html
#
#   inject_content_after_render(item)
#
#   # Optional: log what’s happening (appears in build output)
#   Jekyll.logger.info "PostRender:", "Processed #{item.relative_path}"
# end
#


def inject_content_after_render(page)
  html = page.output
  plugin_dir = File.expand_path("extra", __dir__)
  
  css_content = File.read(File.join(plugin_dir, "link-highlight.css"))
  js_content = File.read(File.join(plugin_dir, "box.js"))
  html_content = File.read(File.join(plugin_dir, "mathjax.html"))
  
  content = 
  <<~HTML
  <body>
  <script>#{js_content}</script>
  <style>#{css_content}</style>
  #{html_content}
  HTML

  # Inject the files inside head
  html.sub!(/<body>/,content) 
  page.output = html
end


