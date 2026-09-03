local screen = arg[1] or "mono"
local variant = arg[2]
LCD_W, LCD_H = screen == "color" and 480 or ((screen == "small" or screen == "tango") and 128 or 212), screen == "color" and 320 or (screen == "tango" and 96 or 64)

local rawType = type
local typeNames = {table = "number", ["function"] = "string", userdata = "table", thread = "function"}
function type(value)
	return typeNames[rawType(value)] or rawType(value)
end

EVT_SYS_FIRST, EVT_ENTER_BREAK, EVT_EXIT_BREAK = 1, 4, 5
EVT_VIRTUAL_NEXT, EVT_VIRTUAL_PREV, EVT_VIRTUAL_MENU_LONG = 6, 7, 8
EVT_TOUCH_TAP, EVT_TOUCH_SLIDE = 9, 10
EVT_ROT_LEFT, EVT_ROT_RIGHT = 11, 12
EVT_VIRTUAL_INC, EVT_VIRTUAL_INC_REPT = 13, 14
EVT_VIRTUAL_DEC, EVT_VIRTUAL_DEC_REPT = 15, 16
EVT_PLUS_FIRST, EVT_PLUS_REPT = 17, 18
EVT_MINUS_FIRST, EVT_MINUS_REPT = 19, 20
EVT_VIRTUAL_NEXT_REPT, EVT_VIRTUAL_PREV_REPT = 21, 22
SMLSIZE, MIDSIZE, DBLSIZE = 1, 2, 4
RIGHT, CENTERED, INVERS, BLINK = 8, 16, 32, 64
SOLID, DOTTED, FORCE, ERASE, GREY_DEFAULT = 1, 2, 4, 8, 16
PLAY_NOW, PLAY_BACKGROUND = 1, 2
WARNING_COLOR, BLACK, GREY, LIGHTGREY, WHITE, RED, DKGREY = 1, 2, 3, 4, 5, 6, 7
CUSTOM_COLOR = 8

