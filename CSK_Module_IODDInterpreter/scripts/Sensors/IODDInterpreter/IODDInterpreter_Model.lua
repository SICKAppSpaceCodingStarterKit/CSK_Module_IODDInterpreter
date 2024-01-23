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

-- Create parameters / instances for this module
ioddInterpreter_Model.ioddFilesStorage = 'public/IODDFiles' -- TODO
File.mkdir(ioddInterpreter_Model.ioddFilesStorage) -- TODO

-- TODO
local defaultPortConfig = {
  selectedReadParameters = {}, -- TODO
  selectedWriteParameters = {}, -- TODO
  selectedProcessDataIn = {}, -- TODO
  selectedProcessDataOut = {}, -- TODO
  deviceMatch = false, -- TODO
  ioddName = nil -- TODO
}

-- Parameters to be saved permanently if wanted
ioddInterpreter_Model.parameters = {}
ioddInterpreter_Model.parameters.instances = {}

ioddInterpreter_Model.availableIODDs = {} -- TODO
local ioddFilesStorageContent = File.list(ioddInterpreter_Model.ioddFilesStorage)
for i, fileName in ipairs(ioddFilesStorageContent) do
  if string.sub(fileName, -5) == '.json' then
    table.insert(ioddInterpreter_Model.availableIODDs, string.sub(fileName, 1, -6))
  end
end

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

-- TODO
--- Function to ...
---@param ioddFilePath [type] ... --TODO
---@return success bool ... --TODO
local function addNewIODDfile(ioddFilePath)
  local tempIODD = ioddInterpreter_Model.ioddInt:new()
  local callSuccess, loadSuccess = pcall(ioddInterpreter_Model.ioddInt.interpretXMLFile, tempIODD, ioddFilePath)
  if not (callSuccess and loadSuccess) then
    File.del(ioddFilePath)
    tempIODD = nil
    _G.logger:warning(_APPNAME..': failed to interpret iodd file: ' .. tostring(ioddFilePath) .. '; error caught: ' .. tostring(loadSuccess))
    return false, 'IODD interpretation failed'
  end
  local ioddStandardFileName = tempIODD:getStandardFileName()
  _G.logger:info(_APPNAME..': new iodd file name to save : ' .. tostring(ioddStandardFileName))
  for _, loadedIODDName in ipairs(ioddInterpreter_Model.availableIODDs) do
    if loadedIODDName == ioddStandardFileName then
      File.del(ioddFilePath)
      tempIODD = nil
      return false, 'IODD is already loaded'
    end
  end

  local newioddFilePath = ioddInterpreter_Model.ioddFilesStorage .. '/' .. ioddStandardFileName
  table.insert(ioddInterpreter_Model.availableIODDs, ioddStandardFileName)
  tempIODD:saveAsJSON(ioddInterpreter_Model.ioddFilesStorage, ioddStandardFileName..'.json')
  local success = File.copy(ioddFilePath, newioddFilePath .. '.xml')
  File.del(ioddFilePath)
  tempIODD = nil
  return loadSuccess, ioddStandardFileName
end
ioddInterpreter_Model.addNewIODDfile = addNewIODDfile

-- TODO
--- Function to ...
---@param ioddName [type] ... --TODO
local function deleteIODDFile(ioddName)
  File.del(ioddInterpreter_Model.ioddFilesStorage .. '/' .. ioddName .. '.xml')
  File.del(ioddInterpreter_Model.ioddFilesStorage .. '/' .. ioddName .. '.json')
  ioddInterpreter_Model.availableIODDs = {}
  local ioddFilesStorageContent = File.list(ioddInterpreter_Model.ioddFilesStorage)
  for i, fileName in ipairs(ioddFilesStorageContent) do
    if string.sub(fileName, -5) == '.json' then
      table.insert(ioddInterpreter_Model.availableIODDs, string.sub(fileName, 1, -6))
    end
  end
end
ioddInterpreter_Model.deleteIODDFile = deleteIODDFile

-- TODO
--- Function to ...
---@param instanceId [type] ... --TODO
---@param processDataInfo [type] ... --TODO
local function updateProcessDataInfo(instanceId, processDataInfo)
  local currentInstance = ioddInterpreter_Model.parameters.instances[instanceId]
  currentInstance.processDataInInfo = processDataInfo.ProcessDataIn
  currentInstance.processDataOutInfo = processDataInfo.ProcessDataOut
  currentInstance.processDataInSubindexAccess = false
  currentInstance.processDataOutSubindexAccess = false
  currentInstance.selectedProcessDataIn = ioddInterpreter_Model.dynamicTableHelper.makeDefaultSelectedProcessDataTable(processDataInfo.ProcessDataIn)
  currentInstance.selectedProcessDataOut = ioddInterpreter_Model.dynamicTableHelper.makeDefaultSelectedProcessDataTable(processDataInfo.ProcessDataOut)
