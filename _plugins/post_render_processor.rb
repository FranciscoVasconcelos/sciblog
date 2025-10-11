# This hook runs after each page/post has been fully rendered (Liquid + layout)
Jekyll::Hooks.register [:pages, :documents], :post_render do |item|
  # item.output contains the final HTML string
  html = item.output

  # Get the site object
  site = item.site

  # Access _config.yml data
  config = site.config

  # Example: read a setting from _config.yml
  # custom_value = config['my_setting']
  
  # puts config["eqlabel"]
  eqlabel = config['eqlabel']

  html = html.gsub(/<mathlabel>(.*?)<\/mathlabel>/m) do
    inner = Regexp.last_match(1).strip
    # Check if inner key exists
    if eqlabel.key?(inner)
      equrl = eqlabel[inner]['url']
      label = "(#{eqlabel[inner]['label']})"
      # Return an anchor
      %(<a style="color:blue" href="#{equrl}">#{label}</a>)
    end
  end
  # Example: wrap every <h1> in a div
  # html = html.gsub(/(<h1>.*?<\/h1>)/, '<div class="header-wrapper">\1</div>')

  # Assign the modified HTML back to the output
  item.output = html

  # Optional: log what’s happening (appears in build output)
  Jekyll.logger.info "PostRender:", "Processed #{item.relative_path}"
end
