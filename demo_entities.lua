local Pine3D = require("Pine3D")
local goggleAR = require("goggleAR")

-- create a new frame
local ThreeDFrame = Pine3D.newFrame()
ThreeDFrame:setFoV(120)
goggleAR.bind(ThreeDFrame)

-- define the objects to be rendered
local objects = {}

local back = peripheral.wrap("back")

local function scanning()
	while true do
		local scans = back.sense()
		local newObjects = {}
		for i = 1, #scans do
			local scan = scans[i]
			if scan.x == 0 and scan.y == 0 and scan.z == 0 then
				goggleAR.setCameraOrientation(ThreeDFrame, scan.yaw, scan.pitch)
			else
				local distance = (scan.x*scan.x + scan.y*scan.y + scan.z*scan.z)^0.5
				if distance <= 16 then
					newObjects[#newObjects+1] = ThreeDFrame:newObject("models/box", scan.z, scan.y, -scan.x)
				end
			end
		end
		objects = newObjects

		os.queueEvent("test")
		os.pullEvent("test")
	end
end

local function rendering()
	-- render the objects
	while true do
		-- load all objects onto the buffer and draw the buffer
		ThreeDFrame:drawObjects(objects)
		ThreeDFrame:drawBuffer()
		sleep(0)
	end
end

parallel.waitForAny(rendering, scanning)
