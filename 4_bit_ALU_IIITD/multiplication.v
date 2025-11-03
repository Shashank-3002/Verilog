module mul #(parameter WIDTH = 4) (
    input [WIDTH-1:0] A, B,
    output [2*WIDTH-1:0] result,
    output carry_out  // Always 0, as 8-bit output fits
);
    assign result = A * B;  // 4x4 multiplication
    assign carry_out = 0;
endmodule