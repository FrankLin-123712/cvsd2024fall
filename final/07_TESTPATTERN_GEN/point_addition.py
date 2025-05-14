from ed25519 import number, q, d, point

class point_4d:
    def __init__(self, X: number, Y: number, Z: number = number(1), T: number = number(0), init = 1):
        """Initialize a point with X, Y, Z coordinates and compute T
            init: 1 indicates self.T=X*Y*Z, otherwise self.T=T
        """
        self.X = X
        self.Y = Y
        self.Z = Z
        if(init):
            self.T = (X * Y) * Z
        else:
            self.T = T
        

def point_add_4d(P1: point_4d, P2: point_4d) -> point_4d:
    """
    Implement 4D point addition from the paper's Algorithm 3
    P1, P2: Points with (X,Y,Z,T) coordinates using number class
    """
    # Step 1: A = (Y1-X1)(Y2-X2)
    A = (P1.Y - P1.X) * (P2.Y - P2.X)
    print("\nStep 1: A = {:064x}".format(A.value))

    # Step 2: B = (Y1+X1)(Y2+X2)
    B = (P1.Y + P1.X) * (P2.Y + P2.X)
    print("Step 2: B = {:064x}".format(B.value))

    # Step 3: C = 2dT1T2
    two = number(2)
    C = two * d * P1.T * P2.T
    print("Step 3: C = {:064x}".format(C.value))

    # Step 4: D = 2Z1Z2
    D = two * P1.Z * P2.Z
    print("Step 4: D = {:064x}".format(D.value))

    # Step 5: E = B-A
    E = B - A
    print("Step 5: E = {:064x}".format(E.value))

    # Step 6: F = D-C
    F = D - C
    print("Step 6: F = {:064x}".format(F.value))

    # Step 7: G = D+C
    G = D + C
    print("Step 7: G = {:064x}".format(G.value))

    # Step 8: H = B+A
    H = B + A
    print("Step 8: H = {:064x}".format(H.value))

    # Steps 9-12: Calculate output coordinates
    X3 = E * F
    Y3 = G * H
    Z3 = F * G
    T3 = E * H
    
    result = point_4d(X3, Y3, Z3, T3, init=0)
    
    print("\nOutput coordinates:")
    print("X3 ={:064x}".format(result.X.value))
    print("Y3 ={:064x}".format(result.Y.value))
    print("Z3 ={:064x}".format(result.Z.value))
    print("T3 ={:064x}".format(result.T.value))
    
    return result

def point_double_4d(P1: point_4d) -> point_4d:
    """
    Implement 4D point addition from the paper's Algorithm 3
    P1, P2: Points with (X,Y,Z,T) coordinates using number class
    """
    # Step 1: A = X1*X1
    A = P1.X * P1.X
    print("\nStep 1: A = {:064x}".format(A.value))

    # Step 2: B = Y1*Y1
    B = P1.Y * P1.Y
    print("Step 2: B = {:064x}".format(B.value))

    # Step 3: C = 2*(Z1^2)
    two = number(2)
    C = two * P1.Z * P1.Z
    print("Step 3: C = {:064x}".format(C.value))

    # Step 4: H = B+A
    H = B + A
    print("Step 4: H = {:064x}".format(H.value))

    # Step 5: E = H-(X1+Y1)^2
    E = H - (P1.X + P1.Y) * (P1.X + P1.Y)
    print("Step 5: E = {:064x}".format(E.value))

    # Step 6: G = A-B
    G = A - B
    print("Step 7: G = {:064x}".format(G.value))

    # Step 7: F = C+G
    F = C + G
    print("Step 8: F = {:064x}".format(F.value))

    # Steps 8-11: Calculate output coordinates
    X3 = E * F
    Y3 = G * H
    Z3 = F * G
    T3 = E * H
    
    result = point_4d(X3, Y3, Z3, T3, init=0)
    
    print("\nOutput coordinates:")
    print("X3 ={:064x}".format(result.X.value))
    print("Y3 ={:064x}".format(result.Y.value))
    print("Z3 ={:064x}".format(result.Z.value))
    print("T3 ={:064x}".format(result.T.value))
    
    return result

def point_mul_4d(P: point_4d, m: int) -> point_4d:
    """
    Point multiplication using the 4D point addition method
    P: Base point (X,Y,Z,T)
    m: Scalar value
    """
    print("\nStarting point multiplication with scalar: {:064x}".format(m))
    
    # Initialize result as identity point
    R = point_4d(number(0), number(1))
    
    # Convert to 255-bit binary string with leading zeros
    m_bin = "{:0255b}".format(m)
    print(f"\nBinary representation of scalar (255 bits): {m_bin}")
    print(f"Length of binary scalar: {len(m_bin)}")
    
    for i, bit in enumerate(m_bin):
        print(f"\nIteration {i}:")
        print("Current R (before doubling):")
        print("X: {:064x}".format(R.X.value))
        print("Y: {:064x}".format(R.Y.value))
        print("Z: {:064x}".format(R.Z.value))
        print("T: {:064x}".format(R.T.value))
        
        # Double
        R = point_double_4d(R)
        
        if bit == '1':
            print(f"\nAdding base point (bit = 1):")
            R = point_add_4d(R, P)
    
    return R

