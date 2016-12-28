//-----------------------------------------------------------------------------
// File          : freq.v
// Author        : Ryohei Kobayashi
// Created       : 28.12.2016
// Last modified : 28.12.2016
//-----------------------------------------------------------------------------
// Description :
// A project file to evaluate the maximum frequency of Bitonic mergesort 
// network
//-----------------------------------------------------------------------------
`default_nettype none

`define P_LOG  7
`define DATW  64
`define KEYW  32

module freq(input  wire       CLK,
            input  wire       RST_IN,
            output wire [1:0] ULED);

  reg RST; always @(posedge CLK) RST <= RST_IN;
     
  wire [(`DATW<<`P_LOG)-1:0] init_data;
  wire [(`DATW<<`P_LOG)-1:0] chk_rslt;
  
  reg  [(`DATW<<`P_LOG)-1:0] DIN;
  reg                        DINEN;
  
  wire [(`DATW<<`P_LOG)-1:0] DOT;
  wire                       DOTEN;
  
  reg  [(`DATW<<`P_LOG)-1:0] dot;
  reg                        doten;
  
  BITONIC #(`P_LOG, `DATW, `KEYW) bitonic(CLK, RST, DIN, DINEN, DOT, DOTEN);

  genvar i;
  generate
    for (i=0; i<(1<<`P_LOG); i=i+1) begin: loop
      wire [`KEYW-1:0] init_data_key = (1<<`P_LOG) - i;
      wire [`KEYW-1:0] chk_rslt_key  = i + 1;
      assign init_data[`DATW*(i+1)-1:`DATW*i] = {{(`DATW-`KEYW){1'b1}}, init_data_key};
      assign chk_rslt[`DATW*(i+1)-1:`DATW*i]  = {{(`DATW-`KEYW){1'b1}}, chk_rslt_key};
    end
  endgenerate
  
  always @(posedge CLK) begin
    if (RST) begin
      DIN    <= init_data;
      DINEN  <= 1;
      dot    <= 0;
      doten  <= 0;
    end else begin
      DIN    <= {DIN[`KEYW-1:0], DIN[(`DATW<<`P_LOG)-1:`KEYW]};
      DINEN  <= 0;
      dot    <= DOT;
      doten  <= DOTEN;
    end
  end
  
  assign ULED = {^dot, doten};
  
endmodule

`default_nettype wire
