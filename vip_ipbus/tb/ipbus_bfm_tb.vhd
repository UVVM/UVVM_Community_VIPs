--========================================================================================================================
-- Copyright (c) 2017 by Bitvis AS.  All rights reserved.

-- You should have received a copy of the license file containing the MIT License (see LICENSE.TXT), if not,
-- contact Bitvis AS <support@bitvis.no>.
--========================================================================================================================
-- Copyright (c) 2019 by Michał Kruszewski. All rights reserved.
--
-- All IPbus Bus Functional Model files are provided with the same MIT License as the rest of the UVVM infrastrucutre.
--=======================================================================================================================
-- UVVM AND ANY PART THEREOF ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
-- WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
-- OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH UVVM OR THE USE OR OTHER DEALINGS IN UVVM.
--========================================================================================================================

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

entity ipbus_bfm_tb is
  generic (
    NUM_IPBUS_CTRL_REGISTERS : positive := 4;
    NUM_IPBUS_STAT_REGISTERS : positive := 4
  );
end entity;

architecture behavioral of ipbus_bfm_tb is

  constant CLK_PERIOD : time := C_IPBUS_USUAL_CLK_PERIOD; -- 31.25 MHz

  signal clk : std_logic := '0';
  signal rst : std_logic := '0';

  signal ipbus_transactor_inputs  : t_ipbus_transactor_inputs := C_IPBUS_TRANSACTOR_INPUTS_DEFAULT;
  signal ipbus_transactor_outputs : t_ipbus_transactor_outputs;

  signal ipb_status_regs  : ipb_reg_v(NUM_IPBUS_STAT_REGISTERS-1 downto 0) := (0 => X"FFFFFF00",
                                                                               1 => X"FFFFFF01",
                                                                               2 => X"FFFFFF02",
                                                                               3 => X"FFFFFF03");
  signal ipb_control_regs : ipb_reg_v(NUM_IPBUS_CTRL_REGISTERS-1 downto 0);
  signal ipb_control_stbs : std_logic_vector(NUM_IPBUS_CTRL_REGISTERS-1 downto 0);

  --===============================================================================================
  -- Examples showing how to define IPbus transaction signals.
  --
  -- Note that the direction of ranges for transaction bodyy is "to"!
  --
  -- Unfortunately user has to explicitly define length of the bodyy.
  -- Length of the bodyy always equals to the length of the data user sends + 1.
  -- If you know how to define request transaction signals in more
  -- user friendly way please submit an issue on github!
  -- In case of insufficient bodyy length you will get some error at runtime.
  --===============================================================================================
  signal read_request_transaction : t_ipbus_transaction(bodyy(0 to 0))
         := ipbus_read_transaction(X"00000006", 1);

  constant C_WRITE_DATA : t_ipbus_slv_array(0 to 1)
           := (0 => X"00000007", 1 => X"00000004");
  signal write_request_transaction : t_ipbus_transaction(bodyy(0 to 2))
         := ipbus_write_transaction(X"00000000", 2, C_WRITE_DATA);

  signal non_inc_read_request_transaction : t_ipbus_transaction(bodyy(0 to 0))
         := ipbus_non_inc_read_transaction(X"00000007", 3);

  constant C_NON_INC_WRITE_DATA : t_ipbus_slv_array(0 to 3)
           := (0 => X"11111111", 1 => X"22222222", 2 => X"33333333", 3 => X"44444444");
  signal non_inc_write_request_transaction : t_ipbus_transaction(bodyy(0 to 4))
         := ipbus_non_inc_write_transaction(X"00000002", 4, C_NON_INC_WRITE_DATA);

  signal rmw_bits_request_transaction : t_ipbus_transaction(bodyy(0 to 2))
         := ipbus_rmw_bits_transaction(X"00000000", X"00000004", X"F0000000");

  signal rmw_sum_request_transaction : t_ipbus_transaction(bodyy(0 to 1))
         := ipbus_rmw_sum_transaction(X"00000003", X"00000003");

  signal response_transaction : t_ipbus_transaction(bodyy(0 to 2));

begin

  clk <= not clk after CLK_PERIOD/2;

  ipbus_ctrlreg_v_0 : entity ipbus.ipbus_ctrlreg_v
      generic map (
          N_CTRL => NUM_IPBUS_CTRL_REGISTERS,
          N_STAT => NUM_IPBUS_STAT_REGISTERS,
          SWAP_ORDER => false
      )
      port map (
          clk => clk,
          reset => rst,
          ipbus_in => ipbus_transactor_outputs.ipb_out,
          ipbus_out => ipbus_transactor_inputs.ipb_in,
          d => ipb_status_regs,
          q => ipb_control_regs,
          qmask => open,
          stb => ipb_control_stbs
      );

  -- Instantiate the IPbus transactor wrapper. It is necessary.
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

    ipbus_transact(read_request_transaction,
                   response_transaction,
                   ipbus_transactor_inputs,
                   ipbus_transactor_outputs,
                   clk);
    check_value(response_transaction.bodyy(0), X"FFFFFF02", FAILURE,
                "Checking read transaction.");

    ipbus_transact(write_request_transaction,
                   response_transaction,
                   ipbus_transactor_inputs,
                   ipbus_transactor_outputs,
                   clk);
    check_value(ipb_control_regs(0), C_WRITE_DATA(0), FAILURE,
                "Checking write transaction.");
    check_value(ipb_control_regs(1), C_WRITE_DATA(1), FAILURE,
                "Checking write transaction.");

    ipbus_transact(non_inc_read_request_transaction,
                   response_transaction,
                   ipbus_transactor_inputs,
                   ipbus_transactor_outputs,
                   clk);
    check_value(response_transaction.bodyy(0), X"FFFFFF03", FAILURE,
                "Checking non-incrementing read transaction.");
    check_value(response_transaction.bodyy(1), X"FFFFFF03", FAILURE,
                "Checking non-incrementing read transaction.");
    check_value(response_transaction.bodyy(2), X"FFFFFF03", FAILURE,
                "Checking non-incrementing read transaction.");

    ipbus_transact(non_inc_write_request_transaction,
                   response_transaction,
                   ipbus_transactor_inputs,
                   ipbus_transactor_outputs,
                   clk);
    check_value(ipb_control_regs(2), C_NON_INC_WRITE_DATA(3), FAILURE,
                "Checking non-incrementing write transaction.");

    ipbus_transact(rmw_bits_request_transaction,
                   response_transaction,
                   ipbus_transactor_inputs,
                   ipbus_transactor_outputs,
                   clk);
    check_value(ipb_control_regs(0), X"F0000004", FAILURE,
                "Checking read/modify/write bits transaction.");

    ipbus_transact(rmw_sum_request_transaction,
                   response_transaction,
                   ipbus_transactor_inputs,
                   ipbus_transactor_outputs,
                   clk);
    check_value(ipb_control_regs(3), X"00000003", FAILURE,
                "Checking read/modify/write sum transaction.");

    wait for 5*CLK_PERIOD;
    std.env.stop;
  end process;

end behavioral;
