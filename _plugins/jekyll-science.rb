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



def saveRef(url,label,env,key,site)
  # Initialize empty dictionary
  site.config["ref"] ||= {}
  ref = site.config["ref"]
  if ref.key?(key)
    elabel = ref[key]["label"]
    eurl = ref[key]["url"]

    # If it is a the same label and url ignore 
    return if (eurl == url) && (elabel == label)
    # else return error
    raise "Key '#{key}' already exists"
  end
  site.config["ref"][key] = {"url"=>url,"label"=>label,"env"=>env}
end

def genRef(context,envname,label,level=nil,subeq=false,ref='math-ref-')
  # envcounter = setupEnv(context,envname)
  envcounter = context[envname]["counter"]
  anchor = "#{ref}#{label}"

  page = context.registers[:page]
  site = context.registers[:site]
  url  = page['url']
  acronym = page['acronym']
  
  if !level
    level = site.config[envname]["countby"]
   end
  # Get the number from the section counters
  number_str = get_number_from_context(context,level)
  label_str = acronym + "-" + number_str + (envcounter.class == Array ? "" : envcounter.to_s)
  if subeq
    subcounter = context[envname]["subcounter"]
    label_str = "#{label_str}#{(subcounter + 'a'.ord).chr}"
  end
  # If the reference anchor is empty
  if anchor == ref
    # Set a unique anchor from the label string
    anchor = "#{ref}#{label_str}"
  end

  equrl = url + "\#" + anchor
  
  saveRef(equrl,label_str,envname,anchor,site)

  return label_str,equrl,number_str,anchor
end

def setupEnv(context,envname)
  site = context.registers[:site]
 
  # Config for env
  site.config[envname] ||= {} 
  site.config[envname]["countby"] ||= 0

  # Counter for env  
  context[envname] ||= {}
  context[envname]["counter"] ||= 1
end

def setupSectionEnv(context,level,envname)
  site = context.registers[:site]
  page = context.registers[:page]

  context[envname] ||= {}
  context[envname]["withacronym"] ||= page["#{envname}_with_acronym"] || false
  # Create counter for each section level
  context[envname]["counter"] ||= Array.new
  # Initialize counter if empty
  context[envname]["counter"][level] ||= 0
  # increment counter
  context[envname]["counter"][level] += 1
end



def get_url_label_from_config(context,key)
  site = context.registers[:site]
  return site.config["ref"][key]["url"],site.config["ref"][key]["label"]
end



# Get reference from site. Raise error if key not found
def getRef(ref,key)
  if (ref == nil) || ref[key] == nil
    raise "Key '#{key}' not found!"
  end
  return ref[key]["url"],ref[key]["label"],ref[key]["env"]
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
      @proof = named['showproof'] || positional[2] == 'true' 

    end
    def render(context)
      page = context.registers[:page]
      site = context.registers[:site]

      url  = page['url']
      acronym = page['acronym']
      
      # anchor = "math-ref-#{@label}"
      
      # envcounter = setupEnv(context,@envname)
      setupEnv(context,@envname)
      label_str,equrl,number_str,anchor = genRef(context,@envname,@label)
      # increment env counter 
      context[@envname]["counter"] += 1
        
      id = "#{@envname}#{number_str.gsub('.','_')}" # Define a unique id

      linkproof = ""
      if @proof 
        proofname = site.config[@envname]['proofname']
        linkproof = 
        <<~HTML
        See <prooflabel>#{anchor}:proof</prooflabel>
        HTML
      end

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
        <button class="hide-button user-hide-button" onclick="toggleContent('#{anchor}')"></button>
        <div class="content user-content">
            #{rendered}
            #{linkproof}
        </div>
        </div>
      </div>
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
      setupSectionEnv(context,@level,"section")

      # Iterate over envs
      if context["envs"] != nil 
        context["envs"].each do |env|
          # Reset env counter when at specified level
          if @level == site.config[env]["countby"]
            context[env]["counter"] = 1
          end
        end
      end

      label_str,equrl,number_str,anchor = genRef(context,"section",@ref,level=@level)
      
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
  class ProofReference < Liquid::Tag
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

      # @envname = named['envname'] || positional[0]
      @label = named['label'] || positional[0]
      
      # Give error if @label or @envname are nil or empty 
    end
    def render(context)
      page = context.registers[:page]
      site = context.registers[:site]

      url = page['url']
      acronym = page['acronym']
      
      # envcounter = setupEnv(context,"proof")
      # anchor = "math-ref-#{@label}"
      setupEnv(context,"proof")
      label_str,equrl,number_str,anchor = genRef(context,"proof","#{@label}:proof")
    
      content = super 
      # Render any Liquid inside it
      template = Liquid::Template.parse(content)
      rendered = template.render(context)

      <<~HTML
      <proofenv anchor="#{anchor}">
      #{rendered}
      </proofenv>
      HTML

    end
  end
