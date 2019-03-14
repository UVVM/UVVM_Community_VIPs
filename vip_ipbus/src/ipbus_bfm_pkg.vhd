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

library std;
use std.textio.all;

library ipbus;
use ipbus.ipbus.all;
use ipbus.ipbus_trans_decl.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

package ipbus_bfm_pkg is

  --===============================================================================================
  -- Types and constants for IPbus BFM (Bus Functional Model).
  --===============================================================================================
  constant C_SCOPE : string := "IPbus BFM";

  constant C_IPBUS_USUAL_CLK_PERIOD : time := 32 ns;

  -- The IPbus transaction has fixed timeout on both read and write operations that is specified
  -- in the standard and equals 256 IPbus clock cycles. The usual IPbus clock is 31.25 MHz,
  -- resulting in a bus timeout period of approximately 8 us.
  constant C_IPBUS_TIMEOUT_PERIOD : time := 8 us;

  type t_ipbus_transactor_inputs is
  record
    ipb_in        : ipb_rbus;
    ipb_grant     : std_logic;
    trans_in      : ipbus_trans_in;
    cfg_vector_in : std_logic_vector(127 downto 0);
  end record;

  constant C_IPBUS_TRANSACTOR_INPUTS_DEFAULT : t_ipbus_transactor_inputs := (
    -- ipb_in is driven by the slaves so it must be set to 'Z' to enable proper resolution.
    ipb_in => (ipb_rdata => (others => 'Z'),
               ipb_ack   => 'Z',
               ipb_err   => 'Z'),
    ipb_grant => '1',
    trans_in => (pkt_rdy => '0',
                 rdata => (others => '0'),
                 busy => '0'),
    cfg_vector_in => (others => '0')
  );

  type t_ipbus_transactor_outputs is
  record
    ipb_out        : ipb_wbus;
    ipb_req        : std_logic;
    trans_out      : ipbus_trans_out;
    cfg_vector_out : std_logic_vector(127 downto 0);
  end record;

  type t_ipbus_transaction_type_id is (
    READ,
    WRITE,
    NON_INC_READ,    -- Non-incrementing read.
    NON_INC_WRITE,   -- Non-incrementing write.
    RMW_BITS,        -- Read/modify/write bits. X <= (X & and_term) | or_term
    RMW_SUM,         -- Read/modify/write sum.  X <= (X + addend)
    CONF_SPACE_READ, -- Configuration space read. Not implemented as it doesn't read from main
                     -- address space. See IPbus protocol specification.
    CONF_SPACE_WRITE -- Configuration space write. Not implemented as it doesn't read from main
                     -- address space. See IPbus protocol specification.
  );

  type t_ipbus_transaction_info_code is (
    REQ_HANDLED_SUCCESSFULLY, -- Request handled successfully by target
    BAD_HEADER,
    RESERVED_0x2,
    RESERVED_0x3,
    BUS_ERROR_ON_READ,
    BUS_ERROR_ON_WRITE,
    BUS_TIMEOUT_ON_READ,
    BUS_TIMEOUT_ON_WRITE,
    RESERVED_0x8,
    RESERVED_0x9,
    RESERVED_0xA,
    RESERVED_0xB,
    RESERVED_0xC,
    RESERVED_0xD,
    RESERVED_0xE,
    OUTBOUND_REQUEST
  );

  type t_ipbus_bfm_config is
  record
    expected_response           : t_ipbus_transaction_info_code;
    expected_response_severity  : t_alert_level; -- A response mismatch will have this severity.
    id_for_bfm                  : t_msg_id; -- The message ID used as a general message ID in the IPbus BFM
  end record;

  constant C_IPBUS_BFM_CONFIG_DEFAULT : t_ipbus_bfm_config := (
    expected_response           => REQ_HANDLED_SUCCESSFULLY,
    expected_response_severity  => TB_FAILURE,
    id_for_bfm                  => ID_BFM
  );

  type t_ipbus_tranaction_header is
  record
    protocol_version : natural range 0 to 2**4  - 1;
    transaction_id   : natural range 0 to 2**12 - 1;
    word_count       : natural range 0 to 2**8  - 1;
    type_id          : t_ipbus_transaction_type_id;
    info_code        : t_ipbus_transaction_info_code;
  end record;

  type t_ipbus_slv_array is array (natural range <>) of std_logic_vector(31 downto 0);

  type t_ipbus_transaction is
  record
    header : t_ipbus_tranaction_header;
    bodyy  : t_ipbus_slv_array; -- body is one of the VHDL reserved words.
  end record;

  --===============================================================================================
  -- IPbus BFM functions.
  --===============================================================================================

  function ipbus_transaction_header_to_slv (
    header : t_ipbus_tranaction_header
  ) return std_logic_vector;

  function slv_to_ipbus_transaction_header (
    v : std_logic_vector
  ) return t_ipbus_tranaction_header;

  function t_ipbus_transaction_info_code_to_slv (
    info_code : t_ipbus_transaction_info_code
  ) return std_logic_vector;

