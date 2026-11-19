-----------------------
-- Name: Show objects blood for FCEUX
-- Author: FlameCyclone
-- Date: 2023.10.9
-----------------------
-- Draws objects blood
-----------------------

local game_stage_addr           =   0x0030      --游戏关卡
local obj_state_addr            =   0x04B8      --敌人状态起始地址 5:弹起爆炸 0:不存在 6:下落 7:原地爆炸
local obj_type_addr             =   0x0528      --敌人类型  10: 第2关boss 1C: 第4关boss

local obj_blood_addr            =   0x0578      --敌人血量
local obj_boss2_blood_addr      =   0x05B8      --第2关敌人BOSS血量
local obj_boss4_blood_addr      =   0x05E8      --第4关敌人BOSS血量

local obj_valid_addr            =   0x0598      --敌人有效性(是否可击打)
local obj_x_addr                =   0x033E      --敌人X坐标
local obj_y_addr                =   0x0324      --敌人Y坐标

local bullet_state_addr         =   0x0438      --子弹状态 0:不存在 1:存在 2:销毁
local bullet_type_addr          =   0x0388      --子弹类型 0: 无 1:普通 2:m 3:f 4:s 5:l
local bullet_icon_addr          =   0x0368      --子弹图像 普通:1E M:1F F:22 S:1F-21 L:24(横向)23(纵向)25(右下)
local bullet_x_pos_addr         =   0x03C8      --子弹X坐标
local bullet_y_pos_addr         =   0x03B8      --子弹Y坐标
local bullet_x_speed_addr       =   0x0408      --子弹X速度
local bullet_y_speed_addr       =   0x03F8      --子弹Y速度

local bullet_track_list = {0}

local enemy_begin_index         = 0
local enemy_end_index           = 0
local enemy_track_index         = 0

--存放子弹追踪的敌人序号
for i = 0, 15, 1 do
    bullet_track_list[i] = 0xff
end

--脚本退出回调函数
function on_exit()
    emu.print("stop...")
end

--注册脚本退出回调函数
emu.registerexit(on_exit)

--追踪敌人

--
function calculate_enemy_count()
    enemy_begin_index = 0
    for i = 0, 15, 1 do
        obj_type = memory.readbyte(obj_type_addr +  i)
        obj_state = memory.readbyte(obj_state_addr +  i)
        obj_valid = memory.readbyte(obj_valid_addr +  i)
        obj_x = memory.readbyte(obj_x_addr +  i)
        obj_y = memory.readbyte(obj_y_addr +  i)
        
        obj_blood = memory.readbyte(obj_blood_addr +  i)
        
        --第2关BOSS检测与特殊处理
        if 0x10 == obj_type and 1 == game_stage then
            obj_blood = memory.readbyte(obj_boss2_blood_addr +  i)
        end
        
        --第4关BOSS检测与特殊处理
        if 0x1C == obj_type and 3 == game_stage then
            obj_blood = memory.readbyte(obj_boss4_blood_addr +  i)
        end
                
        if (0 ~= obj_state) and (obj_blood < 128) and (obj_blood > 0) and (obj_valid < 128) then
            enemy_begin_index = i     
            break;
        end
    end
    
    enemy_end_index = 0
    for i = 15, 0, -1 do
        obj_type = memory.readbyte(obj_type_addr +  i)
        obj_state = memory.readbyte(obj_state_addr +  i)
        obj_valid = memory.readbyte(obj_valid_addr +  i)
        obj_x = memory.readbyte(obj_x_addr +  i)
        obj_y = memory.readbyte(obj_y_addr +  i)
        
        obj_blood = memory.readbyte(obj_blood_addr +  i)
        
        --第2关BOSS检测与特殊处理
        if 0x10 == obj_type and 1 == game_stage then
            obj_blood = memory.readbyte(obj_boss2_blood_addr +  i)
        end
        
        --第4关BOSS检测与特殊处理
        if 0x1C == obj_type and 3 == game_stage then
            obj_blood = memory.readbyte(obj_boss4_blood_addr +  i)
        end
                
        if (0 ~= obj_state) and (obj_blood < 128) and (obj_blood > 0) and (obj_valid < 128) then
            enemy_end_index = i     
            break;
        end
    end
    
    enemy_count_total = 0
    for i = 0, 15, 1 do
        obj_type = memory.readbyte(obj_type_addr +  i)
        obj_state = memory.readbyte(obj_state_addr +  i)
        obj_valid = memory.readbyte(obj_valid_addr +  i)
        obj_x = memory.readbyte(obj_x_addr +  i)
        obj_y = memory.readbyte(obj_y_addr +  i)
        
        obj_blood = memory.readbyte(obj_blood_addr +  i)
        
        --第2关BOSS检测与特殊处理
        if 0x10 == obj_type and 1 == game_stage then
            obj_blood = memory.readbyte(obj_boss2_blood_addr +  i)
        end
        
        --第4关BOSS检测与特殊处理
        if 0x1C == obj_type and 3 == game_stage then
            obj_blood = memory.readbyte(obj_boss4_blood_addr +  i)
        end
                
        if (0 ~= obj_state) and (obj_blood < 128) and (obj_blood > 0) and (obj_valid < 128) then
            enemy_count_total = enemy_count_total + 1
        end
    end
end

