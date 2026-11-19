-----------------------
-- Name: 执行记录 For FCEUX
-- Author: FlameCyclone
-- Date: 2025.8.12
-----------------------
local cur_frame_count = 0
local last_frame_seconds = 0
local data_list = {}

--初始化记录表
for i=1, 0xFFFF, 1 do
    data_list[i] = nil
end

--执行回调
function on_exec()
    y = memory.getregister('y')
    addr_l = memory.readbyte(0x0E)
    addr_h = memory.readbyte(0x0F)
    addr = (addr_h * 0x100) + addr_l + y
    data = memory.readbyte(addr)
    
    if nil == data_list[addr] then
        data_list[addr] = data
        emu.print(string.format("%0.4X = %0.2X\n", addr, data))
    end
end

--注册端口执行回调
memory.registerexec(0x8114, on_exec)
memory.registerexec(0x81AF, on_exec)

--停止回调
function on_exit()
    file_out = io.open ("file_out_fceux.txt", "wb")

	for i = 0x8000, 0xFFFF, 0x01 do
		data = data_list[i]
    	if nil ~= data then
	        info = string.format("$%0.4X = $%0.2X\n", i, data)
	        file_out:write(info)
        end
	end
	
    file_out:close()
    emu.print("stop...")
end

emu.registerexit(on_exit)

emu.print("start...")
while (true) do
	emu.frameadvance()
    cur_frame_count = cur_frame_count + 1
    frame_seconds = math.floor(cur_frame_count / 60.0988)
    if last_frame_seconds ~= frame_seconds then
        last_frame_seconds = frame_seconds
    end
end
