require('moonloader')
local dlstatus = require('moonloader').download_status
local inicfg = require 'inicfg'
local keys = require "vkeys"
local imgui = require 'imgui'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

update_state = false

local script_vers = 2
local script_vers_text = "2.00"

local update_url = "https://raw.githubusercontent.com/barsScripter/Spek/main/update.ini" -- тут тоже свою ссылку
local update_path = getWorkingDirectory() .. "/update.ini" -- и тут свою ссылку

local script_url = "https://github.com/barsScripter/Spek/blob/main/spec.luac?raw=true" -- тут свою ссылку
local script_path = thisScript().path


local themes = import "resource/imgui_themes.lua"

main_window_state = imgui.ImBool(false)
arrSelectable = {false, false}

local rkeys = require 'rkeys'
imgui.ToggleButton = require('imgui_addons').ToggleButton
imgui.HotKey = require('imgui_addons').HotKey
imgui.Spinner = require('imgui_addons').Spinner
imgui.BufferingBar = require('imgui_addons').BufferingBar

local on = false
local draw_suka = false
local mark = nil
local dtext = nil
local lock = nil
local label = 0
local tag = "<<Director.SDA>>"

local x, y, z = 0, 0, 0

function main()
	repeat wait(0) until isSampAvailable()
    while not isSampLoaded() or not isSampfuncsLoaded() do wait(80) end
    sampRegisterChatCommand('sp', search)
    sampRegisterChatCommand('help', cmd_update)
    sampRegisterChatCommand('cl', clist)
	sampRegisterChatCommand('sos', sos)
	sampRegisterChatCommand('helpos', helpos)
	sampRegisterChatCommand('ps', ps)
    sampRegisterChatCommand('pf', pf)
	sampRegisterChatCommand('kmb', cmd_kmb)
	sampRegisterChatCommand('l', cmd_undate)
	sampRegisterChatCommand('menu', menu)
	
	imgui.SwitchContext()
    themes.SwitchColorTheme()
	
	    downloadUrlToFile(update_url, update_path, function(id, status)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            updateIni = inicfg.load(nil, update_path)
            if tonumber(updateIni.info.vers) > script_vers then
                sampAddChatMessage("Есть обновление! Версия: " .. updateIni.info.vers_text, -1)
                update_state = true
            end
            os.remove(update_path)
        end
    end)
	
		        if update_state then
            downloadUrlToFile(script_url, script_path, function(id, status)
                if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                    sampAddChatMessage("Скрипт успешно обновлен!", -1)
                    thisScript():reload()
                end
            end)
            break
        end
	
	while true do
        wait(0)
        if on then
            if draw_suka then
                --setMarker(1, x, y, z-2, 1, 0xFFFFFFFF)
                removeUser3dMarker(mark)
                mark = createUser3dMarker(x,y,z+2,0xFFD00000)
            else
                removeUser3dMarker(mark)
                --deleteCheckpoint(marker)
                --removeBlip(checkpoint)
            end
        end
    end
end

function search(arg)
    if not on and (not arg or not arg:find('^.+$')) then sampAddChatMessage('{9370DB}[sPecLuA]{FFFFFF}: ID жертвы то забыл.', -1) return end
    if arg:find('^%d$') or arg:find('%d+') then
        if sampIsPlayerConnected(arg) then
            arg = sampGetPlayerNickname(arg)
        else
            sampAddChatMessage('{9370DB}[sPecLuA]{FFFFFF} Такого нету на сервере ', -1)
            return
        end
    end

    on = not on
    if on then
		sampAddChatMessage('{9370DB}[sPecLuA]{FFFFFF}: Имя человека:{9370DB}'..arg..'{FFFFFF}, установил метку. Следуй по ней.', -1)
		lua_thread.create(function()

            while on do
                wait(0)
                local id = sampGetPlayerIdByNickname(arg)
                if id ~= nil and id ~= -1 and id ~= false then
                    local res, handle = sampGetCharHandleBySampPlayerId(id)
                    if res then

                        

                        local screen_text = 'топай на метку'
                        x, y, z = getCharCoordinates(handle)
                        local mX, mY, mZ = getCharCoordinates(playerPed)
                        local x1, y1 = convert3DCoordsToScreen(x,y,z)
                        local x2, y2 = convert3DCoordsToScreen(mX, mY, mZ)
                        --sampDestroy3dText(dtext)
                        if not dtext then
                            dtext = sampCreate3dText('цель',0xFFD00000,0,0,0.4,9999,true,id,-1)
                        end
                        if isPointOnScreen(x,y,z,0) then
                            renderDrawLine(x2, y2, x1, y1, 2.0, 0xFFD00000)
                            renderDrawBox(x1-2, y1-2, 8, 8, 0xAA00CC00)
                        else
                            screen_text = 'Не туда смотришь'
                        end
                        printStringNow(conv(screen_text),1)
                        draw_suka = true
                    else
                        if marker or checkpoint then
                            deleteCheckpoint(marker)
                            removeBlip(checkpoint)
                        end
                        sampDestroy3dText(dtext)
                        dtext = nil
                        draw_suka = false
                    end
                end
            end
    
        end)
    else
        lua_thread.create(function()
            draw_suka = false
            wait(10)
            removeUser3dMarker(mark)
            sampDestroy3dText(dtext)
            dtext = nil
            --deleteCheckpoint(marker)
            --removeBlip(checkpoint)
            sampAddChatMessage('{9370DB}[sPecLuA]{FFFFFF}: нужна будет помощь, обращайся!', -1)
        end)
    end
