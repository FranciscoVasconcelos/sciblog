module Jekyll
  class Reference < Liquid::Tag
    def initialize(tag_name,markup,tokens)
      super

      args = markup.strip.split(/\s+/)
      @label = args[0]
    end

    def render(context)
      # page = context.registers[:page]
      # # eqlabel = context.registers[:eqlabel]["math-eqref-#{@label}"]
      # # label_str_p = "(#{eqlabel['label']})"
      # # equrl = eqlabel['url']
      # # puts page['data'][:eqlabel]
      # site = context.registers[:site]  # Jekyll::Site object
      # output = []
      #
      # equrl = ""
      # label_str_p = ""
      #
      # if site.config["eqlabel"] != nil
      #   dict = site.config["eqlabel"]["math-eqref-#{@label}"]
      #   label_str_p = "(#{dict['label']})"
      #   equrl = dict['url']
      # end

      # # Look for Reference in all posts 
      # site.posts.docs.each do |post|
      #   # title = page['title']
      #   puts post.url
      #   # puts post.methods
      #   eqlabel = post.data["eqlabel"]
      #   if eqlabel != nil
      #     puts eqlabel
      #     # Check if key exists in the current post
      #     if eqlabel.key?("math-eqref-#{@label}")
      #       dict = eqlabel["math-eqref-#{@label}"]
      #       label_str_p = "(#{dict['label']})"
      #       equrl = dict['url']
      #       puts equrl 
      #       puts label_str_p
      #       break
      #     end
      #   end
      #
      #   # puts post.data["eqlabel"]
      #   # url   = page.url
      #   # date  = post.data['date']
      #   # if page['data'] != nil
      #   #   puts page['data'][:eqlabel]
      #   # end
      #   # return ""
      #
      # end

      <<~HTML
      <mathlabel>math-eqref-#{@label}</mathlabel>
      HTML

      # output.join("<br>")
      # return ""
      # <<~HTML
      #   <a style="color:blue" href="#{equrl}">#{label_str_p}</a>
      # HTML

    end
  end
end

Liquid::Template.register_tag('ref',Jekyll::Reference)


