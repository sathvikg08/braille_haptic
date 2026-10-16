// braille_decoder.v
// Combinational decoder: 6-dot braille cell -> 8-bit ASCII.
// dots[0] = dot1 ... dots[5] = dot6   (so dots = {d6,d5,d4,d3,d2,d1})
module braille_decoder (
    input  wire [5:0] dots,
    output reg  [7:0] ascii_out,
    output reg        valid        // 1 = recognised pattern, 0 = unknown
);
    always @(*) begin
        ascii_out = 8'h00;
        valid     = 1'b0;
        case (dots)
            6'b000000: begin ascii_out = 8'h20; valid = 1'b1; end  // space
            6'b000001: begin ascii_out = 8'h61; valid = 1'b1; end  // a  (dots 1)
            6'b000011: begin ascii_out = 8'h62; valid = 1'b1; end  // b  (dots 12)
            6'b001001: begin ascii_out = 8'h63; valid = 1'b1; end  // c  (dots 14)
            6'b011001: begin ascii_out = 8'h64; valid = 1'b1; end  // d  (dots 145)
            6'b010001: begin ascii_out = 8'h65; valid = 1'b1; end  // e  (dots 15)
            6'b001011: begin ascii_out = 8'h66; valid = 1'b1; end  // f  (dots 124)
            6'b011011: begin ascii_out = 8'h67; valid = 1'b1; end  // g  (dots 1245)
            6'b010011: begin ascii_out = 8'h68; valid = 1'b1; end  // h  (dots 125)
            6'b001010: begin ascii_out = 8'h69; valid = 1'b1; end  // i  (dots 24)
            6'b011010: begin ascii_out = 8'h6A; valid = 1'b1; end  // j  (dots 245)
            6'b000101: begin ascii_out = 8'h6B; valid = 1'b1; end  // k  (dots 13)
            6'b000111: begin ascii_out = 8'h6C; valid = 1'b1; end  // l  (dots 123)
            6'b001101: begin ascii_out = 8'h6D; valid = 1'b1; end  // m  (dots 134)
            6'b011101: begin ascii_out = 8'h6E; valid = 1'b1; end  // n  (dots 1345)
            6'b010101: begin ascii_out = 8'h6F; valid = 1'b1; end  // o  (dots 135)
            6'b001111: begin ascii_out = 8'h70; valid = 1'b1; end  // p  (dots 1234)
            6'b011111: begin ascii_out = 8'h71; valid = 1'b1; end  // q  (dots 12345)
            6'b010111: begin ascii_out = 8'h72; valid = 1'b1; end  // r  (dots 1235)
            6'b001110: begin ascii_out = 8'h73; valid = 1'b1; end  // s  (dots 234)
            6'b011110: begin ascii_out = 8'h74; valid = 1'b1; end  // t  (dots 2345)
            6'b100101: begin ascii_out = 8'h75; valid = 1'b1; end  // u  (dots 136)
            6'b100111: begin ascii_out = 8'h76; valid = 1'b1; end  // v  (dots 1236)
            6'b111010: begin ascii_out = 8'h77; valid = 1'b1; end  // w  (dots 2456)
            6'b101101: begin ascii_out = 8'h78; valid = 1'b1; end  // x  (dots 1346)
            6'b111101: begin ascii_out = 8'h79; valid = 1'b1; end  // y  (dots 13456)
            6'b110101: begin ascii_out = 8'h7A; valid = 1'b1; end  // z  (dots 1356)
            default:   begin ascii_out = 8'h3F; valid = 1'b0; end  // '?'
        endcase
    end
endmodule
