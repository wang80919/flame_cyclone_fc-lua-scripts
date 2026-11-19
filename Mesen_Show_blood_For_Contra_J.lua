-----------------------
-- Name: Show objects blood for Mesen
-- Author: FlameCyclone
-- Date: 2023.10.9
-----------------------
-- Draws objects blood
-----------------------

local life_icon_disable         =   true       --禁用生命图标显示

local game_stage_addr           =   0x0030      --游戏关卡
local obj_state_addr            =   0x04B8      --敌人状态起始地址 5:弹起爆炸 0:不存在 6:下落 7:原地爆炸
local obj_type_addr             =   0x0528      --敌人类型  10: 第2关boss 1C: 第4关boss
local obj_blood_addr            =   0x0578      --敌人血量
local obj_blood_x               =   -4
local obj_blood_y               =   -26

local obj_boss2_blood_addr      =   0x05B8      --第2关敌人BOSS血量
local obj_boss4_blood_addr      =   0x05E8      --第4关敌人BOSS血量

local obj_valid_addr            =   0x0598      --敌人有效性(是否可击打)
local obj_x_addr                =   0x033E      --敌人X坐标
local obj_y_addr                =   0x0324      --敌人Y坐标

local player1_weapon_addr       =   0x00AA     --1P武器
local player1_life_addr         =   0x0032     --1P生命
local player1_bulletproof_addr  =   0x00B0     --1P防弹状态
local player1_flashing_addr     =   0x00AE     --1P闪烁状态
local player1_info_x            =   16
local player1_info_y            =   33

local player1_score_addr        =   0x07E2      --1P分数
local player1_score_x           =   16
local player1_score_y           =   45

local player2_weapon_addr       =   0x00AB     --2P武器
local player2_life_addr         =   0x0033     --2P生命
local player2_bulletproof_addr  =   0x00B1     --2P防弹状态
local player2_flashing_addr     =   0x00AF     --1P闪烁状态
local player2_info_x            =   192
local player2_info_y            =   33

local player2_score_addr        =   0x07E4      --2P分数
local player2_score_x           =   192
local player2_score_y           =   45

--颜色顺序 #aarrggbb 透明度(ff:全透明, 00:不透明),红,绿,蓝
local obj_blood_bkg_color       = 0xCF000000    --血量框背景颜色
local obj_blood_border_color    = 0x00ffff00    --血量框边框颜色
local obj_blood_text_bkg_color  = 0xff000000    --血量文本背景颜色
local obj_blood_text_color      = 0x00ffff00    --血量文本颜色

--玩家1颜色
local player1_box_bkg_color     = 0xCF000000   --背景颜色
local player1_box_border_color  = 0x002038ef   --边框颜色
local player1_text_bkg_color    = 0xff000000   --文本背景颜色
local player1_text_color        = 0x00ffdbaa   --文本颜色

--玩家2颜色
local player2_box_bkg_color     = 0xCF000000   --背景颜色
local player2_box_border_color  = 0x00db2800   --边框颜色
local player2_text_bkg_color    = 0xff000000   --文本背景颜色
local player2_text_color        = 0x00ffbeb2   --文本颜色

--武器名称
local weapon_name = {
    ["00"] = "-",
    ["01"] = "M",
    ["02"] = "F",
    ["03"] = "S",
    ["04"] = "L",
    ["10"] = "R",
    ["11"] = "RM",
    ["12"] = "RF",
    ["13"] = "RS",
    ["14"] = "RL",
}

if life_icon_disable then
    player1_score_y = 21
    player2_score_y = 21
end

local consoleType = emu.getState()["consoleType"]
if consoleType ~= "Nes" then
  emu.displayMessage("Script", "This script only works on the NES.")
  return
end

