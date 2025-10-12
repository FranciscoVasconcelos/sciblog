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

Liquid::Template.register_tag('ref',Jekyll::Reference)


