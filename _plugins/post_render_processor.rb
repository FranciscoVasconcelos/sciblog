# This hook runs after each page/post has been fully rendered (Liquid + layout)
Jekyll::Hooks.register [:pages, :documents], :post_render do |item|
  # item.output contains the final HTML string
  html = item.output

  # Get the site object
  site = item.site

  # Access _config.yml data
  config = site.config

    
  # puts config["ref"]
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
  
  # Assign the modified HTML back to the output
  item.output = html

  # Optional: log what’s happening (appears in build output)
  Jekyll.logger.info "PostRender:", "Processed #{item.relative_path}"
end
