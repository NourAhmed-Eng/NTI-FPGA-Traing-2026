module RAM #(parameter ADDR_WIDTH = 8, parameter DATA_WIDTH = 20, parameter DEPTH = 256) (

    //INPUTS
    input wire clk,
    input wire rst_n,
    input wire wr_en,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    input wire rd_en,

    //OUTPUTS
    output reg [DATA_WIDTH-1:0] dout,
    output reg valid

);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    always @(posedge clk) begin
        if (wr_en)
            mem[addr] <= din;
    end

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            dout  <= 0;
            valid <= 0;

        end else begin
            valid <= rd_en;

            if (rd_en)
                dout <= mem[addr];
        end
    end

endmodule



module piso #(parameter WIDTH = 20, parameter ADDR_WIDTH = 8) (

    //INPUTS
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] parallel_in,

    //OUTPUTS
    output reg [ADDR_WIDTH-1:0] addr,
    output reg rd_en,
    output reg serial_out,
    output reg valid

);

    reg [WIDTH-1:0] shift_reg;
    integer count;

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            shift_reg  <= 0;
            count      <= 0;
            addr       <= 0;
            rd_en      <= 0;
            valid      <= 0;
            serial_out <= 0;

        end else begin

            if (count == 0) begin
                rd_en <= 1;
                valid <= 0;
                count <= count + 1;
            end

            else if (count == 1) begin
                shift_reg  <= parallel_in;
                serial_out <= parallel_in[WIDTH-1];
                valid      <= 1;
                rd_en      <= 0;
                count      <= count + 1;
            end

            else if (count <= WIDTH) begin
                shift_reg  <= {shift_reg[WIDTH-2:0], 0};
                serial_out <= shift_reg[WIDTH-2];
                valid      <= 1;
                count      <= count + 1;
            end

            else begin
                valid      <= 0;
                serial_out <= 0;
                addr       <= addr + 1;
                count      <= 0;
            end
        end
    end

endmodule



module sipo #(parameter WIDTH = 20) (

    // INPUTS
    input wire clk,
    input wire rst_n,
    input wire shift_en,
    input wire serial_in,

    // OUTPUT
    output reg [WIDTH-1:0] parallel_out

);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            parallel_out <= 0;

        else if (shift_en)
            parallel_out <= {parallel_out[WIDTH-2:0], serial_in};
    end

endmodule



module ALU #(parameter WIDTH = 8) (

    // INPUTS
    input wire [WIDTH-1:0] in_a,
    input wire [WIDTH-1:0] in_b,
    input wire [2:0] opcode,
    input wire alu_en,

    // OUTPUTS
    output reg [WIDTH-1:0] alu_out,
    output wire a_is_zero

);

    assign a_is_zero = (in_a == 0);

    always @(*) begin

        if (!alu_en) begin
            alu_out = 0;

        end else begin

            case (opcode)
                3'b000:  alu_out = in_a + in_b;   // ADD
                3'b001:  alu_out = in_a - in_b;   // SUB
                3'b010:  alu_out = in_a & in_b;   // AND
                3'b011:  alu_out = in_a ^ in_b;   // XOR
                3'b100:  alu_out = in_a | in_b;   // OR
                3'b101:  alu_out = in_a;          // OUT A
                default: alu_out = 0;
            endcase

        end
    end

endmodule



