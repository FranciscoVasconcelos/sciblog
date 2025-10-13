module Jekyll
  class EnvLabel < Liquid::Block
    def initialize(tag_name, markup, tokens)
      super
      # markup contains everything after the tag name
      args = markup.strip.split(/\s+/)
      @envname = args[0]
      @label = args[1]
      @proof = args[2] == "true"
    end
    def render(context)
      page = context.registers[:page]
      site = context.registers[:site]

      url  = page['url']
      acronym = page['acronym']
      
      # Create a number for the env
      number_str = ""
      context["section"]["counter"].each_with_index do |element,index|
        break if index > context[@envname]["countby"]
        if element == nil
          context["section"]["counter"][index] = 0
        end
        # append the counter number to the string
        number_str += context["section"]["counter"][index].to_s + "." 
      end

      context[@envname]["counter"] ||= 1
      envcounter = context[@envname]["counter"]
      

      anchor = "math-ref-#{@label}"
      id = "#{@envname}#{number_str.gsub('.','_')}" # Define a unique id

      label_str = acronym + "-" + number_str + envcounter.to_s
      equrl = url + "\#" + anchor
      ref = {"url"=> equrl,"label"=>label_str}

      # Store ref in the global config
      site.config["ref"] ||= {}
      site.config["ref"][anchor] = ref
 
      seeproof = ""

      if @proof 
        proofname = context[@envname]['proofname']
        seeproof = 
        <<~HTML
        See #{proofname} <a href="#{equrl}:proof">here</a>.
        HTML
      end

      # Iterate config 
      context[@envname]["counter"] += 1
      content = super
           
      # The content with a toggle button inside
      <<~HTML
      <div class="#{@envname}-box" id="#{anchor}">
      <div class='box'>
        <div class="header">
            #{@envname.capitalize}<a href="#{equrl}">&nbsp;#{label_str}</a>
        </div>
        <button class="hide-button" onclick="toggleContent#{id}()"></button>
        <div class="content">
            #{content}
        </div>
        #{seeproof}
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

Liquid::Template.register_tag('envlabel', Jekyll::EnvLabel)



