---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter
--*****************************************************************
-- Inside of this script, you will find the module definition
-- including its parameters and functions
--*****************************************************************
--**************************************************************************
--**********************Start Global Scope *********************************
--**************************************************************************
local nameOfModule = 'CSK_IODDInterpreter'

local ioddInterpreter_Model = {}

-- Check if CSK_UserManagement module can be used if wanted
ioddInterpreter_Model.userManagementModuleAvailable = CSK_UserManagement ~= nil or false

-- Check if CSK_PersistentData module can be used if wanted
ioddInterpreter_Model.persistentModuleAvailable = CSK_PersistentData ~= nil or false

-- Default values for Persistent data
-- If available, following values will be updated from data of CSK_PersistentData module (check CSK_PersistentData module for this)
ioddInterpreter_Model.parametersName = 'CSK_IODDInterpreter_Parameter' -- name of parameter dataset to be used for this module
ioddInterpreter_Model.parameterLoadOnReboot = false -- Status if parameter dataset should be loaded on app/device reboot

-- Load script to communicate with the IODDInterpreter_Model interface and give access
-- to the IODDInterpreter_Model object.
-- Check / edit this script to see/edit functions which communicate with the UI
local setIODDInterpreter_ModelHandle = require('Sensors/IODDInterpreter/IODDInterpreter_Controller')
setIODDInterpreter_ModelHandle(ioddInterpreter_Model)

--Loading helper functions if needed
ioddInterpreter_Model.helperFuncs = require('Sensors/IODDInterpreter/helper/funcs')
ioddInterpreter_Model.ioddInt = require "Sensors.IODDInterpreter.helper.IODDInterpreter"
ioddInterpreter_Model.dynamicTableHelper = require "Sensors.IODDInterpreter.helper.IODDDynamicTable"
ioddInterpreter_Model.json = require "Sensors.IODDInterpreter.helper.Json"
ioddInterpreter_Model.tableCompiler = require "Sensors.IODDInterpreter.helper.tableCompiler"

ioddInterpreter_Model.styleForUI = 'None' -- Optional parameter to set UI style
ioddInterpreter_Model.version = Engine.getCurrentAppVersion() -- Version of module

-- Create parameters / instances for this module
ioddInterpreter_Model.ioddFilesStorage = 'public/IODDFiles' -- Default folder to store iodd .xml files and their .json interpretations 
File.mkdir(ioddInterpreter_Model.ioddFilesStorage) -- creating the storage folder

-- Parameters to be saved permanently if wanted
ioddInterpreter_Model.parameters = {}
ioddInterpreter_Model.parameters.instances = {}
ioddInterpreter_Model.parameters.activeIODDs = {} -- list of active iodds to keep lua tables in cash
ioddInterpreter_Model.parameters.availableIODDs = {} -- list of all loaded IODD files that were checked and ready for interpretation

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

--- Function to react on UI style change
local function handleOnStyleChanged(theme)
  ioddInterpreter_Model.styleForUI = theme
  Script.notifyEvent("IODDInterpreter_OnNewStatusCSKStyle", ioddInterpreter_Model.styleForUI)
end
Script.register('CSK_PersistentData.OnNewStatusCSKStyle', handleOnStyleChanged)

--- Function to derive the latest version between two (For future use)
---@param vers table Array of versions of IODD file 1 and file2
---@return string? higherVersion Higher version of the two
local function getHigherVersion(vers)
  local endings = {0,0}
  local inits = {0,0}
  while endings[1] do
    inits[1],endings[1] = string.find(vers[1], "%d+", endings[1]+1)
    inits[2],endings[2] = string.find(vers[2], "%d+", endings[2]+1)
    if not inits[1] then
      break
    end
    if tonumber(string.sub(vers[1], inits[1], endings[1])) > tonumber(string.sub(vers[2], inits[2], endings[2])) then
      return vers[1]
    elseif tonumber(string.sub(vers[1], inits[1], endings[1])) < tonumber(string.sub(vers[2], inits[2], endings[2])) then
      return vers[2]
    end
  end
  return nil
end

