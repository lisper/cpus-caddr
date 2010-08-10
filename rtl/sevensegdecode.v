// sevensegdecode.v
// seven segment decoder for s3board

module sevensegdecode(digit, ss_out);

    input [3:0] digit;
    output [6:0] ss_out;
   
    // segments abcdefg
    //  a
    // f b
    //  g
    // e c
    //  d

    assign ss_out =
        (digit == 4'd0) ? 7'b0000001 :
        (digit == 4'd1) ? 7'b1001111 :
        (digit == 4'd2) ? 7'b0010010 :
        (digit == 4'd3) ? 7'b0000110 :
        (digit == 4'd4) ? 7'b1001100 :
        (digit == 4'd5) ? 7'b0100100 :
        (digit == 4'd6) ? 7'b1100000 :
        (digit == 4'd7) ? 7'b0001111 :
        (digit == 4'd8) ? 7'b0000000 :
        (digit == 4'd9) ? 7'b0001100 :
        (digit == 4'ha) ? 7'b0001001 :
        (digit == 4'hb) ? 7'b1100000 :
        (digit == 4'hc) ? 7'b0110001 :
        (digit == 4'hd) ? 7'b1000010 :
        (digit == 4'he) ? 7'b0010000 :
        (digit == 4'hf) ? 7'b0111000 :
    	7'b1111111;
   
endmodule
