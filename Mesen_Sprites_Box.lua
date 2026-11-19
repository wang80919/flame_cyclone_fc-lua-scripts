-----------------------
-- Name: Show Sprites Box for Mesen
-- Author: FlameCyclone
-- Date: 2023.8.5
-----------------------
-- Draws a line for IRQ
-----------------------

local oam_dma_addr = 0
local sprites_size = 16
local sprite_data_index = 0
local sprite_data_list = {0}

local consoleType = emu.getState()["consoleType"]
if consoleType ~= "Nes" then
  emu.displayMessage("Script", "This script only works on the NES.")
  return
end

--初始化精灵缓冲
for i = 0, 63, 1 do
    sprite_data_list[i * 4 + 0] = 0xF8
    sprite_data_list[i * 4 + 1] = 0xF8
    sprite_data_list[i * 4 + 2] = 0xF8
    sprite_data_list[i * 4 + 3] = 0xF8
end

--精灵数据DMA写入回调
function on_oam_dma_write(address, value)
    oam_dma_addr = value
end

--精灵 OAM_ADDR 写入回调
function on_oam_addr(address, value)
    sprite_data_index = value
end

--精灵 OAM_DATA 写入回调
function on_oam_data(address, value)
    if sprite_data_index < 256 then
        sprite_data_list[sprite_data_index] = value
        sprite_data_index = sprite_data_index + 1
    end
end

--注册端口写入回调
emu.addMemoryCallback(on_oam_dma_write, emu.callbackType.write, 0x4014)
emu.addMemoryCallback(on_oam_addr, emu.callbackType.write, 0x2003)
emu.addMemoryCallback(on_oam_data, emu.callbackType.write, 0x2004)

function on_end_frame()
    largeSprites     = emu.getState()['ppu.control.largeSprites']
    state = emu.getMouseState()
    xmouse = state['x'];
    ymouse = state['y'];
    leftclick = state['left'];
    
    sprite_hit = false
    sprite_hit_x = 0
    sprite_hit_y = 0
    sprite_hit_id = 0
    sprite_hit_tile = 0
    
    x_offset = 0
    y_offset = 0
    
    if xmouse > (256 - 76) then
        x_offset = -76
    end

    if ymouse > (240 - 48) then
        y_offset = -48
    end

    line_color   = 0x00ffff00
    bkg_color    = 0xf0000000
    text_color   = 0x0000ff00
    
    if leftclick then
        emu.drawString(xmouse + 8 + x_offset, ymouse + y_offset, string.format("[%d,%d]", xmouse, ymouse), text_color, bkg_color)
    end
    
    if largeSprites then
        sprites_size = 16
    else
        sprites_size = 8
    end
    
    for i = 0, 63, 1 do
        sprite_x = sprite_data_list[i * 4 + 3]
        sprite_y = sprite_data_list[i * 4 + 0]
        sprite_tile = sprite_data_list[i * 4 + 1]
        if(sprite_y < 240)then
            emu.drawRectangle(sprite_x, sprite_y, 8 + 1, sprites_size + 1, line_color, false)
        end
        
        if (ymouse >= sprite_y and ymouse < sprite_y + sprites_size) and (xmouse >= sprite_x and xmouse < sprite_x + 8) then
            sprite_hit = true
            sprite_hit_x = sprite_x
            sprite_hit_y = sprite_y
            sprite_hit_id = i
            sprite_hit_tile = sprite_tile
            
        end
        
    end
    
    foucs_color   = 0x00ff0000
    fill_color   = 0x7f00ff00
    if sprite_hit then
        emu.drawRectangle(sprite_hit_x, sprite_hit_y, 8 + 1, sprites_size + 1, fill_color, true)
        emu.drawRectangle(sprite_hit_x, sprite_hit_y, 8 + 1, sprites_size + 1, foucs_color, false)
        emu.drawString(xmouse + 8 + x_offset, ymouse + 9 + y_offset, string.format("[pos: $%02X,$%02X]", sprite_hit_x, sprite_hit_y), text_color, bkg_color)
        emu.drawString(xmouse + 8 + x_offset, ymouse + 18 + y_offset, string.format("[addr: $%04X]", oam_dma_addr * 256 + sprite_hit_id * 4), text_color, bkg_color)
        emu.drawString(xmouse + 8 + x_offset, ymouse + 27 + y_offset, string.format("[id: $%02X]", sprite_hit_id), text_color, bkg_color)
        emu.drawString(xmouse + 8 + x_offset, ymouse + 36 + y_offset, string.format("[tile: $%02X]", sprite_hit_tile), text_color, bkg_color)
    end
    
    sprite_data_index = 0
    
end

emu.addEventCallback(on_end_frame, emu.eventType.endFrame)