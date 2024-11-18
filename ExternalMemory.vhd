-- ExternalMemory.VHD
-- 2024.10.22
--
-- This SCOMP peripheral provides one 16-bit word of external memory for SCOMP.
-- Any value written to this peripheral can be read back.

library ieee;
library altera_mf;
library lpm;

use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use altera_mf.altera_mf_components.all;
use lpm.lpm_components.all;


ENTITY ExternalMemory IS
    PORT(
		  CLOCK : IN STD_LOGIC;
        RESETN : IN    STD_LOGIC;
		  EXTMEM_INDEX_EN : IN STD_LOGIC;
		  EXTMEM_OFFSET_EN : IN STD_LOGIC;
		  EXTMEM_PERMISSION_EN     : IN STD_LOGIC;
		  EXTMEM_DATA_EN : IN STD_LOGIC;
        IO_WRITE : IN    STD_LOGIC;
        IO_DATA  : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		  dbg_PAGE_INDEX : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		  dbg_PAGE_OFFSET : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
		  dbg_MEM_DATA_OUTPUT: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		  dbg_FINAL_ADDR: OUT STD_LOGIC_VECTOR(17 DOWNTO 0);
		  dbg_EXTMEM_EN : OUT    STD_LOGIC;
		  dbg_HAS_PERMISSION : OUT STD_LOGIC;
		  dbg_PERMISSION_LEVEL : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
		  
    );
END ExternalMemory;

ARCHITECTURE a OF ExternalMemory IS	 
    SIGNAL PAGE_INDEX       : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL PAGE_OFFSET      : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL MEM_DATA_OUTPUT  : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL PERMISSION_LEVEL : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL FINAL_ADDR       : STD_LOGIC_VECTOR(17 DOWNTO 0);
	 SIGNAL EXTMEM_EN : STD_LOGIC;
	 SIGNAL HAS_PERMISSION : STD_LOGIC;

    BEGIN
	 
	 EXTMEM_EN <= EXTMEM_INDEX_EN or EXTMEM_OFFSET_EN or EXTMEM_PERMISSION_EN or EXTMEM_DATA_EN;
	 FINAL_ADDR <= PAGE_INDEX & PAGE_OFFSET;
	 
	 --check
	 HAS_PERMISSION <= '1' when (PERMISSION_LEVEL >= PAGE_INDEX) else '0';

	 
    -- Use Intel LPM IP to create tristate drivers
    IO_BUS: lpm_bustri
        GENERIC MAP (
        lpm_width => 16
    )
    PORT MAP (
        enabledt => EXTMEM_EN AND NOT(IO_WRITE), -- when extmem is writing
        data     => MEM_DATA_OUTPUT,  -- provide this value
        tridata  => IO_DATA -- driving the IO_DATA bus
    );
	 
    altsyncram_component : altsyncram
    GENERIC MAP (
        numwords_a => 262144,
        widthad_a => 18,
        width_a => 16,
        intended_device_family => "MAX 10",
        clock_enable_input_a => "BYPASS",
        clock_enable_output_a => "BYPASS",
        lpm_hint => "ENABLE_RUNTIME_MOD=NO",
        lpm_type => "altsyncram",
        operation_mode => "SINGLE_PORT",
        outdata_reg_a => "UNREGISTERED",
        outdata_aclr_a => "NONE",
        power_up_uninitialized => "FALSE",
        read_during_write_mode_port_a => "NEW_DATA_NO_NBE_READ",
        width_byteena_a => 1
    )
    PORT MAP (
        wren_a    => IO_WRITE and HAS_PERMISSION and EXTMEM_DATA_EN,
        clock0    => CLOCK,
        address_a => FINAL_ADDR,
        data_a    => IO_DATA,
        q_a       => MEM_DATA_OUTPUT
    );
	 

    PROCESS(CLOCK, RESETN)
    BEGIN
		  IF RESETN = '0' THEN
				PAGE_INDEX <= "00000000";
				PAGE_OFFSET <= "0000000000";
				PERMISSION_LEVEL <= "00111111";
		  ELSIF RISING_EDGE(CLOCK) THEN
				
--		  we need to set the data when we put the offset or index 
            IF IO_WRITE = '1' THEN -- If SCOMP is writing,
               IF EXTMEM_INDEX_EN = '1' THEN
						PAGE_INDEX <= IO_DATA (7 DOWNTO 0);
					ELSIF EXTMEM_OFFSET_EN = '1' THEN
						PAGE_OFFSET <= IO_DATA (9 DOWNTO 0);
					ELSIF EXTMEM_PERMISSION_EN = '1' THEN
						PERMISSION_LEVEL <= IO_DATA (7 DOWNTO 0);
					END IF;
            END IF;
			
				IF IO_WRITE = '0' THEN
               IF EXTMEM_DATA_EN = '1' THEN
						
						IF PAGE_OFFSET = "1111111111" THEN
							PAGE_OFFSET <= "0000000000";
							IF PAGE_INDEX = "11111111" THEN
								PAGE_INDEX <= "00000000";
							ELSE
								PAGE_INDEX <= PAGE_INDEX + 1;
							END IF;
						ELSE
							PAGE_OFFSET <= PAGE_OFFSET + 1;
						END IF;
					END IF;
            END IF;
			END IF;
    END PROCESS;
	 
	dbg_PAGE_INDEX <= PAGE_INDEX;
	dbg_PAGE_OFFSET <= PAGE_OFFSET;
	dbg_MEM_DATA_OUTPUT <= MEM_DATA_OUTPUT;
	dbg_FINAL_ADDR <= FINAL_ADDR;
	dbg_EXTMEM_EN <= EXTMEM_EN;
	dbg_HAS_PERMISSION <= HAS_PERMISSION;
	dbg_PERMISSION_LEVEL <= PERMISSION_LEVEL;

END a;