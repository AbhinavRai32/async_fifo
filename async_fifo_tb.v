`timescale 1ns / 1ps

module async_fifo_tb(

    );
    parameter width=8;
    parameter depth=16;
    parameter N=17;
    reg wclk,rclk,rst,wr_en,rd_en;
    reg [width-1:0] datain;
    wire full,empty;
    wire [width-1:0] dataout;
    
    async_fifo asf(.wclk(wclk),.rclk(rclk),.reset(rst),.wr_en(wr_en),.rd_en(rd_en),.datain(datain),.dataout(dataout),.full(full),.empty(empty));
  
    reg [width-1:0] expected_data;
reg [width-1:0] ref_mem [0:depth-1];
integer ref_wptr, ref_rptr;
localparam ADDR_BITS = $clog2(depth);   
integer i2,i3; 
reg read_valid;
 
    // reference model tasks
//write condition
always@(posedge wclk )
if(rst)
ref_wptr<=0;
else
begin
if(wr_en&&!full)
begin
ref_mem[ref_wptr[ADDR_BITS-1:0]]<=datain;
ref_wptr<=ref_wptr+1'b1;
end
end

//read condition
always@(posedge rclk )
if(rst)
begin
ref_rptr<=0;
read_valid<=0;
end
else
begin
if(rd_en&&!empty)
begin
expected_data<= ref_mem[ref_rptr[ADDR_BITS-1:0]];
ref_rptr<=ref_rptr+1'b1;
read_valid<=1;
end
else
read_valid<=0;
end

//compare
always@(negedge rclk)
begin
if(read_valid)
  if (expected_data === dataout) begin
            $display("\n[PASS] : expected=%h, got=%h\n", expected_data, dataout);
        end else begin
            $display("\n[FAIL] : expected=%h, got=%h\n", expected_data, dataout);
        end
        end
    
    initial
    {wclk,rclk,rst,wr_en,rd_en,datain,expected_data}=0;
    
    always #10 wclk=~wclk;
        always #7 rclk=~rclk;
        
        initial 
        begin
        // Reset
        @(posedge wclk);#2;
        rst = 1;
        @(posedge wclk);#2;
        rst = 0;
        $display("\n===== FIFO TEST START =====\n");
        
fork  
   begin   
    // WRITE stimulus - independent
    for (i2 = 0; i2 < N; i2 = i2 + 1) begin
    @(posedge wclk);
     @(posedge wclk);
     #2;
        datain = $random;
        wr_en = 1;      
        @(posedge wclk);
    end
    wr_en = 0;
    end
    // READ stimulus - independent
begin
    for (i3 = 0; i3 < N; i3 = i3 + 1) begin
        rd_en = 1;     
        @(posedge rclk);
        @(posedge rclk);
        #2;
    end
    rd_en = 0;
    end
    join
    #160 $finish;
end  

endmodule
