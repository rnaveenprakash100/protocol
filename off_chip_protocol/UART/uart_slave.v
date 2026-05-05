module uart_slave#(
    parameter SYS_CLK=100_000_000,
    parameter BAUD_RATE=9600,
    parameter OVER_SAMPLING_FACTOR=16)
  (
    input clk,
    input rst,
    input rx,
    output reg[7:0]rx_data,
    output reg error
);
parameter MAX_COUNT=SYS_CLK/(BAUD_RATE*OVER_SAMPLING_FACTOR);
parameter N=$clog2(MAX_COUNT);
reg[N-1:0]counter;
reg baud_tick;
reg baud_en;
reg[3:0]tick_count;
always@(posedge clk)begin
        if(rst)begin
            counter<=0;
            baud_tick<=0;
            tick_count<=0;
        end else if(baud_en)begin
            baud_tick<=0;
            if(counter==MAX_COUNT-1)begin
                counter<=0;
                baud_tick<=1;
                if(tick_count==15)
                    tick_count<=0;
                else
                    tick_count<=tick_count+1;
            end else begin
                counter<=counter+1;
            end
        end else begin
            counter<=0;
            baud_tick<=0;
            tick_count<=0;
        end
    end

    parameter IDLE=0,START=1,DATA=2,PARITY=3,STOP=4;
    reg[2:0]state,nxt_state;

    reg[7:0]rx_shift_reg;
    reg[3:0]rx_count;
    reg start;
    reg parity_check;

    always@(posedge clk)begin
        if(rst)
            state<=IDLE;
        else
            state<=nxt_state;
    end
    always@(*)begin
        nxt_state=state;
        case(state)
            IDLE:nxt_state=(!rx)?START:IDLE;
            START:nxt_state=(tick_count==15&&start)?DATA:START;
            DATA:nxt_state=(tick_count==15&&rx_count==7)?PARITY:DATA;
            PARITY:nxt_state=(tick_count==15)?STOP:PARITY;
            STOP:nxt_state=(tick_count==15)?IDLE:STOP;
        endcase
    end

    always@(posedge clk)begin
        if(rst)begin
            baud_en<=0;
            rx_shift_reg<=0;
            rx_count<=0;
            start<=0;
            parity_check<=0;
            rx_data<=0;
            error<=0;
        end else begin
            case(state)
                IDLE:begin
                    baud_en<=0;
                    start<=0;
                end
                START:begin
                    baud_en<=1;
                    if(tick_count==8&&rx==0)
                        start<=1;
                    if(tick_count==15)
                        rx_count<=0;
                end
                DATA:begin
                    baud_en<=1;
                    if(tick_count==8)
                        rx_shift_reg[rx_count]<=rx;
                    if(tick_count==15)
                        rx_count<=rx_count+1;
                end
                PARITY:begin
                    if(tick_count==8)
                        parity_check<=rx;
                    if(tick_count==9)begin
                        if(parity_check!=(^rx_shift_reg))
                            error<=1;
                        else
                            error<=0;
                    end
                end
                STOP:begin
                    baud_en<=1;
                    if(tick_count==8&&rx==0)
                        error<=1;
                    if(tick_count==15)
                        rx_data<=rx_shift_reg;
                end
            endcase
        end
    end
endmodule
