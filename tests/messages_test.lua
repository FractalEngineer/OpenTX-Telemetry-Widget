local screen = arg[1] or "small"
if screen == "color" then
	LCD_W, LCD_H = 480, 320
elseif screen == "wide" then
	LCD_W, LCD_H = 212, 64
elseif screen == "tango" then
	LCD_W, LCD_H = 128, 96
else
	LCD_W, LCD_H = 128, 64
end

SMLSIZE, MIDSIZE, RIGHT, CENTERED, INVERS = 1, 2, 4, 8, 16
if screen ~= "color" then CENTERED = nil end
SOLID, DOTTED, FORCE = 1, 2, 4

local function draw(...) end
local data = {
	messages = {
		{text = "PreArm: RC not found", severity = 4, firstTime = 4200, count = 1},
		{text = "EKF variance and a deliberately long continuation", severity = 2, firstTime = 6800, count = 3}
	},
	messageScroll = 99,
	messageOffset = 99,
	TextColor = 32,
	WarningColor = 64,
	set_flags = function(flag, color) return flag + color end
}

local view = assert(loadfile("src/SCRIPTS/TELEMETRY/iNav/messages.lua"))()
view(data, {}, {}, {}, {}, {}, nil, nil, nil, nil, nil, "2.4", LCD_W < 212, "", draw, draw, draw, draw, string.format)
assert(data.messageScroll == 0)
assert(data.messageMaxOffset > 0 and data.messageOffset == data.messageMaxOffset)

data.messages = {}
view(data, {}, {}, {}, {}, {}, nil, nil, nil, nil, nil, "2.4", LCD_W < 212, "", draw, draw, draw, draw, string.format)
assert(data.messageOffset == 0 and data.messageMaxOffset == 0)

print("messages view test passed: " .. screen)