--显示对象血量
function show_objects_blood()

    --遍历最多16个对象(0 - 15)
    for i = 0, 15, 1 do
        game_stage = emu.read(game_stage_addr, emu.memType.nesDebug)
        obj_type = emu.read(obj_type_addr + i, emu.memType.nesDebug)
        obj_state = emu.read(obj_state_addr + i, emu.memType.nesDebug)
        obj_valid = emu.read(obj_valid_addr + i, emu.memType.nesDebug)
        obj_x = emu.read(obj_x_addr + i, emu.memType.nesDebug)
        obj_y = emu.read(obj_y_addr + i, emu.memType.nesDebug)
            
        --检测物体状态和可击打状态
        if 0 ~= obj_state and obj_valid < 128 then
            obj_blood = emu.read(obj_blood_addr + i, emu.memType.nesDebug)
            
            --第2关BOSS检测与特殊处理
            if 0x10 == obj_type and 1 == game_stage then
                obj_blood = emu.read(obj_boss2_blood_addr + i, emu.memType.nesDebug)
            end
            
            --第4关BOSS检测与特殊处理
            if 0x1C == obj_type and 3 == game_stage then
                obj_blood = emu.read(obj_boss4_blood_addr + i, emu.memType.nesDebug)
            end
            
            --血量为正数才显示
            if obj_blood <= 127 then
                text_width = string.len(tostring(obj_blood))
                
                content_x_pos = obj_x + obj_blood_x
                content_y_pos = obj_y + obj_blood_y
                
                --显示血量背景框
                emu.drawRectangle(content_x_pos, content_y_pos, 9 * text_width, 11, obj_blood_bkg_color, true)
                emu.drawRectangle(content_x_pos, content_y_pos, 9 * text_width, 11, obj_blood_border_color, false)
                emu.drawString(content_x_pos + 2, content_y_pos + 2, string.format("%d", obj_blood), obj_blood_text_color, obj_blood_text_bkg_color)
            else
                --血量为负数的为无敌状态
                --emu.drawRectangle(obj_x - 9 * 3 - 2, obj_y - 2, 9 * 4 + 2, 11, obj_blood_border_color, false)
                --emu.drawString(obj_x - 9 * 3, obj_y, string.format("protected", obj_blood), obj_blood_text_color, obj_blood_text_bkg_color)
            end
        end
    end
end

--显示玩家分数(显示X坐标, 显示Y坐标, 分数地址, 边框背景色, 边框色, 文本色, 文本背景色)
function show_player_score(x, y, score_addr, box_bkg_color, box_border_color, text_color, text_bkg_color)
    info_x = x
    info_y = y
    text_width = 10
    text_height = 10
    
    value = emu.readWord(score_addr, emu.memType.nesDebug)
    text_width = 1 + 3
    
    text_content = string.format("HI %d", value * 100)
    text_lenth = string.len(text_content)
    
    --分数
    if text_content and text_lenth > 0 then
        text_width = 6 * text_lenth - 1
        text_height = 11
        emu.drawRectangle(info_x, info_y, text_width + 2, text_height, box_bkg_color, true)
        emu.drawRectangle(info_x, info_y, text_width + 2, text_height, box_border_color, false)
        emu.drawString(info_x + 2, info_y + 2, string.format("%s", text_content), text_color, text_bkg_color)
        info_x = info_x + text_width + 4
    end

end

