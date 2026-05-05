module uart_master#(
    parameter SYS_CLK=100_000_000,
    parameter BAUD_RATE=9600
)(
    input clk,
    input rst,
    input tx_start,
    input[7:0]tx_data,
    output reg tx,
    output reg busy
);
parameter CLKS_PER_BIT=SYS_CLK/BAUD_RATE;
parameter N=$clog2(CLKS_PER_BIT);
reg[N-1:0]clk_count;
reg baud_tick;
parameter IDLE=0,START=1,DATA=2,PARITY=3,STOP=4;
reg[2:0]state,next_state;
reg[2:0]bit_index;
reg parity_bit;
always@(posedge clk)begin
        if(rst)begin
            clk_count<=0;
            baud_tick<=0;
        end else begin
            if(clk_count==CLKS_PER_BIT-1)begin
                clk_count<=0;
                baud_tick<=1;
            end else begin
                clk_count<=clk_count+1;
                baud_tick<=0;
            end
        end
    end
    always@(posedge clk)begin
        if(rst)
            state<=IDLE;
        else
            state<=next_state;
    end

    always@(*)begin
        next_state=state;
        case(state)
            IDLE:next_state=(tx_start)?START:IDLE;
            START:next_state=(baud_tick)?DATA:START;
            DATA:next_state=(baud_tick&&bit_index==7)?PARITY:DATA;
            PARITY:next_state=(baud_tick)?STOP:PARITY;
            STOP:next_state=(baud_tick)?IDLE:STOP;
        endcase
    end

    always@(posedge clk)begin
        if(rst)begin
            tx<=1'b1;
            busy<=0;
            bit_index<=0;
            parity_bit<=0;
        end else begin
            case(state)
                IDLE:begin
                    tx<=1'b1;
                    busy<=0;
                    bit_index<=0;
                end
                START:begin
                    busy<=1;
                    tx<=1'b0;
                    parity_bit<=^tx_data;
                end
                DATA:begin
                    if(baud_tick)begin
                        tx<=tx_data[bit_index];
                        bit_index<=bit_index+1;
                    end
                end
                PARITY:begin
                    if(baud_tick)
                        tx<=parity_bit;
                end
                STOP:begin
                    if(baud_tick)
                        tx<=1'b1;
                end
            endcase
        end
    end
endmodule
