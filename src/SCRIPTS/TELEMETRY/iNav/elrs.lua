-- Adapted from ELRSv2.lua in ExpressLRS

local function fieldStrFF(data, offset)
  while data[offset] ~= nil and data[offset] ~= 0 do
    offset = offset + 1
  end
  return data[offset] == 0 and offset + 1 or nil
end

local function fieldGetValue(data, offset, size)
   if offset == nil or offset + size - 1 > #data then return nil end
   local result = 0
   for i=0, size-1 do
      result = bit32.lshift(result, 8) + data[offset + i]
   end
   return result
end

--  See https://github.com/ExpressLRS/ExpressLRS/wiki/CRSF-Protocol#device-info--device-ping-response-0x29
--  For annotation
local function parseDeviceInfoMessage(data)
   local majId = -1
   if type(data) ~= "table" or #data < 3 then return 0 end
   local deviceId = data[2]
   local offset = fieldStrFF(data, 3)
   if deviceId == 0xEE then -- TX device
      if offset == nil or offset + 3 > #data then return 0 end
      -- debug_devinfo(data)
      if fieldGetValue(data,offset,4) == 0x454C5253 then -- 'ELRS'
        if offset + 9 > #data then return 0 end
        majId = data[offset+9]
        if majId == 0 then
          majId = 2 -- v2 did not report version, v1 didn't support this protocol
        end
      end
   end
   return majId
end

-- Returns the ELRS major version, -1 for another CRSF device, or 0 for malformed data
return parseDeviceInfoMessage
