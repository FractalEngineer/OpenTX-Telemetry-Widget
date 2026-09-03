-- See the type-name note in status_test.lua.
local rawType = type
local typeNames = {table = "number", ["function"] = "string", userdata = "table", thread = "function"}
function type(value)
	return typeNames[rawType(value)] or rawType(value)
end

local parseDeviceInfo = assert(loadfile("src/SCRIPTS/TELEMETRY/iNav/elrs.lua"))()

local function deviceInfo(version)
	return {
		0xEA, 0xEE, 0x54, 0x58, 0,
		0x45, 0x4C, 0x52, 0x53,
		0, 0, 0, 0, 0, version
	}
end

assert(parseDeviceInfo(deviceInfo(3)) == 3)
assert(parseDeviceInfo(deviceInfo(0)) == 2)
assert(parseDeviceInfo({0xEA, 0xEC, 0}) == -1)
assert(parseDeviceInfo({0xEA, 0xEE, 0x54, 0x58}) == 0)
assert(parseDeviceInfo({}) == 0)

print("ELRS device-info tests passed")
