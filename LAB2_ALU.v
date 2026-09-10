module ALU #( parameter WIDTH = 8 )

(
    //INPUTS
    input  wire [WIDTH -1:0] in_a,
    input  wire [WIDTH -1:0] in_b,
    input  wire [2:0] opcode,

    //OUTPUTS
    output reg  [WIDTH -1:0] ALU_out,
    output wire a_is_zero
);

    assign a_is_zero = (in_a == 0);       // output 1 when in_a is 0, otherwise 0


    always @(*) begin

        case (opcode)

            3'b000:  ALU_out = in_a;           // HLT: PASS A
            3'b001:  ALU_out = in_a - in_b;    // SKZ: (A - B)
            3'b010:  ALU_out = in_a + in_b;    // ADD
            3'b011:  ALU_out = in_a & in_b;    // AND
            3'b100:  ALU_out = in_a ^ in_b;    // XOR
            3'b101:  ALU_out = in_b;           // LDA: PASS B
            3'b110:  ALU_out = in_a;           // STO: PASS A
            3'b111:  ALU_out = in_a;           // JMP: PASS A

            default: ALU_out = { WIDTH {1'b0} };

        endcase

    end

endmodule


module ALU_tb;

    parameter WIDTH = 8;

    reg  [WIDTH-1:0] in_a;
    reg  [WIDTH-1:0] in_b;
    reg  [2:0] opcode;

    wire [WIDTH-1:0] ALU_out;
    wire a_is_zero;

    // Instantiate ALU
     ALU #(.WIDTH(WIDTH)) dut (

        .in_a(in_a),
        .in_b(in_b),
        .opcode(opcode),
        .ALU_out(ALU_out),
        .a_is_zero(a_is_zero)

    );

    initial begin

        $monitor("At time %0t  opcode = %b  in_a = %b  in_b = %b  a_is_zero = %b  ALU_out = %b", 
                 $time, opcode, in_a, in_b, a_is_zero, ALU_out);
        
        
        in_a = 8'b01000010; in_b = 8'b10000110; opcode = 3'b000;
        #10;

        in_a = 8'b01000010; in_b = 8'b10000110; opcode = 3'b001;
        #10;

        in_a = 8'b01000010; in_b = 8'b10000110; opcode = 3'b010;
        #10;

        in_a = 8'b01000010; in_b = 8'b10000110; opcode = 3'b011;
        #10;

        in_a = 8'b01000010; in_b = 8'b10000110; opcode = 3'b100;
        #10;

        in_a = 8'b01000010; in_b = 8'b10000110; opcode = 3'b101;
        #10;

        in_a = 8'b01000010; in_b = 8'b10000110; opcode = 3'b110;
        #10;

        in_a = 8'b01000010; in_b = 8'b10000110; opcode = 3'b111;
        #10;

        in_a = 8'b00000000; in_b = 8'b10000110; opcode = 3'b111;
        #10;

        $finish;

    end

endmodule
