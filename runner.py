#!/usr/bin/env python
import sys
import os
import importlib.util
from pathlib import Path

def run_script_and_save(script_path, output_path):
    """
    Run a Python script and save its data_out variable if it exists.
    
    Args:
        script_path: Path to the script to execute
        output_filename: Name of the file to save data_out to
    """
    # Check if script exists
    if not os.path.exists(script_path):
        print(f"Error: Script '{script_path}' not found")
        return False
    
    # Load and execute the script
    spec = importlib.util.spec_from_file_location("dynamic_script", script_path)
    module = importlib.util.module_from_spec(spec)
    
    try:
        spec.loader.exec_module(module)
    except Exception as e:
        print(f"Error executing script: {e}")
        return False
    
    # Check if data_out exists in the executed script
    if not hasattr(module, 'data_out'):
        print(f"Warning: 'data_out' variable not found in {script_path}")
        return False
    
    # Get data_out
    data_out = module.data_out
    
    try:
        if output_path.endswith('.msgpack'):
            import msgpack
            with open(output_path, 'wb') as f:
                msgpack.pack(data_out, f)
        elif output_path.endswith('.json'):
            import json
            with open(output_path, 'w') as f:
                json.dump(data_out, f, indent=2)
        elif output_path.endswith('.txt'):
            with open(output_path, 'w') as f:
                f.write(str(data_out))
        else:
            # Default: try to write as text
            with open(output_path, 'w') as f:
                f.write(str(data_out))
        
        print(f"Success: data_out saved to {output_path}")
        return True
    
    except Exception as e:
        print(f"Error saving data: {e}")
        return False

def rewrite_path(script_path, output_filename):
    """
    Rewrite a path like path/to/_posts/path/to/script.py
    to path/to/_posts.msgpack/path/to/output_filename
    
    Args:
        script_path: Original script path containing _posts
        output_filename: Desired output filename
    
    Returns:
        The rewritten path
    """
    # Normalize the path
    script_path = os.path.normpath(script_path)
    
    # Find _posts in the path
    parts = script_path.split(os.sep)
    
    if '_posts' not in parts:
        raise ValueError(f"Error: '_posts' not found in path: {script_path}")
    
    # Find the index of _posts
    posts_index = parts.index('_posts')
    
    # Split the path at _posts
    before_posts = parts[:posts_index]  # path/to
    after_posts = parts[posts_index + 1:-1]  # path/to (excluding script.py)
    
    # Reconstruct the new path
    new_parts = ['/'] + before_posts + ['_posts.msgpack'] + after_posts + [output_filename]
    new_path = os.path.join(*new_parts) if new_parts else output_filename
    
    return new_path

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <script_name> <output_filename>")
        print("Example: python runner my_script.py output.msgpack")
        sys.exit(1)
    
    script_name = sys.argv[1]
    filename = sys.argv[2]
    
    # Change the directory where the output data is going to be saved 
    script_path = os.path.abspath(script_name)
    filename = rewrite_path(script_path,filename)
    
    # Create the directories if they do not exist
    file_path = Path(filename)
    file_path.parent.mkdir(parents=True, exist_ok=True)

    print(script_path)
    print(filename)

    run_script_and_save(script_name, filename)
