library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipbus;
use ipbus.ipbus.all;
use ipbus.ipbus_trans_decl.all;
use ipbus.ipbus_reg_types.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library work;
use work.ipbus_bfm_pkg.all;

entity simple_tb_template is
end entity;

architecture behavioral of simple_tb_template is

  constant CLK_PERIOD : time := C_IPBUS_USUAL_CLK_PERIOD; -- 31.25 MHz

  signal clk : std_logic := '0';
  signal rst : std_logic := '0';

  signal ipbus_transactor_inputs  : t_ipbus_transactor_inputs := C_IPBUS_TRANSACTOR_INPUTS_DEFAULT;
  signal ipbus_transactor_outputs : t_ipbus_transactor_outputs;

  --===============================================================================================
  -- Example showing how to define IPbus transaction signals.
  --
  -- Note that the direction of ranges for transaction bodyy is "to"!
  --
  -- Unfortunately user has to explicitly define length of the bodyy.
  -- Length of the bodyy always equals to the length of the data user sends + 1.
  -- If you know how to define request transaction signals in more
  -- user friendly way please submit an issue on github!
  -- In case of insufficient bodyy length you will get some error at runtime.
  --===============================================================================================
  signal sample_user_transaction : t_ipbus_transaction(bodyy(0 to 0))
         := ipbus_read_transaction(X"00000006", 1);

begin

  clk <= not clk after CLK_PERIOD/2;

  -- Instantiate your Devices Under Test (DUT).

--  This is sample DUT instantiation. It should be removed as it only shows how to
--  use ipbus_transactor_outputs.ipb_out and ipbus_transactor_inputs.ipb_in.
----------------------------------------------------------------------------------
--  ipbus_ctrlreg_v_0 : entity ipbus.ipbus_ctrlreg_v
--      generic map (
--          N_CTRL => NUM_IPBUS_CTRL_REGISTERS,
--          N_STAT => NUM_IPBUS_STAT_REGISTERS,
--          SWAP_ORDER => false
--      )
--      port map (
--          clk => clk,
--          reset => rst,
--          ipbus_in => ipbus_transactor_outputs.ipb_out,
--          ipbus_out => ipbus_transactor_inputs.ipb_in,
--          d => ipb_status_regs,
--          q => ipb_control_regs,
--          qmask => open,
--          stb => ipb_control_stbs
--      );

  -- Instantiation of the IPbus transactor wrapper. At least one is necessary.
  ipbus_transactor_wrapper_0 : entity work.ipbus_transactor_wrapper
    port map (
      clk => clk,
      rst => rst,
      ipbus_transactor_inputs => ipbus_transactor_inputs,
      ipbus_transactor_outputs => ipbus_transactor_outputs
    );

  main: process
  begin
    wait for 2*CLK_PERIOD;

    gen_pulse(rst, 2 * CLK_PERIOD, "Reset pulse");
    wait for 2*CLK_PERIOD;

    -- User testbench code goes here.

--    This is sample transaction, feel free to remove it.
-----------------------------------------------
--    ipbus_transact(sample_user_transaction,
--                   response_transaction,
--                   ipbus_transactor_inputs,
--                   ipbus_transactor_outputs,
--                   clk);
--
    wait for 5*CLK_PERIOD;
    std.env.stop;

  end process;

end behavioral;
