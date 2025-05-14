def hex_to_binary_list(hex_str):
    """Convert hexadecimal string to binary list with three trailing zeros"""
    try:
        # Convert hex to integer
        num = int(hex_str, 16)
        # Convert to binary string
        binary = bin(num)[2:]  # Remove '0b' prefix
        # Add trailing zeros
        binary = binary + "000"
        # Convert to list of integers and reverse for coefficient order
        return [int(bit) for bit in reversed(binary)]
    except ValueError:
        raise ValueError(f"Invalid hexadecimal input: {hex_str}")

def parse_input(input_str, is_hex=True):
    """Parse input string to coefficients list"""
    if is_hex:
        return hex_to_binary_list(input_str)
    else:
        # Remove any spaces and non-digit characters
        cleaned_input = ''.join(c for c in input_str if c.isdigit())
        # Convert to list of integers and reverse
        coefficients = [int(digit) for digit in reversed(cleaned_input)]
        # Verify all coefficients are 0 or 1
        if not all(c in [0, 1] for c in coefficients):
            raise ValueError("Coefficients must be binary (0 or 1)")
        return coefficients

def mod2_polynomial_division(dividend, divisor):
    """Perform polynomial division in GF(2) (modulo 2)"""
    # Ensure lists have at least one element
    if not dividend or not divisor:
        return [0], [0]
    
    # Convert to lists and ensure they're in the right format
    dividend = [x % 2 for x in dividend]
    divisor = [x % 2 for x in divisor]
    
    if all(x == 0 for x in divisor):
        raise ValueError("Division by zero polynomial")
    
    # Remove leading zeros from dividend
    while len(dividend) > 1 and dividend[-1] == 0:
        dividend.pop()
        
    # Remove leading zeros from divisor
    while len(divisor) > 1 and divisor[-1] == 0:
        divisor.pop()
    
    # Initialize quotient coefficients with zeros
    quotient = [0] * (len(dividend) - len(divisor) + 1)
    remainder = dividend.copy()
    
    # Perform polynomial long division
    for i in range(len(dividend) - len(divisor), -1, -1):
        if len(remainder) > i + len(divisor) - 1 and remainder[i + len(divisor) - 1] == 1:
            quotient[i] = 1
            for j in range(len(divisor)):
                remainder[i + j] ^= divisor[j]
    
    # Remove leading zeros from remainder
    while len(remainder) > 1 and remainder[-1] == 0:
        remainder.pop()
    
    return quotient, remainder

def process_pattern_file(input_file, output_file, divisor_binary="1011"):
    """Process pattern file and generate output file"""
    try:
        # Read input file
        with open(input_file, 'r') as f:
            hex_patterns = [line.strip() for line in f if line.strip()]
        
        # Convert divisor to binary list
        divisor = parse_input(divisor_binary, is_hex=False)
        
        # Process each pattern and collect results
        results = []
        for hex_pattern in hex_patterns:
            try:
                # Convert hex to binary and add three zeros
                dividend = parse_input(hex_pattern, is_hex=True)
                # Perform division
                _, remainder = mod2_polynomial_division(dividend, divisor)
                # Convert remainder to decimal
                remainder_str = ''.join(str(x) for x in reversed(remainder))
                decimal_value = int(remainder_str, 2) if remainder_str else 0
                # Format as 32-character string with leading zeros
                formatted_result = f"{decimal_value:032d}"
                results.append(formatted_result)
            except ValueError as e:
                print(f"Error processing pattern {hex_pattern}: {e}")
                results.append("0" * 32)
        
        # Write results to output file
        with open(output_file, 'w') as f:
            for result in results:
                f.write(result + '\n')
        
        print(f"Successfully processed {len(results)} patterns")
        print(f"Results written to {output_file}")
        
    except Exception as e:
        print(f"Error processing file: {e}")

def main():
    # Example usage
    input_file = "pattern1.dat"
    output_file = "output.dat"
    divisor = "1110"  # This represents x³ + x + 1
    
    process_pattern_file(input_file, output_file, divisor)

if __name__ == "__main__":
    main()