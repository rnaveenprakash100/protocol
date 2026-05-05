module spi_master
  (
    input clk,
    input rst_n,
    input [7:0]m_data_in,
    input MISO,
    input transfer_en,
    input [1:0]slav_sel,
    input CPOL,CPHA,
    output reg SCLK,
    output reg MOSI,
    output reg CS0,
    output reg CS1,
    output reg CS2,
    output reg m_busy,
    output reg m_done,
    output reg[7:0]m_data_out,
    output reg temp_CPHA,temp_CPOL
  );
  localparam [1:0] IDLE=2'b00,LOAD=2'b01,TRANSFER=2'b10,STOP=2'b11;
  reg [1:0] state,nxt_state;
  reg SCLK_en,SCLK_prev;
  reg [7:0]tx_reg,rx_reg;
  reg[3:0] bit_count;
  reg [1:0]count;
  wire rising_edge,falling_edge; 
 //clk divider  
  always@(posedge clk) begin
    if(!rst_n) begin
       count<=2'b00;
       SCLK_prev<=CPOL;
       SCLK<=CPOL;
      end
    else if(SCLK_en) begin
       count<=count+1'b1;
       SCLK_prev<=SCLK;
      if(count==2'b10) begin
         SCLK<=~SCLK;
         count<=2'b00;
       end
      end
    else begin 
      SCLK_prev<=SCLK;
      SCLK<=CPOL;
     end
  end
  // fsm
  always @(posedge clk or negedge rst_n)begin
      if(!rst_n)begin
        MOSI<=1'bx;
        CS0<=1'b1;
        CS1<=1'b1;
        CS2<=1'b1;
        tx_reg<=8'b0;
        rx_reg<=8'b0;
        m_data_out<=8'b0;
        state<=IDLE;
      end
      else
        state<=nxt_state;
    end
  //nxt_state logic
  always@(*)begin
      case(state)
        IDLE:begin
          if(transfer_en && (slav_sel<=2'b10))begin
            nxt_state=LOAD;
          end
          else 
            nxt_state=IDLE;
        end
        LOAD:begin
          nxt_state=TRANSFER;
        end
        TRANSFER:begin
          if(bit_count==4'b1000) begin
            nxt_state=STOP;
            bit_count=4'd0;
          end
          else begin
            nxt_state=TRANSFER;
          end
        end
        STOP:begin
            nxt_state=IDLE;
        end
        default:nxt_state=IDLE;
      endcase
    end   
  //rising edgeand falling edge detection
assign rising_edge=(SCLK_prev==0 && SCLK==1);
assign falling_edge=(SCLK_prev==1 && SCLK==0);
//output logic
 always@(posedge clk)begin
   if(!rst_n)begin
        SCLK_en<=1'b0;
        m_busy<=1'b1;
        m_done<=1'b1;
        end
      else begin
        case(state)
          IDLE:begin
          if(transfer_en )begin
            case(slav_sel)
              2'b00:CS0<=1'b0;
              2'b01:CS1<=1'b0;
              2'b10:CS2<=1'b0;
              default:begin
                CS0<=1'b1;
                CS1<=1'b1;
                CS2<=1'b1;
              end
             endcase
             bit_count<=1'b0;
             SCLK_en<=1'b0;
             m_busy<=1'b0;
             m_done<=1'b0;
             MOSI<=1'bx;
             temp_CPHA<=CPHA;
             temp_CPOL<=CPOL;
          end
         end
       LOAD:begin
          tx_reg<=m_data_in;
          rx_reg<=8'b0;
         if(CPHA==0)begin
            MOSI<=m_data_in[7];
          end
          bit_count<=1'b0;
          m_busy<=1'b1;
          m_done<=1'b0;
          temp_CPHA<=temp_CPHA;
          temp_CPOL<=temp_CPOL;
         end
        TRANSFER:begin
          temp_CPHA<=temp_CPHA;
          temp_CPOL<=temp_CPOL;
          SCLK_en<=1'b1;
          m_busy<=1'b1;
          case({temp_CPOL,temp_CPHA})
            2'b00:begin
              if(falling_edge) begin
                tx_reg<={tx_reg[6:0],1'b0};
                MOSI<=tx_reg[6]; 
              end
               if(rising_edge) begin
                 rx_reg<={rx_reg[6:0],MISO};
                 bit_count<=bit_count+1;
              end
             end
            2'b01:begin
               if(rising_edge) begin
                 MOSI<=tx_reg[7];
                 tx_reg<={tx_reg[6:0],1'b0};
               end
               if(falling_edge) begin
                  rx_reg<={rx_reg[6:0],MISO};
                 bit_count<=bit_count+1;
                end
               end
            2'b10:begin
              if(rising_edge) begin
                  tx_reg<={tx_reg[6:0],1'b0};
                  MOSI <= tx_reg[6]; 
                end            
              if(falling_edge) begin
                  rx_reg<={rx_reg[6:0],MISO};
                  bit_count<=bit_count+1;
                end
              end
            2'b11:begin
              if(falling_edge) begin
                  MOSI<=tx_reg[7];
                  tx_reg<={tx_reg[6:0],1'b0};
                end
              if(rising_edge) begin
                  rx_reg<={rx_reg[6:0],MISO};
                  bit_count<=bit_count+1;
                end
             end
          endcase
        end
        STOP:begin
          m_data_out<=rx_reg;
          MOSI<=1'bx;
          SCLK_en<=1'b0;
          m_done<=1'b1;
          CS0<=1'b1;
          CS1<=1'b1;
          CS2<=1'b1;
        end
      endcase
     end
    end
  endmodule
