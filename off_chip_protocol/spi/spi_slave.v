module spi_slave(
    input SCLK,
    input [7:0] s_data_in,
    input MOSI,
    input CS,
    input CPOL,
    input CPHA,
    output reg MISO,
    output reg s_busy,
    output reg s_done,
  output reg [7:0] s_data_out
);
  reg [7:0] tx_reg,rx_reg;
  reg [3:0] bit_count;
  reg SCLK_prev;
  always @(negedge CS) begin
    tx_reg<=s_data_in;
    rx_reg<=8'b0;
    bit_count<=3'd0;
    s_done <= 1'b0;
      if(CPHA==0)//preload for 00 and 10
      MISO<=s_data_in[7];
  end
always @(negedge SCLK) begin //faling edge 
    if(CS) begin
      MISO <= 1'bz;
      s_busy <= 1'b0;
    end
    else begin
      if(bit_count<=8)begin
        case({CPOL,CPHA})
        2'b00: begin
            tx_reg<={tx_reg[6:0],1'b0};
            MISO <= tx_reg[6]; 
        end
          2'b11: begin
            MISO<=tx_reg[7];
            tx_reg<={tx_reg[6:0],1'b0};
        end
        2'b01: begin
            rx_reg<={rx_reg[6:0],MOSI};
            bit_count<=bit_count+1;
          if(bit_count==4'b0111)begin
               s_done<=1'b1;
               s_data_out=rx_reg;
          end
        end
          2'b10: begin
            rx_reg<={rx_reg[6:0],MOSI};
            bit_count<=bit_count+1;
            if(bit_count==4'b0111)begin
               s_done<=1'b1;
               s_data_out=rx_reg;
            end
        end
        endcase
      end
    end
end
always @(posedge SCLK) begin//rising edge
    if(CS) begin            
      s_done<=1'b0;        
      s_busy<=1'b0; 
    end
    else begin
      if(bit_count<9)begin
       s_busy<=1'b1;
        case({CPOL,CPHA})
        2'b00: begin
            rx_reg<={rx_reg[6:0],MOSI};
            bit_count<=bit_count+1;
          if(bit_count==4'b1000)begin
              s_done<=1'b1;
              s_data_out=rx_reg;
          end
        end
        2'b11: begin
            rx_reg<={rx_reg[6:0],MOSI};
            bit_count<=bit_count + 1;
          if(bit_count==4'b1000)begin
              s_done<=1'b1;
              s_data_out=rx_reg;
          end
        end
        2'b01: begin
            MISO<=tx_reg[7];
            tx_reg<={tx_reg[6:0],1'b0};
        end
        2'b10: begin
            tx_reg<={tx_reg[6:0],1'b0};
            MISO <= tx_reg[6];
        end
        endcase
      end
    end
 end
endmodule
