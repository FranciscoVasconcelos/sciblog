module Jekyll
  class EquationLabel < Liquid::Block
    def initialize(tag_name, markup, tokens)
      super
      # markup contains everything after the tag name
      args = markup.strip.split(/\s+/)
      @label = args[0]
    end
    def render(context)
      page = context.registers[:page]
      post = context.registers[:post]
      site = context.registers[:site]

      url  = page['url']
      acronym = page['acronym']
      sec_counter = context["section_counter"][0] || 0
      
      context["equation_counter"] ||= 1
      eq_counter = context["equation_counter"]

      label_str = acronym + "-" + sec_counter.to_s + "." + eq_counter.to_s
      equrl = url+"\#"+ "math-eqref-#{@label}"
      label_str_p = "(#{label_str})"
      eqlabel = {"url"=> url+"\#"+ "math-eqref-#{@label}","label"=>label_str}

      # page['FUCKKKKK'] = "??????"

      # page["data"] ||= {}
      site.config["eqlabel"] ||= {}
      site.config["eqlabel"]["math-ref-#{@label}"] = eqlabel
      
      # page['data'] = "teststes"
      # puts page['data']
      context["equation_counter"] += 1
      content = super
      
      <<~HTML
      <div id="math-eqref-#{@label}">
        <div style="float:left">$#{content}$</div>
        <a style="float:right; color:green" href="#{equrl}">#{label_str_p}</a>
      </div>
      <br />
      HTML
    end

  end
end

Liquid::Template.register_tag('equation', Jekyll::EquationLabel)