end

-- TODO
--- Function to ...
---@param someTable [type] ... --TODO
---@return size int ... --TODO
local function getTableSize(someTable)
  local size = 0
  for _,_ in pairs(someTable) do
    size = size + 1
  end
  return size
end

-- TODO
--- Function to ...
---@return newInstanceId string ... --TODO
local function createNewInstance()
  local instanceNumber = getTableSize(ioddInterpreter_Model.parameters.instances)
  local newInstanceId = 'newIntance' .. tostring(instanceNumber)
  while ioddInterpreter_Model.parameters.instances[newInstanceId] do
    instanceNumber = instanceNumber + 1
    newInstanceId = 'newIntance' .. tostring(instanceNumber)
  end
  ioddInterpreter_Model.parameters.instances[newInstanceId] = ioddInterpreter_Model.helperFuncs.copy(defaultPortConfig)
  return newInstanceId
end
ioddInterpreter_Model.createNewInstance = createNewInstance

-- TODO
--- Function to ...
---@param instanceId [type] ... --TODO
---@param ioddName [type] ... --TODO
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
  updateProcessDataInfo(instanceId, loadedIODD:getProcessDataInfo(currentInstance.currentProcessDataConditionValue))
end
ioddInterpreter_Model.loadIODD = loadIODD

-- TODO
--- Function to ...
---@param vers [type] ... --TODO
---@return vers int[?] ... --TODO
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

-- TODO
--- Function to ...
---@param vendorId [type] ... --TODO
---@param deviceId [type] ... --TODO
---@param version [type] ... --TODO
---@return bla bool ... --TODO
---@return blabla string ... --TODO
local function checkVendorIdDeviceIdVersionMatchIODD(vendorId, deviceId, version)
  for _, loadedIODDName in ipairs(ioddInterpreter_Model.availableIODDs) do
    local tempIODD = ioddInterpreter_Model.ioddInt:new()
    tempIODD:loadFromJson(ioddInterpreter_Model.ioddFilesStorage, loadedIODDName..'.json')
    local tempVendorId, tempDeviceId, tempVersion = tempIODD:getVendorIdDeviceIdVersion()
    if vendorId == tempVendorId and tempDeviceId == deviceId then
      if not version then
        return true, loadedIODDName
      end
      if tempVersion == version then
        return true, loadedIODDName
      elseif getHigherVersion({tempVersion, version}) == tempVersion then
        return true, loadedIODDName
      else
        return true, loadedIODDName
      end
    end
  end
  return false, "NO MATCH"
end
ioddInterpreter_Model.checkVendorIdDeviceIdVersionMatchIODD = checkVendorIdDeviceIdVersionMatchIODD

-- TODO
--- Function to ...
---@param productName [type] ... --TODO
---@return bla bool ... --TODO
---@return blabla string ... --TODO
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

-- TODO
--- Function to ...
---@param instanceId [type] ... --TODO
---@param newOptionName [type] ... --TODO
local function changeProcessDataStructureOptionName(instanceId, newOptionName)
  local currentInstance = ioddInterpreter_Model.parameters.instances[instanceId]
  local newOptionValue = currentInstance.iodd:getProcessDataConditionValueFromName(newOptionName)
  currentInstance.currentProcessDataConditionValue = newOptionValue
  currentInstance.currentProcessDataConditionName = newOptionName
  updateProcessDataInfo(instanceId, currentInstance.iodd:getProcessDataInfo(currentInstance.currentProcessDataConditionValue))
end
ioddInterpreter_Model.changeProcessDataStructureOptionName = changeProcessDataStructureOptionName

-- TODO
--- Function to ...
---@param instanceId [type] ... --TODO
---@param newOptionValue [type] ... --TODO
local function changeProcessDataStructureOptionValue(instanceId, newOptionValue)
  local currentInstance = ioddInterpreter_Model.parameters.instances[instanceId]
  local newOptionName = currentInstance.iodd:getProcessDataConditionNameFromValue(newOptionValue)
  currentInstance.currentProcessDataConditionValue = newOptionValue
  currentInstance.currentProcessDataConditionName = newOptionName
  updateProcessDataInfo(instanceId, currentInstance.iodd:getProcessDataInfo(currentInstance.currentProcessDataConditionValue))
end
ioddInterpreter_Model.changeProcessDataStructureOptionValue = changeProcessDataStructureOptionValue

-- TODO
--- Function to ...
---@param instanceId [type] ... --TODO
---@return blabla string ... --TODO
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
  return ioddInterpreter_Model.json.encode(jsonTemplate), json.encode(infoTable)
end
ioddInterpreter_Model.getReadDataJsonTemplateAndInfo = getReadDataJsonTemplateAndInfo

-- TODO
--- Function to ...
---@param instanceId [type] ... --TODO
---@return bla string ... --TODO
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
