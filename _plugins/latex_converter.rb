#!/usr/bin/env ruby
# frozen_string_literal: true

# Convert LaTeX environments and commands to Liquid tags in Markdown files.
# Usage: ruby convert_latex_to_liquid.rb input.md output.md

require 'fileutils'

$section_pattern = /\\(section|subsection|subsubsection|paragraph|subparagraph)\{([^}]+)\}/
$label_pattern = /\\label\{([^}]+)\}/
$env_pattern = /\\begin\{(?<name>[a-zA-Z0-9_-]+)\}(?<content>.*?)\\end\{\k<name>\}/m
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
    # puts ""
    # puts start
    # puts finish
    # puts content.length
    segment = content[start...finish]
    segment.scan(pattern) do
      match = Regexp.last_match
      # Adjust index to be relative to original content
      # absolute_index = start + match.offset(0)[0]
      # puts "Found match at index #{start+match.offset(0)[0]}: #{match[0]}"
      matches << match[1]
    end
  end
  return matches
end

def parse_recursive(content)

  # puts content 
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
    content.scan($env_pattern) do
      match = Regexp.last_match
      env_name = match[:name]
      matched_content = match[:content]
      bounds << [match.offset(2)[0],match.offset(2)[1]]
      # puts "Parsing content of #{env_name}"
      labels, cleaned_content = parse_recursive(matched_content)

      if (env_name == 'align') || (env_name == 'equation')
        opening_tag = "{% #{env_name} #{labels} %}"
        closing_tag = "{% end#{env_name} %}"
      else
        opening_tag = "{% envlabel #{env_name} #{labels} %}"
        closing_tag = "{% endenvlabel %}"
      end

      cleaned_content_out += %(#{opening_tag}\n#{cleaned_content}\n#{closing_tag}\n)
    end
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
  # puts tag_part
end


# Convert LaTeX section commands with labels to Liquid tags
def convert_sections_to_liquid(content)
  # Define section hierarchy
  section_levels = {
    'section' => 1,
    'subsection' => 2,
    'subsubsection' => 3,
    'paragraph' => 4,
    'subparagraph' => 5
  }

  # Find all sections and their positions
  section_pattern = /\\(section|subsection|subsubsection|paragraph|subparagraph)\{([^}]+)\}/
  label_pattern = /\\label\{([^}]+)\}/

  sections = []
  content.scan(section_pattern).each do |match|
    type, title = match
    pos = content.index("\\#{type}{#{title}}")
    sections << {
      type: type,
      title: title,
      start: pos,
      end: pos + "\\#{type}{#{title}}".length,
      level: section_levels[type]
    }
  end

  # Find all environment boundaries to exclude labels inside them
  env_pattern = /\\begin\{([a-zA-Z0-9_-]+)\}.*?\\end\{\1\}/m
  env_ranges = []
  content.scan(env_pattern) do
    env_ranges << (Regexp.last_match.begin(0)..Regexp.last_match.end(0))
  end

  # Find all labels that are NOT inside environments
  labels = []
  content.to_enum(:scan, label_pattern).each do
    label = Regexp.last_match[1]
    pos = Regexp.last_match.begin(0)
    
    # Check if this label is inside any environment
    inside_env = env_ranges.any? { |range| range.cover?(pos) }
    
    unless inside_env
      labels << {
        label: label,
        start: pos,
        end: pos + "\\label{#{label}}".length
      }
    end
  end

  return content if sections.empty?

  # Build the converted content
  result = []
  last_pos = 0

  sections.each_with_index do |section, i|
    # Add content before this section
    result << content[last_pos...section[:start]]

    # Find the label for this section
    section_label = nil
    section_content_end = nil

    # Look for label within reasonable distance
    search_end = section[:end] + 500
    search_end = [search_end, sections[i + 1][:start]].min if i + 1 < sections.length

    labels.each do |label|
      if section[:end] <= label[:start] && label[:start] < search_end
        section_label = label[:label]
        section_content_end = label[:start]
        break
      end
    end

    # Determine where this section ends
    if section_content_end.nil?
      # Find next section of same or higher level
      sections[(i + 1)..-1].each do |next_section|
        if next_section[:level] <= section[:level]
          section_content_end = next_section[:start]
          break
        end
      end

      section_content_end = content.length if section_content_end.nil?
    end

    # Extract section content
    if section_label
      label_obj = labels.find { |l| l[:label] == section_label }
      section_text = content[section[:end]...label_obj[:start]]
      last_pos = label_obj[:end]
    else
      section_text = content[section[:end]...section_content_end]
      last_pos = section[:end]
    end

    # Build the Liquid tag with named parameters
    if section_label
      opening_tag = "{% section level=#{section_levels[section[:type]]} header=\"#{section[:title]}\" label=\"#{section_label}\" %}"
    else
      opening_tag = "{% section  level=#{section_levels[section[:type]]} header=\"#{section[:title]}\" %}"
    end

    result << opening_tag
    result << section_text

    # Check if we need to close this section before the next one
    if i + 1 < sections.length
      next_section = sections[i + 1]
    end
  end

  # Add any remaining content
  result << content[last_pos..-1]

  result.join
