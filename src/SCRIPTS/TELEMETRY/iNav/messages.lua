local severityLabels = {[0] = "EMR", "ALR", "CRT", "ERR", "WRN", "NOT", "INF", "DBG"}
local HORUS = LCD_W >= 480 or LCD_H >= 480

local function elapsed(ticks)
	local seconds = math.min(math.floor(math.max(ticks, 0) * 0.01), 5999)
	return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function severityText(severity)
	return (severity <= 3 and "!" or "") .. (severityLabels[severity] or "UNK")
end

local function fit(value, length)
	if #value <= length then return value end
	return string.sub(value, 1, math.max(length - 1, 1)) .. "."
end

local function view(data, config, modes, dir, units, labels, gpsDegMin, hdopGraph, icons, calcBearing, calcDir, VERSION, SMLCD, FILE_PATH, text, line, rect, fill, frmt, event)
	if event ~= nil then
		local nextEvent = event == EVT_VIRTUAL_NEXT or event == EVT_ROT_RIGHT
		local prevEvent = event == EVT_VIRTUAL_PREV or event == EVT_ROT_LEFT
		local incEvent = event == EVT_VIRTUAL_INC or event == EVT_VIRTUAL_INC_REPT or event == EVT_PLUS_FIRST or event == EVT_PLUS_REPT or event == EVT_VIRTUAL_NEXT_REPT
		local decEvent = event == EVT_VIRTUAL_DEC or event == EVT_VIRTUAL_DEC_REPT or event == EVT_MINUS_FIRST or event == EVT_MINUS_REPT or event == EVT_VIRTUAL_PREV_REPT
		if nextEvent or prevEvent then
			data.messageScroll = math.max(data.messageScroll + (nextEvent and 1 or -1), 0)
			data.messageOffset = 0
		elseif incEvent or decEvent then
			data.messageOffset = math.max(data.messageOffset + (incEvent and 1 or -1), 0)
		end
	end
	local count = #data.messages
	local rows = HORUS and math.max(math.floor((LCD_H - 76) / 24), 1) or math.max(math.floor((LCD_H - 18) / 9), 1)
	data.messageScroll = math.min(data.messageScroll, math.max(count - rows, 0))
	data.messageOffset = math.max(data.messageOffset or 0, 0)

	if HORUS then
		local headerFlags = data.set_flags(MIDSIZE, data.TextColor)
		text(8, 25, "MESSAGES", headerFlags)
		text(LCD_W - 8, 28, count == 0 and "0" or (count - data.messageScroll) .. "/" .. count, data.set_flags(RIGHT, data.TextColor))
		line(6, 51, LCD_W - 7, 51, SOLID, data.set_flags(0, data.TextColor))
		if count == 0 then
			text(LCD_W * 0.5, LCD_H * 0.5, "No status messages", data.set_flags(CENTERED, data.TextColor))
		else
			local maxChars = math.max(math.floor((LCD_W - 20) / 8), 10)
			for row = 1, rows do
				local item = data.messages[count - data.messageScroll - row + 1]
				if item == nil then break end
				local suffix = item.count > 1 and " x" .. item.count or ""
				local value = elapsed(item.firstTime) .. " " .. severityText(item.severity) .. " " .. item.text .. suffix
				if row == 1 then
					data.messageMaxOffset = math.max(#value - maxChars, 0)
					data.messageOffset = math.min(data.messageOffset, data.messageMaxOffset)
					value = string.sub(value, data.messageOffset + 1, data.messageOffset + maxChars)
				else
					value = fit(value, maxChars)
				end
				local color = item.severity <= 4 and data.WarningColor or data.TextColor
				local y = 55 + (row - 1) * 24
				text(10, y, value, data.set_flags(SMLSIZE + (row == 1 and INVERS or 0), color))
				line(8, y + 21, LCD_W - 9, y + 21, DOTTED, data.set_flags(0, color))
			end
		end
		text(8, LCD_H - 20, "UP/DN scroll   EXIT back", data.set_flags(SMLSIZE, data.TextColor))
	else
		text(0, 9, "MESSAGES +/- read", SMLSIZE)
		text(LCD_W, 9, count == 0 and "0" or (count - data.messageScroll) .. "/" .. count, SMLSIZE + RIGHT)
		line(0, 16, LCD_W - 1, 16, SOLID, FORCE)
		if count == 0 then
			text((LCD_W - 55) * 0.5, 34, "No messages", SMLSIZE)
		else
			local maxChars = math.max(math.floor(LCD_W / 5), 10)
			for row = 1, rows do
				local item = data.messages[count - data.messageScroll - row + 1]
				if item == nil then break end
				local suffix = item.count > 1 and " x" .. item.count or ""
				local value = (SMLCD and "" or elapsed(item.firstTime) .. " ") .. severityText(item.severity) .. " " .. item.text .. suffix
				if row == 1 then
					data.messageMaxOffset = math.max(#value - maxChars, 0)
					data.messageOffset = math.min(data.messageOffset, data.messageMaxOffset)
					value = string.sub(value, data.messageOffset + 1, data.messageOffset + maxChars)
				else
					value = fit(value, maxChars)
				end
				text(0, 18 + (row - 1) * 9, value, SMLSIZE + ((row == 1 or item.severity <= 3) and INVERS or 0))
			end
		end
	end
	if count == 0 then
		data.messageMaxOffset = 0
		data.messageOffset = 0
	end
end

return view
