module stream_data_manipulator #(
    parameter DATA_BUS_WIDTH = 32,
    parameter CTRL_SEL_WIDTH = 2
) (
    input  wire                     clock,
    input  wire                     reset_n,
    input  wire [DATA_BUS_WIDTH-1:0]   in_data,
    input  wire [DATA_BUS_WIDTH/8-1:0] in_byte_en,
    input  wire                     in_valid,
    input  wire                     in_end,
    output wire                     in_ready,
    output wire [DATA_BUS_WIDTH-1:0]   out_data,
    output wire [DATA_BUS_WIDTH/8-1:0] out_byte_en,
    output wire                     out_valid,
    output wire                     out_end,
    input  wire                     out_ready,
    input  wire [CTRL_SEL_WIDTH-1:0]    ctrl_sel,
    input  wire [DATA_BUS_WIDTH-1:0]   increment_val
);

    reg [DATA_BUS_WIDTH-1:0]   data_buf;
    reg [DATA_BUS_WIDTH/8-1:0] byte_en_buf;
    reg                     valid_buf;
    reg                     end_buf;
    reg                     ready_buf;

    function [DATA_BUS_WIDTH-1:0] flip_bytes;
        input [DATA_BUS_WIDTH-1:0] value;
        integer i;
        begin
            for (i = 0; i < DATA_BUS_WIDTH/8; i = i + 1) begin
                flip_bytes[8*i +: 8] = value[8*(DATA_BUS_WIDTH/8-1-i) +: 8];
            end
        end
    endfunction

    always @(*) begin
        case (ctrl_sel)
            2'd0: data_buf = in_data;
            2'd1: data_buf = flip_bytes(in_data);
            2'd2: data_buf = in_data + increment_val;
            default: data_buf = in_data;
        endcase
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            valid_buf <= 1'b0;
            ready_buf <= 1'b1;
            byte_en_buf  <= 1'b0;
            end_buf  <= 1'b0;
        end else begin
            if (out_ready || !valid_buf) begin
                if (in_valid && ready_buf) begin
                    valid_buf <= 1'b1;
                    byte_en_buf  <= in_byte_en;
                    end_buf  <= in_end;
                    ready_buf <= 1'b1;
                end else begin
                    valid_buf <= 1'b0;
                    ready_buf <= 1'b1;
                end
            end
        end
    end

    assign out_data  = data_buf;
    assign out_byte_en  = byte_en_buf;
    assign out_valid = valid_buf;
    assign out_end  = end_buf;
    assign in_ready = ready_buf;

endmodule

