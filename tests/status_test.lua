local now = 1000
local queue = {}
local removeFirst = table.remove

-- The vendored Lua sources reserve OpenTX-only type tags without changing the
-- standalone interpreter's type-name table, so normalize its test output.
local rawType = type
local typeNames = {table = "number", ["function"] = "string", userdata = "table", thread = "function"}
function type(value)
	return typeNames[rawType(value)] or rawType(value)
end

function getTime() return now end
function crossfireTelemetryPop()
	local frame = removeFirst(queue, 1)
	if frame ~= nil then return frame[1], frame[2] end
end

local data = {messages = {}, messageStartTime = 100, messagePopupUntil = 0, elrs = 0}
table = nil -- FreedomTX on the Tango 2 does not expose the table library.
local dispatch = assert(loadfile("src/SCRIPTS/TELEMETRY/iNav/status.lua"))(data)

local function payload(text, severity)
	local result = {0xF1, severity}
	for i = 1, #text do result[#result + 1] = string.byte(text, i) end
	result[#result + 1] = 0
	return result
end

local function send(value, command)
	queue[#queue + 1] = {command or 0x80, value}
	dispatch()
end

send(payload("PreArm", 4))
assert(#data.messages == 1 and data.messages[1].text == "PreArm" and data.messages[1].severity == 4)
local malformed = {false, {0xF1, 4}, {0xF0, 4, 65}, {0xF1, -1, 65}, {0xF1, 4, 256}}
for i = 1, #malformed do
	local count = #data.messages
	send(malformed[i])
	assert(#data.messages == count)
end

send({0xF1, 4, 65, 66})
assert(data.messages[#data.messages].text == "AB")
send(payload(string.rep("X", 50), 6))
assert(#data.messages[#data.messages].text == 50)

send(payload("Repeat", 4))
local popupUntil = data.messagePopupUntil
now = now + 200
send(payload("Repeat", 4))
assert(data.messages[#data.messages].count == 2)
assert(data.messagePopupUntil == popupUntil)

send(payload("Repeat", 2))
assert(data.messages[#data.messages].severity == 2)
now = now + 301
send(payload("Repeat", 2))
assert(data.messages[#data.messages].count == 1)

local deviceInfo = {0xEA, 0xEE, 0x54, 0x58, 0, 0x45, 0x4C, 0x52, 0x53, 0, 0, 0, 0, 0, 3}
queue = {{0x16, {1, 2}}, {0x29, deviceInfo}, {0x80, payload("Ready", 6)}, {0x7F, payload("Legacy", 5)}}
dispatch()
assert(data.elrs == 3)
assert(data.messages[#data.messages - 1].text == "Ready")
assert(data.messages[#data.messages].text == "Legacy")

queue = {{0x29, {0}}}
dispatch()
assert(data.elrs == 3)

now = now + 301
send(payload("Debug", 7))
assert(data.messagePopupUntil == now)

for i = 1, 25 do
	now = now + 301
	send(payload("Message " .. i, 6))
end
assert(#data.messages == 20)
assert(data.messages[1].text == "Message 6")

queue = {}
for i = 1, 10 do queue[i] = {0x80, payload("Queued " .. i, 6)} end
dispatch()
assert(#queue == 2)
dispatch()
assert(#queue == 0)

print("status tests passed")