end

function sampGetPlayerIdByNickname(nick)
    local _, myid = sampGetPlayerIdByCharHandle(playerPed)
    if tostring(nick) == sampGetPlayerNickname(myid) then return myid end
    for i = 0, 1000 do if sampIsPlayerConnected(i) and sampGetPlayerNickname(i) == tostring(nick) then return i end end
end

function setMarker(type, x, y, z, radius, color)
    deleteCheckpoint(marker)
    removeBlip(checkpoint)
    checkpoint = addBlipForCoord(x, y, z)
    marker = createCheckpoint(type, x, y, z, 1, 1, 1, radius)
    changeBlipColour(checkpoint, color)
--[[    lua_thread.create(function()
    repeat
        wait(0)
        local x1, y1, z1 = getCharCoordinates(PLAYER_PED)
        until getDistanceBetweenCoords3d(x, y, z, x1, y1, z1) < radius or not doesBlipExist(checkpoint)
        deleteCheckpoint(marker)
        removeBlip(checkpoint)
        addOneOffSound(0, 0, 0, 1149)
    end)]]
end

function onScriptTerminate(s, quit)
    if s == thisScript() then
        if marker or checkpoint or mark or dtext then
            removeUser3dMarker(mark)
            deleteCheckpoint(marker)
            removeBlip(checkpoint)
            sampDestroy3dText(dtext)
        end
    end
end


function conv(text)
    local convtbl = {[230]=155,[231]=159,[247]=164,[234]=107,[250]=144,[251]=168,[254]=171,[253]=170,[255]=172,[224]=97,[240]=112,[241]=99,[226]=162,[228]=154,[225]=151,[227]=153,[248]=165,[243]=121,[184]=101,[235]=158,[238]=111,[245]=120,[233]=157,[242]=166,[239]=163,[244]=63,[237]=174,[229]=101,[246]=36,[236]=175,[232]=156,[249]=161,[252]=169,[215]=141,[202]=75,[204]=77,[220]=146,[221]=147,[222]=148,[192]=65,[193]=128,[209]=67,[194]=139,[195]=130,[197]=69,[206]=79,[213]=88,[168]=69,[223]=149,[207]=140,[203]=135,[201]=133,[199]=136,[196]=131,[208]=80,[200]=133,[198]=132,[210]=143,[211]=89,[216]=142,[212]=129,[214]=137,[205]=72,[217]=138,[218]=167,[219]=145}
    local result = {}
    for i = 1, #text do
        local c = text:byte(i)
        result[i] = string.char(convtbl[c] or c)
    end
    return table.concat(result)
end

function cmd_update(arg)
    sampShowDialog(1000, "{9370DB}[sPecLuA]{9370DB}", " \n {9370DB}/help{FFFFFF} - вызов меню помощи. \n {9370DB} /sp{FFFFFF} - слежка за игроком. \n {9370DB} /cl{FFFFFF} - ввод команды /clist 7. \n {9370DB} /kbm{FFFFFF} - созвать рядовых на КМБ. \n {9370DB} /kmbh{FFFFFF} - вопросы для КМБ \n {9370DB} /l{FFFFFF} - ввод команды /lock \n {9370DB} /ps{FFFFFF} - доклад о разгрузке с поставок | Фракция | Тонаж |, /ps SFa 199 \n автотег еще не сделан. Он есть. Но его нету. Кароче пока в процессе тег в рациюю IF", "{9370DB}Close", "", 0)
