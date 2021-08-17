
// I2C Master Controller Module
`timescale 1ns/1ps
module i2c_master_controller(
	input        i2c_clock_in      , // top module clock signal
	input        i2c_reset_in      , // active high reset signal
	input        i2c_start         , // start signal connected to wr_en of fifo
	input        rw_bit            , // rw_bit is used for read and write operation
	input  [6:0] i2c_master_addr_wr, // address in which master is read or write data
	input  [7:0] i2c_master_data_wr, // data write into slave
	output [7:0] i2c_master_data_rd, // data read from slave
	output       fifo_full         , // when fifo is full it shows high
	output       ready_out         , // master is ready to transfer addr and data
	inout        i2c_sda_inout     , // serial data line
	inout        i2c_scl_inout       // serial clock line
				      );
	
	// parameter & signal declaration
	localparam DSIZE = 15;
	localparam ASIZE = 9 ;
	
	wire [14:0] fifo_data_in  ; // addr+data going to fifo
	wire [14:0] fifo_data_out ; // addr+data coming from fifo
	wire [6:0]  fsm_addr_in   ; // 7bit addr going to slave_fsm
	wire [7:0]  fsm_data_in   ; // 8bit data going to slave_fsm
	wire        empty         ; // connected to empty port in fifo
	wire        ready_in      ; // connected to ready_out port
	wire        vld_master_en ; // goes to rd_en of fifo and start of slave_fsm
	
	assign fifo_data_in  = {i2c_master_addr_wr, i2c_master_data_wr}; // 15bit addr+data
	assign fsm_addr_in   = fifo_data_out[14:8]; // upper 7bit detect as addr 
	assign fsm_data_in   = fifo_data_out[7:0] ; // lower 8bit detect as data
	assign ready_out     = ready_in           ; // ready for read & write to slave
	assign vld_master_en = ~empty & ready_in  ; // enables read operation for fifo & start operation for fsm
	
	// fsm_controller instatiation
	i2c_fsm_controller i2c_fsm_controller_inst
	(.i2c_clock_in        (i2c_clock_in)      , // clock_port
	 .i2c_reset_in        (i2c_reset_in)      , // reset_port
	 .enable              (vld_master_en)     , // slave_fsm enable port for start operation
	 .rw_bit              (rw_bit)            , // read write port
	 .fifo_to_fsm_addr_in (fsm_addr_in)       , // address port
	 .fifo_to_fsm_data_in (fsm_data_in)       , // data_write port
	 .i2c_master_data_out (i2c_master_data_rd), // data_read port
	 .i2c_sda             (i2c_sda_inout)     , // i2c_sda port
	 .i2c_scl             (i2c_scl_inout)     , // i2c_scl port
	 .ready               (ready_in)            // ready for read and write
	                                         );
								  
	// i2c_fifo instatiation
	i2c_fifo #(.FIFO_WIDTH (DSIZE)          , // parameter instantiation for data size
		   .FIFO_ADDR  (ASIZE)            // parameter instantiation for address size
		  ) i2c_fifo_inst
	          (.i2c_clock_in (i2c_clock_in) , // clock_port
		   .i2c_reset_in (i2c_reset_in) , // reset_port
		   .wr_en_in     (i2c_start)    , // fifo wr_en port
		   .rd_en_in     (vld_master_en), // fifo rd_en port
		   .data_in      (fifo_data_in) , // input data port
		   .data_out     (fifo_data_out), // output data port
		   .fifo_full    (fifo_full)    , // fifo full detection port
		   .fifo_empty   (empty)          // fifo empty detection port
				               );

endmodule
