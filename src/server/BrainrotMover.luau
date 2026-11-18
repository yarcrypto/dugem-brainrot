-- Dugem Brainrot: walks a brainrot model along the floor. One walk token per
-- model: starting a new walk cancels the old one, and destroying the model
-- ends every walk that touches it.

local RunService = game:GetService("RunService")

local BrainrotMover = {}

local function nextToken(model)
	local token = (model:GetAttribute("WalkToken") or 0) + 1
	model:SetAttribute("WalkToken", token)
	return token
end

function BrainrotMover.stop(model)
	nextToken(model)
end

-- Walks the model in a straight line to target at speed (studs/sec).
-- Returns true when it arrives, false when the walk was cancelled.
function BrainrotMover.walkTo(model, target, speed)
	local token = nextToken(model)
	local body = model.PrimaryPart
	if not body then
		return false
	end
	while model.Parent do
		if model:GetAttribute("WalkToken") ~= token then
			return false
		end
		local pos = body.Position
		local delta = target - pos
		local dist = delta.Magnitude
		if dist < 0.4 then
			return true
		end
		local step = math.min(dist, speed * 0.08)
		local dir = delta.Unit
		local newPos = pos + dir * step
		local yaw = math.atan2(-dir.X, -dir.Z)
		model:PivotTo(CFrame.new(newPos) * CFrame.Angles(0, yaw, 0))
		RunService.Heartbeat:Wait()
	end
	return false
end

function BrainrotMover.walkWaypoints(model, waypoints, speed)
	for _, point in ipairs(waypoints) do
		if not BrainrotMover.walkTo(model, point, speed) then
			return false
		end
	end
	return true
end

return BrainrotMover