end

function cmd_undate(arg)
sampSendChat("/lock")
end

function cmd_kmb(arg)
sampSendChat("/r "..tag.." Внимание! Рядовые отслужившие 2 дня в части, прошу подойти к ГС для сдачи КМБ!")
end	

function clist(arg)
sampSendChat('/clist 7')
end

function sos(arg)
sampSendChat("/r "..tag.." На колонну напали, требуется поддержка в сектор" ..kvadrat())
end

function pf(arg)
sampSendChat("/r "..tag.." взял грузовик снабжения!")
end

function ps(arg)
    var1, var2 = string.match(arg, "(.+) (.+)")
    if var1 == nil or var1 == "" then    
		sampAddChatMessage("{FFFFFF} Ты ввел не все аргументы.")
    else
        sampSendChat("/r "..tag.." Доставил боеприпасы на склад - "..var1.." состояние склада: "..var2.."т. Едем в часть. ")
    end 
end

require('samp.events').onServerMessage = function(color, text) -- тут 2 входящих значения, это color, то есть цвет самого сообщения, и текст(ну это понятно), им присваивается значение локальной переменной для хука
    if text:match('Барс') then -- окей, с агром разобрались, теперь посложнее, заменим сообщение Как дела на Как жизнь, допустим
        msg = text:match('Барс') -- мы сделали проверку, что такой текст действительно есть, затем присвоили переменную именно части  'как дела'
         str = string.gsub (text, msg, "Мой господин товарищь Алексей Барсов") -- в самом тексте мы заменяем Как дела из переменной msg на Как жизнь и возвращаем значения
        return {color, str} -- вместо text возвращаем str
    end -- закрываем проверку
end

-- КВАДРАТЫ 

function kvadrat()
    local KV = {
        [1] = "А",
        [2] = "Б",
        [3] = "В",
        [4] = "Г",
        [5] = "Д",
        [6] = "Ж",
        [7] = "З",
        [8] = "И",
        [9] = "К",
        [10] = "Л",
        [11] = "М",
        [12] = "Н",
        [13] = "О",
        [14] = "П",
        [15] = "Р",
        [16] = "С",
        [17] = "Т",
        [18] = "У",
        [19] = "Ф",
        [20] = "Х",
        [21] = "Ц",
        [22] = "Ч",
        [23] = "Ш",
        [24] = "Я",
    }
    local X, Y, Z = getCharCoordinates(playerPed)
    X = math.ceil((X + 3000) / 250)
    Y = math.ceil((Y * - 1 + 3000) / 250)
    Y = KV[Y]
    local KVX = (Y.."-"..X)
    return KVX
end	

toggle_status = imgui.ImBool(false)
toggle_status_2 = imgui.ImBool(false)
toggle_status_3 = imgui.ImBool(false)
toggle_status_4 = imgui.ImBool(false)
toggle_status_5  = imgui.ImBool(false)
toggle_status_6 = imgui.ImBool(false)

function menu(arg)
	main_window_state.v = not main_window_state.v
    imgui.Process = main_window_state.v
end

