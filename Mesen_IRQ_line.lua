-----------------------
-- Name: Show IRQ Scanline for Mesen
-- Author: FlameCyclone
-- Date: 2023.8.5
-----------------------
-- Draws a line for IRQ
-----------------------

local consoleType = emu.getState()["consoleType"]
if consoleType ~= "Nes" then
  emu.displayMessage("Script", "This script only works on the NES.")
  return
end

function on_irq()
    -- 颜色常量
    line_color   = 0x00FFFF00
    bkg_color    = 0xF0000000
    text_color   = 0x00FFFF00
    
    -- 绘制当前扫描线
    irq_scanline     = emu.getState()['ppu.scanline']
    emu.drawLine(0, irq_scanline, 256, irq_scanline, line_color, 1)
    emu.drawString(12, irq_scanline + 4, irq_scanline, text_color, bkg_color)
    
    -- 绘制中断入口
    nmi_addr = emu.readWord(0xFFFA, emu.memType.nesDebug , false)
    reset_addr = emu.readWord(0XFFFC, emu.memType.nesDebug , false)
    irq_addr = emu.readWord(0XFFFE, emu.memType.nesDebug , false)
    emu.drawString(29, 9, string.format("nmi: $%04X reset: $%04X irq: $%04X", nmi_addr, reset_addr, irq_addr), text_color, bkg_color)
end

emu.addEventCallback(on_irq, emu.eventType.reset)
emu.addEventCallback(on_irq, emu.eventType.nmi)
emu.addEventCallback(on_irq, emu.eventType.irq)
emu.displayMessage("Script", "Irq Scanline")