local drawnText = {}
local function draw(...) end
local function drawText(x, y, value, flags)
	drawnText[#drawnText + 1] = {x = x, y = y, value = value}
end
lcd = {
	drawText = drawText,
	drawLine = draw,
	drawRectangle = draw,
	drawFilledRectangle = draw,
	drawGauge = draw,
	drawTimer = draw,
	drawPoint = draw,
	drawBitmap = draw,
	clear = draw,
	RGB = function(r, g, b) return r + g + b end,
	setColor = draw
}
Bitmap = {open = function(path) return path end}

local ids, names = {}, {}
function getFieldInfo(name)
	if ids[name] == nil then
		ids[name] = #names + 1
		names[ids[name]] = name
	end
	return {id = ids[name], unit = 9}
end

local values = {
	["tx-voltage"] = 8,
	thr = -1024,
	FM = "OK",
	RFMD = 2,
	["1RSS"] = 100,
	Sats = 8,
	RxBt = 12,
	TPWR = 100,
	Yaw = 0,
	Hdg = 0,
	Ptch = 0,
	Roll = 0,
	GPS = {lat = 1, lon = 1},
	VFAS = 12,
	["VFAS-"] = 12,
	A4 = 4,
	["A4-"] = 4,
	Fuel = 50,
	Capa = 500,
	Curr = 1,
	["Curr+"] = 1,
	Alt = 1,
	["Alt+"] = 1,
	GAlt = 1,
	Dist = 1,
	["Dist+"] = 1,
	VSpd = 0,
	GSpd = 1,
	["GSpd+"] = 1,
	ail = 0,
	ele = 0,
	rud = 0,
	["trim-t6"] = 0
}
function getValue(id) return values[names[id]] or 0 end
function getRSSI() return 100, 45, 42 end
function getVersion() return 2, screen == "color" and "tx15" or (screen == "tango" and "tango2" or "x9d"), 3, 0, nil, "EdgeTX" end
function getGeneralSettings() return {battMin = 6, battMax = 9, language = "en", voice = "en"} end
function getDateTime() return {year = "2026", mon = 9, day = 4} end
function playFile(...) end
function playNumber(...) end
function playHaptic(...) end
function playTone(...) end

local timer = {mode = 0, start = 0, value = 3600}
model = {
	getInfo = function() return {name = "Test"} end,
	getTimer = function() return timer end,
	setTimer = function(index, value) timer = value end
}

local now = 1000
function getTime() now = now + 1 return now end
local freeMemory = 65536
if variant ~= "nomem" then function getAvailableMemory() return freeMemory end end
local queue = {}
function crossfireTelemetryPop()
	local frame = table.remove(queue, 1)
	if frame ~= nil then return frame[1], frame[2] end
end
function crossfireTelemetryPush(...) end

local capturedData
local messagesRendered = 0
local statusLoads = 0
local pilotLoads = 0
local radarLoads = 0
local classicLoads = 0
function loadScript(path, env)
	local name = string.match(path, "([^/]+)$")
	name = string.gsub(name, "%.luac$", "")
	freeMemory = freeMemory - 128
	if variant == "fail" and name == "pilot_s" then return nil end
	local chunk = assert(loadfile("src/SCRIPTS/TELEMETRY/iNav/" .. name .. ".lua"))
	if name == "status" then
		statusLoads = statusLoads + 1
		return function(...)
			capturedData = select(1, ...)
			return chunk(...)
		end
	elseif name == "messages" then
		return function(...)
			local render = chunk(...)
			return function(...)
				messagesRendered = messagesRendered + 1
				return render(...)
			end
		end
	elseif name == "pilot_s" then
		pilotLoads = pilotLoads + 1
	elseif name == "radar_s" then
		radarLoads = radarLoads + 1
	elseif name == "view" then
		classicLoads = classicLoads + 1
	end
	return chunk
end

local function statusPayload(value, severity)
	local result = {0xF1, severity}
	for i = 1, #value do result[#result + 1] = string.byte(value, i) end
	result[#result + 1] = 0
	return result
end

local inav = assert(loadfile("src/SCRIPTS/TELEMETRY/iNav.lua"))(nil, {Text = WHITE, Warn = RED})
assert(capturedData == nil, "status dispatcher should load after initialization")
queue[1] = {0x80, statusPayload("Ready", 6)}
inav.background()
assert(capturedData ~= nil and #capturedData.messages == 1)
inav.run(0)
local popupFound = false
for index = 1, #drawnText do
	if string.find(drawnText[index].value, "INF Ready", 1, true) ~= nil then
		popupFound = true
		assert(drawnText[index].y >= 8 and drawnText[index].y < LCD_H)
	end
end
assert(popupFound, "status popup should render within the runtime LCD geometry")

if screen == "color" then
	inav.run(EVT_ENTER_BREAK)
else
	inav.run(EVT_ENTER_BREAK)
	if screen == "small" or screen == "tango" then
		assert(pilotLoads == (variant == "fail" and 0 or 1), "small radios should use the lightweight Pilot renderer")
		if variant == "fail" then
			local fallbackFound = false
			for index = 1, #drawnText do
				if drawnText[index].value == "LOAD pilot_s FAILED" then fallbackFound = true end
			end
			assert(fallbackFound, "failed views should show a diagnostic instead of a blank page")
			assert(capturedData.loadFailed == "pilot_s")
		end
	end
	inav.run(EVT_ENTER_BREAK)
	if screen == "small" or screen == "tango" then assert(radarLoads == 1, "small radios should use the lightweight Radar renderer") end
	inav.run(EVT_ENTER_BREAK)
end
assert(messagesRendered > 0)
assert(statusLoads > 1, "status dispatcher should reload after view changes")

queue[1] = {0x80, statusPayload("This is a long status message for horizontal reading", 4)}
inav.background()
inav.run(EVT_PLUS_FIRST)
assert(capturedData.messageOffset == 1 and capturedData.messageMaxOffset > 0)
for index = 1, 100 do inav.run(EVT_PLUS_REPT) end
assert(capturedData.messageOffset == capturedData.messageMaxOffset, "horizontal offset should stay bounded")
inav.run(EVT_VIRTUAL_PREV)
assert(capturedData.messageOffset == 0, "vertical scrolling should reset the horizontal offset")
inav.run(EVT_ENTER_BREAK)
assert((screen == "color" and not capturedData.messageView) or classicLoads > 1, "Enter should cycle from Messages back to Classic")

print("main integration test passed: " .. screen .. (variant and " " .. variant or ""))
