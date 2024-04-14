
myObj = Space.Host.ExecutingObject

waypointParent = Space.Host.GetReference("Waypoints")
waypoints = {}

follower = Space.Host.GetReference("Follower")

turnSpeed = turnSpeed or 1
moveSpeed = moveSpeed or 1
turnDistance = turnDistance or 0.5

currentWaypoint = 1
currentDistance = 0
vectorToWaypoint = Vector.One
updateToRotation = Quaternion.Identity
startNextWaypoint = 0

interrupted = false
interruptWaypoint = Space.Host.GetReference("Interrupt")

startPoint = Space.Host.GetReference("Start")


function onUpdate()
    -- Every frame...
    if follower ~= nil and follower.Active then
        -- Find out how close we are to our current waypoint target
        if interrupted then
            currentDistance = interruptWaypoint.WorldPosition.Distance(follower.WorldPosition)
        else
            currentDistance = waypoints[currentWaypoint].WorldPosition.Distance(follower.WorldPosition)
        end
        if currentDistance <= turnDistance then
            -- We're close enough to begin turning towards the next waypoint
            if interrupted then
                interrupted = false
            else
                startNextWaypoint = currentWaypoint
                while startNextWaypoint == currentWaypoint or not waypoints[currentWaypoint].Active do
                    currentWaypoint = currentWaypoint + 1
                    if currentWaypoint > #waypoints then
                        -- Make sure we loop back around if we run out of waypoints.
                        currentWaypoint = 1
                    end
                    if currentWaypoint == startNextWaypoint then
                        -- All waypoints are inactive for some reason.
                        break
                    end
                end
            end
        end
        -- Get a vector from us to the current waypoint target
        if interrupted then
            vectorToWaypoint = interruptWaypoint.WorldPosition - follower.WorldPosition
        else
            vectorToWaypoint = waypoints[currentWaypoint].WorldPosition - follower.WorldPosition
        end
        -- Calculate the direction we'd like to be facing (toward our target)
        updateToRotation = Quaternion.LookRotation(vectorToWaypoint)
        -- Lerp our rotation between our current rotation and the rotation we need to be on.
        follower.WorldRotation = follower.WorldRotation.Lerp(updateToRotation, turnSpeed * Space.DeltaTime)
        -- Move us forward
        follower.WorldPosition = follower.WorldPosition + (follower.Forward * (moveSpeed * Space.DeltaTime))
        -- Wash, rinse, repeat.
    end
end

function resetToStart()
    if follower ~= nil and startPoint ~= nil and startPoint.Active then
        follower.WorldPosition = startPoint.WorldPosition
        follower.WorldRotation = startPoint.WorldRotation
    end
end

function resetWaypoints()
    currentWaypoint = 1
end

function onInterruptClicked()
    if not interrupted then
        interrupted = true
    end
end

function init()
    local children = waypointParent.children
    local editables = {myObj}
    for w=1,#children,1 do
        table.insert(waypoints, children[w])
        table.insert(editables, waypoints[w])
        if waypoints[w].Data ~= nil then
            waypoints[w].Data.GetVariable("Label").UIText.Text = tostring(w)
        end
    end
    if interruptWaypoint ~= nil then
        table.insert(editables, interruptWaypoint)
        if interruptWaypoint.Data ~= nil then
            interruptWaypoint.Data.GetVariable("Label").UIText.Text = "!"
        end
    end
    if startPoint ~= nil then
        table.insert(editables, startPoint)
        if startPoint.Data ~= nil then
            startPoint.Data.GetVariable("Label").UIText.Text = "S"
        end
    end
    if initLiveRoomEditing ~= nil then
        initLiveRoomEditing(editables)
    end

    resetToStart()

    -- Bind to OnUpdate so we run every frame.
    myObj.OnUpdate(onUpdate)
end

init()
