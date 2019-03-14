-------------------------------------------------------------------------------
-- Directory structure                                                       --
-------------------------------------------------------------------------------
- src      : IPbus BFM source codes.
- script   : Compile scripts.
- tb       : Example test bench demonstrating the use.  Note: tb/ipbus_bfm_tb.sav
             is the file that was used for debugging in GTKWave.
- template : Templates for different test bench structures.

For testing with GHDL just run:
make -f script/Makefile
Do not forget to compile UVVM and IPbus library first!
By default all libraries should be installed in LIBRARY=/usr/local/lib/ghdl/vendors/
Edit script/Makefile if necessary.
For cleanup:
make -f script/Makefile clean

Important!
The IPbus BFM was not implemented for estimation or evaluation of the IPbus
transactions duration, so do not use it to measure the latency.
