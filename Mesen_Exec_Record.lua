-----------------------
-- Name: 执行记录 For Mesen
-- Author: FlameCyclone
-- Date: 2025.8.12
-----------------------
local consoleType = emu.getState()["consoleType"]
if consoleType ~= "Nes" then
  emu.displayMessage("Script", "This script only works on the NES.")
  return
end

data_list = {}

for i = 0, 0xFFFF, 0x01 do
	data_list[i] = nil
end

--执行回调
function on_exec()
	bank = emu.read(0x8000, emu.memType.nesDebug, false)
	if 0x04 == bank then
    	addr_l = emu.read(0x0E, emu.memType.nesDebug, false)
    	addr_h = emu.read(0x0F, emu.memType.nesDebug, false)
    	y = emu.getState()["cpu.y"]
    	addr = addr_h * 0x100 + addr_l + y
    	data = emu.read(addr, emu.memType.nesDebug , false)
    	if nil == data_list[addr] then
    		data_list[addr] = data
    		emu.log(string.format("%0.4X = %0.2X", addr, data))
    	end
	end
end

--停止回调
function on_stop()
    emu.log("stop...")
	file_out = io.open ("file_out_mesen.txt", "w")
	
	for i = 0x8000, 0xFFFF, 0x01 do
		data = data_list[i]
    	if nil ~= data then
	        info = string.format("$%0.4X = $%0.2X\n", i, data)
	        file_out:write(info)
        end
	end
	
    file_out:close()
    emu.log("stop...")
	emu.displayMessage("Script", "Script stop")
end

emu.addMemoryCallback(on_exec, emu.callbackType.exec, 0x8114)
emu.addMemoryCallback(on_exec, emu.callbackType.exec, 0x81AF)
emu.displayMessage("Script", "Script start")

emu.addEventCallback(on_stop, emu.eventType.scriptEnded)

