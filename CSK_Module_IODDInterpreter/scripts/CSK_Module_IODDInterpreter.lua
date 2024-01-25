--MIT License
--
--Copyright (c) 2023 SICK AG
--
--Permission is hereby granted, free of charge, to any person obtaining a copy
--of this software and associated documentation files (the "Software"), to deal
--in the Software without restriction, including without limitation the rights
--to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--copies of the Software, and to permit persons to whom the Software is
--furnished to do so, subject to the following conditions:
--
--The above copyright notice and this permission notice shall be included in all
--copies or substantial portions of the Software.
--
--THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--SOFTWARE.

---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter
--**************************************************************************
--**********************Start Global Scope *********************************
--**************************************************************************

-- If app property "LuaLoadAllEngineAPI" is FALSE, use this to load and check for required APIs
-- This can improve performance of garbage collection

--_G.availableAPIs = require('Sensors/IODDInterpreter/helper/checkAPIs') -- can be used to adjust function scope of the module related on available APIs of the device
-----------------------------------------------------------
-- Logger
_G.logger = Log.SharedLogger.create('ModuleLogger')
_G.logHandle = Log.Handler.create()
_G.logHandle:attachToSharedLogger('ModuleLogger')
_G.logHandle:setConsoleSinkEnabled(false) --> Set to TRUE if CSK_Logger module is not used
_G.logHandle:setLevel("ALL")
_G.logHandle:applyConfig()
-----------------------------------------------------------

-- Loading script regarding IODDInterpreter_Model
-- Check this script regarding IODDInterpreter_Model parameters and functions
_G.ioddInterpreter_Model = require('Sensors/IODDInterpreter/IODDInterpreter_Model')

--**************************************************************************
--**********************End Global Scope ***********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

local function main()

  ----------------------------------------------------------------------------------------
  -- INFO: Please check if module will eventually load inital configuration triggered via
  --       event CSK_PersistentData.OnInitialDataLoaded
  --       (see internal variable _G.ioddInterpreter_Model.parameterLoadOnReboot)
  --       If so, the app will trigger the "OnDataLoadedOnReboot" event if ready after loading parameters
  --
  -- Can be used e.g. like this
  --[[
  CSK_IODDInterpreter.addInstance()
  CSK_IODDInterpreter.addIODDFile('IODD.xml')
  CSK_IODDInterpreter.findIODDMatchingProductName('Productname')
  CSK_IODDInterpreter.findIODDMatchingVendorIdDeviceIdVersion('VendorID', 'DeviceID', 'Version')

  -- Optional process data structure
  local processDataStructure = CSK_IODDInterpreter.getProcessDataConditionList()

  local processDataIn = CSK_IODDInterpreter.getProcessDataInInfo()
  local processDataOut = CSK_IODDInterpreter.getProcessDataOutInfo()
  local parameterData = CSK_IODDInterpreter.getParameterDataPointInfo('instanceID', 120, 0)
  local processDataCondition = CSK_IODDInterpreter.getProcessDataConditionInfo()
  ]]
  ----------------------------------------------------------------------------------------

  CSK_IODDInterpreter.pageCalledInstances() -- Update UI

end
Script.register("Engine.OnStarted", main)

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************
