module custom (
    input  wire [3:0] A,
    input  wire [3:0] B,
    input  wire [1:0] custom_sel, // 2'b00: logical left shift, 2'b01: logical right shift, 2'b10: rotate left, 2'b11: popcount(A|B)
    output reg  [7:0] result
);
    wire [1:0] shamt = B[1:0];
    reg  [3:0] shifted;
    integer i;
    function [2:0] popcount4;
        input [3:0] v;
        integer j;
        begin
            popcount4 = 0;
            for (j = 0; j < 4; j = j + 1)
                popcount4 = popcount4 + v[j];
        end
    endfunction

    always @(*) begin
        case (custom_sel)
            2'b00: begin // logical left shift
                shifted = (A << shamt);
                result = {4'b0000, shifted};
            end
            2'b01: begin // logical right shift
                shifted = (A >> shamt);
                result = {4'b0000, shifted};
            end
            2'b10: begin // rotate left
                case (shamt)
                    2'd0: shifted = A;
                    2'd1: shifted = {A[2:0], A[3]};
                    2'd2: shifted = {A[1:0], A[3:2]};
                    2'd3: shifted = {A[0], A[3:1]};
                    default: shifted = A;
                endcase
                result = {4'b0000, shifted};
            end
            2'b11: begin // popcount of (A | B)
                result = {5'b00000, popcount4(A | B)}; // small number, place in LSBs
            end
            default: result = 8'b0;
        endcase
    end
endmodule