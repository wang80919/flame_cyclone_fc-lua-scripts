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

local irq_scanline_show = 1
local mouse_pos_show = 1
local sprites_show_mode = 0
local sprites_show_tile = 0
local middleclick_last = false
local leftclick_last = false

local cur_frame_cycles = 0
local last_frame_cycles = 0
local frame_cycles = 0
local irq_addr = 0
local reset_addr = 0
local nmi_addr = 0

local oam_dma_addr = 0
local sprites_size = 16
local sprite_data_index = 0
local sprite_data_list = {0}

--初始化精灵缓冲
for i = 0, 63, 1 do
    sprite_data_list[i * 4 + 0] = 0xF8
    sprite_data_list[i * 4 + 1] = 0xF8
    sprite_data_list[i * 4 + 2] = 0xF8
    sprite_data_list[i * 4 + 3] = 0xF8
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

--精灵数据DMA写入回调
function on_oam_dma_write(address, size, value)
    oam_dma_addr = value
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

--注册端口写入回调
memory.registerwrite(0x4014, on_oam_dma_write)
memory.registerwrite(0x2000, on_ppu_ctrl)
memory.registerwrite(0x2003, on_oam_addr)
memory.registerwrite(0x2004, on_oam_data)

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

--停止回调
function on_exit()
    emu.print("stop...")
end

emu.registerexit(on_exit)

emu.print("start...")

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
    
    sprite_hit = false
    sprite_hit_x = 0
    sprite_hit_y = 0
    sprite_hit_id = 0
    sprite_hit_tile = 0
    
    x_offset = 0
    y_offset = 0
    
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
    
    reset_addr_check = memory.readword(0xFFFC)
    if reset_addr ~= reset_addr_check then
        reset_addr = reset_addr_check
    end
    
    nmi_addr_check = memory.readword(0xFFFA)
    if nmi_addr ~= nmi_addr_check then
        nmi_addr = nmi_addr_check
    end
    
    gui.text(32, 9, string.format("nmi: $%04X", nmi_addr), "#ffff00ff", "#0000007f")
    gui.text(96, 9, string.format("rst: $%04X", reset_addr), "#ffff00ff", "#0000007f")
    
    --检测是否存在 IRQ
    instruction = memory.readbyte(irq_addr)
    if 0x40 ~= instruction then
        gui.text(160, 9, string.format("irq: $%04X", irq_addr), "#ffff00ff", "#0000007f")
    else
        gui.text(160, 9, string.format("irq: $%04X(no irq)", irq_addr), "#ffff00ff", "#0000007f")
    end
    
    if xmouse > (256 - 76) then
        x_offset = -76
    end

    if ymouse > (240 - 48) then
        y_offset = -48
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
                sprites_show_tile = sprites_show_tile + 1
                if 2 == sprites_show_tile then
                    sprites_show_tile = 0
                end
            end
            
        end
    else
        leftclick_last = false
    end
    
    if middleclick then
        if false == middleclick_last then
            middleclick_last = true
            
            if control then
                mouse_pos_show = mouse_pos_show + 1
                if 2 == mouse_pos_show then
                    mouse_pos_show = 0
                end
            else
                sprites_show_mode = sprites_show_mode + 1
                if 4 == sprites_show_mode then
                    sprites_show_mode = 0
                end
            end
        end
    else
        middleclick_last = false
    end
    
    if 1 == mouse_pos_show then
        gui.line(0, ymouse, 256, ymouse, "#ffffffff")
        gui.line(xmouse, 0, xmouse, 240, "#ffffffff")
    end
    
    pos_y = ymouse + y_offset + 2
    gui.text(xmouse + 8 + x_offset, pos_y, string.format("[%d,%d] ", xmouse, ymouse), "#00ff00ff", "#0000007f")
    pos_y = pos_y + 8
    gui.text(xmouse + 8 + x_offset, pos_y, string.format("tile(left): %d", sprites_show_tile), "#00ff00ff", "#0000007f")
    pos_y = pos_y + 8
    gui.text(xmouse + 8 + x_offset, pos_y, string.format("mode(middle): %d", sprites_show_mode), "#00ff00ff", "#0000007f")
    pos_y = pos_y + 8
    gui.text(xmouse + 8 + x_offset, pos_y, string.format("irq(ctrl+left): %d", irq_scanline_show), "#00ff00ff", "#0000007f")
    pos_y = pos_y + 8
    gui.text(xmouse + 8 + x_offset, pos_y, string.format("pos(ctrl+middle): %d", mouse_pos_show), "#00ff00ff", "#0000007f")
    pos_y = pos_y + 8
    
    for i = 0, 63, 1 do
        sprite_x = sprite_data_list[i * 4 + 3]
        sprite_y = sprite_data_list[i * 4 + 0]
        sprite_tile = sprite_data_list[i * 4 + 1]
        if (sprite_y < 240 and sprite_tile >= 0x00) then
        
            if 1 == sprites_show_mode then
                if 1 == sprites_show_tile then
                    gui.text(sprite_x, sprite_y + sprites_size + 2, string.format("%02X", sprite_tile), "#00ff00ff", "#0000007f")
                end
                gui.drawbox(sprite_x, sprite_y, sprite_x + 8, sprite_y + sprites_size, "#00000000", "#ffff00ff")
            end
            if 2 == sprites_show_mode then
                if 0 == (sprite_tile % 2) then
                    if 1 == sprites_show_tile then
                        gui.text(sprite_x, sprite_y - 16, string.format("%02X", sprite_tile), "#00ff00ff", "#0000007f")
                    end
                    gui.drawbox(sprite_x, sprite_y, sprite_x + 8, sprite_y + sprites_size, "#00000000", "#ffff00ff")
                end
            end
            if 3 == sprites_show_mode then
                if 0 ~= (sprite_tile % 2) then
                    if 1 == sprites_show_tile then
                        gui.text(sprite_x, sprite_y - 16, string.format("%02X", sprite_tile), "#00ff00ff", "#0000007f")
                    end
                    gui.drawbox(sprite_x, sprite_y, sprite_x + 8, sprite_y + sprites_size, "#00000000", "#ffff00ff")
                end
            end
        end
        
        if (ymouse >= sprite_y and ymouse < sprite_y + sprites_size) and (xmouse >= sprite_x and xmouse < sprite_x + 8) then
            sprite_hit = true
            sprite_hit_x = sprite_x
            sprite_hit_y = sprite_y
            sprite_hit_id = i
            sprite_hit_tile = sprite_tile
            
        end
    end
    
    if sprite_hit then
        gui.drawbox(sprite_hit_x, sprite_hit_y, sprite_hit_x + 8, sprite_hit_y + sprites_size, "#00ff007f", "#ff0000ff")
        gui.text(xmouse + 8 + x_offset, ymouse + 9 + y_offset, string.format("[pos: $%02X,$%02X]", sprite_hit_x, sprite_hit_y), "#00ff00ff", "#0000007f")
        gui.text(xmouse + 8 + x_offset, ymouse + 18 + y_offset, string.format("[addr: $%04X]", oam_dma_addr * 256 + sprite_hit_id * 4), "#00ff00ff", "#0000007f")
        gui.text(xmouse + 8 + x_offset, ymouse + 27 + y_offset, string.format("[id: $%02X]", sprite_hit_id), "#00ff00ff", "#0000007f")
        gui.text(xmouse + 8 + x_offset, ymouse + 36 + y_offset, string.format("[tile: $%02X]", sprite_hit_tile), "#00ff00ff", "#0000007f")
    end
    
    sprite_data_index = 0
end