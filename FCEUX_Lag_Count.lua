-----------------------
-- Name: Show Lag count for FCEUX
-- Author: FlameCyclone
-- Date: 2023.10.8
-----------------------
-- Show Lag count
-----------------------

local nmi_addr = 0              --游戏NMI地址
local cur_frame_cycles = 0
local last_frame_cycles = 0
local lag_count = 0
local ppu_screen_enable = false

--颜色顺序 #rrggbbaa 红,绿蓝,不透明度(00:全透明, ff:不透明)
local text_bkg_color  = "#0000007f"   --血量文本背景颜色
local text_color      = "#ffff00ff"   --血量文本颜色

--停止回调
function on_exit()
    emu.print("stop...")
end

emu.registerexit(on_exit)

--PPU掩码写入回调
function on_ppu_mask(address, size, value)
    if (0 ~= AND(value, 0x18)) then
        ppu_screen_enable = true
    else
        ppu_screen_enable = false
    end
end

memory.registerwrite(0x2001, on_ppu_mask)

emu.print("start...")

while (true) do
    if 0 == last_frame_cycles then
        last_frame_cycles = debugger.getcyclescount()
	end
    
    emu.frameadvance()
    cur_frame_cycles = debugger.getcyclescount()
    frame_cycles = cur_frame_cycles - last_frame_cycles
    last_frame_cycles = cur_frame_cycles

    nmi_addr_check = memory.readword(0xFFFA)
    if nmi_addr ~= nmi_addr_check then
        nmi_addr = nmi_addr_check
    end
    
    lagcount = emu.lagcount()
    gui.text(12, 12, string.format("nmi: $%04X cycles: %d lag: %d", nmi_addr, frame_cycles, lagcount), text_color, text_bkg_color)
end