function imgui.OnDrawFrame()

	if not main_window_state.v then
		imgui.Process = false
	end

    if main_window_state.v then
        
		
		local sw, sh = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 1.3), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(600, 260), imgui.Cond.FirstUseEver)

        imgui.Begin('Speck ', main_window_state, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoResize)

            imgui.BeginChild("ChildWindow", imgui.ImVec2(585, 120), true)

                imgui.Text(u8 "3.1 - Военнослужащему ззапрещенно продавать форму")
                imgui.Text(u8 "3.6 - Военнослужащему запрещенно открывать огонь по своим сослуживцам")
                imgui.Text(u8 "3.13 - Военнослужащему запрещенно самовольно менять взвод")                
				imgui.Text(u8 "3.2 - Военнослужащему запрещенно доставлять боеприпасы ОПГ")
			    imgui.Text(u8 "3.7 - Военнослужащему запрещенно обманывать своих товарищей")
                imgui.Text(u8 "3.20 - Военнослужащему запрещенно проводить гражданских лиц на территорию части")             				        		
			imgui.EndChild()
        
		
		imgui.Text(u8"спросить пункты устава:")
		
		imgui.SameLine()
		
		if imgui.Button(u8"3.1", toggle_status) then
            sampSendChat("Пункт устава 3.1", -1)
        end		
        
		imgui.SameLine()
		
		if imgui.Button(u8"3.6", toggle_status_2) then
            sampSendChat("Пункт устава 3.6", -1)
        end	
		
		imgui.SameLine()
		
		if imgui.Button(u8"3.13", toggle_status_3) then
            sampSendChat("Пункт устава 3.13", -1)
        end	
	   
		imgui.SameLine()

		if imgui.Button(u8"3.2", toggle_status_4) then
            sampSendChat("Пункт устава 3.2", -1)
        end	
		
		imgui.SameLine()
		
		if imgui.Button(u8"3.7", toggle_status_5) then
            sampSendChat("Пункт устава 3.7", -1)
        end	
		
		imgui.SameLine()
		
		if imgui.Button(u8"3.20", toggle_status_6) then
            sampSendChat("Пункт устава 3.20", -1)
        end	
		
	    imgui.SameLine()
		
		imgui.Text(u8' | Позвать Ст.Офицеров')
		
		imgui.SameLine()
		
		if imgui.Button(u8'PRESS') then
		   sampSendChat('/r '..tag..' Ст.Офицеры подойдите на плац, для выдачи рядовым лычки!')
		end
		
		imgui.Separator()
		
		if imgui.Button(u8"Доступные команды") then 
		    sampShowDialog(1000, "{9370DB}[sPecLuA]{9370DB}", "\n /menu {FFFFFF} - меню скрпита  \n {9370DB} /sp{FFFFFF} - слежка за игроком. \n {9370DB} /cl{FFFFFF} - ввод команды /clist 7. \n {9370DB} /kbm{FFFFFF} - созвать рядовых на КМБ. \n {9370DB} /l{FFFFFF} - ввод команды /lock \n {9370DB} /ps{FFFFFF} - доклад о разгрузке с поставок | Фракция | Тонаж |, /ps SFa 199 \n автотег еще не сделан. Он есть. Но его нету. Кароче пока в процессе тег в рациюю IF", "{9370DB}Close", "", 0)
		end
		
		imgui.SameLine()
		
		imgui.Text(u8'| Темы скрипта: - ') 
		 
	    imgui.SameLine()
		
		if imgui.Button(u8 'Красная тема') then
		    themes.SwitchColorTheme(2)
		end
		
		imgui.SameLine()
		
		if imgui.Button(u8 'Черная тема') then
            themes.SwitchColorTheme(5)
		end
		
		imgui.SameLine()
		
		if imgui.Button(u8 'Фиолетовая тема') then
            themes.SwitchColorTheme(6)
		end
		
		imgui.Separator()
		
		if imgui.Button(u8'Перезагрузить скрипт') then
           thisScript():reload()
        end
		 
		imgui.SameLine()
		 
        if imgui.Button(u8 'Отключить скрипт') then
            thisScript():unload()
        end		

		imgui.SameLine()
 		
		if imgui.Button(u8 'Сообщить о ошибке / баге') then
	        os.execute('explorer "https://vk.com/oper797"') 
		end
		
		imgui.Separator()
		
		_,id = sampGetPlayerIdByCharHandle(playerPed)
        imgui.Text(u8('Nick: '.. sampGetPlayerNickname(id) ..' ID: '..tostring(id)))
		
		imgui.SameLine()
		
		imgui.Text(u8' | Мониторинг слежки -')
        imgui.TextColored(imgui.ImVec4(1.0, 0.0, 0.0, 1.0 ), u8'нет', imgui.SameLine())
		
        imgui.SameLine()
		
		imgui.ToggleButton(u8'| Cheat Helper', toggle_status)
		
		imgui.SameLine()
				
		imgui.ToggleButton(u8' | AutoTag', toggle_status_3)
		
		imgui.Separator()
		
		imgui.Text(u8'Автор скрипта --')
        imgui.TextColored(imgui.ImVec4(1.0, 0.0, 0.0, 1.0 ), u8'Alexey Barsow', imgui.SameLine())
		
		imgui.SameLine()
		
		imgui.Text(u8' | Version: 3 | Ваш ключ: 44655 | Ключ активен')
		
		imgui.End()
    end
end