--显示玩家信息(显示X坐标, 显示Y坐标, 武器地址, 生命地址, 防弹地址, 透明地址, 边框背景色, 边框色, 文本色, 文本背景色)
function show_player_info(x, y, weapon_addr, life_addr, bulletproof_addr, flashing_addr, box_bkg_color, box_border_color, text_color, text_bkg_color)
    info_x = x
    info_y = y
    text_width = 10
    text_height = 11
    text_lenth = 0;
    
    --武器
    value = emu.read(weapon_addr, emu.memType.nesDebug)
    text_content = weapon_name[string.format("%0.2X", value)]
    if text_content then 
        text_lenth = string.len(text_content)
    end
    
    if text_content and text_lenth > 0 then
        text_width = 6 * text_lenth + 1
        emu.drawRectangle(info_x, info_y, text_width + 2, text_height, box_bkg_color, true)
        emu.drawRectangle(info_x, info_y, text_width + 2, text_height, box_border_color, false)
        emu.drawString(info_x + 2, info_y + 2, string.format("%s", text_content), text_color, text_bkg_color)
        info_x = info_x + text_width + 4
    end

    --生命
    value = emu.read(life_addr, emu.memType.nesDebug)
    text_content = string.format("%d", value)
    text_lenth = string.len(text_content)
    if text_content and text_lenth > 0 then
        text_width = 6 * text_lenth + 1
        emu.drawRectangle(info_x, info_y, text_width + 2, text_height, box_bkg_color, true)
        emu.drawRectangle(info_x, info_y, text_width + 2, text_height, box_border_color, false)
        emu.drawString(info_x + 2, info_y + 2, string.format("%s", text_content), text_color, text_bkg_color)
        info_x = info_x + text_width + 4
    end
    
    --防弹金身无敌
    value = emu.read(bulletproof_addr, emu.memType.nesDebug)
    text_content = string.format("B %d", value)
    text_lenth = string.len(text_content)
    if text_content and text_lenth > 0 and value > 0 then
        text_width = 6 * text_lenth + 1
        emu.drawRectangle(info_x, info_y, text_width + 2, text_height, box_bkg_color, true)
        emu.drawRectangle(info_x, info_y, text_width + 2, text_height, box_border_color, false)
        emu.drawString(info_x + 2, info_y + 2, string.format("%s", text_content), text_color, text_bkg_color)
        info_x = info_x + text_width + 4
    end
    
    --透明闪烁无敌
    value = emu.read(flashing_addr, emu.memType.nesDebug)
    text_content = string.format("F %d", value)
    text_lenth = string.len(text_content)
    if text_content and text_lenth > 0 and value > 0 then
        text_width = 6 * text_lenth + 1
        emu.drawRectangle(info_x, info_y, text_width + 2, text_height, box_bkg_color, true)
        emu.drawRectangle(info_x, info_y, text_width + 2, text_height, box_border_color, false)
        emu.drawString(info_x + 2, info_y + 2, string.format("%s", text_content), text_color, text_bkg_color)
        info_x = info_x + text_width + 4
    end
end

function show_info()
    is_game_running = emu.read(0x2c, emu.memType.nesDebug)
    --检查是否处于正常游戏中
    if 0x04 == is_game_running or 0x08 == is_game_running  or 0x09 == is_game_running or 0x0B == is_game_running then
        --禁用生命图标显示
        if life_icon_disable then
            emu.write(0x37, 0x00, emu.memType.nesDebug)
        end

        --显示敌人血量
        show_objects_blood()
        
        --显示玩家1信息与分数
        show_player_score(player1_score_x, player1_score_y, player1_score_addr, player1_box_bkg_color, player1_box_border_color, player1_text_color, player1_text_bkg_color)
        show_player_info(player1_info_x, player1_info_y, player1_weapon_addr, player1_life_addr, player1_bulletproof_addr, player1_flashing_addr, player1_box_bkg_color, player1_box_border_color, player1_text_color, player1_text_bkg_color)
        
        --检查是否处于双人模式, 是的话就显示玩家1信息与分数
        is_double_player = emu.read(0x22, emu.memType.nesDebug)
        if 0x01 == is_double_player then
            show_player_score(player2_score_x, player2_score_y, player2_score_addr, player2_box_bkg_color, player2_box_border_color, player2_text_color, player2_text_bkg_color)
            show_player_info(player2_info_x, player2_info_y, player2_weapon_addr, player2_life_addr, player2_bulletproof_addr, player2_flashing_addr, player2_box_bkg_color, player2_box_border_color, player2_text_color, player2_text_bkg_color)
        end
    end
end

--脚本停止回调函数
function on_script_stop()
    if life_icon_disable then
        emu.write(0x37, 0xff, emu.memType.nesDebug)
    end
	emu.displayMessage("Script", "Stoped")
end

-- 注册帧开始回调函数
emu.addEventCallback(show_info, emu.eventType.startFrame)
emu.addEventCallback(on_script_stop, emu.eventType.scriptEnded)
emu.displayMessage("Script", "Show objects blood start")