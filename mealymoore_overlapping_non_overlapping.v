module mealy_overlapping (

    //INPUTS
    input  wire clk,
    input  wire rst_n,
    input  wire in,

    //OUTPUT
    output reg  tick

);

    parameter S0 = 3'b000;
    parameter S1 = 3'b001;
    parameter S2 = 3'b010;
    parameter S3 = 3'b011;
    parameter S4 = 3'b100;
    parameter S5 = 3'b101;

    reg [2:0] state, next_state;

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n)
            state <= S0;

        else
            state <= next_state;

    end

    always @(*) begin

        tick = 0;

        case (state)
        
            S0: next_state = in ? S1 : S0;
            S1: next_state = in ? S2 : S0;
            S2: next_state = in ? S2 : S3;
            S3: next_state = in ? S4 : S0;
            S4: next_state = in ? S2 : S5;
            S5: begin
            
                if (in) begin
                    tick = 1;
                    next_state = S2;

                end else begin
                    next_state = S0;

                end
            end

            default: next_state = S0;

        endcase
    end

endmodule

module mealy_non_overlapping (

    //INPUTS
    input  wire clk,
    input  wire rst_n,
    input  wire in,

    //OUTPUT
    output reg  tick

);

    parameter S0 = 3'b000;
    parameter S1 = 3'b001;
    parameter S2 = 3'b010;
    parameter S3 = 3'b011;
    parameter S4 = 3'b100;
    parameter S5 = 3'b101;

    reg [2:0] state, next_state;

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n)
            state <= S0;

        else
            state <= next_state;
    end

    always @(*) begin

        tick = 0;

        case (state)

            S0: next_state = in ? S1 : S0;
            S1: next_state = in ? S2 : S0;
            S2: next_state = in ? S2 : S3;
            S3: next_state = in ? S4 : S0;
            S4: next_state = in ? S2 : S5;
            S5: begin

                if (in) begin
                    tick = 1;
                    next_state = S0;

                end else begin

                    next_state = S0;

                end
            end

            default: next_state = S0;

        endcase
    end

endmodule

module moore_overlapping (

    //INPUTS
    input  wire clk,
    input  wire rst_n,
    input  wire in,

    //Output
    output reg  tick

);

    parameter S0 = 3'b000;
    parameter S1 = 3'b001;
    parameter S2 = 3'b010;
    parameter S3 = 3'b011;
    parameter S4 = 3'b100;
    parameter S5 = 3'b101;
    parameter S6 = 3'b110;

    reg [2:0] state, next_state;

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n)
            state <= S0;

        else
            state <= next_state;
    end

    always @(*) begin

        case (state)

            S0: next_state = in ? S1 : S0;
            S1: next_state = in ? S2 : S0;
            S2: next_state = in ? S2 : S3;
            S3: next_state = in ? S4 : S0;
            S4: next_state = in ? S2 : S5;
            S5: next_state = in ? S6 : S0;
            S6: next_state = in ? S2 : S3;
            default: next_state = S0;

        endcase
    end

    always @(*) begin

        tick = (state == S6);

    end

endmodule

module moore_non_overlapping (

    //INPUTS
    input  wire clk,
    input  wire rst_n,
    input  wire in,

    //OUTPUT
    output reg  tick

);

    parameter S0 = 3'b000;
    parameter S1 = 3'b001;
    parameter S2 = 3'b010;
    parameter S3 = 3'b011;
    parameter S4 = 3'b100;
    parameter S5 = 3'b101;
    parameter S6 = 3'b110;

    reg [2:0] state, next_state;

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n)
            state <= S0;

        else
            state <= next_state;
    end

    always @(*) begin

        case (state)

            S0: next_state = in ? S1 : S0;
            S1: next_state = in ? S2 : S0;
            S2: next_state = in ? S2 : S3;
            S3: next_state = in ? S4 : S0;
            S4: next_state = in ? S2 : S5;
            S5: next_state = in ? S6 : S0;
            S6: next_state = in ? S1 : S0;
            default: next_state = S0;

        endcase
    end

    always @(*) begin

        tick = (state == S6);

    end

endmodule

module seq_det_topmodule (

    input  wire clk,
    input  wire rst_n,
    input  wire in,

    output wire tick_mealy_overlap,
    output wire tick_mealy_nonoverlap,
    output wire tick_moore_overlap,
    output wire tick_moore_nonoverlap
);

    mealy_overlapping u_mealy_ol (

        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .tick(tick_mealy_overlap)

    );

    mealy_non_overlapping u_mealy_nol (

        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .tick(tick_mealy_nonoverlap)

    );

    moore_overlapping u_moore_ol (

        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .tick(tick_moore_overlap)

    );

    moore_non_overlapping u_moore_nol (

        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .tick(tick_moore_nonoverlap)

    );

endmodule


module seq_det_tb;

    reg clk;
    reg rst_n;
    reg in;

    wire tick_mealy_overlap;
    wire tick_mealy_nonoverlap;
    wire tick_moore_overlap;
    wire tick_moore_nonoverlap;

    seq_det_topmodule dut (

        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .tick_mealy_overlap(tick_mealy_overlap),
        .tick_mealy_nonoverlap(tick_mealy_nonoverlap),
        .tick_moore_overlap(tick_moore_overlap),
        .tick_moore_nonoverlap(tick_moore_nonoverlap)

    );

    always #5 clk = ~clk;

    reg [11:0] test_seq = 12'b110101101010;

    integer i;

    initial begin

        $monitor("Time = %0t  in = %b  Mealy_OL = %b Mealy_NOL = %b  Moore_OL = %b  Moore_NOL = %b", 
                 $time, in, tick_mealy_overlap, tick_mealy_nonoverlap, tick_moore_overlap, tick_moore_nonoverlap);

    end

    initial begin

        clk   = 0;
        rst_n = 0;
        in    = 0;

        #12
        rst_n = 1;

        for (i = 11; i >= 0; i = i - 1) begin

            @(posedge clk);
            #1
            in = test_seq[i];

        end

        #30
        $finish;

    end

endmodule
