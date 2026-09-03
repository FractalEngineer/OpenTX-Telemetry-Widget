local data = ...

local function dispatch()
	for frame = 1, 8 do
		local command, payload = crossfireTelemetryPop()
		if command == nil then return end

		if command == 0x29 and data.elrs == 0 and type(payload) == "table" and #payload >= 3 then
			local version = -1
			if payload[2] == 0xEE then
				local offset = 3
				while payload[offset] ~= nil and payload[offset] ~= 0 do offset = offset + 1 end
				offset = payload[offset] == 0 and offset + 1 or nil
				if offset == nil or offset + 9 > #payload then
					version = 0
				elseif payload[offset] * 0x1000000 + payload[offset + 1] * 0x10000 + payload[offset + 2] * 0x100 + payload[offset + 3] == 0x454C5253 then
					version = payload[offset + 9]
					if version == 0 then version = 2 end
				end
			end
			if version ~= 0 then data.elrs = version end
		elseif (command == 0x80 or command == 0x7F) and type(payload) == "table" and #payload >= 3 and payload[1] == 0xF1 then
			local severity = payload[2]
			if type(severity) == "number" and severity >= 0 and severity <= 255 and severity % 1 == 0 then
				local last = math.min(#payload, 52)
				local valid = true
				for index = 3, last do
					local byte = payload[index]
					if byte == 0 then
						last = index - 1
						break
					elseif type(byte) ~= "number" or byte < 0 or byte > 255 or byte % 1 ~= 0 then
						valid = false
						break
					end
				end

				if valid and last >= 3 then
					local message = ""
					for index = 3, last do message = message .. string.char(payload[index]) end
					local now = getTime()
					local latest = data.messages[#data.messages]
					if latest ~= nil and latest.text == message and latest.severity == severity and now >= latest.lastTime and now - latest.lastTime <= 300 then
						latest.lastTime = now
						latest.count = latest.count + 1
					else
						if #data.messages >= 20 then
							for index = 2, #data.messages do data.messages[index - 1] = data.messages[index] end
							data.messages[#data.messages] = nil
						end
						data.messages[#data.messages + 1] = {text = message, severity = severity, firstTime = now - data.messageStartTime, lastTime = now, count = 1}
						data.lastMessageText = message
						data.lastMessageSeverity = severity
						local duration = severity <= 3 and 1000 or severity == 4 and 700 or severity == 5 and 500 or severity == 7 and 0 or 350
						data.messagePopupUntil = now + duration
					end
				end
			end
		end
	end
end

return dispatch
