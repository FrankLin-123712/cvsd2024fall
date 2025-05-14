def ModMul(x, y):
   # Split inputs into 129-bit parts
   A1 = x & ((1 << 129) - 1)  # Lower 129 bits
   A2 = (x >> 129) & ((1 << 129) - 1)  # Upper 129 bits
   B1 = y & ((1 << 129) - 1)
   B2 = (y >> 129) & ((1 << 129) - 1)
   
   intermediates = {}
   intermediates['A1'] = A1
   intermediates['A2'] = A2 
   intermediates['B1'] = B1
   intermediates['B2'] = B2

   # Karatsuba multiplication for 130x130 bits
   H0 = (A2 * B2) & ((1 << 258) - 1)
   L0 = (A1 * B1) & ((1 << 258) - 1)
   M0 = ((A2 + A1) * (B2 + B1)) & ((1 << 260) - 1)
   
   intermediates['H0'] = H0
   intermediates['L0'] = L0
   intermediates['M0'] = M0

   # Mod p reduction
   H0_shift7 = (H0 << 7) & ((1 << 265) - 1)
   H0_shift4 = (H0 << 4) & ((1 << 262) - 1) 
   H0_shift3 = (H0 << 3) & ((1 << 261) - 1)
   
   intermediates['H0_shift7'] = H0_shift7
   intermediates['H0_shift4'] = H0_shift4
   intermediates['H0_shift3'] = H0_shift3

   add_temp1 = H0_shift7 + H0_shift4
   add_temp2 = H0_shift3 + L0
   add_temp3 = add_temp1 + add_temp2
   
   intermediates['add_temp1'] = add_temp1
   intermediates['add_temp2'] = add_temp2
   intermediates['add_temp3'] = add_temp3

   sub_temp1 = M0 - L0
   sub_temp2 = sub_temp1 - H0
   sub_temp3 = (sub_temp2 << 129) & ((1 << 391) - 1)
   
   intermediates['sub_temp1'] = sub_temp1
   intermediates['sub_temp2'] = sub_temp2 
   intermediates['sub_temp3'] = sub_temp3

   T = (add_temp3 + sub_temp3) & ((1 << 392) - 1)
   intermediates['T'] = T

   Th = (T >> 255) & ((1 << 137) - 1)
   Tl = T & ((1 << 255) - 1)
   
   intermediates['Th'] = Th
   intermediates['Tl'] = Tl

   Th_shift4 = (Th << 4) & ((1 << 141) - 1)
   Th_shift1 = (Th << 1) & ((1 << 138) - 1)
   Th_shift_1_plus_4 = Th_shift4 + Th_shift1
   Th19 = Th_shift_1_plus_4 + Th
   
   intermediates['Th_shift4'] = Th_shift4
   intermediates['Th_shift1'] = Th_shift1
   intermediates['Th_shift_1_plus_4'] = Th_shift_1_plus_4
   intermediates['Th19'] = Th19

   T_prime = (Th19 + Tl) & ((1 << 256) - 1)
   intermediates['T_prime'] = T_prime

   p = (1 << 255) - 19
   if T_prime >= p:
       result = T_prime - p
   else:
       result = T_prime

   intermediates['result'] = result
   
   return result, intermediates

if __name__ == "__main__":

    x = 29601092606522057299714081035237051434897758323652415049575150849937959312839  # Your input value
    y = 29601092606522057299714081035237051434897758323652415049575150849937959312839 

    result, nodes = ModMul(x, y)
    print("Intermediate Values (Decimal):")
    for key, value in nodes.items():
        print(f"{key}: {value}")
    