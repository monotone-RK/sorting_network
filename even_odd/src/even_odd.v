/******************************************************************************/
/* Sorting Network: Batcher's odd-even mergesort             Ryohei Kobayashi */
/*                                                         Version 2016-09-12 */
/******************************************************************************/
`default_nettype none
  
/***** Compare-and-exchange (CAE)                                         *****/
/******************************************************************************/
module CAE #(parameter               WIDTH = 64)
            (input  wire [WIDTH-1:0] DIN0,
             input  wire [WIDTH-1:0] DIN1,
             output wire [WIDTH-1:0] DOT0,
             output wire [WIDTH-1:0] DOT1);
  
  function [WIDTH-1:0] mux;
    input [WIDTH-1:0] a;
    input [WIDTH-1:0] b;
    input             sel;
    begin
      case (sel)
        1'b0: mux = a;
        1'b1: mux = b;
      endcase
    end
  endfunction
  
  wire comp_rslt = (DIN0[31:0] <= DIN1[31:0]);
  
  assign DOT0 = mux(DIN1, DIN0, comp_rslt);
  assign DOT1 = mux(DIN0, DIN1, comp_rslt);
  
endmodule


/***** BOX                                                                *****/
/******************************************************************************/
module BOX #(parameter                        P_LOG = 4,
             parameter                        WIDTH = 64)
            (input  wire                      CLK,
             input  wire [(WIDTH<<P_LOG)-1:0] DIN,
             output wire [(WIDTH<<P_LOG)-1:0] DOT);


  reg  [(WIDTH<<P_LOG)-1:0] pd [P_LOG-1:0];  // pipeline regester for data

  genvar i, j, k;
  generate
    for (i=0; i<P_LOG; i=i+1) begin: stage
      wire [(WIDTH<<P_LOG)-1:0] dot;
      if (i == 0) begin
        for (j=0; j<(1<<(P_LOG-1)); j=j+1) begin: caes
          CAE #(WIDTH) cae(DIN[WIDTH*(j+1)-1:WIDTH*j],
                           DIN[WIDTH*((j+1)+(1<<(P_LOG-1)))-1:WIDTH*(j+(1<<(P_LOG-1)))],
                           dot[WIDTH*(j+1)-1:WIDTH*j],
                           dot[WIDTH*((j+1)+(1<<(P_LOG-1)))-1:WIDTH*(j+(1<<(P_LOG-1)))]);
        end
        always @(posedge CLK) pd[i] <= dot;
      end else begin
        for (k=0; k<((1<<i)-1); k=k+1) begin: blocks
          for (j=0; j<(1<<(P_LOG-(i+1))); j=j+1) begin: caes
            CAE #(WIDTH) cae(pd[i-1][WIDTH*((j+1)+(k*(1<<(P_LOG-i)))+(1<<(P_LOG-(i+1))))-1:WIDTH*(j+(k*(1<<(P_LOG-i)))+(1<<(P_LOG-(i+1))))],
                             pd[i-1][WIDTH*((j+1)+(k*(1<<(P_LOG-i)))+(1<<(P_LOG-(i+1)))+(1<<(P_LOG-(i+1))))-1:WIDTH*(j+(k*(1<<(P_LOG-i)))+(1<<(P_LOG-(i+1)))+(1<<(P_LOG-(i+1))))],
                             dot[WIDTH*((j+1)+(k*(1<<(P_LOG-i)))+(1<<(P_LOG-(i+1))))-1:WIDTH*(j+(k*(1<<(P_LOG-i)))+(1<<(P_LOG-(i+1))))],
                             dot[WIDTH*((j+1)+(k*(1<<(P_LOG-i)))+(1<<(P_LOG-(i+1)))+(1<<(P_LOG-(i+1))))-1:WIDTH*(j+(k*(1<<(P_LOG-i)))+(1<<(P_LOG-(i+1)))+(1<<(P_LOG-(i+1))))]);
          end
        end
        always @(posedge CLK) pd[i] <= {pd[i-1][(WIDTH<<P_LOG)-1:WIDTH*((1<<P_LOG)-(1<<(P_LOG-(i+1))))], 
                                        dot[WIDTH*((1<<P_LOG)-(1<<(P_LOG-(i+1))))-1:WIDTH*(1<<(P_LOG-(i+1)))], 
                                        pd[i-1][WIDTH*(1<<(P_LOG-(i+1)))-1:0]};
      end
    end
  endgenerate
  
  assign DOT = pd[P_LOG-1];

endmodule  

  
/***** Sorting Network                                                    *****/
/******************************************************************************/
module EVEN_ODD #(parameter                        P_LOG = 4,
                  parameter                        WIDTH = 64)
                 (input  wire                      CLK,
                  input  wire                      RST_IN,
                  input  wire [(WIDTH<<P_LOG)-1:0] DIN,
                  input  wire                      DINEN,
                  output wire [(WIDTH<<P_LOG)-1:0] DOT,
                  output wire                      DOTEN);


  // Input
  ////////////////////////////////////////////////////////////////////////////////////////////////
  reg                      RST;   always @(posedge CLK) RST   <= RST_IN;
  reg [(WIDTH<<P_LOG)-1:0] din;   always @(posedge CLK) din   <= DIN;
  reg                      dinen; always @(posedge CLK) dinen <= (RST) ? 0 : DINEN;
  
  
  // Core
  ////////////////////////////////////////////////////////////////////////////////////////////////
  reg pc [((P_LOG*(P_LOG+1))>>1)-1:0];  // pipeline regester for control
  
  genvar i, j;
  generate
    for (i=0; i<P_LOG; i=i+1) begin: level
      wire [(WIDTH<<P_LOG)-1:0] box_din;
      wire [(WIDTH<<P_LOG)-1:0] box_dot;
      for (j=0; j<(1<<(P_LOG-(i+1))); j=j+1) begin: boxes
        BOX #((i+1), WIDTH) box(CLK, box_din[WIDTH*(1<<(i+1))*(j+1)-1:WIDTH*(1<<(i+1))*j], box_dot[WIDTH*(1<<(i+1))*(j+1)-1:WIDTH*(1<<(i+1))*j]);
      end
    end
  endgenerate
  
  generate
    for (i=0; i<P_LOG; i=i+1) begin
      if (i == 0) assign level[i].box_din = din;
      else        assign level[i].box_din = level[i-1].box_dot;
    end
  endgenerate

  integer p;
  always @(posedge CLK) begin
    if (RST) begin
      for (p=0; p<((P_LOG*(P_LOG+1))>>1); p=p+1) pc[p] <= 0;
    end else begin
      pc[0] <= dinen;
      for (p=1; p<((P_LOG*(P_LOG+1))>>1); p=p+1) pc[p] <= pc[p-1];
    end
  end
  

  // Output
  ////////////////////////////////////////////////////////////////////////////////////////////////
  assign DOT   = level[P_LOG-1].box_dot;
  assign DOTEN = pc[((P_LOG*(P_LOG+1))>>1)-1];

endmodule

`default_nettype wire
