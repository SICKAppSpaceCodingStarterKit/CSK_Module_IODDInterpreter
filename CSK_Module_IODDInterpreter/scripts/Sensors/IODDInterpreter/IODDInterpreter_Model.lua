---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter
--*****************************************************************
-- Inside of this script, you will find the module definition
-- including its parameters and functions
--*****************************************************************

--**************************************************************************
--**********************Start Global Scope *********************************
--**************************************************************************
local nameOfModule = 'CSK_IODDInterpreter'

local iODDInterpreter_Model = {}

-- Check if CSK_UserManagement module can be used if wanted
iODDInterpreter_Model.userManagementModuleAvailable = CSK_UserManagement ~= nil or false

-- Check if CSK_PersistentData module can be used if wanted
iODDInterpreter_Model.persistentModuleAvailable = CSK_PersistentData ~= nil or false

-- Default values for persistent data
-- If available, following values will be updated from data of CSK_PersistentData module (check CSK_PersistentData module for this)
iODDInterpreter_Model.parametersName = 'CSK_IODDInterpreter_Parameter' -- name of parameter dataset to be used for this module
iODDInterpreter_Model.parameterLoadOnReboot = false -- Status if parameter dataset should be loaded on app/device reboot

-- Load script to communicate with the IODDInterpreter_Model interface and give access
-- to the IODDInterpreter_Model object.
-- Check / edit this script to see/edit functions which communicate with the UI
local setIODDInterpreter_ModelHandle = require('Sensors/IODDInterpreter/IODDInterpreter_Controller')
setIODDInterpreter_ModelHandle(iODDInterpreter_Model)

--Loading helper functions if needed
iODDInterpreter_Model.helperFuncs = require('Sensors/IODDInterpreter/helper/funcs')

-- Optionally check if specific API was loaded via
--[[
if _G.availableAPIs.specific then
-- ... doSomething ...
end
]]

--[[
-- Create parameters / instances for this module
iODDInterpreter_Model.object = Image.create() -- Use any AppEngine CROWN
iODDInterpreter_Model.counter = 1 -- Short docu of variable
iODDInterpreter_Model.varA = 'value' -- Short docu of variable
--...
]]

-- Parameters to be saved permanently if wanted
iODDInterpreter_Model.parameters = {}
--iODDInterpreter_Model.parameters.paramA = 'paramA' -- Short docu of variable
--iODDInterpreter_Model.parameters.paramB = 123 -- Short docu of variable
--...

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

--[[
-- Some internal code docu for local used function to do something
---@param content auto Some info text if function is not already served
local function doSomething(content)
  _G.logger:info(nameOfModule .. ": Do something")
  iODDInterpreter_Model.counter = iODDInterpreter_Model.counter + 1
end
iODDInterpreter_Model.doSomething = doSomething
]]

--*************************************************************************
--********************** End Function Scope *******************************
--*************************************************************************

return iODDInterpreter_Model
