module Jekyll
  class Sectioning < Liquid::Tag
    def initialize(tag_name,text,tokens)
      super

      args = text.split(' ')
      @header = args[0] || ""
      @level = args[1].to_i || 0
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

      number_str = " "

      context["section"]["counter"].each_with_index do |element,index|
        break if index > @level
        if element == nil
          context["section"]["counter"][index] = 0
        end
        number_str += context["section"]["counter"][index].to_s + "." 
      end
    
      return "\#"*(@level +1) + number_str + " #{@header}"

    end
  end
end

Liquid::Template.register_tag('section',Jekyll::Sectioning)



