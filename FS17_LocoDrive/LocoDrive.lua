
LocoDrive = {};

local modItem = ModsUtil.findModItemByModName(g_currentModName);
LocoDrive.version = (modItem and modItem.version) and modItem.version or "?.?.?";


function LocoDrive:prerequisitesPresent(specializations)
    return true;
end;

function LocoDrive:load(xmlFile)
end;

function LocoDrive:delete()
end;

function LocoDrive:mouseEvent(posX, posY, isDown, isUp, button)
end;

function LocoDrive:keyEvent(unicode, sym, modifier, isDown)
end;

function LocoDrive:getIsLocoDriveActive()
    return self.ldActive
end

LocoDrive.ACTIVE_TOGGLE = 2
LocoDrive.ACTIVE_ON     = 1
LocoDrive.ACTIVE_OFF    = 0

function LocoDrive:setLocoDriveState(newState, force)
    if g_server == nil then
        -- Client-side only
        if LocoDrive.ACTIVE_TOGGLE == state then
            g_client:getServerConnection():sendEvent(LocoDriveInputEvent:new(self, LocoDrive.ACTIVE_TOGGLE));
        else
            self.ldActive = (LocoDrive.ACTIVE_ON == state)
        end
        return
    end

    -- Server-side only
    if LocoDrive.ACTIVE_TOGGLE == newState then
        if self.ldActive then
            newState = LocoDrive.ACTIVE_OFF
        else
            newState = LocoDrive.ACTIVE_ON
            self.ldSpeed = self.cruiseControl.speed;
        end
    end

    if LocoDrive.ACTIVE_ON == newState and (not self.ldActive or force) then
        self.ldActive = true

        if self.isMotorStarted == false then
            self:startMotor();
        end;

        self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_ACTIVE)
        self:setCruiseControlMaxSpeed(self.ldSpeed)

        g_server:broadcastEvent(LocoDriveInputEvent:new(self, LocoDrive.ACTIVE_ON));
    elseif LocoDrive.ACTIVE_OFF == newState and (self.ldActive or force) then
        self.ldActive = false

        self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)

        g_server:broadcastEvent(LocoDriveInputEvent:new(self, LocoDrive.ACTIVE_OFF));
    end
end

function LocoDrive:update(dt)
    if self == g_currentMission.controlledVehicle then
        if InputBinding.hasEvent(InputBinding.LDEnDisable) then
            LocoDrive.setLocoDriveState(self, LocoDrive.ACTIVE_TOGGLE)
        end;
    end;
end;

function LocoDrive:updateTick(dt)
    if not self.isServer then
        return
    end

    if nil == self.ldActive then
        self.getIsLocoDriveActive  = LocoDrive.getIsLocoDriveActive

        self.ldActive = true;
        self.ldSpeed = math.random(35, 40);
        self.ldWarmUpTimer = math.random(4, 15)*1000
--[[
        self.ldNextHonkTime = 0
        self.ldHonkStopTime = 0
--]]
    end

    if self.ldWarmUpTimer >= 0 then
        self.ldWarmUpTimer = self.ldWarmUpTimer - dt;
        if self.ldWarmUpTimer >= 0 then
            return
        end
        LocoDrive.setLocoDriveState(self, LocoDrive.ACTIVE_ON, true)
    end

    if self.ldActive == true then
        if self.numLightTypes ~= nil then
            local lightsRequired = (g_currentMission.environment.dayTime > 20*60*60*1000) or (g_currentMission.environment.dayTime < 6*60*60*1000)
            self:setLightsTypesMask(lightsRequired and 1 or 0);
        end

        self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_ACTIVE)

--[[
        if self.ldNextHonkTime < self.ldHonkStopTime then
            if self.ldHonkStopTime < g_currentMission.time then
                LocoDrive.playHonk(self, false);
                self.ldNextHonkTime = g_currentMission.time + (math.random(1,5) * 1000) -- * 60)
            end
        elseif self.ldNextHonkTime < g_currentMission.time then
            self.ldHonkStopTime = g_currentMission.time + (math.random(2, 6) * 500)
            LocoDrive.playHonk(self, true);
        end
--]]
    end
end;

function LocoDrive:draw()
end;

--[[
function LocoDrive.playHonk(self, isPlaying)
    if nil ~= g_dedicatedServerInfo then
        -- Dedicated-server
        HonkEvent.sendEvent(self, isPlaying);
    else
        -- Listen-server or single-player
        self:playHonk(isPlaying)
    end
end
--]]

--
--
--

LocoDrive.locomotive_update = function(self, superFunc, dt)
    if self.isServer then
        local newSpeed = nil

        if not self.isControlled and self.isMotorStarted and self.ldActive then
            -- Too keep movement going when LocoDrive is active
            self.motor:updateInput(dt, 1);
            newSpeed = self.speed
            self.speed = 0 -- hack to prohibit a second call to self.motor:updateInput()
        end

        superFunc(self, dt)

        if nil ~= newSpeed then
            self.speed = newSpeed
        end
    end
end

Locomotive.update = Utils.overwrittenFunction(Locomotive.update, LocoDrive.locomotive_update)

--
--
--

--[[
function Locomotive:getIsActive()
-->>
    if self.isClient and self.ldActive then
        return true;
    end
--<<
    if self.isEntered or self.isControlled then
        return true;
    end
    if self.attacherVehicle ~= nil and self.attacherVehicle.getIsActive ~= nil then
        return self.attacherVehicle:getIsActive();
    end
end

function Locomotive:getIsActiveForSound()
    if self.isClient then
-->>
        if self.ldActive then
            return true;
        end
--<<
        if self.isEntered then
            return true;
        end
        if self.attacherVehicle ~= nil then
            return self.attacherVehicle:getIsActiveForSound();
        end
    end
    return false;
end
--]]

--
--
--


LocoDriveInputEvent = {};
LocoDriveInputEvent_mt = Class(LocoDriveInputEvent, Event);

InitEventClass(LocoDriveInputEvent, "LocoDriveInputEvent");

function LocoDriveInputEvent:emptyNew()
    local self = Event:new(LocoDriveInputEvent_mt);
    self.className="LocoDriveInputEvent";
    return self;
end;

function LocoDriveInputEvent:new(vehicle, state)
    local self = LocoDriveInputEvent:emptyNew()
    self.vehicle = vehicle
    self.state   = state
    return self;
end;

function LocoDriveInputEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, networkGetObjectId(self.vehicle));
    streamWriteUInt8(streamId, self.state)
end;

function LocoDriveInputEvent:readStream(streamId, connection)
    local vehicle = networkGetObject(streamReadInt32(streamId));
    local state = streamReadUInt8(streamId)

    if nil ~= vehicle then
        LocoDrive.setLocoDriveState(vehicle, state)
    end
end;
