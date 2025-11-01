# Convert LaTeX environments and commands to Liquid tags in Markdown files.

# require 'debug'  # Must be at the top or before code you want to debug
require 'fileutils'

$section_pattern = /\\(section|subsection|subsubsection|paragraph|subparagraph)\{([^}]+)\}/
$label_pattern = /\\label\{([^}]+)\}/
# $env_pattern = /\\begin\{(?<name>[a-zA-Z0-9_-]+)\}(?<content>.*?)\\end\{\k<name>\}/m
$env_pattern = /
  \\begin\{(?<name>[a-zA-Z0-9_-]+)\}        # environment name
  (?:\[(?<options>[^\]]*)\])?                # optional [options]
  (?<content>.*?)                           # environment content
  \\end\{\k<name>\}                         # matching \end{...}
/mxs

$section_levels = {
  'section' => 1,
  'subsection' => 2,
  'subsubsection' => 3,
  'paragraph' => 4,
  'subparagraph' => 5
}

def find_pattern_exclude_bounds(content,bounds,pattern)
  # Sort bounds by start position
  bounds.sort_by! { |start, _| start }

  # Create list of allowed ranges
  allowed_ranges = []
  prev_end = 0

  bounds.each do |start, finish|
    allowed_ranges << [prev_end, start] if prev_end < start
    prev_end = finish
  end

  # Don't forget the last segment
  allowed_ranges << [prev_end, content.length] if prev_end < content.length

  matches = []

  # Search in each allowed range
  allowed_ranges.each do |start, finish|
    segment = content[start...finish]
    segment.scan(pattern) do
      match = Regexp.last_match
      matches << match[1]
    end
  end
  return matches
end

def parse_recursive(content)

  bounds = [] # The env bounds to ignore
  matches = []
  content.scan($section_pattern) do |match|
    match_data = Regexp.last_match
    matches << {
      text: match_data[0],
      start: match_data.offset(0)[0],
      end: match_data.offset(0)[1],
      type: match[0],
      header: match[1]
    }
  end
  
  # Create a copy
  cleaned_content_out = ""

  tag_head = nil
  if matches.length > 0
    matches.each_with_index do |match,idx|
      # puts "Parsing content #{idx}"
      if idx < matches.length-1
        labels, cleaned_content = parse_recursive(content[match[:end]...(matches[idx+1][:start])])
        bounds << [match[:end],matches[idx+1][:start]]
      else
        labels, cleaned_content = parse_recursive(content[match[:end]...])
        bounds << [match[:end],content.length-1]
      end
      tag_head = %({% section level=#{$section_levels[match[:type]]} header=\"#{match[:header]}\" #{labels} %})
      cleaned_content_out += %(#{tag_head}\n#{cleaned_content})
      # puts match[1]
    end
  else
    matches = []
    content.scan($env_pattern) do
      match = Regexp.last_match
      matches << {
        envname: match[:name],
        cnt: match[:content],
        options: match[:options],
        idx_cnt_start: match.offset(3)[0],
        idx_cnt_end: match.offset(3)[1],
        idx_start: match.offset(0)[0],
        idx_end: match.offset(0)[1],
      }
    end 
    matches.each_with_index do |match,idx|
      bounds << [match[:idx_cnt_start],match[:idx_cnt_end]]
      labels, cleaned_content = parse_recursive(match[:cnt])
      env_name = match[:envname]

      opening_tag = "{% #{env_name} #{labels} #{match[:options]} %}"
      closing_tag = "{% end#{env_name} %}"
      
      cleaned_content_out += %(#{opening_tag}\n#{cleaned_content}\n#{closing_tag}\n)

      # In between content 
      if idx+1 < matches.length
        cleaned_content_out += content[match[:idx_end]...(matches[idx+1][:idx_start])]
      end
    end
    if matches.length > 0
      # Add the last segment of content
      cleaned_content_out += content[(matches[-1][:idx_end])...]
    end
  end

  # No environment found
  if matches.length == 0
    cleaned_content_out = content
  end

  # Find all label matches 
  labels = find_pattern_exclude_bounds(content,bounds,$label_pattern)
  tag_part = ""
  if labels.length > 1 
    tag_part = %(labels=\"#{labels.join(";")}\")
  elsif labels.length == 1
    tag_part = %(label=#{labels[0]})
  end
  return tag_part,cleaned_content_out
end

def parse_tex(content)
  tag_part,content = parse_recursive(content)
  # Remove all labels from the content
  content = convert_latex_commands(content)
  content.gsub!($label_pattern,"")
  return content
end




def convert_latex_commands(content)

  liquid_commands = {"ref"=>"ref"}

  commands_pattern = /\\(ref)\{([^}]+)\}/
  content.gsub!(commands_pattern).each do |match|
    command = $1
    argument = $2
    liquid_command = liquid_commands[command]
    "{% #{liquid_command} #{argument} %}"
  end
  return content
end




=begin
# Usage: ruby parse_tex.rb myfile.tex

# Check if a filename is given
if ARGV.empty?
  puts "Usage: ruby #{__FILE__} filename.tex"
  exit 1
end

filename = ARGV[0]

# Check file exists
unless File.exist?(filename)
  puts "File not found: #{filename}"
  exit 1
end

# Read the entire file
content = File.read(filename)
parse_tex(content)
=end
