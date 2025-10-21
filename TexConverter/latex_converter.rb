#!/usr/bin/env ruby
# frozen_string_literal: true

# Convert LaTeX environments and commands to Liquid tags in Markdown files.
# Usage: ruby convert_latex_to_liquid.rb input.md output.md

require 'fileutils'

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
      opening_tag = "{% sectioning level=#{section_levels[section[:type]]} title=\"#{section[:title]}\" label=\"#{section_label}\" %}"
    else
      opening_tag = "{% sectioning  level=#{section_levels[section[:type]]} title=\"#{section[:title]}\" %}"
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
    
    opening_tag = "{% #{tag_parts.join(' ')} %}"
    closing_tag = "{% end#{env_name} %}"

    %(#{opening_tag}\n#{cleaned_content}\n#{closing_tag})
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

# Main execution
if ARGV.length < 2
  puts 'Usage:'
  puts '  Single file: ruby convert_latex_to_liquid.rb input.md output.md'
  puts '  Directory:   ruby convert_latex_to_liquid.rb input_dir/ output_dir/'
  exit 1
end

input_arg = ARGV[0]
output_arg = ARGV[1]

if File.file?(input_arg)
  process_file(input_arg, output_arg)
elsif File.directory?(input_arg)
  process_directory(input_arg, output_arg)
else
  warn "Error: #{input_arg} is not a valid file or directory"
  exit 1
end
