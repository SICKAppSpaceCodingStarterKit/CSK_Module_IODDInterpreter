---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter

--***************************************************************
-- Inside of this script, you will find the necessary functions,
-- variables and events to communicate with the IODDInterpreter_Model
--***************************************************************

--**************************************************************************
--************************ Start Global Scope ******************************
--**************************************************************************
local nameOfModule = 'CSK_IODDInterpreter'

-- Timer to update UI via events after page was loaded
local tmrIODDInterpreter = Timer.create()
tmrIODDInterpreter:setExpirationTime(300)
tmrIODDInterpreter:setPeriodic(false)

-- Reference to global handle
local iODDInterpreter_Model

-- ************************ UI Events Start ********************************

-- Script.serveEvent("CSK_IODDInterpreter.OnNewEvent", "IODDInterpreter_OnNewEvent")
Script.serveEvent("CSK_IODDInterpreter.OnNewStatusLoadParameterOnReboot", "IODDInterpreter_OnNewStatusLoadParameterOnReboot")
Script.serveEvent("CSK_IODDInterpreter.OnPersistentDataModuleAvailable", "IODDInterpreter_OnPersistentDataModuleAvailable")
Script.serveEvent("CSK_IODDInterpreter.OnNewParameterName", "IODDInterpreter_OnNewParameterName")
Script.serveEvent("CSK_IODDInterpreter.OnDataLoadedOnReboot", "IODDInterpreter_OnDataLoadedOnReboot")

Script.serveEvent('CSK_IODDInterpreter.OnUserLevelOperatorActive', 'IODDInterpreter_OnUserLevelOperatorActive')
Script.serveEvent('CSK_IODDInterpreter.OnUserLevelMaintenanceActive', 'IODDInterpreter_OnUserLevelMaintenanceActive')
Script.serveEvent('CSK_IODDInterpreter.OnUserLevelServiceActive', 'IODDInterpreter_OnUserLevelServiceActive')
Script.serveEvent('CSK_IODDInterpreter.OnUserLevelAdminActive', 'IODDInterpreter_OnUserLevelAdminActive')

-- ...

-- ************************ UI Events End **********************************

--[[
--- Some internal code docu for local used function
local function functionName()
  -- Do something

end
]]

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

-- Functions to forward logged in user roles via CSK_UserManagement module (if available)
-- ***********************************************
--- Function to react on status change of Operator user level
---@param status boolean Status if Operator level is active
local function handleOnUserLevelOperatorActive(status)
  Script.notifyEvent("IODDInterpreter_OnUserLevelOperatorActive", status)
end

--- Function to react on status change of Maintenance user level
---@param status boolean Status if Maintenance level is active
local function handleOnUserLevelMaintenanceActive(status)
  Script.notifyEvent("IODDInterpreter_OnUserLevelMaintenanceActive", status)
end

--- Function to react on status change of Service user level
---@param status boolean Status if Service level is active
local function handleOnUserLevelServiceActive(status)
  Script.notifyEvent("IODDInterpreter_OnUserLevelServiceActive", status)
end

--- Function to react on status change of Admin user level
---@param status boolean Status if Admin level is active
local function handleOnUserLevelAdminActive(status)
  Script.notifyEvent("IODDInterpreter_OnUserLevelAdminActive", status)
end

--- Function to get access to the iODDInterpreter_Model object
---@param handle handle Handle of iODDInterpreter_Model object
local function setIODDInterpreter_Model_Handle(handle)
  iODDInterpreter_Model = handle
  if iODDInterpreter_Model.userManagementModuleAvailable then
    -- Register on events of CSK_UserManagement module if available
    Script.register('CSK_UserManagement.OnUserLevelOperatorActive', handleOnUserLevelOperatorActive)
    Script.register('CSK_UserManagement.OnUserLevelMaintenanceActive', handleOnUserLevelMaintenanceActive)
    Script.register('CSK_UserManagement.OnUserLevelServiceActive', handleOnUserLevelServiceActive)
    Script.register('CSK_UserManagement.OnUserLevelAdminActive', handleOnUserLevelAdminActive)
  end
  Script.releaseObject(handle)
end

--- Function to update user levels
local function updateUserLevel()
  if iODDInterpreter_Model.userManagementModuleAvailable then
    -- Trigger CSK_UserManagement module to provide events regarding user role
    CSK_UserManagement.pageCalled()
  else
    -- If CSK_UserManagement is not active, show everything
    Script.notifyEvent("IODDInterpreter_OnUserLevelAdminActive", true)
    Script.notifyEvent("IODDInterpreter_OnUserLevelMaintenanceActive", true)
    Script.notifyEvent("IODDInterpreter_OnUserLevelServiceActive", true)
    Script.notifyEvent("IODDInterpreter_OnUserLevelOperatorActive", true)
  end
end

