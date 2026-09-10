module gray_to_binary (

    input  wire [3:0] gray,

    output wire [3:0] binary

);

    assign binary[3] = gray[3];
    assign binary[2] = binary[3] ^ gray[2];
    assign binary[1] = binary[2] ^ gray[1];
    assign binary[0] = binary[1] ^ gray[0];

endmodule


module binary_to_7seg (


    input  wire [3:0] binary,

    output reg  [6:0] seg

);

    always @(*) begin

        case (binary)

            4'h0: seg = 7'b100_0000;  
            4'h1: seg = 7'b111_1001;  
            4'h2: seg = 7'b010_0100;  
            4'h3: seg = 7'b011_0000;  
            4'h4: seg = 7'b001_1001;  
            4'h5: seg = 7'b001_0010;  
            4'h6: seg = 7'b000_0010;  
            4'h7: seg = 7'b111_1000;  
            4'h8: seg = 7'b000_0000;  
            4'h9: seg = 7'b001_0000;  

            4'hA: seg = 7'b000_1000;  
            4'hB: seg = 7'b000_0011;  
            4'hC: seg = 7'b100_0110;  
            4'hD: seg = 7'b010_0001;  
            4'hE: seg = 7'b000_0110;  
            4'hF: seg = 7'b000_1110;  

            default: seg = 7'b111_1111; // Off
            
        endcase

    end
endmodule

module gray_to_binary_to_7seg (

    input  wire [3:0] gray,

    output wire [6:0] seg

);

    wire [3:0] internal_binary;

    gray_to_binary dut_gray (

        .gray(gray),
        .binary(internal_binary)

    );

    binary_to_7seg dut_7seg (

        .binary(internal_binary),
        .seg(seg)

    );

endmodule


module gray_to_binary_to_7seg_tb;

    reg  [3:0] gray;
    wire [6:0] seg;

    gray_to_binary_to_7seg dut (

        .gray(gray),
        .seg(seg)

    );

    integer i;

    initial begin

        $monitor("Time = %0t  Gray Input = %b  Binary = %b  7Seg Output = %b",
                  $time, gray, dut.internal_binary, seg);

        for (i = 0; i < 16; i = i + 1) begin

            gray = i[3:0];
            #10;
        end

        $finish;

    end
endmodule
