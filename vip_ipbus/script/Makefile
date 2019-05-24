STD=standard
VSTD=08
WORKDIR=work
LIBRARY=/usr/local/lib/ghdl/vendors/

TRANSACTOR_TB = \
 ./src/ipbus_bfm_pkg.vhd \
 ./src/ipbus_transactor_wrapper.vhd \
 ./tb/ipbus_bfm_tb.vhd \

ipbus_bfm_tb:
	@mkdir -p work
	ghdl -a --std=${VSTD} --ieee=${STD} --workdir=${WORKDIR} -frelaxed-rules -P${LIBRARY} ${TRANSACTOR_TB}
	ghdl -e --std=${VSTD} --workdir=${WORKDIR} -frelaxed-rules -P${LIBRARY} ipbus_bfm_tb
	./ipbus_bfm_tb --wave=ipbus_bfm_tb.ghw
	gtkwave ipbus_bfm_tb.ghw tb/ipbus_bfm_tb.sav > /dev/null 2>&1 & disown

clean:
	rm e~ipbus_bfm_tb.o
	rm _Alert.txt
	rm _Log.txt
	rm ipbus_bfm_tb.ghw
	rm ipbus_bfm_tb

.PHONY: ipbus_bfm_tb clean
