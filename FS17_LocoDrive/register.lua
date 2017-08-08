
SpecializationUtil.registerSpecialization("LocoDrive", "LocoDrive", g_currentModDirectory.."LocoDrive.lua")

LocoDrive_Register = {};
addModEventListener(LocoDrive_Register);

function LocoDrive_Register:loadMap(name)
end;

function LocoDrive_Register:deleteMap()
end;

function LocoDrive_Register:keyEvent(unicode, sym, modifier, isDown)
end;

function LocoDrive_Register:mouseEvent(posX, posY, isDown, isUp, button)
end;

function LocoDrive_Register:update(dt)
    if not self.initialized then
        self.initialized = true
        local cnt = 0
        for k, v in pairs(g_currentMission.nodeToVehicle) do
            if v ~= nil then
                local loco = v.motorType;
                if loco ~= nil and loco == "locomotive" then
                    table.insert(v.specializations, SpecializationUtil.getSpecialization("LocoDrive"));
                    cnt = cnt + 1
                end;
            end;
        end;
        print("--- LocoDrive specialization added to "..cnt.." locomotive(s)")
    end;
end;

function LocoDrive_Register:draw()
end;