--- Function to check if the currently used IODD file mathches needed venor ID, device ID and version. Used to check if this instance can still be used for connected IO-Link device.
--- NOTE! Only vendor and device ID check currently work as it is not clear what to do if version is lower
---@param vendorId string Vendor ID from device identification
---@param deviceId string Device ID from device identification
---@param version string Version from device identification
---@return bool success True if the vendor ID, device ID match the used IODD file
---@return string IODDname Name of the loaded IODD for external reference
local function checkVendorIdDeviceIdVersionMatchIODD(vendorId, deviceId, version)
  for loadedIODDName, loadedIODDInfo in pairs(ioddInterpreter_Model.parameters.availableIODDs) do
    if loadedIODDInfo.vendorId == vendorId and loadedIODDInfo.deviceId == deviceId then
      return true, loadedIODDName
      -- For future usage / TODO:
      -- Decide what to do in case a newer IODD version is loaded
      --if not version then
      --  return true, loadedIODDName
      --end
      --if tempVersion == version then
      --  return true, loadedIODDName
      --elseif getHigherVersion({tempVersion, version}) == tempVersion then
      --  return true, loadedIODDName
      --else
      --  return true, loadedIODDName
      --end
    end
  end
  return false, "NO MATCH"
end
ioddInterpreter_Model.checkVendorIdDeviceIdVersionMatchIODD = checkVendorIdDeviceIdVersionMatchIODD

--- Function to deactivate not used IODDs
local function deactivateNotUsedActiveIodds()
  for ioddName, _ in pairs(ioddInterpreter_Model.parameters.activeIODDs) do
    for _, instanceConfig in pairs(ioddInterpreter_Model.parameters.instances) do
      if instanceConfig.ioddName == ioddName then
        goto nextActiveIodd
      end
    end
    ioddInterpreter_Model.parameters.activeIODDs[ioddName] = nil
    ::nextActiveIodd::
  end
end
ioddInterpreter_Model.deactivateNotUsedActiveIodds = deactivateNotUsedActiveIodds

--- Function to check if loaded .xml IODD file can be interpreted. If yes, then file with standartized name and its .json interpetation are storred in IODD storage folder. The original file is deleted.
---@param ioddFilePath string Path to a loaded .xml IODD file
---@return bool loadSuccess Success of interpretation 
---@return string ioddStandardFileName Standartised name of the IODD file generated according to IODD standard
local function addNewIODDfile(ioddFilePath)
  local tempIODD = ioddInterpreter_Model.ioddInt:new()
  local callSuccess, loadSuccess = pcall(ioddInterpreter_Model.ioddInt.interpretXMLFile, tempIODD, ioddFilePath)
  if not (callSuccess and loadSuccess) then
    File.del(ioddFilePath)
    tempIODD = nil
    _G.logger:warning(_APPNAME..': failed to interpret iodd file: ' .. tostring(ioddFilePath) .. '; error caught: ' .. tostring(loadSuccess))
    return false, 'IODD interpretation failed'
  end
  local tempVendorId, tempDeviceId, tempVersion = tempIODD:getVendorIdDeviceIdVersion()
  if checkVendorIdDeviceIdVersionMatchIODD(tempVendorId, tempDeviceId) == true then
    File.del(ioddFilePath)
    tempIODD = nil
    return false, 'IODD is already loaded'
  end
  local ioddStandardFileName = tempIODD:getStandardFileName()
  _G.logger:info(_APPNAME..': new iodd file name to save : ' .. tostring(ioddStandardFileName))
  ioddInterpreter_Model.parameters.availableIODDs[ioddStandardFileName] = {
    vendorId = tempVendorId,
    deviceId = tempDeviceId,
    version = tempVersion
  }
  local newioddFilePath = ioddInterpreter_Model.ioddFilesStorage .. '/' .. ioddStandardFileName
  tempIODD:saveAsJSON(ioddInterpreter_Model.ioddFilesStorage, ioddStandardFileName..'.json')
  local success = File.copy(ioddFilePath, newioddFilePath .. '.xml')
  File.del(ioddFilePath)
  tempIODD = nil
  return loadSuccess, ioddStandardFileName
end
ioddInterpreter_Model.addNewIODDfile = addNewIODDfile

