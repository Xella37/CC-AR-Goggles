
local floor = math.floor
local colorToCode = {}
for i = 1, 16 do
	local color = 2 ^ (i - 1)
	local r, g, b = term.getPaletteColor(color)
	colorToCode[color] = (floor(r*255+0.5) * 0x1000000) + (floor(g*255+0.5) * 0x10000) + (floor(b*255+0.5) * 0x100) + 255
end

local function bind(frame)
	local back = peripheral.wrap("back")
	local canvas = back.canvas()
	canvas.clear()

	local width, height = canvas.getSize()

	local triangleGroup = canvas.addGroup({0, 0})
	local triangles = {}
	local textGroup = canvas.addGroup({0, 0})
	local texts = {}
	local nextTriangleIndex = 1

	local fakeBuffer = {
		width = width,
		height = height,
		canvas = canvas,
		back = back,
	}
	function fakeBuffer:drawTriangle(x1, y1, x2, y2, x3, y3, c, char, charc, outlineColor)
		if x1 < 0 and x2 < 0 and x3 < 0 or y1 < 0 and y2 < 0 and y3 < 0 then return end
		local frameWidth = self.width
		if x1 > frameWidth and x2 > frameWidth and x3 > frameWidth then return end
		local frameHeight = self.height
		if y1 > frameHeight and y2 > frameHeight and y3 > frameHeight then return end

		local tri = triangles[nextTriangleIndex]
		if tri then
			tri.setPoint(1, x1, y1)
			tri.setPoint(2, x2, y2)
			tri.setPoint(3, x3, y3)
			local r, g, b = term.getPaletteColor(c)
			tri.setColor(floor(r*255), floor(g*255), floor(b*255), 255)
		else
			triangles[nextTriangleIndex] = triangleGroup.addTriangle({x1, y1}, {x2, y2}, {x3, y3}, colorToCode[c])
		end
		nextTriangleIndex = nextTriangleIndex + 1
	end
	function fakeBuffer:drawText(x, y, str, scale)
		local text = textGroup.addText({x, y}, str)
		text.setScale(scale)
		texts[#texts+1] = text
	end
	function fakeBuffer:drawBuffer()
		for i = nextTriangleIndex, #triangles do
			triangles[i].setAlpha(0)
		end
		nextTriangleIndex = 1
	end
	function fakeBuffer:clearText()
		for i = 1, #texts do
			texts[i].remove()
			texts[i] = nil
		end
	end
	function fakeBuffer:fastClear()
	end
	frame:setSize(1, 1, width/2, height/3)

	frame.buffer = fakeBuffer
end

local function renderText(ThreeDFrame, x, y, z, str)
	local screenX, screenY, vis = ThreeDFrame:map3dTo2d(z, y, -x)
	if vis then
		local dx = x + ThreeDFrame.camera[3]
		local dy = y - ThreeDFrame.camera[2]
		local dz = z - ThreeDFrame.camera[1]

		local distance = (dx*dx + dy*dy + dz*dz)^0.5
		local scale = 10 / distance
		scale = math.max(scale, 0.5)
		ThreeDFrame.buffer:drawText(screenX, screenY, str, scale)
	end
end

local function clearText(ThreeDFrame)
	ThreeDFrame.buffer:clearText()
end

local function getPlayerOrientation(buffer)
	local scans = buffer.back.sense()
	for i = 1, #scans do
		local scan = scans[i]
		if scan.x == 0 and scan.y == 0 and scan.z == 0 then
			return scan.yaw, scan.pitch
		end
	end
end

local function getPlayerPosition(buffer)
	local x, y, z = gps.locate()

	if not x then
		print("Failed to locate GPS!")
		return
	end

	if not buffer.oX then
		buffer.oX, buffer.oY, buffer.oZ = x, y, z
	end
	local oX, oY, oZ = buffer.oX, buffer.oY, buffer.oZ

	local dx = x - oX
	local dy = y - oY
	local dz = z - oZ

	return dz, dy, -dx
end

local function worldCamera(frame, x, y, z)
	local buffer = frame.buffer
	local dx, dy, dz = x, y, z

	local yaw, pitch = getPlayerOrientation(buffer)
	if not dx or not dy or not dz then
		local x, y, z = getPlayerPosition(buffer)
		if not dx then dx = x end
		if not dy then dy = y end
		if not dz then dz = z end
	end

	frame:setCamera(dx, dy, dz, nil, yaw, -pitch)
end

local function setCameraOrientation(frame, yaw, pitch)
	frame:setCamera(nil, nil, nil, nil, yaw, -pitch)
end

local function setCameraPosition(ThreeDFrame, x, y, z)
	ThreeDFrame:setCamera(z, y, x and -x or nil)
end

return {
	bind = bind,
	worldCamera = worldCamera,
	setCameraOrientation = setCameraOrientation,
	setCameraPosition = setCameraPosition,
	renderText = renderText,
	clearText = clearText,
}
