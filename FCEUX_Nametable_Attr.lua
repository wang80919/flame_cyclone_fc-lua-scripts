-----------------------
-- Name: Show Grid for FCEUX
-- Author: FlameCyclone
-- Date: 2023.7.6
-----------------------
-- Draws Grid
-----------------------

ppu_scroll_h = 0
ppu_scroll_v = 0
ppu_scroll_toggle = false
    
--停止回调
function on_exit()
    emu.print("stop...")
end

emu.registerexit(on_exit)

--PPU控制写入回调
function on_ppu_scroll(address, size, value)
    if false == ppu_scroll_toggle then
        ppu_scroll_h = value
        ppu_scroll_toggle = true
    else
        ppu_scroll_v = value
        ppu_scroll_toggle = false
    end
    
end

memory.registerwrite(0x2005, on_ppu_scroll)


emu.print("start...")
while (true) do
    state = input.get()
    mouse_x = state['xmouse'];
    mouse_y = state['ymouse'];
    leftclick = state['leftclick'];
    
    x_offset = 0
    y_offset = 0
    
    if mouse_x > (256 - 110) then
        x_offset = -110
    end

    if mouse_y > (240 - 48) then
        y_offset = -48
    end

	emu.frameadvance()
    
    if leftclick then
        for i = 0, 16, 1 do
            gui.line(0, 16 * i, 256, 16 * i, "#00ff00ff")
        end
        --下边横线
        gui.line(0, 239, 256, 239, "#00ff00ff")
        
        for j = 0, 15, 1 do
            gui.line(16 * j, 0, 16 * j, 240, "#00ff00ff")
        end
        --右边竖线
        gui.line(255, 0, 255, 239, "#00ff00ff")
        
        for i = 0, 16, 1 do
            for j = 0, 15, 1 do
                --gui.text(16 * j + 3, i * 16 + 4, string.format("%02X", i * 16 + j), "#ffff00ff", "#0000001f")
            end
        end
    end
    
    ppu_ctrl = memory.readbyte(0x2000)
    ppu_addr_x = mouse_x + ppu_scroll_h
    ppu_addr_y = mouse_y + ppu_scroll_v
    ppu_tile_x_count = math.floor(ppu_addr_x / 8)
    ppu_tile_y_count = math.floor(ppu_addr_y / 8)
    nt_offset = (0x400 * AND(ppu_ctrl, 0x03))
    
    if ppu_tile_x_count > 31 then
        nt_offset = (0x400 + 0x400 * AND(ppu_ctrl, 0x03))
        ppu_tile_x_count = ppu_tile_x_count - 32
    end
    
    if ppu_tile_y_count > 29 then
        nt_offset = (0x800 + 0x400 * AND(ppu_ctrl, 0x03))
        ppu_tile_y_count = ppu_tile_y_count - 30
    end
    
    ppu_addr = 0x2000 + ppu_tile_y_count * 32 + ppu_tile_x_count + nt_offset
    
    tile_id = ppu.readbyte(ppu_addr)
    
    attr_addr_x = math.floor(ppu_tile_x_count / 2)
    attr_addr_y = math.floor(ppu_tile_y_count / 2)
    
    attr_color_addr = 0x23C0 + math.floor(attr_addr_y / 2) * 7 + math.floor(attr_addr_x / 2)
    attr_color_data = ppu.readbyte(attr_color_addr)
    color_pos = bit.bor(bit.band(attr_addr_x, 0x01), bit.lshift(bit.band(attr_addr_y, 0x01), 1))
    color_index = 0
    
    --左上
    if (0 == color_pos) then
        color_index = bit.rshift(bit.band(attr_color_data, 0x03), 0)
    end
    
    --右上
    if (1 == color_pos) then
        color_index = bit.rshift(bit.band(attr_color_data, 0x0C), 2)
    end
    
    --左下
    if (2 == color_pos) then
        color_index = bit.rshift(bit.band(attr_color_data, 0x30), 4)
    end
    
    --右下
    if (3 == color_pos) then
        color_index = bit.rshift(bit.band(attr_color_data, 0xC0), 6)
    end
    
    tile_x = ppu_tile_x_count * 8 + ppu_scroll_h
    tile_y = ppu_tile_y_count * 8 + ppu_scroll_v
    gui.drawbox(tile_x, tile_y, tile_x + 8, tile_y + 8, "#ffff001f", "#ffff00ff")
    
    gui.text(mouse_x + 8 + x_offset, mouse_y + y_offset, string.format("Mouse: [%d,%d]", mouse_x, mouse_y), "#00ff00ff", "#000000ff")
    gui.text(mouse_x + 8 + x_offset, mouse_y + y_offset + 8 * 1, string.format("addr: [%04X] [%d,%d]", ppu_addr, attr_addr_x, attr_addr_y), "#00ff00ff", "#000000ff")
    gui.text(mouse_x + 8 + x_offset, mouse_y + y_offset + 8 * 2, string.format("tile: [%02X]", tile_id), "#00ff00ff", "#000000ff")
    gui.text(mouse_x + 8 + x_offset, mouse_y + y_offset + 8 * 3, string.format("color: %02X", color_index), "#00ff00ff", "#000000ff")
    gui.text(mouse_x + 8 + x_offset, mouse_y + y_offset + 8 * 4, string.format("attr addr: %04X = %02X", attr_color_addr, attr_color_data), "#00ff00ff", "#000000ff")
    
end