module RAM_PISO_SIPO_ALU (

    input wire clk,
    input wire rst_n,
    input wire tb_wr_en,
    input wire [7:0] tb_wr_addr,
    input wire [19:0] tb_din,

    output wire [7:0] alu_out,
    output wire a_is_zero

);

    wire [19:0] ram_dout;
    wire        ram_valid;
    wire [7:0]  piso_ram_addr;
    wire        rd_en;
    wire        serial_line;
    wire        valid_line;
    wire [19:0] sipo_parallel_out;

    wire [7:0] active_ram_addr = tb_wr_en ? tb_wr_addr : piso_ram_addr;



    RAM #(.ADDR_WIDTH(8), .DATA_WIDTH(20)) RAM1 (

        .clk(clk),
        .rst_n(rst_n),
        .wr_en(tb_wr_en),
        .addr(active_ram_addr),
        .din(tb_din),
        .rd_en(rd_en),
        .dout(ram_dout),
        .valid(ram_valid)

    );

    piso #(.WIDTH(20), .ADDR_WIDTH(8)) PISO1 (

        .clk(clk),
        .rst_n(rst_n),
        .parallel_in(ram_dout),
        .addr(piso_ram_addr),
        .rd_en(rd_en),
        .serial_out(serial_line),
        .valid(valid_line)
    );

    sipo #(.WIDTH(20)) SIPO1 (

        .clk(clk),
        .rst_n(rst_n),
        .shift_en(valid_line),
        .serial_in(serial_line),
        .parallel_out(sipo_parallel_out)

    );

    ALU #(.WIDTH(8)) ALU1 (

        .alu_en(sipo_parallel_out[19]),
        .opcode(sipo_parallel_out[18:16]),
        .in_a(sipo_parallel_out[15:8]),
        .in_b(sipo_parallel_out[7:0]),
        .alu_out(alu_out),
        .a_is_zero(a_is_zero)

    );

endmodule



module RAM_PISO_SIPO_ALU_tb;

    reg        clk;
    reg        rst_n;
    reg        tb_wr_en;
    reg  [7:0] tb_wr_addr;
    reg [19:0] tb_din;

    wire [7:0] alu_out;
    wire       a_is_zero;

    RAM_PISO_SIPO_ALU dut (

        .clk(clk),
        .rst_n(rst_n),
        .tb_wr_en(tb_wr_en),
        .tb_wr_addr(tb_wr_addr),
        .tb_din(tb_din),
        .alu_out(alu_out),
        .a_is_zero(a_is_zero)

    );

    always #5 clk = ~clk;

    task send_cmd(input [7:0] addr, input [19:0] cmd);
        begin

            tb_wr_en   = 1;
            tb_wr_addr = addr;
            tb_din     = cmd;
            @(posedge clk);
            #1
            tb_wr_en   = 0;

        end
    endtask

    initial begin

        $monitor("Time = %0t  wr = %b  RAM = %b  PISO_addr = %d  rd = %b  serial = %b  valid = %b  SIPO = %b  ALU = %b  zero = %b",
         $time, tb_wr_en, dut.ram_dout, dut.piso_ram_addr, dut.rd_en, dut.serial_line, dut.valid_line, dut.sipo_parallel_out, alu_out,
         a_is_zero);

    end

    initial begin

        clk        = 0;
        rst_n      = 0;
        tb_wr_en   = 0;
        tb_wr_addr = 0;
        tb_din     = 0;

        send_cmd(8'd0, {1'b1, 3'b000, 8'b00001111, 8'b00001010}); // ADD
        send_cmd(8'd1, {1'b1, 3'b001, 8'b00110010, 8'b00010100}); // SUB
        send_cmd(8'd2, {1'b1, 3'b010, 8'b11111111, 8'b00001111}); // AND
        send_cmd(8'd3, {1'b1, 3'b011, 8'b10101010, 8'b11111111}); // XOR
        send_cmd(8'd4, {1'b1, 3'b100, 8'b11110000, 8'b00001111}); // OR
        send_cmd(8'd5, {1'b1, 3'b101, 8'b00101010, 8'b01100011}); // OUT A
        send_cmd(8'd6, {1'b1, 3'b110, 8'b00001010, 8'b00001010}); // Default
        send_cmd(8'd7, {1'b0, 3'b000, 8'b00000101, 8'b00000101}); // Disabled ALU
        send_cmd(8'd8, {1'b1, 3'b000, 8'b00000000, 8'b00001010}); // Zero Operand A

        #10;
        rst_n = 1;

        #2200;

        $finish;
    end

endmodule