function track_enemy(bullet_index, enemy_index)

    obj_type = memory.readbyte(obj_type_addr + enemy_index)
    obj_state = memory.readbyte(obj_state_addr + enemy_index)
    obj_valid = memory.readbyte(obj_valid_addr + enemy_index)
    obj_x = memory.readbyte(obj_x_addr + enemy_index)
    obj_y = memory.readbyte(obj_y_addr + enemy_index)
    obj_blood = memory.readbyte(obj_blood_addr + enemy_index)
    
    bullet_x = memory.readbyte(bullet_x_pos_addr + bullet_index)
    bullet_y = memory.readbyte(bullet_y_pos_addr + bullet_index)
    bullet_x_speed = memory.readbyte(bullet_x_speed_addr + bullet_index)
    bullet_y_speed = memory.readbyte(bullet_y_speed_addr + bullet_index)

    --获取子弹水平速度绝对值
    if bullet_x_speed > 127 then
        bullet_x_speed = 256 - bullet_x_speed
    end
    
    --获取子弹垂直速度绝对值
    if bullet_y_speed > 127 then
        bullet_y_speed = 256 - bullet_y_speed
    end

    --比较子弹与敌人的坐标
    if obj_x > bullet_x and obj_x - bullet_x > bullet_x_speed then
        memory.writebyte(bullet_x_speed_addr + bullet_index, 3)
    end
    
    if obj_y > bullet_y and obj_y - bullet_y > bullet_y_speed then
        memory.writebyte(bullet_y_speed_addr + bullet_index, 3)
    end
    
    if bullet_x > obj_x and bullet_x - obj_x > bullet_x_speed then
        memory.writebyte(bullet_x_speed_addr + bullet_index, 256 - 3)
    end
    
    if bullet_y > obj_y and bullet_y - obj_y > bullet_y_speed then
        memory.writebyte(bullet_y_speed_addr + bullet_index, 256 - 3)
    end
    
    distance_x = obj_x - bullet_x
    distance_y = obj_y - bullet_y
    
    if obj_x > bullet_x then
        distance_x = obj_x - bullet_x
    else
        distance_x = bullet_x - obj_x
    end
    
    if obj_y > bullet_y then
        distance_y = obj_y - bullet_y
    else
        distance_y = bullet_y - obj_y
    end
    
    if distance_x > 127 then
        distance_x = 256 - distance_x
    end
    
    if distance_y > 127 then
        distance_y = 256 - distance_y
    end
    
    if distance_x < 2 then
        memory.writebyte(bullet_y_speed_addr + bullet_index, 0)
    end
    
    if distance_y < 2 then
        memory.writebyte(bullet_x_speed_addr + bullet_index, 0)
    end
    
    if bullet_x == obj_x then
        memory.writebyte(bullet_y_speed_addr + bullet_index, 0)
    end
    
    if bullet_y == obj_y then
        memory.writebyte(bullet_x_speed_addr + bullet_index, 0)
    end
    
    if bullet_x_speed < 2 and bullet_y_speed < 2 then
        memory.writebyte(bullet_x_speed_addr + bullet_index, 3)
    end
end

local obj_blood_text_bkg_color  = "#00000000"   --血量文本背景颜色
local obj_blood_text_color      = "#ffff00ff"   --血量文本颜色      = "#ffff00ff"   --血量文本颜色

local global_index = 0

--子弹追踪
function bullet_track()

    game_stage = memory.readbyte(game_stage_addr)
    --不考虑2, 4关
    calculate_enemy_count()
    enemy_track_index = enemy_begin_index
    
    if 1 ~= game_stage and 3 ~= game_stage then
        --遍历最多16个对象(0 - 15)
        
        for i = 0, 15, 1 do
            
            bullet_state = memory.readbyte(bullet_state_addr + i)
            
            
            --检查子弹是否存在
            if 1 == bullet_state then
            
                for j = enemy_track_index, enemy_end_index, 1 do
                    obj_type = memory.readbyte(obj_type_addr + j)
                    obj_state = memory.readbyte(obj_state_addr + j)
                    obj_valid = memory.readbyte(obj_valid_addr + j)
                    obj_blood = memory.readbyte(obj_blood_addr + j)
                    is_valid = false
                    
                    if (0 ~= obj_state) and (obj_blood < 128) and (obj_blood > 0) then
                        is_valid = true
                    end
                    
                    --第2关BOSS检测与特殊处理
                    if 0x10 == obj_type and 1 == game_stage then
                        obj_blood = memory.readbyte(obj_boss2_blood_addr + j)
                    end
                    
                    --第4关BOSS检测与特殊处理
                    if 0x1C == obj_type and 3 == game_stage then
                        obj_blood = memory.readbyte(obj_boss4_blood_addr + j)
                    end
                    
                    for k = 0, 15, 1 do
                        gui.text(k * 14, 0, string.format("%0.2x", bullet_track_list[k]), obj_blood_text_color, obj_blood_text_bkg_color)
                    end
                
                    if enemy_track_index < enemy_end_index then
                        enemy_track_index = enemy_track_index + 1
                    end
                    
                    if is_valid then
                        --未分配对象则分配
                        if 0xff == bullet_track_list[i] then 
                            bullet_track_list[i] = j
                            
                            emu.print(i.." = "..j)
                            break
                        end
                        
                        --追踪敌人
                        if bullet_track_list[i] == j then 
                            --track_enemy(i, j)
                        end
                        
                        --emu.print(string.format("%d", global_index))
                
                    end
                    
                end
                
                if enemy_track_index >= enemy_end_index then
                    enemy_track_index = enemy_begin_index
                end
            
            else
                --清除追踪的对象
                if 0xff ~= bullet_track_list[i] then
                    bullet_track_list[i] = 0xff
                    --emu.print("clear = "..i)
                end
            end
            
        end
    end
    
    global_index = global_index + 1
    
    for i = 0, 15, 1 do
        gui.text(i * 14, 10, string.format("%0.2x", bullet_track_list[i]), obj_blood_text_color, obj_blood_text_bkg_color)
    end
    
end

emu.print("start...")
while (true) do
	emu.frameadvance()
    bullet_track()
end