def reduce(R: point_4d):
    # (1) find inverse Z
    # precomputation
    b2 = R.Z*R.Z
    print("b2: {:064x}".format(b2.value))
    b4 = b2*b2
    print("b4: {:064x}".format(b4.value))
    reg3 = R.Z*b2
    print("b3: {:064x}".format(reg3.value))

    reg4 = b2 # b2
    reg5 = b4
    reg6 = number(0)

    print("initail status")
    print("reg4 : {:064x}".format(reg4.value))
    print("reg5 : {:064x}".format(reg5.value))
    print("reg6 : {:064x}".format(reg6.value))

    # repeat multiplication
    for i in range(0, 248):
        print("===================================")
        print(f"           iteration {i}           ")
        print("-----------------------------------")
        if i == 0: 
            reg4 = R.Z*reg4
            print("reg4: {:064x}".format(reg4.value))
            reg6 = reg5*reg5
            print("reg6: {:064x}".format(reg6.value))
        else:
            if i%2 == 1: # odd
                reg4 = reg4*reg5
                print("reg4: {:064x}".format(reg4.value))
                reg5 = reg6*reg6
                print("reg5: {:064x}".format(reg5.value))
            else: # even
                reg4 = reg4*reg6
                print("reg4: {:064x}".format(reg4.value))
                reg6 = reg5*reg5
                print("reg4: {:064x}".format(reg4.value))
    # postcomputation
    A = reg4
    print("A: {:064x}".format(A.value))
    B = reg5
    print("B: {:064x}".format(B.value))
    C = A*A
    print("C: {:064x}".format(C.value))
    D = B*B
    print("D: {:064x}".format(D.value))
    E = C*C
    print("E: {:064x}".format(E.value))
    F = R.Z*D
    print("F: {:064x}".format(F.value))
    G = E*F
    print("G: {:064x}".format(G.value))
    H = G*G
    print("H: {:064x}".format(H.value))
    I = H*H
    print("I: {:064x}".format(I.value))
    J = I*I
    print("J: {:064x}".format(J.value))
    b_inv = J*reg3
    print("b_inv: {:064x}".format(b_inv.value))

    # divide
    Xg = R.X*b_inv
    Yg = R.Y*b_inv
    print("Xg(before modular): {:064x}".format(Xg.value))
    print("Yg(before modular): {:064x}".format(Yg.value))

    if(Xg.value%2==1): Xg.value = q-Xg.value
    if(Yg.value%2==1): Yg.value = q-Yg.value
    return point(Xg, Yg)

def verify_point_multiplication():
    # Test values from testcase 1
    scalar_M = 0x259f4329e6f4590b9a164106cf6a659eb4862b21fb97d43588561712e8e5216a
    x = number(0x0fa4d2a95dafe3275eaf3ba907dbb1da819aba3927450d7399a270ce660d2fae)
    y = number(0x2f0fe2678dedf6671e055f1a557233b324f44fb8be4afe607e5541eb11b0bea2)
    
    # Create base point
    base_point_3d = point(x, y)
    base_point_4d = point_4d(x, y)
    print("\nPoint P in 3D coordinate:")
    print("X: {:064x}".format(base_point_3d.X.value))
    print("Y: {:064x}".format(base_point_3d.Y.value))
    print("Z: {:064x}".format(base_point_3d.Z.value))

    print("\nPoint P in 4D coordinate:")
    print("X: {:064x}".format(base_point_4d.X.value))
    print("Y: {:064x}".format(base_point_4d.Y.value))
    print("Z: {:064x}".format(base_point_4d.Z.value))
    print("T: {:064x}".format(base_point_4d.T.value))



    # Get original result before reduction
    orig_result = base_point_3d * scalar_M
    print("\nOriginal implementation result (before reduce):")
    print("X: {:064x}".format(orig_result.X.value))
    print("Y: {:064x}".format(orig_result.Y.value))
    print("Z: {:064x}".format(orig_result.Z.value))
    
    golden_xgyg = orig_result.reduce()
    print("\nOriginal implementation result (after reduce):")
    print(golden_xgyg)

    # Get 4D implementation result
    result_4d = point_mul_4d(base_point_4d, scalar_M)
    print("\n4D implementation result: (before reduce)")
    print("X: {:064x}".format(result_4d.X.value))
    print("Y: {:064x}".format(result_4d.Y.value))
    print("Z: {:064x}".format(result_4d.Z.value))
    
    # Reduce
    result = reduce(result_4d)
    print("\n4D implementation result:(after reduce)")
    print(result)

    # Compare results
    print("\nComparison:")
    x_match = golden_xgyg.X.value == result.X.value
    y_match = golden_xgyg.Y.value == result.Y.value
    if x_match and y_match:
        print("original implement match with 4D and fast reduce implementation !!")
    else:
        print("fail ....")


if __name__ == "__main__":
    verify_point_multiplication()