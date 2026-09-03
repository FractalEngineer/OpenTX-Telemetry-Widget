-- Low-memory Radar view for 128-pixel radios.
local function view(data, config, modes, dir, units, labels, gpsDegMin, hdopGraph, icons, calcBearing, calcDir, VERSION, SMLCD, FILE_PATH, text, line, rect, fill, frmt)
	local left, right = 31, LCD_W - 32
	local top, bottom = 9, LCD_H - 11
	local cx, cy = math.floor((left + right) * 0.5), math.floor((top + bottom) * 0.5)
	local radius = math.min((right - left) * 0.5 - 3, (bottom - top) * 0.5 - 3)
	rect(left, top, right - left + 1, bottom - top + 1, SOLID)
	line(cx, top + 2, cx, bottom - 2, DOTTED, FORCE)
	line(left + 2, cy, right - 2, cy, DOTTED, FORCE)
	line(cx, cy - 5, cx - 4, cy + 4, SOLID, FORCE)
	line(cx, cy - 5, cx + 4, cy + 4, SOLID, FORCE)
	line(cx - 4, cy + 4, cx + 4, cy + 4, SOLID, FORCE)

	if data.gpsFix and data.gpsHome ~= false then
		local bearing = calcBearing(data.gpsHome, data.gpsLatLon)
		local reference = data.showDir and data.headingRef ~= -1 and data.headingRef or data.heading
		local angle = math.rad(bearing - reference)
		local x, y = cx + math.sin(angle) * radius, cy - math.cos(angle) * radius
		line(cx, cy, x, y, DOTTED, FORCE)
		icons.home(x - 3, y - 2)
	end

	local flag = data.telem and 0 or 3
	text(0, 10, "DIST", SMLSIZE)
	text(29, 18, math.floor((data.showMax and data.distanceMax or data.distanceLast) + 0.5) .. units[data.dist_unit], SMLSIZE + RIGHT + flag)
	text(0, 29, "ALT", SMLSIZE)
	text(29, 37, math.floor(data.altitude + 0.5) .. units[data.alt_unit], SMLSIZE + RIGHT + flag)
	text(LCD_W, 10, "SATS", SMLSIZE + RIGHT)
	text(LCD_W, 18, data.satellites % 100, SMLSIZE + RIGHT + flag)
	text(LCD_W, 29, "HDG", SMLSIZE + RIGHT)
	text(LCD_W, 37, math.floor(data.heading + 0.5), SMLSIZE + RIGHT + flag)
	text(left, bottom + 2, frmt("%.1fV", data.batt), SMLSIZE + flag)
	text(right, bottom + 2, math.min(data.rssiLast, data.crsf and 100 or 99) .. (data.crsf and "%" or "dB"), SMLSIZE + RIGHT + flag)
	text(cx - 12, top + 1, modes[data.modeId].t, SMLSIZE + INVERS)
end

return view