end

module Jekyll
  class Subequations < Liquid::Block
    def initialize(tag_name, markup, tokens)
      super

    end
    def render(context)   

      context["subequation"] = true
      context["equation"]["subcounter"] = 0

      content = super 
      # Render any Liquid inside it
      template = Liquid::Template.parse(content)

      rendered = template.render(context)
      context["subequation"] = false

      return rendered

    end
  end
end


module Jekyll
  class ProofRef < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super

      unless valid_param_order?(markup)
        raise SyntaxError, 
          "Positional arguments must come before named arguments"
      end
      
      positional, named = parse_params(markup)

      # @envname = named['envname'] || positional[0]
      @label = named['label'] || positional[0]
      
      # Give error if @label id nil or empty 
    end

    def render(context)
      
      <<~HTML
      <prooflabel>
      math-ref-#{@label}:proof
      </prooflabel>
      HTML

    end
  end
end

def split_equations(content)
  equations = []
  
  # Find all environment boundaries to exclude labels inside them
  env_pattern = /\\begin\{([a-zA-Z0-9_-]+)\}.*?\\end\{\1\}/m
  ranges = []
  content.scan(env_pattern) do
    ranges << (Regexp.last_match.begin(0)..Regexp.last_match.end(0))
  end

  idx_last = 0
  idx = 0
  content.scan(/\\\\/) do
    match = Regexp.last_match
    idx = match.offset(0)[1]
    
    # Check if "\\" is inside any environment
    inside = ranges.any? { |range| range.cover?(idx) }
    
    # Add only the equations that are not inside
    unless inside
      equations << content[idx_last...idx]
      idx_last = match.offset(0)[0]
    end
  end

  equations << content[idx...]

  return equations
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
      # @subequation = (named['subequation'] || positional[1]) == "true"
      # Give error if @label is nil or empty 
    end
    def render(context)
      
      @subequation = context["subequation"]
      setupEnv(context,"equation")

      if @subequation
        context["equation"]["subcounter"] ||= 0         
      else 
        context["equation"]["subcounter"] = 0 
      end

      label_str,equrl,number_str,anchor = genRef(context,"equation",@label,level=nil,subeq=@subequation)

      label_str_p = "(#{label_str})"

      if @subequation
        context["equation"]["subcounter"] += 1
      else
        context["equation"]["counter"] += 1
      end
      content = super
      
      <<~HTML
        <div class="equation-group">
        <div class="single-equation">
            <div class="math" id="#{anchor}">
                $$#{content}\\notag$$
            </div>
            <div class='ocupa'></div>
            <div class="tag">
                <a href="#{equrl}" class="tag-link">#{label_str_p}</a>
            </div>
        </div>
        </div>
      HTML

    end
  end

  class AlignLabel < Liquid::Block
    def initialize(tag_name, markup, tokens)
      super
      
      unless valid_param_order?(markup)
        raise SyntaxError, 
          "Positional arguments must come before named arguments"
      end
      
      positional, named = parse_params(markup)

      labels = named['labels'] || positional[0]
      if labels
        @labels = labels.split(";")
      else
        @labels = []
      end
    end
    def render(context)
      
      @subequation = context["subequation"]

      setupEnv(context,"equation")

      if @subequation
        context["equation"]["subcounter"] ||= 0         
      else 
        context["equation"]["subcounter"] = 0 
      end

      content = super
      
      # Split each equation by \\
      # equations = content.split(/\\\\/)
      equations = split_equations(content)
      
      html = ""
      equations.each_with_index do |eq,idx|
        label_str,equrl,number_str,anchor = genRef(context,"equation",@labels[idx],level=nil,subeq=@subequation)
        label_str_p = "(#{label_str})"
        if @subequation
          context["equation"]["subcounter"] += 1
        else
          context["equation"]["counter"] += 1
        end

        html <<
        <<~HTML
        <div class="single-equation">
            <div class="math" id="#{anchor}">
                $$#{eq}\\notag$$
            </div>
            <div class='ocupa'></div>
            <div class="tag">
                <a href="#{equrl}" class="tag-link">#{label_str_p}</a>
            </div>
        </div>
        HTML
      end
      
      <<~HTML  
        <div class="equation-group">
          #{html}
        </div>
      HTML

    end
  end

  class GridEquations < Liquid::Block
    def initialize(tag_name, markup, tokens)
      super
      
      unless valid_param_order?(markup)
        raise SyntaxError, 
          "Positional arguments must come before named arguments"
      end
      
      positional, named = parse_params(markup)

      labels = named['labels'] || positional[0]
      @ncols = (named['ncols'] || positional[1]).to_i # Number of columns
      # puts "@ncols"
      # puts @ncols
      @ncols = 1 if @ncols == 0 || @ncols == nil
      if labels
        @labels = labels.split(";")
      else
        @labels = []
      end
      @rowsubequations = true # Each row is a subequation
    end
    def render(context)
      
      setupEnv(context,"equation")

      if @rowsubequations
        context["equation"]["subcounter"] = 0        
        @subequation = true
      end

      content = super
      
      # Split each equation by \\
      # equations = content.split(/\\\\/)
      equations = split_equations(content)
      
      # Get all the references
      refDict = []
      col = 0 # The index of column
      equations.each_with_index do |eq,idx|
        if col >= @ncols 
          col = 0  # Reset the column counter
          if @rowsubequations 
            # Reset the subcounter
            context["equation"]["subcounter"] = 0
            context["equation"]["counter"] += 1 # increment the main counter
          end
        end
        label_str,equrl,number_str,anchor = genRef(context,"equation",@labels[idx],level=nil,subeq=@subequation)
        refDict << { 
          label: label_str,
          url: equrl,
          number: number_str,
          anchor: anchor,
          equation: eq
        }
        if @rowsubequations
          context["equation"]["subcounter"] += 1
        else
          context["equation"]["counter"] += 1
        end
        col += 1
      end
      
      idx = 0
      html = ""
      while idx < refDict.length
        html << "<div class='single-equation'>"
        # Add all the equations in a row
        j = 0
        for i in 0...@ncols
          if idx < refDict.length
            html << %(<div class="math" id="#{refDict[idx][:anchor]}">$$#{refDict[idx][:equation]}\\notag$$</div>)
            html << "<div class='ocupa'></div>"
            j += 1
            idx += 1
          end
        end
        
        idx -= j
        
        # Add the tags in a row
        html << "<div class='tag'>("
        for i in 0...j
          # puts idx
          html << %(<a href="#{refDict[idx][:url]}" class="tag-link">#{refDict[idx][:label]}</a>,)
          idx += 1
        end
        html.chop! # Remove the last comma
        html << ")</div>" # Close tag
        html << "</div>\n" # Close single-equation       
      end
      
      # Put everything inside an equation group
      <<~HTML  
        <div class="equation-group">
          #{html}
        </div>
      HTML
    end
  end
end


def transform_path_to_tex(original_path)
  # Split into directory and filename
  dir = File.dirname(original_path)   # "_posts/path/to"
  file = File.basename(original_path, '.*')  # "post" (without .*)
  
  # Replace first directory component
  parts = dir.split('/')
  parts[0] = parts[0] + '.tex'  
  new_dir = parts.join('/')
  
  # Reconstruct with .tex extension
  "#{new_dir}/#{file}.tex"
end

module Jekyll
  class IncludeTex < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      
      unless valid_param_order?(markup)
        raise SyntaxError, 
          "Positional arguments must come before named arguments"
      end
      
      positional, named = parse_params(markup)
      location = named["location"]
          
    end
    def render(context)
      page = context.registers[:page]
      original_path = page['path']  # "_posts/path/to/post.md"
      tex_path = transform_path_to_tex(original_path)
      content = File.read(tex_path, encoding: 'utf-8')

      converted = parse_tex(content)

      # Render any Liquid inside it
      template = Liquid::Template.parse(converted)
      rendered = template.render(context)
      return rendered

    end
  end
end

module Jekyll
  class SideNoteTag < Liquid::Block
    @@counter = 0

    def initialize(tag_name, markup, tokens)
      super

      unless valid_param_order?(markup)
        raise SyntaxError, 
          "Positional arguments must come before named arguments"
      end
      positional, named = parse_params(markup)
      @highlight = named['highlight'] || positional[0]
      @label = named['label'] || positional[1]
      @title = named['title'] || positional[2]


      # @text = text.strip
    end

    def render(context)

      setupEnv(context,'side-note')
      label_str,url,number_str,anchor = genRef(context,'side-note',@label,level=nil,subeq=false,ref="note-ref-")
      context['side-note']["counter"] += 1;
      
      note_content = super

      # @@counter += 1
      
      # note_id = "note-#{@@counter}"
      note = {
        'id' => anchor,
        'label' => label_str,
        'url' => url,
        'content' => note_content,
        'title' => @title
      }
      
      highlighted = %(<span class="highlight" data-note="#{anchor}" onclick="toggleNote('#{anchor}')">#{@highlight}</span>)

      js = generate_javascript_notes(note)
      # Return the element together with the JavaScript
      <<~HTML
      #{highlighted}

      <script>
        #{js}
      </script>
      HTML
    end
  end
end


Liquid::Template.register_tag('align',Jekyll::AlignLabel)
Liquid::Template.register_tag('subequations',Jekyll::Subequations)
Liquid::Template.register_tag('section',Jekyll::Sectioning)
Liquid::Template.register_tag('envlabel', Jekyll::EnvLabel)
Liquid::Template.register_tag('ref',Jekyll::Reference)
Liquid::Template.register_tag('envproof', Jekyll::EnvProof)
Liquid::Template.register_tag('equation', Jekyll::EquationLabel)
Liquid::Template.register_tag('gridequations', Jekyll::GridEquations)
Liquid::Template.register_tag('repeat', Jekyll::Repeat)
Liquid::Template.register_tag('proofref', Jekyll::ProofRef)
Liquid::Template.register_tag('includetex', Jekyll::IncludeTex)
Liquid::Template.register_tag('sidenote', Jekyll::SideNoteTag)

# Function to create JavaScript from collected notes
def generate_javascript_notes(note)
  return "" if(!note) 
  
  escaped_content = note['content'].gsub('`', '\\`')
                                   .gsub('${', '\\${')
                                   .gsub("\n", '<br>')
  
  id = note['id'].gsub('-','_').gsub('.','_')
  <<~JS
    // Note #{note['id']}
    const noteElement#{id} = document.createElement('div');
    noteElement#{id}.id = '#{note['id']}';
    noteElement#{id}.className = 'side-note hidden';
    noteElement#{id}.innerHTML = \`
      <button class="close-btn" data-note="#{note['id']}" onclick="hideNote('#{note['id']}')">×</button>
      <h3><a href="#{note['url']}">#{note['label']}</a> #{note['title']}</h3>
      <p>#{escaped_content}</p>\`;
    document.getElementById('side-notes-container').appendChild(noteElement#{id});
  JS
end


def generate_sidenav(site)
  sidenav_items = site.posts.docs
    .reject { |post| post.data['title'] == 'Fetch' || post.data['title'] == 'Scroll' }
    .map do |post|
      <<~HTML
        <button class="dropdown-btn" onclick="fetchElements('#{post.url}',this)">
          #{post.data['title']}
          <span class="fa-caret-down">▼</span>
        </button>
        <div class="dropdown-container"></div>
      HTML
    end.join("\n")
  
  <<~HTML
    <div class="sidenav" id="sidenav">
      #{sidenav_items}
    </div>
  HTML
end


def AppendAllEnvStyles(site,post)
  envs = site.config["sciblog"]["envs"]
  content = envs.map do |key, value|
    # Add the default style 
    load_replace('_plugins/extra/default.css',".#{key}-box")
  end.join("\n")
  html = post.output
  html.sub!(/<\/body>/,"<style>#{content}</style></body>")
end

def createEnv(site,dict,name)
  # This must be executed after_init or pre_render
  countby = dict["countby"]
  proofname = dict["proofname"]
  level = count_sub_prefixes(countby)
  
  level = 0 if !countby or !level
  proofname = 'proof' if !proofname

  envdict = {}
  envdict["countby"] = level
  envdict["proofname"] = proofname

  site.config[name] = envdict
  site.config['envs'] ||= []
  site.config['envs'] << name
end

def createEnvs(site,envs)
  envs.each do |key, value|
    createEnv(site,value,key)
  end
end

def addEnvs(site)
  raise "No environment defined" if !site.config["sciblog"] or !site.config["sciblog"]["envs"]
  createEnvs(site,site.config["sciblog"]["envs"])
end



module ExtraPages
  class  ExtraPagesGenerator < Jekyll::Generator
    safe true

    def generate(site)
      baseurl = site.config['baseurl']+'/'
      
      js_content  = appendPostsUrlVar(site,"repeat.js")
      extra_content = getContentExtra()
      extra_posts_dir = File.expand_path("extra/posts", __dir__)
      
      generated_pages = []

      Dir.glob(File.join(extra_posts_dir, "*.html")).each do |html_file|
        html = File.read(html_file)
        html.sub!(/<div class="sidenav" id="sidenav">(.*?)<\/div>/m,generate_sidenav(site))
        html.sub!(/<startPage>/m,"'#{baseurl}'")

        html.sub!(/<\/body>/, "#{extra_content}</body>")
        html.sub!(/<\/body>/, "#{js_content}</body>")
        basename = File.basename(html_file, '.html')
        page = CategoryPage.new(site, basename,html,basename.capitalize)
        site.pages << page
        generated_pages << { title: basename.gsub('-', ' ').capitalize, url: page.url }
      end
      site.config['_generated_pages'] = generated_pages
    end
  end

  # Subclass of `Jekyll::Page` with custom method definitions.
  class CategoryPage < Jekyll::Page
    def initialize(site, basename, content,title="RAW")
      @site = site             # the current site instance.
      @base = site.source      # path to the source directory.
      @dir  = basename        # the directory the page will reside in.

      # All pages have the same filename, so define attributes straight away.
      @basename = 'index'      # filename without the extension.
      @ext      = '.html'      # the extension.
      @name     = 'index.html' # basically @basename + @ext.

      # Initialize data hash with a key pointing to all posts under current category.
      # This allows accessing the list in a template via `page.linked_docs`.
      
      @content = content
      @data = {
        'layout' => nil,
        'title' => title,
      }

    end

    # Placeholders that are used in constructing page URL.
    def url_placeholders
      {
        :path       => @dir,
        :category   => @dir,
        :basename   => basename,
        :output_ext => output_ext,
      }
    end
  end
end

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



def injectAtEndBody(post,content)
  if post.output_ext == ".html"
      post.output.sub!(/<\/body>/, "#{content}</body>")
      return true
  end
  return false
end

def injectAtBeginBody(post,content)
  if post.output_ext == ".html"
      post.output.sub!(/<body>/, "<body>#{content}")
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
      equrl,label,env = getRef(ref,keyenv)
      return equrl,label,env
    end
  end
  return nil,nil,nil
end

def refProof(proofurl,envurl,label,proofname,envname)
  <<~HTML
  <a style="color:red" href=#{proofurl}>#{proofname.capitalize}</a> of #{envname} <a href=#{envurl}>#{label}</a>
  HTML
end

def linkProof(site,key)
  ref = site.config['ref']
  envurl,label,env = proofCheck(ref,key)
  return nil if envurl == nil
  
  proofurl,_,_ = getRef(ref,key)
  proofname = site.config[env]['proofname']
  refProof(proofurl,envurl,label,proofname,env)
end

def setProof(post,site)
  html = post.output
  html = html.gsub(/<prooflabel>(.*?)<\/prooflabel>/m) do
    key = Regexp.last_match(1).strip
    
    html = linkProof(site,key)
    if(html)
      html
    else
      raise "Key #{key} does not exist"
    end
  end
  post.output = html
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
  post.output = html
end

def getEnvRef(ref,anchor)
  if anchor.end_with?(":proof")
    keyenv = anchor[0..-7]
    if ref.key?(keyenv)
      getRef(ref,keyenv)
    else 
      raise "Proof with anchor #{anchor} does not have env!"
    end
  else
    raise "Not a proof label"
  end
end

def generateProof(post,site)
  ref = site.config["ref"]
  html = post.output
  # Iterate and replace all <proofenv> tags
  html.gsub!(/<proofenv anchor="([^"]*)">(.*?)<\/proofenv>/m) do |match|
    anchor = $1      # Captures the anchor value
    content = $2     # Captures the content between tags
    
    # Get the ref of the proof and the corresponding env
    envurl,envlabel,envname = getEnvRef(ref,anchor)
    proofurl,prooflabel,proofname = getRef(ref,anchor)

    proofname = site.config[envname]['proofname']
    proof_ref_html = refProof(proofurl,envurl,envlabel,proofname,envname)

    id = "proof#{prooflabel.gsub('.','_').gsub('-','_')}"
        
    # The content with a toggle button inside
    <<~HTML
    <div class="#{envname}-box user-#{@envname}-box" id="#{anchor}">
    <div class='box'>
      <div class="header user-header">
      #{proof_ref_html}
      </div>
      <button class="hide-button user-hide-button" onclick="toggleContent('#{anchor}')"></button>
      <div class="content user-content">
          #{content}
      </div>
      </div>
    </div>

    HTML
  end
end

def getSideNotesExtra(filename='side-notes')
  plugin_dir = File.expand_path("extra", __dir__) 
  css_content = File.read(File.join(plugin_dir, "#{filename}.css"))
  js_content = File.read(File.join(plugin_dir, "#{filename}.js"))
 
  <<~HTML
  <script>#{js_content}</script>
  <style>#{css_content}</style>
  HTML
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

def getBalloonStyle()
  plugin_dir = File.expand_path("extra", __dir__)
  css_content = File.read(File.join(plugin_dir, "balloon.css"))
  
  <<~HTML
  <style>#{css_content}</style>
  HTML
end

# Get the latex commands 
def getLatexCommands()
  dir = File.expand_path("../",__dir__)
  filename = File.join(dir,"latex-commands.tex")
  return "" if !File.file?(filename)
  commands = File.read(filename)

  <<~HTML
  <div style="display:none">
  $$
  #{commands}
  $$
  </div>
  HTML
end

Jekyll::Hooks.register :site, :post_render do |site|
  js_content  = appendPostsUrlVar(site,"repeat.js")
  extra_content = getContentExtra()
  commands = getLatexCommands()
  ballon_style = getBalloonStyle()
  # side_notes_extra = getSideNotesExtra()
  # side_notes_extra.sub!("GENERATED_JAVASCRIPT",generate_javascript_notes(site))
  # puts commands
  ref = site.config['ref']

  # Iterate over all posts
  site.posts.docs.each do |post|
    if post.output_ext == ".html"
      setRepeat(post,ref)
      setReference(post,ref)
      setProof(post,site)
      generateProof(post,site)
      injectAtEndBody(post,js_content)
      injectAtEndBody(post,extra_content)
      injectAtBeginBody(post,commands)
      injectAtBeginBody(post,ballon_style)
      # injectAtBeginBody(post,side_notes_extra)
      AppendAllEnvStyles(site,post)
    end
  end
end

Jekyll::Hooks.register :site, :after_init do |site|
  # Set variables for all the posts
  addEnvs(site)
end

module Jekyll
  # Inject into index.html after rendering
  Jekyll::Hooks.register [:pages], :post_render do |page|
    if page.name == 'index.html' || page.name == 'index.markdown'
      generated_pages = page.site.config['_generated_pages']
      
      next if page.data["title"] == "Fetch" || page.data["title"] == "Split" 

      if generated_pages && generated_pages.any?
        page_list_html = generate_page_list_html(generated_pages)
        
        # Append to the begining of the post lists
        page.output.sub!(/<ul class="post-list">/, %(<ul class="post-list">#{page_list_html}))
      end
    end
  end
  
  def self.generate_page_list_html(pages)
    items = pages.map do |p|
      <<~HTML
        <li><span class="post-meta">Auto generated post</span>
        <h3>
          <a class="post-link" href="#{p[:url]}">
            #{p[:title]}
          </a>
        </h3></li>
      HTML
    end.join("\n")
    
  end
end

