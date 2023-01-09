local Pine3D = require("Pine3D")
local goggleAR = require("goggleAR")

-- create a new frame
local ThreeDFrame = Pine3D.newFrame()
ThreeDFrame:setFoV(120)
goggleAR.bind(ThreeDFrame)

-- define the objects to be rendered
local objects = {}

local signs = {}

local back = peripheral.wrap("back")

local function orientationScans()
	while true do
		local scans = back.sense()
		for i = 1, #scans do
			local scan = scans[i]
			if scan.x == 0 and scan.y == 0 and scan.z == 0 then
				goggleAR.setCameraOrientation(ThreeDFrame, scan.yaw, scan.pitch)
			end
		end
		os.queueEvent("sense")
		os.pullEvent("sense")
	end
end

local function scanning()
	while true do
		local scans = back.scan()
		local x, y, z = gps.locate()
		goggleAR.setCameraPosition(ThreeDFrame, x, y, z)

		for i = 1, #scans do
			local block = scans[i]
			if block.name == "minecraft:standing_sign" or block.name == "minecraft:wall_sign" then
				local meta = back.getBlockMeta(block.x, block.y, block.z)
				if meta.lines then
					local wx = math.floor(x + block.x)
					local wy = math.floor(y + block.y)
					local wz = math.floor(z + block.z)

					local alreadyIndexed = false
					for i = 1, #signs do
						local sign = signs[i]
						if sign.x == wx and sign.y == wy and sign.z == wz then
							alreadyIndexed = true
						end
					end

					if not alreadyIndexed then
						signs[#signs+1] = {
							x = wx,
							y = wy,
							z = wz,
							lines = meta.lines
						}
					end
				end
			end
		end
		sleep(1)
	end
end

local function updateGPS()
	while true do
		local x, y, z = gps.locate()
		goggleAR.setCameraPosition(ThreeDFrame, x, y, z)

		os.queueEvent("gps")
		os.pullEvent("gps")
	end
end

local function drawSignText()
	goggleAR.clearText(ThreeDFrame)
	for i = 1, #signs do
		local sign = signs[i]
		local x, y, z = sign.x, sign.y, sign.z

		local lines = sign.lines
		local sum = ""
		for j = 1, #lines do
			local line = lines[j]
			if line and #line > 0 then
				sum = sum .. line .. "\n"
			end
		end
		goggleAR.renderText(ThreeDFrame, x+0.5, y+0.5, z+0.5, sum)
	end
end

local function rendering()
	-- render the objects
	while true do
		drawSignText()
		ThreeDFrame:drawBuffer()

		sleep(0)
	end
end

parallel.waitForAny(rendering, orientationScans, updateGPS, scanning)
