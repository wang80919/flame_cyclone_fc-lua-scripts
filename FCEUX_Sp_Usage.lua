-----------------------
-- Name: Show Mouse Position for FCEUX
-- Author: FlameCyclone
-- Date: 2023.8.5
-----------------------
-- Show Mouse Position
-----------------------
-----------------------
-- Name: Show Sprites Box for FCEUX
-- Author: FlameCyclone
-- Date: 2023.8.5
-----------------------
-- Draws a line for IRQ
-----------------------

local sprite_data_list = {0}
local sprite_tile_list = {0}

local oam_dma_addr = 0
local sprites_size = 16
local sprite_data_index = 0

local cur_frame_cycles = 0
local last_frame_cycles = 0
local frame_cycles = 0
local irq_addr = 0
local reset_addr = 0
local nmi_addr = 0
local irq_scanline_show = 0
local usage_show = 1


--初始化精灵缓冲
for i = 0, 63, 1 do
    sprite_data_list[i * 4 + 0] = 0xF8
    sprite_data_list[i * 4 + 1] = 0x00
    sprite_data_list[i * 4 + 2] = 0x00
    sprite_data_list[i * 4 + 3] = 0xF8
end

for i = 0, 255, 1 do
    sprite_tile_list[i] = 0
end

--停止回调
function on_exit()
    emu.print("stop...")
end

emu.registerexit(on_exit)

emu.print("start...")

--IRQ回调
function on_irq()
    
    --如果IRQ开始就RTI了, 那就是没有IRQ
    instruction = memory.readbyte(irq_addr)
    if 0x40 == instruction then
        return nil    
    end
    
    NTSC_cycles = 29781
    PAL_cycles = 33248
    Dendy_cycles = 35464

    --总扫描线
    scan_line_total = 262
    
    --NMI扫描线
    vblank_scan_line = 240
    
    --每条扫描线CPU周期
    scan_line_cycle = 341/3
    
    --NTSC制式
    if (frame_cycles > (NTSC_cycles - 10) and frame_cycles < (NTSC_cycles + 10)) then
        scan_line_total = 262
        vblank_scan_line = 240
        scan_line_cycle = 341/3
    --PAL制式
    elseif (frame_cycles > (PAL_cycles - 10) and frame_cycles < (PAL_cycles + 10)) then
        scan_line_total = 312
        vblank_scan_line = 240
        scan_line_cycle = 341/3.2
    --Dendy制式
    elseif (frame_cycles > (Dendy_cycles - 10) and frame_cycles < (Dendy_cycles + 10)) then
        scan_line_total = 312
        vblank_scan_line = 290
        scan_line_cycle = 341/3
    end
    
    if frame_cycles > 0 and 0 ~= irq_scanline_show then
        current_cpu_cycles = debugger.getcyclescount() - last_frame_cycles
        irq_scanline = (current_cpu_cycles - (scan_line_total - vblank_scan_line) * scan_line_cycle) / scan_line_cycle
        gui.line(0, irq_scanline, 256, irq_scanline, "#ffff00ff")
        gui.text(9, irq_scanline + 2, string.format("%d", irq_scanline), "#ffff00ff", "#0000001f")
    end
end

--PPU控制写入回调
function on_ppu_ctrl(address, size, value)
    --检测是否为 8 * 16精灵模式
    if (0 ~= AND(value, 0x20)) then
        sprites_size = 16
    else
        sprites_size = 8
    end
end

--精灵 OAM_ADDR 写入回调
function on_oam_addr(address, size, value)
    sprite_data_index = value
end

--精灵 OAM_DATA 写入回调
function on_oam_data(address, size, value)
    if sprite_data_index < 256 then
        sprite_data_list[sprite_data_index] = value
        sprite_data_index = sprite_data_index + 1
    end
end

--精灵数据DMA写入回调
function on_oam_dma_write(address, size, value)
    oam_dma_addr = value
end

memory.registerwrite(0x2000, on_ppu_ctrl)
memory.registerwrite(0x2003, on_oam_addr)
memory.registerwrite(0x2004, on_oam_data)
memory.registerwrite(0x4014, on_oam_dma_write)

