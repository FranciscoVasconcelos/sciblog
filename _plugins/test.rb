
def load_replace(filename, replacement)
  # Read the file content
  content = File.read(filename)
  
  # Replace all occurrences of 'pretty-box' with the replacement string
  content.gsub('pretty-box', replacement)
rescue Errno::ENOENT
  puts "Error: File '#{filename}' not found"
  nil
rescue => e
  puts "Error reading file: #{e.message}"
  nil
end