-- Function to check what IODD files are available when loading persistent data or restarting device
local function updateAvailableIODDs()
  local ioddFilesStorageContent = File.list(ioddInterpreter_Model.ioddFilesStorage)
  for ioddName, _ in pairs(ioddInterpreter_Model.parameters.availableIODDs) do
    for i, fileName in ipairs(ioddFilesStorageContent) do
      if string.sub(fileName, -5) == '.json' and string.sub(fileName, 1, -6) == ioddName then
        goto nextIoddName
      end
    end
    ioddInterpreter_Model.parameters.availableIODDs[ioddName] = nil
    ::nextIoddName::
  end
  for i, fileName in ipairs(ioddFilesStorageContent) do
    for ioddName, _ in pairs(ioddInterpreter_Model.parameters.availableIODDs) do
      if string.sub(fileName, -5) == '.json' and string.sub(fileName, 1, -6) == ioddName then
        goto nextFile
      end
    end
    if string.sub(fileName, -5) == '.json' then
      local tempIODD = ioddInterpreter_Model.ioddInt:new()
      tempIODD:loadFromJson(ioddInterpreter_Model.ioddFilesStorage, fileName)
      local tempVendorId, tempDeviceId, tempVersion = tempIODD:getVendorIdDeviceIdVersion()
      local ioddStandardFileName = tempIODD:getStandardFileName()
      ioddInterpreter_Model.parameters.availableIODDs[ioddStandardFileName] = {
        vendorId = tempVendorId,
        deviceId = tempDeviceId,
        version = tempVersion,
      }
    end
    ::nextFile::
  end
end
ioddInterpreter_Model.updateAvailableIODDs = updateAvailableIODDs
updateAvailableIODDs()

--- Delete IODD file from IODD storage.
---@param ioddName string Name of the IODD file to be deleted
local function deleteIODDFile(ioddName)
  File.del(ioddInterpreter_Model.ioddFilesStorage .. '/' .. ioddName .. '.xml')
  File.del(ioddInterpreter_Model.ioddFilesStorage .. '/' .. ioddName .. '.json')
  updateAvailableIODDs()
  deactivateNotUsedActiveIodds()
end
ioddInterpreter_Model.deleteIODDFile = deleteIODDFile

--- Set default values to all tables concerning processa data
---@param instanceId string Name of the instance
---@param processDataInfo object Lua table with process data info (depends on the selected process data structure)
local function setDefaultProcessDataInfo(instanceId, processDataInfo)
  local currentInstance = ioddInterpreter_Model.parameters.instances[instanceId]
  currentInstance.processDataInInfo = processDataInfo.ProcessDataIn
  currentInstance.processDataOutInfo = processDataInfo.ProcessDataOut
  currentInstance.processDataInSubindexAccess = false
  currentInstance.processDataOutSubindexAccess = false
  currentInstance.selectedProcessDataIn = ioddInterpreter_Model.dynamicTableHelper.makeDefaultSelectedProcessDataTable(processDataInfo.ProcessDataIn)
  currentInstance.selectedProcessDataOut = ioddInterpreter_Model.dynamicTableHelper.makeDefaultSelectedProcessDataTable(processDataInfo.ProcessDataOut)
end

--- Create a new instance with default name
---@return string newInstanceId Name of the created instance
local function createNewInstance()
  local instanceNumber = ioddInterpreter_Model.helperFuncs.getTableSize(ioddInterpreter_Model.parameters.instances)
  local newInstanceId = 'newInstance' .. tostring(instanceNumber)
  while ioddInterpreter_Model.parameters.instances[newInstanceId] do
    instanceNumber = instanceNumber + 1
    newInstanceId = 'newInstance' .. tostring(instanceNumber)
  end
  ioddInterpreter_Model.parameters.instances[newInstanceId] = {
    selectedReadParameters = {},
    selectedWriteParameters = {},
    selectedProcessDataIn = {},
    selectedProcessDataOut = {},
    deviceMatch = false,
    ioddName = nil
  }
  return newInstanceId
end
ioddInterpreter_Model.createNewInstance = createNewInstance