--  ------------------------------------------
--  -- ipbus_transaction
--  ------------------------------------------
--  -- This function should not be called by users in a tesbench code.
--  -- On the other hand, it is versatile and enables creating any transactions,
--  -- even the ones that are incorrect according to the standard.
--  -- Right now only protocol version 2 exists so argument protocol_version
--  -- should always eqauls 2.
--  function ipbus_transaction (
--    protocol_version : natural;
--    transaction_id   : natural;
--    word_count       : natural;
--    type_id          : t_ipbus_transaction_type_id;
--    info_code        : t_ipbus_transaction_info_code;
--    bodyy            : t_ipbus_slv_array
--  ) return t_ipbus_transaction;

  procedure log_ipbus_transaction (
    constant transaction  : t_ipbus_transaction;
    constant msg          : string := "";
    constant scope        : string := C_SCOPE;
    constant msg_id       : t_msg_id := ID_BFM;
    constant msg_id_panel : t_msg_id_panel := shared_msg_id_panel
  );

  function ipbus_read_transaction (
    base_address : std_logic_vector(31 downto 0);
    read_size    : natural
  ) return t_ipbus_transaction;

  function ipbus_write_transaction (
    base_address : std_logic_vector(31 downto 0);
    write_size   : natural;
    data         : t_ipbus_slv_array
  ) return t_ipbus_transaction;

  function ipbus_non_inc_read_transaction (
    base_address : std_logic_vector(31 downto 0);
    read_size    : natural
  ) return t_ipbus_transaction;

  function ipbus_non_inc_write_transaction (
    base_address : std_logic_vector(31 downto 0);
    write_size   : natural;
    data         : t_ipbus_slv_array
  ) return t_ipbus_transaction;

  function ipbus_rmw_bits_transaction (
    base_address : std_logic_vector(31 downto 0);
    and_term     : std_logic_vector(31 downto 0);
    or_term      : std_logic_vector(31 downto 0)
  ) return t_ipbus_transaction;

  function ipbus_rmw_sum_transaction (
    base_address : std_logic_vector(31 downto 0);
    addend       : std_logic_vector(31 downto 0)
  ) return t_ipbus_transaction;

  procedure ipbus_transact (
    signal   request_transaction      : in    t_ipbus_transaction;
    signal   response_transaction     : inout t_ipbus_transaction;
    signal   ipbus_transactor_inputs  : inout t_ipbus_transactor_inputs;
    signal   ipbus_transactor_outputs : in    t_ipbus_transactor_outputs;
    signal   clk                      : in    std_logic;
    constant msg                      : in    string := "";
    constant scope                    : in    string := C_SCOPE;
    constant msg_id_panel             : in    t_msg_id_panel := shared_msg_id_panel;
    constant config                   : in    t_ipbus_bfm_config := C_IPBUS_BFM_CONFIG_DEFAULT
  );

