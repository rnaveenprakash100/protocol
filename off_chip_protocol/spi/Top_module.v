module spi_top(
    input clk,
    input rst_n,
    input transfer_en,
    input [7:0]m_data_in,
    input [7:0]s_data_in,
    input [1:0]slav_sel,
    input CPOL,
    input CPHA,
    output [7:0]m_data_out,
    output [7:0]s_data_out
);
  wire SCLK;
  wire MOSI;
  wire MISO;
  wire CS0,CS1,CS2;
  wire m_busy,m_done;
  wire s0_busy,s1_busy,s2_busy;
  wire s0_done,s1_done,s2_done;
  wire MISO0,MISO1,MISO2;
  wire temp_CPOL,temp_CPHA;
  wire [7:0] s0_data_out;
  wire [7:0] s1_data_out;
  wire [7:0] s2_data_out;
  spi_master master(.clk(clk),
                    .rst_n(rst_n),
                    .m_data_in(m_data_in),
                    .MISO(MISO),
                    .transfer_en(transfer_en),
                    .slav_sel(slav_sel),
                    .CPOL(CPOL),
                    .CPHA(CPHA),
                    .SCLK(SCLK),
                    .MOSI(MOSI),
                    .CS0(CS0),
                    .CS1(CS1),
                    .CS2(CS2),
                    .m_busy(m_busy),
                    .m_done(m_done),
                    .m_data_out(m_data_out),
                    .temp_CPHA(temp_CPHA),
                    .temp_CPOL(temp_CPOL));
  
  spi_slave slave0(.SCLK(SCLK),
                   .MOSI(MOSI),
                   .CS(CS0),
                   .CPOL(temp_CPOL),
                   .CPHA(temp_CPHA),
                   .MISO(MISO0),
                   .s_busy(s0_busy),
                   .s_done(s0_done)
                   ,.s_data_in(s_data_in),
                   .s_data_out(s0_data_out));
  
  spi_slave slave1(.SCLK(SCLK),
                   .MOSI(MOSI),
                   .CS(CS1),
                   .CPOL(temp_CPOL),
                   .CPHA(temp_CPHA),
                   .MISO(MISO1),
                   .s_busy(s1_busy),
                   .s_done(s1_done),
                   .s_data_in(s_data_in),
                   .s_data_out(s1_data_out));
  
  spi_slave slave2(.SCLK(SCLK),
                   .MOSI(MOSI),
                   .CS(CS2),
                   .CPOL(temp_CPOL),
                   .CPHA(temp_CPHA),
                   .MISO(MISO2),
                   .s_busy(s2_busy),
                   .s_done(s2_done),
                   .s_data_in(s_data_in),
                   .s_data_out(s2_data_out));
  
  assign MISO=(!CS0)?MISO0:(!CS1)?MISO1:(!CS2)?MISO2:1'bz;
  assign s_data_out =(!CS0)?s0_data_out:(!CS1)?s1_data_out:(!CS2)?s2_data_out:8'b0; 
endmodule  
