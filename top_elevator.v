`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:44:55 06/06/2016 
// Design Name: 
// Module Name:    top_elevator 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module top_elevator( rst_n, clk_df, ftsd, ftsd_ctl, led, row_n, col_n, 
	au_appsel, au_sysclk, au_bck, au_ws, au_data, 
	lcd_rst,  lcd_cs,  lcd_rw, lcd_di, lcd_d, lcd_e,
	dip,pb);
	input clk_df; // clock from the crystal
	input rst_n; // active low reset
	output [3:0]ftsd_ctl;
	output [14:0]ftsd;
	output reg [7:0]led; 
	output [3:0] row_n;
	input  [3:0] col_n;
	output au_appsel; // playing mode selection
	output au_sysclk; // control clock for DAC (from crystal)
	output au_bck; // bit clock of au data (5MHz)
	output au_ws; // left/right parallel to serial control
	output au_data; 
	output lcd_rst; // LCD reset
	output [1:0] lcd_cs; // LCD frame selection
	output lcd_rw; // LCD read/write control
	output lcd_di; // LCD data/instruction
	output [7:0] lcd_d; // LCD data
	output lcd_e; // LCD enable
	input [1:0]dip;
	input [7:0]pb;
	
	reg [7:0]led_next;
	reg [7:0]arr;
	reg [2:0]at;
	reg [1:0]state;
	reg [1:0]state_next;
	reg [3:0]i;
	wire [19:0]nd;
	
	wire [15:0] au_in_left, au_in_right;
	wire [3:0]clk_move;
	wire [3:0]ftsd_in;
	wire [1:0]clk_fs;
	
	reg move;	
	reg [3:0]fre;		//frequency indicator
	wire [15:0]key;
	
	buzzer_control Ung(
		.clk(clk_df), // clock from crystal
		.rst_n(rst_n&&~(fre==4'd15)), // active low reset
		.note_div(nd), // div for music note
		.au_left(au_in_left), // left audio
		.au_right(au_in_right) // right audio
	);
	// Speaker controllor
	speaker_control Usc(
		.clk(clk_df), // clock from the crystal
		.rst_n(rst_n&&~(fre==4'd15)), // active low reset
		.au_in_left(au_in_left), // left channel au data
		.au_in_right(au_in_right), // right channel au data
		.au_appsel(au_appsel), // mode selection
		.au_sysclk(au_sysclk), // control clock for DAC (from crystal)
		.au_bck(au_bck), // bit clock of au data (5MHz)
		.au_ws(au_ws), // left/right parallel to serial control
		.au_data(au_data) // serial output au data
	);
	note16 n16(
		.clk(clk_fs[0]),
		.nd(nd),
		.ki(fre),
		.pre(rst_n&&~(fre==4'd15)),
		.d1(),
		.d2()
	);
	wire [3:0]ff; //frequency flag
	reg [4:0]ft;	//frequency time
	wire [63:0]tune0=64'h0001222022002222;
	wire [63:0]tune1=64'h1112332133333333;
	wire [63:0]tune2=64'h2223555255225555;
	wire [63:0]tune3=64'h3335775377777777;
	wire [63:0]tune4=64'h5550123577777777;
	wire [63:0]tune5=64'h7771245799999999;
	wire [63:0]tune6=64'h99924679aaaaaaaa;
	wire [63:0]tune7=64'h9877339955aaaaaa;
	wire [6:0]addr;
   wire [7:0]data;
   wire clk_50k;
  
   reg clk_tm;		//clk true move
	wire ffrst;
	assign ffrst = ft[4]||~rst_n;
	assign ff = (move||ffrst)? 4'd8 : {1'b0,at};
	
	always @*
		case(ff)
			4'd0 :fre<=tune0[(60-ft*4)+:4];
			4'd1 :fre<=tune1[(60-ft*4)+:4];
			4'd2 :fre<=tune2[(60-ft*4)+:4];
			4'd3 :fre<=tune3[(60-ft*4)+:4];
			4'd4 :fre<=tune4[(60-ft*4)+:4];
			4'd5 :fre<=tune5[(60-ft*4)+:4];
			4'd6 :fre<=tune6[(60-ft*4)+:4];
			4'd7 :fre<=tune7[(60-ft*4)+:4];
			default:fre<=4'd15;
		endcase
	

	always @(negedge clk_move[2] or posedge move)
		if(move)
			ft <= 5'b0;
		else
			ft <= ft+1'b1;
	
	scan_ctl sc(
		.ftsd_ctl(ftsd_ctl),
		.ftsd_in(ftsd_in),
		.in0(4'hf),
		.in1(4'hf),
		.in2({2'b11,state}),
		.in3({1'b0,at}),
		.ftsd_ctl_en(clk_fs)
	);
	
	ftsd zer94ftsdr(
		.display(ftsd),
		.bcd(ftsd_in)
	);
	
	keypad_scan K1 (
    .rst_n(rst_n),
    .clk(clk_fs[0]),
    .col(col_n),
    .row(row_n),
    .change(),          // push and release
    .key(key)                 // mask {F,E,D,C,B,3,6,9,A,2,5,8,0,1,4,7}
  );
  
  
  rom_ctrl U_romctrl(
  .clk(clk_50k), // rom controller clock
  .rst_n(rst_n), // active low reset
  .en(lcd_e), // LCD enable
  .data_request(data_request), // request signal from LCD
  .address(addr), // requested address
  .data_ack(data_ack), // data ready acknowledge
  .data(data) // data to be transferred (byte)
);
  wire halt;
  lcd_ctrl U_LCDctrl(
  .clk(clk_50k), // LCD controller clock
  .rst_n(rst_n), // active low reset
  .data_ack(data_ack), // data re-arrangement buffer ready indicator
  .data(data), // byte data transfer from buffer
  .lcd_di(lcd_di), // LCD data/instruction 
  .lcd_rw(lcd_rw), // LCD Read/Write
  .lcd_en(lcd_e), // LCD enable
  .lcd_rst(lcd_rst), // LCD reset
  .lcd_cs(lcd_cs), // LCD frame select
  .lcd_data(lcd_d), // LCD data
  .addr(addr), // Address for each picture
  .data_request(data_request), // request for the memory data
  .cnt_e(~move),
  .halt(halt)
);
	
  clock_divider #(
    .half_cycle(400),         // half cycle = 400 (divided by 800)
    .counter_width(14)         // counter width = 10 bits
  ) www (
    .rst_n(rst_n),
    .clk(clk_df),
    .clk_div(clk_50k)
  );
  freq_div fd(
		.clk_out(clk_move),
		.clk_ctl(clk_fs),
		.clk(clk_df),
		.rst_n(rst_n)
	);
    
	
	always @(posedge clk_fs[0] or negedge rst_n)
		if(~rst_n)begin
			led <= 8'b0;
			state<=2'd1;
		end
		else begin
			led <= led_next;
			state<=state_next;
		end
	always @*begin
		led_next[0] = ~arr[0]&&( led[0] ||key[2] || ~pb[0] );	//key1
		led_next[1] = ~arr[1]&&( led[1] ||key[6] || ~pb[1] );	//key2
		led_next[2] = ~arr[2]&&( led[2] ||key[10]|| ~pb[2] );	//key3
		led_next[3] = ~arr[3]&&( led[3] ||key[1] || ~pb[3] );	//key4
		led_next[4] = ~arr[4]&&( led[4] ||key[5] || ~pb[4] );	//key5
		led_next[5] = ~arr[5]&&( led[5] ||key[9] || ~pb[5] );	//key6
		led_next[6] = ~arr[6]&&( led[6] ||key[0] || ~pb[6] );	//key7
		led_next[7] = ~arr[7]&&( led[7] ||key[4] || ~pb[7] );	//key8
	end
	
	always @(at)begin
		arr <= 8'b0;
		case(at)
			3'd0:arr[0] <= 1'b1;
			3'd1:arr[1] <= 1'b1;
			3'd2:arr[2] <= 1'b1;
			3'd3:arr[3] <= 1'b1;
			3'd4:arr[4] <= 1'b1;
			3'd5:arr[5] <= 1'b1;
			3'd6:arr[6] <= 1'b1;
			3'd7:arr[7] <= 1'b1;
		endcase
	end
	
	initial
		move<=1'b1;
	always @ *begin
		if((arr[0]&&( led[0] ||key[2] || ~pb[0] ))||
			(arr[1]&&( led[1] ||key[6] || ~pb[1] ))||
			(arr[2]&&( led[2] ||key[10]|| ~pb[2] ))||
			(arr[3]&&( led[3] ||key[1] || ~pb[3] ))||
			(arr[4]&&( led[4] ||key[5] || ~pb[4] ))||
			(arr[5]&&( led[5] ||key[9] || ~pb[5] ))||
			(arr[6]&&( led[6] ||key[0] || ~pb[6] ))||
			(arr[7]&&( led[7] ||key[4] || ~pb[7] )))begin
			move<=1'b0;
		end
		else begin
			if(halt)
				move<=1'b1;
			else
				move<=1'b0;
		end
	end
	
	always @*
		case(dip)
			2'd0:clk_tm=clk_move[3];
			2'd1:clk_tm=clk_move[0];
			2'd2:clk_tm=clk_move[2];
			2'd3:clk_tm=clk_move[1];
		endcase
	always @(posedge clk_tm or negedge rst_n)
		if(~rst_n)
			at <= 3'b0;
		else if(move)
			case(state)
				2'b0:/*down*/
					at <= at-1'b1;
				2'b1:/*idle*/;
				2'd2:/*up*/
					at <= at+1'b1;
				default:at<=at;
			endcase
	
	always @* begin					
		state_next = 2'd1;		//idle
		case(state)
			2'd0:begin
			for(i=4'd7;i<=4'd7;i=i-1'b1)begin
					if(led[i])begin
						if(at<(i))
							state_next = 2'd2; //up
						else if(at>(i))
							state_next = 2'd0; //down
						end
						//lack of open door signal
				end
			end
			2'd1:begin
				for(i=4'd0;i<=4'd7;i=i+1'b1)begin
					if(led[i])begin
						if(at<(i))
							state_next = 2'd2; //up
						else if(at>(i))
							state_next = 2'd0; //down
						end
						//lack of open door signal
				end
			end
			2'd2:begin
			for(i=4'd0;i<=4'd7;i=i+1'b1)begin
					if(led[i])begin
						if(at<(i))
							state_next = 2'd2; //up
						else if(at>(i))
							state_next = 2'd0; //down
						end
						//lack of open door signal
				end
			end
			default : state_next = state;
		endcase
	end
	
endmodule