end package ipbus_bfm_pkg;

--=================================================================================================
--=================================================================================================

package body ipbus_bfm_pkg is

  function ipbus_transaction_header_to_slv (
    header : t_ipbus_tranaction_header
  ) return std_logic_vector is
    variable v             : std_logic_vector(31 downto 0);
    variable type_id_int   : natural := t_ipbus_transaction_type_id'pos(header.type_id);
    variable info_code_int : natural := t_ipbus_transaction_info_code'pos(header.info_code);
  begin
    v(31 downto 28) := std_logic_vector(to_unsigned(header.protocol_version, 4));
    v(27 downto 16) := std_logic_vector(to_unsigned(header.transaction_id, 12));
    v(15 downto 8)  := std_logic_vector(to_unsigned(header.word_count, 8));
    v(7  downto 4)  := std_logic_vector(to_unsigned(type_id_int, 4));
    v(3  downto 0)  := std_logic_vector(to_unsigned(info_code_int, 4));
    return v;
  end function;

  function slv_to_ipbus_transaction_header (
    v : std_logic_vector
  ) return t_ipbus_tranaction_header is
    variable header : t_ipbus_tranaction_header;
  begin
    header.protocol_version := to_integer(unsigned(v(31 downto 28)));
    header.transaction_id   := to_integer(unsigned(v(27 downto 16)));
    header.word_count := to_integer(unsigned(v(15 downto 8)));
    header.type_id    := t_ipbus_transaction_type_id'val(to_integer(unsigned(v(7 downto 4))));
    header.info_code  := t_ipbus_transaction_info_code'val(to_integer(unsigned(v(3 downto 0))));
    return header;
  end function;

  function t_ipbus_transaction_info_code_to_slv (
    info_code : t_ipbus_transaction_info_code
  ) return std_logic_vector is
  begin
    case info_code is
      when REQ_HANDLED_SUCCESSFULLY => return "0000";
      when BAD_HEADER               => return "0001";
      when RESERVED_0x2             => return "0010";
      when RESERVED_0x3             => return "0011";
      when BUS_ERROR_ON_READ        => return "0100";
      when BUS_ERROR_ON_WRITE       => return "0101";
      when BUS_TIMEOUT_ON_READ      => return "0110";
      when BUS_TIMEOUT_ON_WRITE     => return "0111";
      when RESERVED_0x8             => return "1000";
      when RESERVED_0x9             => return "1001";
      when RESERVED_0xA             => return "1010";
      when RESERVED_0xB             => return "1011";
      when RESERVED_0xC             => return "1100";
      when RESERVED_0xD             => return "1101";
      when RESERVED_0xE             => return "1110";
      when OUTBOUND_REQUEST         => return "1111";
    end case;
  end function;

  procedure log_ipbus_transaction (
    constant transaction  : t_ipbus_transaction;
    constant msg          : string := "";
    constant scope        : string := C_SCOPE;
    constant msg_id       : t_msg_id := ID_BFM;
    constant msg_id_panel : t_msg_id_panel := shared_msg_id_panel
  ) is
    variable log_msg : line;
  begin
    if msg /= "" then
      write(log_msg, msg & LF);
    end if;
    --write(log_msg, "IPBus transaction" & LF);

    write(log_msg, "  HEADER:" & LF);
    -- Skip Version and Transaction ID from logging as these values right now are constant.
    write(log_msg, "    Protocol version: " & natural'image(transaction.header.protocol_version) & LF);
    write(log_msg, "    Transaction ID:   " & natural'image(transaction.header.transaction_id) & LF);
    write(log_msg, "    Word count:       " & natural'image(transaction.header.word_count) & LF);
    write(log_msg, "    Type ID:          " & t_ipbus_transaction_type_id'image(transaction.header.type_id) & LF);
    write(log_msg, "    Info code:        " & t_ipbus_transaction_info_code'image(transaction.header.info_code));

    log(msg_id, log_msg.all, scope);
  end procedure log_ipbus_transaction;

  function ipbus_transaction (
    protocol_version : natural;
    transaction_id   : natural;
    word_count       : natural;
    type_id          : t_ipbus_transaction_type_id;
    info_code        : t_ipbus_transaction_info_code;
    bodyy            : t_ipbus_slv_array
  ) return t_ipbus_transaction is
    variable trans : t_ipbus_transaction(bodyy(bodyy'length-1 downto 0));
  begin
    assert protocol_version = 2 report "Wrong IPbus protocol version." severity failure;

    trans.header.protocol_version := protocol_version;
    trans.header.transaction_id   := transaction_id;
    trans.header.word_count       := word_count;
    trans.header.type_id          := type_id;
    trans.header.info_code        := info_code;
    trans.bodyy                   := bodyy;

    return trans;
  end function;

  function ipbus_read_transaction (
    base_address : std_logic_vector(31 downto 0);
    read_size    : natural
  ) return t_ipbus_transaction is
    variable aux : t_ipbus_slv_array(0 to 0);
  begin
    aux(0) := base_address;
    return ipbus_transaction(2, 0, read_size, READ, OUTBOUND_REQUEST, aux);
  end function;

  function ipbus_write_transaction (
    base_address : std_logic_vector(31 downto 0);
    write_size   : natural;
    data : t_ipbus_slv_array
  ) return t_ipbus_transaction is
    variable aux : t_ipbus_slv_array(0 to data'length);
  begin
    aux(0) := base_address;
    aux(1 to data'length) := data;
    return ipbus_transaction(2, 0, write_size, WRITE, OUTBOUND_REQUEST, aux);
  end function;

  function ipbus_non_inc_read_transaction (
    base_address : std_logic_vector(31 downto 0);
    read_size    : natural
  ) return t_ipbus_transaction is
    variable aux : t_ipbus_slv_array(0 to 0);
  begin
    aux(0) := base_address;
    return ipbus_transaction(2, 0, read_size, NON_INC_READ, OUTBOUND_REQUEST, aux);
  end function;

  function ipbus_non_inc_write_transaction (
    base_address : std_logic_vector(31 downto 0);
    write_size   : natural;
    data         : t_ipbus_slv_array
  ) return t_ipbus_transaction is
    variable aux : t_ipbus_slv_array(0 to data'length);
  begin
    aux(0) := base_address;
    aux(1 to data'length) := data;
    return ipbus_transaction(2, 0, write_size, NON_INC_WRITE, OUTBOUND_REQUEST, aux);
  end function;

  function ipbus_rmw_bits_transaction (
    base_address : std_logic_vector(31 downto 0);
    and_term     : std_logic_vector(31 downto 0);
    or_term      : std_logic_vector(31 downto 0)
  ) return t_ipbus_transaction is
    variable aux : t_ipbus_slv_array(0 to 2);
  begin
    aux(0) := base_address;
    aux(1) := and_term;
    aux(2) := or_term;

    return ipbus_transaction(2, 0, 1, RMW_BITS, OUTBOUND_REQUEST, aux);
  end function;

  function ipbus_rmw_sum_transaction (
    base_address : std_logic_vector(31 downto 0);
    addend       : std_logic_vector(31 downto 0)
  ) return t_ipbus_transaction is
    variable aux : t_ipbus_slv_array(0 to 1);
  begin
    aux(0) := base_address;
    aux(1) := addend;

    return ipbus_transaction(2, 0, 1, RMW_SUM, OUTBOUND_REQUEST, aux);
  end function;

  procedure ipbus_transact (
    signal   request_transaction      : in    t_ipbus_transaction;
    signal   response_transaction     : inout t_ipbus_transaction;
    signal   ipbus_transactor_inputs  : inout t_ipbus_transactor_inputs;
    signal   ipbus_transactor_outputs : in    t_ipbus_transactor_outputs;
    signal   clk                      : in    std_logic;
    constant msg                      : in    string := "";
    constant scope                    : in    string := C_SCOPE;
    constant msg_id_panel             : in    t_msg_id_panel := shared_msg_id_panel;
    constant config                   : in    t_ipbus_bfm_config := C_IPBUS_BFM_CONFIG_DEFAULT
  ) is

    constant proc_name : string := "ipbus_transact";
    constant proc_call : string := proc_name & "()";

    alias ipb_in        : ipb_rbus is ipbus_transactor_inputs.ipb_in;
    alias ipb_grant     : std_logic is ipbus_transactor_inputs.ipb_grant;
    alias trans_in      : ipbus_trans_in is ipbus_transactor_inputs.trans_in;
    alias trans_out     : ipbus_trans_out is ipbus_transactor_outputs.trans_out;
    alias cfg_vector_in : std_logic_vector(127 downto 0) is ipbus_transactor_inputs.cfg_vector_in;

    variable prev_buffer_read_addr : std_logic_vector(11 downto 0);
    constant req_body_length       : natural := request_transaction.bodyy'length;
    variable req_body_counter      : natural := 0;

  begin

    -- Below call casues GHDL error. Fixes in GHDL are needed.
    log_ipbus_transaction(request_transaction, proc_call & LF & "Request Transaction:");

    trans_in.pkt_rdy <= '1';
    trans_in.rdata(31 downto 16) <= std_logic_vector(to_unsigned(1, 16));
    trans_in.rdata(15 downto 0) <= std_logic_vector(to_unsigned(1 + request_transaction.bodyy'length, 16));

    for i in 1 to 2 loop
      await_change(trans_out.raddr,
                   0 us,
                   C_IPBUS_TIMEOUT_PERIOD,
                   FAILURE,
                   "Waiting for buffer read address change",
                   scope,
                   ID_NEVER, --  <- Should be changed only in case of internal debugging.
                   msg_id_panel);
    end loop;

    prev_buffer_read_addr := trans_out.raddr;
    wait_num_rising_edge(clk, 1);
    trans_in.rdata(31 downto 0) <= ipbus_transaction_header_to_slv(request_transaction.header);

    while trans_out.pkt_done /= '1' loop
      if prev_buffer_read_addr /= trans_out.raddr and req_body_counter < req_body_length then
        trans_in.rdata(31 downto 0) <= request_transaction.bodyy(req_body_counter);
        req_body_counter := req_body_counter + 1;
      end if;

      prev_buffer_read_addr := trans_out.raddr;
      wait_num_rising_edge(clk, 1);

      if trans_out.we = '1' then
        if unsigned(trans_out.waddr) = 2 then
          response_transaction.header <= slv_to_ipbus_transaction_header(trans_out.wdata);
        elsif unsigned(trans_out.waddr) > 2 then
          response_transaction.bodyy(to_integer(unsigned(trans_out.waddr)) - 3) <= trans_out.wdata;
        end if;
      end if;
    end loop;

    trans_in.pkt_rdy <= '0';
    wait_num_rising_edge(clk, 1);

    check_value(t_ipbus_transaction_info_code_to_slv(response_transaction.header.info_code),
                t_ipbus_transaction_info_code_to_slv(config.expected_response),
                config.expected_response_severity,
                proc_call & " IPbus transaction failed" & add_msg_delimiter(msg),
                scope,
                BIN,
                AS_IS,
                ID_NEVER,
                msg_id_panel,
                proc_call);

    log_ipbus_transaction(response_transaction, proc_call & " completed" & LF & "Response Transaction:");

  end procedure ipbus_transact;

end package body ipbus_bfm_pkg;