while (true) do
    cur_frame_cycles = debugger.getcyclescount()
	emu.frameadvance()
    last_frame_cycles = debugger.getcyclescount()
    frame_cycles = last_frame_cycles - cur_frame_cycles
    state = input.get()
    xmouse = state['xmouse'];
    ymouse = state['ymouse'];
    leftclick = state['leftclick'];
    middleclick = state['middleclick'];
    control = state['control'];
    shift = state['shift'];
    
    --IRQ入口变化时重新注册IRQ回调
    irq_addr_check = memory.readword(0xFFFE)
    if irq_addr ~= irq_addr_check then
        memory.registerrun(irq_addr_check, on_irq)
        irq_addr = irq_addr_check
        
        --检测是否存在 IRQ
        instruction = memory.readbyte(irq_addr)
        if 0x40 ~= instruction then
            emu.print(string.format("irq addr = $%04X", irq_addr))
        else
            emu.print(string.format("no irq"))
        end
    end
    
    if leftclick then
        if false == leftclick_last then
            leftclick_last = true
            
            if control then
                irq_scanline_show = irq_scanline_show + 1
                if 2 == irq_scanline_show then
                    irq_scanline_show = 0
                end
            else
            end
            
        end
    else
        leftclick_last = false
    end
    
    if middleclick then
        if false == middle_last then
            middle_last = true
            
            if control and shift then
                for i = 0, 255, 1 do
                    sprite_tile_list[i] = 0
                end
            else
            
                if control then
                    usage_show = usage_show + 1
                    if 2 == usage_show then
                        usage_show = 0
                    end
                else
                end
            end
        end
    else
        middle_last = false
    end
    
    --检查精灵
    for i = 0, 63, 1 do
        sprite_tile = sprite_data_list[i * 4 + 1]
        
        --左边图案
        if 0 == (sprite_tile % 2) then
            if sprite_tile_list[sprite_tile] == 0 then
                --emu.print(string.format("L %.2X", sprite_tile))
                sprite_tile_list[sprite_tile] = sprite_tile
            end
        --右边图案
        else
            if sprite_tile_list[sprite_tile] == 0 then
                --emu.print(string.format("R %.2X", sprite_tile))
                sprite_tile_list[sprite_tile] = sprite_tile
            end
        end
    
    end
    
    --绘制显示
    if 1 == usage_show then
        offset_y = 32
        
        for i = 0, 255, 1 do
        
            sprite_tile = sprite_tile_list[i]
            tile_x = sprite_tile % 16
            tile_y = (sprite_tile - tile_x) / 16
            offset_x = 0
            
            if (sprite_tile > 0) then
                if 0 == (sprite_tile % 2) then
                    offset_x = 0
                else
                    offset_x = 128
                end
                
                pos_x = tile_x - (tile_x % 2)
                gui.drawbox(offset_x + pos_x * 8, tile_y * 8 + offset_y, offset_x + pos_x * 8 + sprites_size, tile_y * 8 + offset_y + 8, "#ffff00Bf", "#ffff00ff")
            end
        
        end
    
        for i = 0, 16, 1 do
            gui.line(0, i * 8 + offset_y, 256, i * 8 + offset_y, "#ffffffDf")
        end
        
        for i = 0, 31, 1 do
            gui.line(i * 8, 0 + offset_y, i * 8, 128 + offset_y, "#ffffffDf")
        end
        
        gui.line(128, offset_y, 128, offset_y + 128, "#00ff00ff")
        gui.line(0, offset_y + 32, 256, offset_y + 32, "#00ff00ff")
        gui.line(0, offset_y + 64, 256, offset_y + 64, "#00ff00ff")
        gui.line(0, offset_y + 96, 256, offset_y + 96, "#00ff00ff")
        
        for i = 0, 255, 1 do
        
            sprite_tile = sprite_tile_list[i]
            tile_x = sprite_tile % 16
            tile_y = (sprite_tile - tile_x) / 16
            offset_x = 0
            
            if (sprite_tile > 0) then
                if 0 == (sprite_tile % 2) then
                    offset_x = 0
                else
                    offset_x = 128
                end
                
                pos_x = tile_x - (tile_x % 2)
                gui.text(offset_x + pos_x * 8 + 2, tile_y * 8 + offset_y + 1, string.format("%02X", sprite_tile), "#000000ff", "#00000000")
            end
        
        end
    end
    
    if control then
        gui.line(0, ymouse, 256, ymouse, "#ffffffff")
        gui.line(xmouse, 0, xmouse, 240, "#ffffffff")
        gui.text(xmouse + 8, ymouse + 2, string.format("[%d,%d] ", xmouse, ymouse), "#00ff00ff", "#0000007f")
    end
    
    reset_addr_check = memory.readword(0xFFFC)
    if reset_addr ~= reset_addr_check then
        reset_addr = reset_addr_check
    end
    
    nmi_addr_check = memory.readword(0xFFFA)
    if nmi_addr ~= nmi_addr_check then
        nmi_addr = nmi_addr_check
    end
    
    info_show_offset = 9
    
    --if 1 == usage_show then
        
        left_count = 0
        right_count = 0

    
        for i = 0, 255, 1 do
            sprite_tile = sprite_tile_list[i]
            if (sprite_tile > 0) then
                if 0 == (sprite_tile % 2) then
                    left_count = left_count + 1
                else
                    right_count = right_count + 1
                end
            end
        end
    
        gui.text(9, 9, string.format("left: %d/256 right: %d/256", left_count, right_count), "#ffff00ff", "#0000007f")
        info_show_offset = info_show_offset + 9
    --end
    
    --if 1 == irq_scanline_show then
        gui.text(9, info_show_offset, string.format("nmi: $%04X rst: $%04X irq: $%04X", nmi_addr, reset_addr, irq_addr), "#ffff00ff", "#0000007f")
    --end
    
    sprite_data_index = 0
end