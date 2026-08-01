`timescale 1ns / 1ps

// top module
module async_fifo #(parameter depth =16 , parameter width=8

    )(input wclk,rclk,reset,wr_en,rd_en,
    input [width-1:0] datain, output wire full,empty,
    output reg [width-1:0] dataout);
    wire rd_sync,wr_sync;
reset_sync u1(wclk,reset,wr_sync);
reset_sync u2(rclk,reset,rd_sync);

localparam ADDR_BITS = $clog2(depth);     // 16 → 4
localparam PTR_BITS  = ADDR_BITS + 1;     // 4+1 = 5 (extra MSB trick!)

reg [PTR_BITS-1:0] wptr_bin,rptr_bin;
wire[PTR_BITS-1:0] wptr_gray,rptr_gray ;

// binary to gray conversion
assign wptr_gray = wptr_bin ^ (wptr_bin >> 1);
assign rptr_gray = rptr_bin ^ (rptr_bin >> 1);

reg [width-1:0]     mem [0:depth-1];      // memory array

//full empty condition
wire [PTR_BITS-1:0]wptr_gray_sync,rptr_gray_sync;
syncff_2 u3 (.clk(rclk), .rst(rd_sync), .gray(wptr_gray), .sync_gray(wptr_gray_sync));
syncff_2 u4 (.clk(wclk), .rst(wr_sync), .gray(rptr_gray), .sync_gray(rptr_gray_sync));

assign empty = ( rptr_gray == wptr_gray_sync);
assign full = ((wptr_gray[PTR_BITS-1]!= rptr_gray_sync[PTR_BITS-1])&&(wptr_gray[PTR_BITS-2]!= rptr_gray_sync[PTR_BITS-2])&&(wptr_gray[PTR_BITS-3:0]==rptr_gray_sync[PTR_BITS-3:0]));


//write condition
always@(posedge wclk or posedge wr_sync)
if(wr_sync)
begin
wptr_bin<=0;
dataout<=0;
end
else
begin
if(wr_en&&!full)
begin
mem[wptr_bin[ADDR_BITS-1:0]]<=datain;
wptr_bin<=wptr_bin+1'b1;
end
end

//read condition
always@(posedge rclk or posedge rd_sync)
if(rd_sync)
rptr_bin<=0;
else
begin
if(rd_en&&!empty)
begin
dataout<= mem[rptr_bin[ADDR_BITS-1:0]];
rptr_bin<=rptr_bin+1'b1;
end
end
endmodule

// reset module
module reset_sync (
    input  wire clk,
    input  wire async_rst,
    output reg  sync_rst
);
reg async_meta;

always@(posedge clk or posedge async_rst)
begin
if(async_rst)
begin
sync_rst<=1;
async_meta<=1'b1;
end
else
begin
async_meta<=1'b0;
sync_rst<=async_meta;
end
end
endmodule

// cross domain for full and empty
module syncff_2 #(parameter WIDTH=5)(input clk,rst,input [WIDTH-1:0]gray,output reg [WIDTH-1:0]sync_gray);

reg [WIDTH-1:0]async_gray;

always@(posedge clk or posedge rst )
begin
if(rst)
begin
sync_gray<=0;
async_gray<=0;
end
else
begin
async_gray<=gray;
sync_gray<=async_gray;
end
end
endmodule