--- Start using the selected IODD in the selected instance
---@param instanceId string Name of the instance
---@param ioddName string Name of the IODD file to start using
local function loadIODD(instanceId, ioddName)
  local currentInstance = ioddInterpreter_Model.parameters.instances[instanceId]
  currentInstance.ioddName = ioddName
  currentInstance.iodd = ioddInterpreter_Model.ioddInt:new()
  local loadedIODD = currentInstance.iodd
  loadedIODD:loadFromJson(ioddInterpreter_Model.ioddFilesStorage, ioddName..'.json')
  currentInstance.selectedReadParameters = ioddInterpreter_Model.dynamicTableHelper.makeDefaultSelectedParameterTable(loadedIODD:getAllParameterInfo())
  currentInstance.selectedWriteParameters = ioddInterpreter_Model.dynamicTableHelper.makeDefaultSelectedParameterTable(loadedIODD:getAllParameterInfo())
  currentInstance.IsProcessDataStructureVariable = loadedIODD.IsProcessDataStructureVariable
  if loadedIODD.IsProcessDataStructureVariable then
    currentInstance.processDataConditionList = loadedIODD:getProcessDataConditionList()
    currentInstance.currentProcessDataConditionValue = loadedIODD.ProcessDataCondition.DefaultValue
    currentInstance.currentProcessDataConditionName = loadedIODD:getProcessDataConditionNameFromValue(currentInstance.currentProcessDataConditionValue)
  end
  currentInstance.allReadParameterInfo = loadedIODD:getAllReadParameterInfo()
  currentInstance.allWriteParameterInfo = loadedIODD:getAllWriteParameterInfo()
  setDefaultProcessDataInfo(instanceId, loadedIODD:getProcessDataInfo(currentInstance.currentProcessDataConditionValue))
end
ioddInterpreter_Model.loadIODD = loadIODD

--- Function to check if the currently used IODD file mathches needed product name. Used to check if this instance can still be used for connected IO-Link device.
---@param productName string Product name from device identification
---@return bool success True if the vendor ID, device ID match the used IODD file
---@return string IODDname Name of the loaded IODD for external reference
local function checkProductNameMatchIODD(productName)
  for _, loadedIODDName in ipairs(ioddInterpreter_Model.availableIODDs) do
    local tempIODD = ioddInterpreter_Model.ioddInt:new()
    tempIODD:loadFromJson(ioddInterpreter_Model.ioddFilesStorage, loadedIODDName..'.json')
    local deviceVariantCollection = tempIODD:getDeviceVariantCollection()
    for _, deviceVariant in ipairs(deviceVariantCollection) do
      if deviceVariant.Name == productName then
        tempIODD = nil
        return true, loadedIODDName
      end
    end
  end
  return false, "NO MATCH"
end
ioddInterpreter_Model.checkProductNameMatchIODD = checkProductNameMatchIODD

--- Function to change the process data structure (update info tables) depending on the new option string name (parsed from IODD)
---@param instanceId string ID of the instance
---@param newOptionName string Name of the new option
local function changeProcessDataStructureOptionName(instanceId, newOptionName)
  local currentInstance = ioddInterpreter_Model.parameters.instances[instanceId]
  local newOptionValue = currentInstance.iodd:getProcessDataConditionValueFromName(newOptionName)
  currentInstance.currentProcessDataConditionValue = newOptionValue
  currentInstance.currentProcessDataConditionName = newOptionName
  setDefaultProcessDataInfo(instanceId, currentInstance.iodd:getProcessDataInfo(currentInstance.currentProcessDataConditionValue))
end
ioddInterpreter_Model.changeProcessDataStructureOptionName = changeProcessDataStructureOptionName

--- Function to change the process data structure (update info tables) depending on the new option string value
---@param instanceId string ID of the instance
---@param newOptionValue string Name of the new option
local function changeProcessDataStructureOptionValue(instanceId, newOptionValue)
  local currentInstance = ioddInterpreter_Model.parameters.instances[instanceId]
  local newOptionName = currentInstance.iodd:getProcessDataConditionNameFromValue(newOptionValue)
  currentInstance.currentProcessDataConditionValue = newOptionValue
  currentInstance.currentProcessDataConditionName = newOptionName
  setDefaultProcessDataInfo(instanceId, currentInstance.iodd:getProcessDataInfo(currentInstance.currentProcessDataConditionValue))