--- Function to send all relevant values to UI on resume
local function handleOnExpiredTmrIODDInterpreter()

  updateUserLevel()

  -- Script.notifyEvent("IODDInterpreter_OnNewEvent", false)

  Script.notifyEvent("IODDInterpreter_OnNewStatusLoadParameterOnReboot", iODDInterpreter_Model.parameterLoadOnReboot)
  Script.notifyEvent("IODDInterpreter_OnPersistentDataModuleAvailable", iODDInterpreter_Model.persistentModuleAvailable)
  Script.notifyEvent("IODDInterpreter_OnNewParameterName", iODDInterpreter_Model.parametersName)
  -- ...
end
Timer.register(tmrIODDInterpreter, "OnExpired", handleOnExpiredTmrIODDInterpreter)

-- ********************* UI Setting / Submit Functions Start ********************

local function pageCalled()
  updateUserLevel() -- try to hide user specific content asap
  tmrIODDInterpreter:start()
  return ''
end
Script.serveFunction("CSK_IODDInterpreter.pageCalled", pageCalled)

--[[
local function setSomething(value)
  _G.logger:info(nameOfModule .. ": Set new value = " .. value)
  iODDInterpreter_Model.varA = value
end
Script.serveFunction("CSK_IODDInterpreter.setSomething", setSomething)
]]

-- *****************************************************************
-- Following function can be adapted for CSK_PersistentData module usage
-- *****************************************************************

local function setParameterName(name)
  _G.logger:info(nameOfModule .. ": Set parameter name: " .. tostring(name))
  iODDInterpreter_Model.parametersName = name
end
Script.serveFunction("CSK_IODDInterpreter.setParameterName", setParameterName)

local function sendParameters()
  if iODDInterpreter_Model.persistentModuleAvailable then
    CSK_PersistentData.addParameter(iODDInterpreter_Model.helperFuncs.convertTable2Container(iODDInterpreter_Model.parameters), iODDInterpreter_Model.parametersName)
    CSK_PersistentData.setModuleParameterName(nameOfModule, iODDInterpreter_Model.parametersName, iODDInterpreter_Model.parameterLoadOnReboot)
    _G.logger:info(nameOfModule .. ": Send IODDInterpreter parameters with name '" .. iODDInterpreter_Model.parametersName .. "' to CSK_PersistentData module.")
    CSK_PersistentData.saveData()
  else
    _G.logger:warning(nameOfModule .. ": CSK_PersistentData module not available.")
  end
end
Script.serveFunction("CSK_IODDInterpreter.sendParameters", sendParameters)

local function loadParameters()
  if iODDInterpreter_Model.persistentModuleAvailable then
    local data = CSK_PersistentData.getParameter(iODDInterpreter_Model.parametersName)
    if data then
      _G.logger:info(nameOfModule .. ": Loaded parameters from CSK_PersistentData module.")
      iODDInterpreter_Model.parameters = iODDInterpreter_Model.helperFuncs.convertContainer2Table(data)
      -- If something needs to be configured/activated with new loaded data, place this here:
      -- ...
      -- ...

      CSK_IODDInterpreter.pageCalled()
    else
      _G.logger:warning(nameOfModule .. ": Loading parameters from CSK_PersistentData module did not work.")
    end
  else
    _G.logger:warning(nameOfModule .. ": CSK_PersistentData module not available.")
  end
end
Script.serveFunction("CSK_IODDInterpreter.loadParameters", loadParameters)

local function setLoadOnReboot(status)
  iODDInterpreter_Model.parameterLoadOnReboot = status
  _G.logger:info(nameOfModule .. ": Set new status to load setting on reboot: " .. tostring(status))
end
Script.serveFunction("CSK_IODDInterpreter.setLoadOnReboot", setLoadOnReboot)

--- Function to react on initial load of persistent parameters
local function handleOnInitialDataLoaded()

  if string.sub(CSK_PersistentData.getVersion(), 1, 1) == '1' then

    _G.logger:warning(nameOfModule .. ': CSK_PersistentData module is too old and will not work. Please update CSK_PersistentData module.')

    iODDInterpreter_Model.persistentModuleAvailable = false
  else

    local parameterName, loadOnReboot = CSK_PersistentData.getModuleParameterName(nameOfModule)

    if parameterName then
      iODDInterpreter_Model.parametersName = parameterName
      iODDInterpreter_Model.parameterLoadOnReboot = loadOnReboot
    end

    if iODDInterpreter_Model.parameterLoadOnReboot then
      loadParameters()
    end
    Script.notifyEvent('IODDInterpreter_OnDataLoadedOnReboot')
  end
end
Script.register("CSK_PersistentData.OnInitialDataLoaded", handleOnInitialDataLoaded)

-- *************************************************
-- END of functions for CSK_PersistentData module usage
-- *************************************************

return setIODDInterpreter_Model_Handle

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************

