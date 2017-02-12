module ahb_master_test;

parameter DATA_WDT = 32;
parameter BEAT_WDT = 32;

        // Clock and reset
        bit                    i_hclk;
        bit                    i_hreset_n;

        // AHB signals. Please see spec for more info.
        logic [31:0]           o_haddr;
        logic [2:0]            o_hburst;
        logic [1:0]            o_htrans;
        logic[DATA_WDT-1:0]    o_hwdata;
        logic                  o_hwrite;
        logic [2:0]            o_hsize;
        logic [DATA_WDT-1:0]   i_hrdata;
        logic                  i_hready;
        logic [1:0]            i_hresp;
        logic                  i_hgrant;
        logic                  o_hbusreq;

        // User interface.
        logic                 o_next;   // UI must change only if this is 1.
        logic   [DATA_WDT-1:0]i_data;   // Data to write. Can change during burst if o_next = 1.
        bit                   i_dav;    // Data to write valid. Can change during burst if o_next = 1.
        bit      [31:0]       i_addr;   // Base address of burst.
        bit      [2:0]        i_size;   // Size of transfer. Like hsize.
        bit                   i_wr;     // Write to AHB bus.
        bit                   i_rd;     // Read from AHB bus.
        bit     [BEAT_WDT-1:0]i_min_len;// Minimum guaranteed length of burst.
        bit                   i_cont;   // Current transfer continues previous one.
        logic[DATA_WDT-1:0]   o_data;   // Data got from AHB is presented here.
        logic[31:0]           o_addr;   // Corresponding address is presented here.
        logic                 o_dav;    // Used as o_data valid indicator.

logic [DATA_WDT-1:0] hwdata0, hwdata1;

assign hwdata0 = U_AHB_MASTER.o_hwdata[0];
assign hwdata1 = U_AHB_MASTER.o_hwdata[1];

ahb_master      #(.DATA_WDT(DATA_WDT), .BEAT_WDT(BEAT_WDT)) U_AHB_MASTER    (.*); 

ahb_slave_sim   #(.DATA_WDT(DATA_WDT))                      U_AHB_SLAVE_SIM_1 (

.i_hclk         (i_hclk),
.i_hreset_n     (i_hreset_n),
.i_hburst       (o_hburst),
.i_htrans       (o_htrans),
.i_hwdata       (o_hwdata),
.i_hsel         (1'd1),
.i_haddr        (o_haddr),
.i_hwrite       (o_hwrite),
.i_hready       (1'd1),
.o_hrdata       (i_hrdata),
.o_hready       (i_hready),
.o_hresp        (i_hresp)

);

always #10 i_hclk++;

always @ (posedge i_hclk)
begin
        if ( o_hbusreq )
                i_hgrant <= 1'd1;
        else
                i_hgrant <= 1'd0;
end

bit dav;
bit [31:0] dat;

initial
begin
        $dumpfile("ahb_master.vcd");
        $dumpvars;

        i_hgrant <= 1;

        i_hreset_n <= 1'd0;
        d(1);
        i_hreset_n <= 1'd1;

        // We can change inputs.
        i_min_len <= 42;
        i_wr      <= 1'd1;
        i_dav     <= $random;

        wait_for_next;       

        i_cont    <= i_dav ? 1'd1 : 1'd0;
        i_wr      <= 1'd1;
        i_dav     <= 1'd1;

        repeat(100)
        begin: bk
                dav = $random;
                dat = dat + dav;

                wait_for_next;
                i_cont    <= 1'd1;
                i_dav     <= dav;
                i_data    <= dav ? dat : 32'dx;
        end

        $finish;
end

task wait_for_next;
        while(o_next !== 1)
        begin
                d(1);
        end
        d(1);
endtask

task d(int x);
        repeat(x) 
                @(posedge i_hclk);
endtask

endmodule
