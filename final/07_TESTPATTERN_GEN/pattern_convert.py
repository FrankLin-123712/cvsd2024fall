import re

def extract_pattern_data(content):
    # Find the pattern array in the content
    pattern_match = re.search(r'const pattern_t test_patterns \[NUM_PATTERNS-1:0\] = \'\{(.*?)\};', content, re.DOTALL)
    if not pattern_match:
        return None
    
    # Extract individual pattern entries
    pattern_entries = pattern_match.group(1).strip().split('},')
    patterns = []
    
    for entry in pattern_entries:
        if not entry.strip():
            continue
            
        # Extract input_data and golden_data using regex
        input_match = re.search(r"768'h([0-9a-f]+)", entry)
        golden_match = re.search(r"512'h([0-9a-f]+)", entry)
        
        if input_match and golden_match:
            patterns.append({
                'input_data': input_match.group(1),
                'golden_data': golden_match.group(1)
            })
    
    return patterns

def generate_package_content(pattern_num, pattern):
    # Add 103 to the pattern number
    actual_num = pattern_num + 103
    template = "package dat_{0};\n" + \
              "integer pat_num = {0};\n" + \
              "reg [767:0] input_data  = 768'h{1};\n" + \
              "reg [511:0] golden_data = 512'h{2};\n" + \
              "endpackage\n\n"
    return template.format(actual_num, pattern['input_data'], pattern['golden_data'])

def convert_patterns(input_content):
    # Extract patterns from input content
    patterns = extract_pattern_data(input_content)
    if not patterns:
        return "Error: Could not extract patterns from input content"
    
    # Generate output content
    output = ""
    for i, pattern in enumerate(patterns):
        output += generate_package_content(i, pattern)
    
    return output

def process_file(input_file, output_file):
    try:
        with open(input_file, 'r') as f:
            input_content = f.read()
        
        output_content = convert_patterns(input_content)
        
        with open(output_file, 'w') as f:
            f.write(output_content)
        print("Successfully converted patterns to " + output_file)
        print("Packages are numbered from dat_103 to dat_202")
    except Exception as e:
        print("Error processing files: " + str(e))

if __name__ == "__main__":
    process_file('tb_dat_hidden.sv', 'output.sv')