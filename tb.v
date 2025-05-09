module stream_data_manipulator_testbench;
    parameter DATA_BUS_WIDTH = 32;
    parameter CLOCK_CYCLE = 10;
    parameter MAX_DATA_COUNT = 10;

    reg clk, reset_n;
    reg [DATA_BUS_WIDTH-1:0] in_data;
    reg [DATA_BUS_WIDTH/8-1:0] in_byte_en;
    reg in_end;
    reg in_valid;
    wire in_ready;
    wire [DATA_BUS_WIDTH-1:0] out_data;
    wire [DATA_BUS_WIDTH/8-1:0] out_byte_en;
    wire out_end;
    wire out_valid;
    reg out_ready;
    reg [1:0] ctrl_sel;
    reg [DATA_BUS_WIDTH-1:0] increment_val;

    stream_data_manipulator #(
        .DATA_BUS_WIDTH(DATA_BUS_WIDTH)
    ) test_unit (
        .clock(clk),
        .reset_n(reset_n),
        .in_data(in_data),
        .in_byte_en(in_byte_en),
        .in_end(in_end),
        .in_valid(in_valid),
        .in_ready(in_ready),
        .out_data(out_data),
        .out_byte_en(out_byte_en),
        .out_end(out_end),
        .out_valid(out_valid),
        .out_ready(out_ready),
        .ctrl_sel(ctrl_sel),
        .increment_val(increment_val)
    );

    initial begin
        clk = 0;
        forever #(CLOCK_CYCLE/2) clk = ~clk;
    end

    initial begin
        reset_n = 0;
        in_data = 0;
        in_byte_en = {(DATA_BUS_WIDTH/8){1'b1}};
        in_end = 0;
        in_valid = 0;
        out_ready = 1;
        ctrl_sel = 0;
        increment_val = 0;
        #20 reset_n = 1;
        ctrl_sel = 0;
        send_data(32'h12345678, 1);
        ctrl_sel = 1;
        send_data(32'h12345678, 1);
        ctrl_sel = 2;
        increment_val = 32'h00000005;
        send_data(32'h12345678, 1);
        increment_val = 32'hFFFFFFFF;
        send_data(32'hFFFFFFFF, 1);
        fork
            begin
                send_data(32'h12345678, 0);
                #10 reset_n = 0;
                #20 reset_n = 1;
            end
            begin
                block_downstream(3);
            end
        join
        ctrl_sel = 0;
        in_byte_en = 4'b1100;
        send_data(32'hAABBCCDD, 1);
        in_byte_en = {(DATA_BUS_WIDTH/8){1'b1}};
        ctrl_sel = 3;
        send_data(32'h12345678, 1);
        #100 $finish;
    end

    task send_data(input [DATA_BUS_WIDTH-1:0] value, input last);
        begin
            @(posedge clk);
            in_data = value;
            in_end = last;
            in_valid = 1;
            @(posedge clk);
            while (!in_ready) @(posedge clk);
            in_valid = 0;
            in_end = 0;
        end
    endtask

    task block_downstream(input integer cycles);
        begin
            out_ready = 0;
            repeat (cycles) @(posedge clk);
            out_ready = 1;
        end
    endtask

    always @(posedge clk) begin
        if (out_valid && out_ready) begin
        end
    end

endmodule
