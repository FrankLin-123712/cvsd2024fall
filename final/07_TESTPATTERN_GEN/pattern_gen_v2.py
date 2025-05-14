from ed25519 import number, point
import random

MAX_ITER = 100

def generate_random_scalar():
    return random.getrandbits(255)

def generate_point_on_curve():
    # Constants for ed25519
    q = pow(2, 255) - 19
    a = q - 1
    d = 0x52036cee2b6ffe738cc740797779e89800700a4d4141d8ab75eb4dca135978a3

    loop = 0
    while loop < MAX_ITER:
        # print(f"Have tried {loop+1} times to find point P.")

        # Generate random y coordinate
        y = number(random.randrange(q))
        
        # Calculate x using the curve equation: ax² + y² = 1 + dx²y²
        # Rearranging: x² * (a - dy²) = 1 - y²
        try:
            y_squared = (y * y).value % q
            numerator = (1 - y_squared) % q
            denominator = ((a) - d * y_squared) % q
            
            # Calculate modular inverse of denominator
            inv_denominator = pow(denominator, q-2, q)
            x_squared = (numerator * inv_denominator) % q
            
            # Try both possible x values (positive and negative square root)
            x = number(pow(x_squared, (q+3)//8, q))
            
            point_P = point(x, y)
            if point_P.is_on_curve():
                return point_P
            
            # Try negative x
            x = number(q - x.value)
            point_P = point(x, y)
            if point_P.is_on_curve():
                return point_P
                
        except:
            pass
            
        loop += 1
        continue

    raise Exception("Failed to find valid point after MAX_ITER attempts")

def main(pattern_num):
    with open("tb_dat_generated.sv", "w") as f:
        f.write("package test_patterns_pkg;\n")
        f.write("    typedef struct packed {\n")
        f.write("        reg [767:0] input_data;\n")
        f.write("        reg [511:0] golden_data;\n")
        f.write("    } pattern_t;\n\n")
        f.write(f"    parameter NUM_PATTERNS = {pattern_num};\n")
        f.write("    const pattern_t test_patterns [NUM_PATTERNS-1:0] = '{\n")
        
        for i in range(pattern_num):
            print(f"Generating pattern {i+1}/{pattern_num}")
            
            # Generate valid input point
            point_P = generate_point_on_curve()
            print(f"generate point P :\n{point_P}")
            scalar_M = generate_random_scalar()
            point_G = (point_P * scalar_M).reduce()
            
            input_hex = f"{scalar_M:064x}{point_P.X.value:064x}{point_P.Y.value:064x}"
            golden_hex = f"{point_G.X.value:064x}{point_G.Y.value:064x}"
            
            f.write(f"        '{{{768}'h{input_hex}, {512}'h{golden_hex}}}")
            f.write(",\n" if i < (pattern_num-1) else "\n    };\n")
        
        f.write("endpackage\n")

if __name__ == "__main__":
    # point_p = generate_point_on_curve()
    # print(f"point_p :\n{point_p}")
    pattern_num = 100
    main(pattern_num)