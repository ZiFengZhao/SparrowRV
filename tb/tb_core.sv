`timescale 1ns/1ns
module tb_core(); 
//`define W25Q//启用w25q spi flash的仿真模型
`define CorePath inst_sparrow_soc.inst_core
//测试用信号
logic clk;
logic rst_n;
logic ex_trap_i;
logic JTAG_TCK,JTAG_TMS,JTAG_TDI,JTAG_TDO;//jtag
wire spi0_miso;
wire [31:0]fpioa;
wire uart0_rx=1'b1;//fpioa[0]
assign fpioa[0]=uart0_rx;
wire uart0_tx=fpioa[1];//fpioa[1]
wire spi0_cs=fpioa[2];//fpioa[2]
assign fpioa[3]=spi0_miso;//fpioa[3]
wire spi0_mosi=fpioa[4];//fpioa[4]
wire spi0_clk=fpioa[5];//fpioa[5]

genvar i,r;//计数工具人

//寄存器监测
wire [31:0] x3  = `CorePath.inst_regs.regs[3];
wire [31:0] x26 = `CorePath.inst_regs.regs[26];
wire [31:0] x27 = `CorePath.inst_regs.regs[27];
wire mends = `CorePath.inst_csr.mends;//仿真结束标志

// 读入程序
initial begin
	$readmemh ("inst.txt", `CorePath.inst_iram.inst_dpram.BRAM);
	$readmemh ("isp.txt", `CorePath.inst_iram.inst_isp.BRAM);
end

// 生成clk
initial begin
	clk = '0;
	forever #(5) clk = ~clk;
end

//启动测试
initial begin
	sysrst();//复位系统
	#900;
	/*ex_trap_i=1;
	#7;
	ex_trap_i=0;
*/
`ifdef ISA_TEST  //通过宏定义，控制是否是指令集测试程序
	wait(x26 == 32'b1);   // x26 == 1，结束仿真
	#10
	if (x27 == 32'b1) begin
	$display("~~~~~~~~~~~~~~~~~~~ TEST_PASS ~~~~~~~~~~~~~~~~~~~");
	$display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
	$display("~~~~~~~~~ #####     ##     ####    #### ~~~~~~~~~");
	$display("~~~~~~~~~ #    #   #  #   #       #     ~~~~~~~~~");
	$display("~~~~~~~~~ #    #  #    #   ####    #### ~~~~~~~~~");
	$display("~~~~~~~~~ #####   ######       #       #~~~~~~~~~");
	$display("~~~~~~~~~ #       #    #  #    #  #    #~~~~~~~~~");
	$display("~~~~~~~~~ #       #    #   ####    #### ~~~~~~~~~");
	$display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
	end else begin
	$display("~~~~~~~~~~~~~~~~~~~ TEST_FAIL ~~~~~~~~~~~~~~~~~~~~");
	$display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
	$display("~~~~~~~~~~######    ##       #    #     ~~~~~~~~~~");
	$display("~~~~~~~~~~#        #  #      #    #     ~~~~~~~~~~");
	$display("~~~~~~~~~~#####   #    #     #    #     ~~~~~~~~~~");
	$display("~~~~~~~~~~#       ######     #    #     ~~~~~~~~~~");
	$display("~~~~~~~~~~#       #    #     #    #     ~~~~~~~~~~");
	$display("~~~~~~~~~~#       #    #     #    ######~~~~~~~~~~");
	$display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
	$display("fail testnum = %2d", x3);
	for (r = 1; r < 32; r = r + 1)
		$display("x%2d = 0x%x", r, `CorePath.inst_regs.regs[r]);
	end
	$stop;//结束
`endif

end

initial begin
`ifndef MODELSIM
	#300000;//iverilog
`else 
	#3000000;//modeslsim
`endif
`ifdef ISA_TEST
	$display("*Sim tool:ISA_TEST Timeout, Err");//ISA测试超时
`else 
	$display("*Sim tool:Normal Sim Timeout");//普通仿真超时
`endif
	$stop;
end

initial begin
	#30;
	wait(mends === 1'b1)//软件控制仿真结束
	$display("*Sim tool:CSR MENDS END, stop sim");
	#10;
	$stop;
end

task sysrst;//复位任务
	ex_trap_i=0;
	JTAG_TCK=0;
	JTAG_TMS=0;
	JTAG_TDI=0;
	rst_n <= '0;
	#15
	rst_n <= '1;
	#10;
endtask : sysrst

for ( i=0; i <32 ; i++) begin//fpioa信号弱下拉
	assign (weak1,weak0) fpioa[i] = 1'b0;
end

initial begin
	wait(rst_n===1'b1);
	if(`CorePath.inst_iram.inst_dpram.BRAM[0][0]===1'bx) begin//如果inst.txt读入失败，停止仿真
		$display("*Sim tool:Inst load error");
		#10;
		$stop;
	end
end
sparrow_soc inst_sparrow_soc (
	.clk               (clk), 
	.hard_rst_n        (rst_n), 

	.JTAG_TCK          (JTAG_TCK),
	.JTAG_TMS          (JTAG_TMS),
	.JTAG_TDI          (JTAG_TDI),
	.JTAG_TDO          (JTAG_TDO),

    .fpioa             (fpioa),//处理器IO接口

	.ex_trap_i         (ex_trap_i)
);

`ifdef W25Q
pullup(WPn);
pullup(HOLDn);
W25Q128JVxIM inst_W25Q128JVxIM (
	.CSn   (spi0_cs),
	.CLK   (spi0_clk),
	.DIO   (spi0_mosi),
	.DO    (spi0_miso),
	.WPn   (WPn),
	.HOLDn (HOLDn)
);
`endif

// 输出波形
`ifndef MODELSIM
initial begin
	$dumpfile("tb.lxt");  //生成lxt的文件名称
	$dumpvars(0,tb_core);   //tb中实例化的仿真目标实例名称	
end
`endif

endmodule