end
ioddInterpreter_Model.changeProcessDataStructureOptionValue = changeProcessDataStructureOptionValue

--- Function to get JSON template and info of all datapoints selected on the read data page
---@param instanceId string ID of the instance
---@return string jsonTemplate JSON table with template generated according to IO-Link JSON standard
---@return string jsonInfoTable JSON table with info about the selected data points
local function getReadDataJsonTemplateAndInfo(instanceId)
  local compiledTableProcessData = ioddInterpreter_Model.helperFuncs.compileProcessDataTable(
    ioddInterpreter_Model.parameters.instances[instanceId].processDataInInfo,
    ioddInterpreter_Model.parameters.instances[instanceId].selectedProcessDataIn
  )
  local compiledTableParameters = ioddInterpreter_Model.helperFuncs.compileParametersTable(
    ioddInterpreter_Model.parameters.instances[instanceId].iodd,
    ioddInterpreter_Model.parameters.instances[instanceId].selectedReadParameters
  )
  local infoTable = {
    ProcessData = compiledTableProcessData,
    Parameters = compiledTableParameters
  }
  local jsonTemplate = {}
  if compiledTableProcessData and compiledTableParameters then
    jsonTemplate = {
      ProcessData = ioddInterpreter_Model.helperFuncs.makeExpectedPayload(compiledTableProcessData),
      Parameters = ioddInterpreter_Model.helperFuncs.makeExpectedPayload(compiledTableParameters)
    }
  elseif compiledTableProcessData then
    jsonTemplate = ioddInterpreter_Model.helperFuncs.makeExpectedPayload(compiledTableProcessData)
  elseif compiledTableParameters then
    jsonTemplate = ioddInterpreter_Model.helperFuncs.makeExpectedPayload(compiledTableParameters)
  end
  return ioddInterpreter_Model.json.encode(jsonTemplate), ioddInterpreter_Model.json.encode(infoTable)
end
ioddInterpreter_Model.getReadDataJsonTemplateAndInfo = getReadDataJsonTemplateAndInfo

--- Function to get JSON template and info of all datapoints selected on the write data page
---@param instanceId string ID of the instance
---@return string jsonTemplate JSON table with template generated according to IO-Link JSON standard
---@return string jsonInfoTable JSON table with info about the selected data points
local function getWriteDataJsonTemplateAndInfo(instanceId)
  local compiledTableProcessData = ioddInterpreter_Model.helperFuncs.compileProcessDataTable(
    ioddInterpreter_Model.parameters.instances[instanceId].processDataOutInfo,
    ioddInterpreter_Model.parameters.instances[instanceId].selectedProcessDataOut
  )
  local compiledTableParameters = ioddInterpreter_Model.helperFuncs.compileParametersTable(
    ioddInterpreter_Model.parameters.instances[instanceId].iodd,
    ioddInterpreter_Model.parameters.instances[instanceId].selectedWriteParameters
  )
  local infoTable = {
    ProcessData = compiledTableProcessData,
    Parameters = compiledTableParameters
  }
  local jsonTemplate = {}
  if compiledTableProcessData and compiledTableParameters then
    jsonTemplate = {
      ProcessData = ioddInterpreter_Model.helperFuncs.makeExpectedPayload(compiledTableProcessData),
      Parameters = ioddInterpreter_Model.helperFuncs.makeExpectedPayload(compiledTableParameters) 
    }
  elseif compiledTableProcessData then
    jsonTemplate = ioddInterpreter_Model.helperFuncs.makeExpectedPayload(compiledTableProcessData)
  elseif compiledTableParameters then
    jsonTemplate = ioddInterpreter_Model.helperFuncs.makeExpectedPayload(compiledTableParameters)
  end
  return ioddInterpreter_Model.json.encode(jsonTemplate), ioddInterpreter_Model.json.encode(infoTable)
end
ioddInterpreter_Model.getWriteDataJsonTemplateAndInfo = getWriteDataJsonTemplateAndInfo

--*************************************************************************
--********************** End Function Scope *******************************
--*************************************************************************

return ioddInterpreter_Model
