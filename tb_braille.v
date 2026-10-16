// tb_braille.v  -- testbench driven by braille_app.py
// Reads N patterns from input.mem, feeds them to the decoder, prints results.
`timescale 1ns/1ps
module tb_braille;
    reg  [5:0] dots;
    wire [7:0] ascii_out;
    wire       valid;
    reg  [5:0] mem [0:4095];
    integer    n, i;

    braille_decoder dut (.dots(dots), .ascii_out(ascii_out), .valid(valid));

    initial begin
        if (!$value$plusargs("N=%d", n)) n = 0;
        $readmemb("input.mem", mem);
        for (i = 0; i < n; i = i + 1) begin
            dots = mem[i];
            #10;
            $display("RESULT %0d %0d", ascii_out, valid);
        end
        $finish;
    end
endmodule
