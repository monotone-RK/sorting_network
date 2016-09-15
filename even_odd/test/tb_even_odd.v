/******************************************************************************/
/* A test bench                                              Ryohei Kobayashi */
/*                                                         Version 2016-09-12 */
/******************************************************************************/
`default_nettype none
  
`include "even_odd.v"

`define P_LOG  9
`define DATW  64
`define KEYW  32
  
module tb_EVEN_ODD();

  reg CLK; initial begin CLK=0; forever #50 CLK=~CLK; end
  reg RST; initial begin RST=1; #400 RST=0; end
  
  wire [(`DATW<<`P_LOG)-1:0] init_data;
  wire [(`DATW<<`P_LOG)-1:0] chk_rslt;
  
  reg                        rst_buf;
  reg                        finish;
     
  reg  [(`DATW<<`P_LOG)-1:0] DIN;
  reg                        DINEN;
  
  wire [(`DATW<<`P_LOG)-1:0] DOT;
  wire                       DOTEN;
  
  EVEN_ODD #(`P_LOG, `DATW, `KEYW) even_odd(CLK, RST, DIN, DINEN, DOT, DOTEN);

  genvar i;
  generate
    for (i=0; i<(1<<`P_LOG); i=i+1) begin: loop
      wire [`KEYW-1:0] init_data_key = (1<<`P_LOG) - i;
      wire [`KEYW-1:0] chk_rslt_key  = i + 1;
      assign init_data[`DATW*(i+1)-1:`DATW*i] = {{(`DATW-`KEYW){1'b1}}, init_data_key};
      assign chk_rslt[`DATW*(i+1)-1:`DATW*i]  = {{(`DATW-`KEYW){1'b1}}, chk_rslt_key};
      always @(posedge CLK) if (DOTEN) $write("%d ", DOT[(`KEYW+`DATW*i)-1:`DATW*i]);
    end
  endgenerate
  
  always @(posedge CLK) rst_buf <= RST;
    
  always @(posedge CLK) begin
    if (rst_buf) begin
      DIN    <= init_data;
      DINEN  <= 1;
      finish <= 0;
    end else begin
      DINEN  <= 0;
      finish <= DOTEN;
      if (DOTEN && (chk_rslt != DOT)) $write("ERROR!!\n");
      if (finish) begin 
        $write("\n"); 
        $finish(); 
      end
    end
  end
  
endmodule

`default_nettype wire
