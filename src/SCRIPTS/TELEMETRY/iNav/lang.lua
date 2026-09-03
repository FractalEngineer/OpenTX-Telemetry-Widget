local modes, labels, data, FILE_PATH, env = ...
local lang

if data.lang ~= "en" then
	local tmp = FILE_PATH .. "lang_" .. data.lang
	local script = loadScript(tmp, env)
	if script ~= nil then
		lang = script(modes, labels)
		collectgarbage()
	end
end

if data.voice ~= "en" then
	local fh = io.open(FILE_PATH .. data.voice .. "/on.wav")
	if fh ~= nil then
		io.close(fh)
	else
		data.voice = "en"
	end
end

return lang
