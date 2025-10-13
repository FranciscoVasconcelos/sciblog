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

Liquid::Template.register_tag('envproof', Jekyll::EnvProof)



