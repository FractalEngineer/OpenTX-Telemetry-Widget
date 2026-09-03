-- Low-memory Pilot view for 128-pixel radios.
local function view(data, config, modes, dir, units, labels, gpsDegMin, hdopGraph, icons, calcBearing, calcDir, VERSION, SMLCD, FILE_PATH, text, line, rect, fill, frmt)
	local left, right = 31, LCD_W - 32
	local cx = math.floor((left + right) * 0.5)
	local top, bottom = 9, LCD_H - 11
	local cy = math.floor((top + bottom) * 0.5)
	local pitch, roll
	if data.pitchRoll then
		pitch = ((math.abs(data.roll) > 900 and -1 or 1) * (270 - data.pitch * 0.1) % 180) - 90
		roll = math.rad((270 - data.roll * 0.1) % 180)
	else
		pitch = -math.deg(math.atan2(data.accx * (data.accz >= 0 and -1 or 1), math.sqrt(data.accy * data.accy + data.accz * data.accz)))
		roll = math.rad(90 - math.deg(math.atan2(data.accy * (data.accz >= 0 and 1 or -1), math.sqrt(data.accx * data.accx + data.accz * data.accz))))
	end

	rect(left, top, right - left + 1, bottom - top + 1, SOLID)
	for mark = -20, 20, 10 do
		local offset = math.max(math.min((pitch - mark) * 0.5, cy - top - 2), -(cy - top - 2))
		local half = mark == 0 and 26 or 11
		local dx, dy = math.sin(roll) * half, math.cos(roll) * half
		local y1 = math.max(math.min(cy + dy - offset, bottom - 1), top + 1)
		local y2 = math.max(math.min(cy - dy - offset, bottom - 1), top + 1)
		line(cx - dx, y1, cx + dx, y2, mark == 0 and SOLID or DOTTED, FORCE)
	end
	line(cx - 10, cy, cx - 3, cy, SOLID, FORCE)
	line(cx + 3, cy, cx + 10, cy, SOLID, FORCE)
	line(cx, cy - 2, cx, cy + 2, SOLID, FORCE)

	local telem = data.telem and 0 or 3
	text(0, 10, "ALT", SMLSIZE)
	text(29, 18, math.floor((data.showMax and data.altitudeMax or data.altitude) + 0.5) .. units[data.alt_unit], SMLSIZE + RIGHT + telem)
	text(0, 29, "V/S", SMLSIZE)
	text(29, 37, frmt("%.1f", data.vspeed) .. units[data.vspeed_unit], SMLSIZE + RIGHT + telem)
	text(LCD_W, 10, "SPD", SMLSIZE + RIGHT)
	text(LCD_W, 18, math.floor((data.showMax and data.speedMax or data.speed) + 0.5) .. units[data.speed_unit], SMLSIZE + RIGHT + telem)
	text(LCD_W, 29, "HDG", SMLSIZE + RIGHT)
	text(LCD_W, 37, math.floor(data.heading + 0.5), SMLSIZE + RIGHT + telem)
	text(left, bottom + 2, frmt("%.1fV", data.batt), SMLSIZE + telem)
	text(right, bottom + 2, math.min(data.rssiLast, data.crsf and 100 or 99) .. (data.crsf and "%" or "dB"), SMLSIZE + RIGHT + telem)
	text(cx - 12, top + 1, modes[data.modeId].t, SMLSIZE + INVERS)
end

return view
