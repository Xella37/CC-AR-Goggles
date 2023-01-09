local Pine3D = require("Pine3D")
local goggleAR = require("goggleAR")

-- create a new frame
local ThreeDFrame = Pine3D.newFrame()
ThreeDFrame:setFoV(120)
goggleAR.bind(ThreeDFrame)

-- define the objects to be rendered
local objects = {}
for x = -2, 2, 2 do
	for y = -2, 2, 2 do
		for z = -2, 2, 2 do
			objects[#objects+1] = ThreeDFrame:newObject("models/pineapple", x, y, z)
		end
	end
end

-- render the objects
while true do
	-- load all objects onto the buffer and draw the buffer
	goggleAR.worldCamera(ThreeDFrame)
	ThreeDFrame:drawObjects(objects)
	ThreeDFrame:drawBuffer()

	os.queueEvent("test")
	os.pullEvent("test")
end
