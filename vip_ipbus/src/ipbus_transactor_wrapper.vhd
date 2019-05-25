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

----------------------------------------------------------------------------------------
-- ipbus_transactor_wrapper is used for wrapping the ipbus_transactor ports to make the
-- test bench code less verbose.
----------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library ipbus;
use ipbus.ipbus.all;

library work;
use work.ipbus_bfm_pkg.all;

entity ipbus_transactor_wrapper is
    port (
        clk: in std_logic; -- IPbus clock
        rst: in std_logic; -- Sync reset

        ipbus_transactor_inputs : in t_ipbus_transactor_inputs;
        ipbus_transactor_outputs : out t_ipbus_transactor_outputs
    );
end ipbus_transactor_wrapper;

architecture structural of ipbus_transactor_wrapper is

begin

    transactor_0 : entity ipbus.transactor
    port map (
        clk => clk,
        rst => rst,
        ipb_out => ipbus_transactor_outputs.ipb_out,
        ipb_in => ipbus_transactor_inputs.ipb_in,
        ipb_req => ipbus_transactor_outputs.ipb_req,
        ipb_grant => ipbus_transactor_inputs.ipb_grant,
        trans_in => ipbus_transactor_inputs.trans_in,
        trans_out => ipbus_transactor_outputs.trans_out,
        cfg_vector_in => ipbus_transactor_inputs.cfg_vector_in,
        cfg_vector_out => ipbus_transactor_outputs.cfg_vector_out
    );

end structural;
