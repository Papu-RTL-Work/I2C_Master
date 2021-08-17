
// testbench to verify i2c master controller

`timescale 1ns/1ps
module i2c_master_controller_test;

	// signal declaration
	reg        sda_in            ; // regester store data_bit value
	reg        i2c_clock_in      ; // top module clock signal
	reg        i2c_reset_in      ; // active high reset signal
	reg        i2c_start         ; // start writing addr+data into fifo
	reg        rw_bit            ; // read_write signal
	reg  [6:0] i2c_master_addr_wr; // address in which master is read or write data
	reg  [7:0] i2c_master_data_wr; // data write into slave
	wire [7:0] i2c_master_data_rd; // data read from slave
	wire       fifo_full         ; // when fifo is full it shows high
	wire       ready_out         ; // master is ready to transfer addr and data
	wire       i2c_sda_inout     ; // serial data line
	wire       i2c_scl_inout     ; // serial clock line
	
	// master controller module instatiation
	i2c_master_controller i2c_master_controller_inst
	(.i2c_clock_in       (i2c_clock_in)      , // top module clock signal
	 .i2c_reset_in       (i2c_reset_in)      , // active high reset signal
	 .i2c_start          (i2c_start)         , // start signal connected to wr_en of fifo
	 .rw_bit             (rw_bit)            , // rw_bit is used for read and write operation
	 .i2c_master_addr_wr (i2c_master_addr_wr), // address in which master is read or write data
	 .i2c_master_data_wr (i2c_master_data_wr), // data write into slave
	 .i2c_master_data_rd (i2c_master_data_rd), // data read from slave
	 .fifo_full          (fifo_full)         , // when fifo is full it shows high
	 .ready_out          (ready_out)         , // master is ready to transfer addr and data
	 .i2c_sda_inout      (i2c_sda_inout)     , // serial data line
	 .i2c_scl_inout      (i2c_scl_inout)       // serial clock line
	                                        );
									  
	// Initialise all the inputs
	task initialise;
		begin
			rw_bit             = 1'b0;
			i2c_master_addr_wr = 7'd0;
			i2c_master_data_wr = 8'd0;
			i2c_start          = 1'b0;
			sda_in             = 1'b0;
		end
	endtask
	
	// start logic
	task enable;
		begin
			i2c_start = 1'b1;
			#10;
			i2c_start = 1'b0;
		end
	endtask
	
	// reset logic
	task clear;
		begin
			i2c_reset_in = 1'b1;
			#30;
			i2c_reset_in = 1'b0;
		end
	endtask
	
	// clock generation logic	
	initial
		begin
			i2c_clock_in = 1'b0;
			forever
				#5 i2c_clock_in = ~i2c_clock_in;
			end
		
	assign i2c_sda_inout = !i2c_master_controller_inst.i2c_fsm_controller_inst.write_en ? sda_in : 1'bz;
	
	initial 
		begin
			initialise;
			clear     ;	
			
			// logic to write data & addr 
			@(negedge i2c_clock_in)         ;
			i2c_master_addr_wr = 7'b1010101 ;
			i2c_master_data_wr = 8'b11010011;
			enable                          ;
			#100;	
	
			// read ack state1 
			sda_in = 1'b0;
			#10;
			#95;
			
			// logic to read data
			rw_bit = 1'b1                   ;
			@(negedge i2c_clock_in)         ;
			i2c_master_addr_wr = 7'b1011001 ;
			i2c_master_data_wr = 8'b10110110;
			enable                          ;
			#100;
			
			// read ack state1
			sda_in = 1'b0; #10;
			
			// read data
			sda_in = 1'b1; #10;
			sda_in = 1'b0; #10;
			sda_in = 1'b0; #10;
			sda_in = 1'b1; #10;
			sda_in = 1'b1; #10;
			sda_in = 1'b0; #10;
			sda_in = 1'b0; #10;
			sda_in = 1'b1; #10;
			#40;			
			$finish;
		end
	
endmodule
