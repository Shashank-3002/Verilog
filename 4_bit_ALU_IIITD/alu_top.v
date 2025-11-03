module alu_top #(parameter WIDTH = 4) (
    input  [WIDTH-1:0] A, B,
    input  [2:0] opcode,
    output reg [2*WIDTH-1:0] result,
    output reg carry_out
);

    // Wires for each module's outputs
    wire [2*WIDTH-1:0] add_res, sub_res, mul_res, div_res, logic_res, custom_res;
    wire add_co, sub_co, mul_co, div_co, logic_co;

    // Instantiate operation modules
    add  #(.WIDTH(WIDTH)) u_add (.A(A), .B(B), .result(add_res), .carry_out(add_co));
    sub  #(.WIDTH(WIDTH)) u_sub (.A(A), .B(B), .result(sub_res), .carry_out(sub_co));
    mul  #(.WIDTH(WIDTH)) u_mul (.A(A), .B(B), .result(mul_res), .carry_out(mul_co));
    div  #(.WIDTH(WIDTH)) u_div (.A(A), .B(B), .result(div_res), .carry_out(div_co));
    logic_ops #(.WIDTH(WIDTH)) u_logic (.A(A), .B(B), .sel(opcode[1:0]), .result(logic_res), .carry_out(logic_co));
    custom u_custom (.A(A), .B(B), .custom_sel(B[1:0]), .result(custom_res));

    // Multiplexer to select based on opcode
    always @(*) begin
        case (opcode)
            3'b000: begin result = add_res;   carry_out = add_co;   end
            3'b001: begin result = sub_res;   carry_out = sub_co;   end
            3'b010: begin result = mul_res;   carry_out = mul_co;   end
            3'b011: begin result = div_res;   carry_out = div_co;   end
            3'b100, 3'b101, 3'b110: begin result = logic_res; carry_out = logic_co; end
            3'b111: begin result = custom_res; carry_out = 0; end
            default: begin result = 0; carry_out = 0; end
        endcase
    end
endmodule
