module div #(parameter WIDTH = 4) (
    input [WIDTH-1:0] A, B,
    output [2*WIDTH-1:0] result,
    output carry_out  // 1 if divide-by-zero
);
    assign result[2*WIDTH-1:WIDTH] = (B == 0) ? 0 : (A / B);  // Quotient
    assign result[WIDTH-1:0] = (B == 0) ? 0 : (A % B);       // Remainder
    assign carry_out = (B == 0) ? 1 : 0;  // Error flag
endmodule