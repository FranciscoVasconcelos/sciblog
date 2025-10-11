module Jekyll
  class Sectioning < Liquid::Tag
    def initialize(tag_name,text,tokens)
      super

      args = text.split(' ')
      @header = args[0] || ""
      @level = args[1].to_i || 0
    end

    def render(context)

      # Create counter for each section level
      context["section_counter"] ||= Array.new
      
      # Initialize counter if empty
      context["section_counter"][@level] ||= 0
      
      # increment counter
      context["section_counter"][@level] += 1

      # Reset equation counter when at level 0
      if @level == 0
        context["equation_counter"] = 1
      end


      number_str = " "

      context["section_counter"].each_with_index do |element,index|
        break if index > @level
        if element == nil
          context["section_counter"][index] = 0
        end
        number_str += context["section_counter"][index].to_s + "." 
      end
    
      return "\#"*(@level +1) + number_str + " #{@header}"

    end
  end
end

Liquid::Template.register_tag('section',Jekyll::Sectioning)