end

# Convert LaTeX environments to Liquid tags
def convert_latex_to_liquid(content)
  # Pattern to match \begin{envname} or \begin{envname}[params]
  pattern = /\\begin\{([a-zA-Z0-9_-]+)\}(?:\[([^\]]*)\])?(.*?)\\end\{\1\}/m

  content.gsub(pattern) do |match|
    env_name = Regexp.last_match(1)
    params = Regexp.last_match(2)
    env_content = Regexp.last_match(3)

    # Find all \label commands inside this environment
    label_pattern = /\\label\{([^}]+)\}/
    env_labels = []
    
    env_content.scan(label_pattern) do |label_match|
      env_labels << label_match[0]
    end
    
    # Remove all labels from the content
    cleaned_content = env_content.gsub(label_pattern, '').strip

    # Recursively process nested environments
    cleaned_content = convert_latex_to_liquid(cleaned_content)

    # Build the Liquid tag with labels if present
    tag_parts = [env_name]
    tag_parts << params if params
    
    # Add labels as comma-separated list
    unless env_labels.empty?
      labels_str = env_labels.join(';')
      tag_parts << "labels=\"#{labels_str}\""
    end
    
    if (env_name == 'align') || (env_name == 'equation')
      opening_tag = "{% #{tag_parts.join(' ')} %}"
      closing_tag = "{% end#{env_name} %}"
    else
      opening_tag = "{% envlabel #{tag_parts.join(' ')} %}"
      closing_tag = "{% endenvlabel %}"
    end

    %(#{opening_tag}\n#{cleaned_content}\n#{closing_tag})
  end
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
end

# Process a single file
def process_file(input_path, output_path)
  content = File.read(input_path, encoding: 'utf-8')

  # First convert sections, then environments
  converted = convert_sections_to_liquid(content)
  converted = convert_latex_to_liquid(converted)

  File.write(output_path, converted, encoding: 'utf-8')

  puts "✓ Converted: #{input_path} -> #{output_path}"
  true
rescue StandardError => e
  warn "✗ Error processing #{input_path}: #{e.message}"
  false
end

# Process all markdown files in a directory
def process_directory(input_dir, output_dir)
  FileUtils.mkdir_p(output_dir)

  md_files = Dir.glob(File.join(input_dir, '**', '*.md'))

  if md_files.empty?
    puts "No markdown files found in #{input_dir}"
    return
  end

  success_count = 0
  md_files.each do |md_file|
    # Preserve directory structure
    relative_path = md_file.sub(/^#{Regexp.escape(input_dir)}\//, '')
    output_file = File.join(output_dir, relative_path)

    # Create subdirectories if needed
    FileUtils.mkdir_p(File.dirname(output_file))

    success_count += 1 if process_file(md_file, output_file)
  end

  puts "\n#{success_count}/#{md_files.length} files converted successfully"
end


