--luacheck: no max line length, ignore CSK_PersistentData

--***************************************************************
-- Inside of this script, you will find the necessary functions,
-- variables and events to communicate with the IODDInterpreter_Model
--***************************************************************

local json = require "Sensor.IODDInterpreter.helper.Json"
local dynamicTableHelper = require "Sensor.IODDInterpreter.helper.IODDDynamicTable"
local helperFuncs = require "Sensor.IODDInterpreter.helper.funcs"
--**************************************************************************
--************************ Start Global Scope ******************************
--**************************************************************************
local nameOfModule = 'CSK_IODDInterpreter'


-- Reference to global handle
local ioddInterpreter_Model

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


Script.serveEvent('CSK_IODDInterpreter.OnNewReadDataJsonTemplateAndInfo', 'IODDInterpreter_OnNewReadDataJsonTemplateAndInfo')
Script.serveEvent('CSK_IODDInterpreter.OnNewWriteDataJsonTemplateAndInfo', 'IODDInterpreter_OnNewWriteDataJsonTemplateAndInfo')

-- Functions to forward logged in user roles via CSK_UserManagement module (if available)
--@handleOnUserLevelOperatorActive(status:bool):
local function handleOnUserLevelOperatorActive(status)
  Script.notifyEvent("IODDInterpreter_OnUserLevelOperatorActive", status)
end

--@handleOnUserLevelMaintenanceActive(status:bool):
local function handleOnUserLevelMaintenanceActive(status)
  Script.notifyEvent("IODDInterpreter_OnUserLevelMaintenanceActive", status)
end

--@handleOnUserLevelServiceActive(status:bool):
local function handleOnUserLevelServiceActive(status)
  Script.notifyEvent("IODDInterpreter_OnUserLevelServiceActive", status)
end

--@handleOnUserLevelAdminActive(status:bool):
local function handleOnUserLevelAdminActive(status)
  Script.notifyEvent("IODDInterpreter_OnUserLevelAdminActive", status)
end

-- Function to get access to the IODDInterpreter_Model object
--@setIODDInterpreter_Model_Handle(handle:table):
local function setIODDInterpreter_Model_Handle(handle)
  ioddInterpreter_Model = handle
  if ioddInterpreter_Model.userManagementModuleAvailable then
    -- Register on events of CSK_UserManagement module if available
    Script.register('CSK_UserManagement.OnUserLevelOperatorActive', handleOnUserLevelOperatorActive)
    Script.register('CSK_UserManagement.OnUserLevelMaintenanceActive', handleOnUserLevelMaintenanceActive)
    Script.register('CSK_UserManagement.OnUserLevelServiceActive', handleOnUserLevelServiceActive)
    Script.register('CSK_UserManagement.OnUserLevelAdminActive', handleOnUserLevelAdminActive)
  end
  Script.releaseObject(handle)
end

-- Function to update user levels
local function updateUserLevel()
  if ioddInterpreter_Model.userManagementModuleAvailable then
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


--**************************************************************************
--******************* Start IODDs and Instances Scope **********************
--**************************************************************************
local selectedIoddToHandle = ''

local currentCalloutType = 'info'
local currentCalloutValue = 'Application started'
local selectedInstance = ''
local selectedIodd = ''

Script.serveEvent('CSK_IODDInterpreter.OnIoddListChanged', 'IODDInterpreter_OnIoddListChanged')
Script.serveEvent('CSK_IODDInterpreter.OnNewCalloutValue', 'IODDInterpreter_OnNewCalloutValue')
Script.serveEvent('CSK_IODDInterpreter.OnNewCalloutType', 'IODDInterpreter_OnNewCalloutType')
Script.serveEvent('CSK_IODDInterpreter.OnNewListIodd', 'IODDInterpreter_OnNewListIodd')
Script.serveEvent('CSK_IODDInterpreter.OnNewSelectedIodd', 'IODDInterpreter_OnNewSelectedIodd')
Script.serveEvent('CSK_IODDInterpreter.OnNewListIntances', 'IODDInterpreter_OnNewListIntances')
Script.serveEvent('CSK_IODDInterpreter.OnNewSelectedInstance', 'IODDInterpreter_OnNewSelectedInstance')
Script.serveEvent('CSK_IODDInterpreter.isInstanceSelected', 'IODDInterpreter_isInstanceSelected')
Script.serveEvent('CSK_IODDInterpreter.OnNewInstanceName', 'IODDInterpreter_OnNewInstanceName')
Script.serveEvent('CSK_IODDInterpreter.OnNewSelectedIoddToHandle', 'IODDInterpreter_OnNewSelectedIoddToHandle')

-- Function to send all relevant values to UI on resume
--@handleOnExpiredTmrIODDInterpreter()
local function handleOnExpiredTmrInstances()
  Script.notifyEvent('IODDInterpreter_OnNewCalloutType', currentCalloutType)
  Script.notifyEvent('IODDInterpreter_OnNewCalloutValue', currentCalloutValue)
  Script.notifyEvent("IODDInterpreter_OnNewListIodd", json.encode(ioddInterpreter_Model.availableIODDs))
  Script.notifyEvent("IODDInterpreter_OnNewSelectedIoddToHandle", json.encode(selectedIoddToHandle))
  Script.notifyEvent("IODDInterpreter_OnPersistentDataModuleAvailable", (CSK_PersistentData ~= nil))
  Script.notifyEvent("IODDInterpreter_OnNewStatusLoadParameterOnReboot", ioddInterpreter_Model.parameterLoadOnReboot)
  Script.notifyEvent("IODDInterpreter_OnNewParameterName", ioddInterpreter_Model.parametersName)
  local instancesList = {}
  for instanceId, _ in pairs(ioddInterpreter_Model.parameters.instances) do
    table.insert(instancesList, instanceId)
  end
  table.sort(instancesList)
  Script.notifyEvent("IODDInterpreter_OnNewListIntances", json.encode(instancesList))
  Script.notifyEvent("IODDInterpreter_OnNewSelectedInstance", selectedInstance)
  local isSelected = (selectedInstance ~= '')
  Script.notifyEvent("IODDInterpreter_isInstanceSelected", isSelected)
  if isSelected then
    Script.notifyEvent("IODDInterpreter_OnNewInstanceName", selectedInstance)
    Script.notifyEvent("IODDInterpreter_OnNewSelectedIodd", selectedIodd)
  end
end

-- Timer to update UI via events after page was loaded
local tmrInstances = Timer.create()
tmrInstances:setExpirationTime(300)
tmrInstances:setPeriodic(false)
Timer.register(tmrInstances, "OnExpired", handleOnExpiredTmrInstances)

--@pageCalled():string
local function pageCalledInstances()
  updateUserLevel() -- try to hide user specific content asap
  tmrInstances:start()
  return ''
end
Script.serveFunction("CSK_IODDInterpreter.pageCalledInstances", pageCalledInstances)

---@param path string Path to a temporary IODD file. The file will be deleted after interpretation attempt.
---@return bool success Interpretation success.
---@return string result If interpretation is successful, returns a standartized IODD file name that is used for the uploaded IODD file. Else returns a reason of interpretation failure.
local function addIoddFile(path)
  local success, result = ioddInterpreter_Model.addNewIoddfile(path)
  if success then
    Script.notifyEvent('IODDInterpreter_OnIoddListChanged')
  end
  return success, result
end
Script.serveFunction('CSK_IODDInterpreter.addIoddFile', addIoddFile)

---@param uploadSuccess bool Upload success.
local function uploadFinished(uploadSuccess)
  currentCalloutType ='error'
  currentCalloutValue = 'Failed to upload IODD XML file'
  if uploadSuccess then
    local tempFilePath = 'public/tempIodd.xml'
    local interpretationSuccess, result = addIoddFile(tempFilePath)
    if interpretationSuccess then
      currentCalloutType = 'success'
      currentCalloutValue = 'IODD file uploaded ' .. result
    end
  end
  handleOnExpiredTmrInstances()
end
Script.serveFunction('CSK_IODDInterpreter.uploadFinished', uploadFinished)

local function addInstance()
  selectedInstance = ioddInterpreter_Model.createNewInstance()
  handleOnExpiredTmrInstances()
end
Script.serveFunction('CSK_IODDInterpreter.addInstance', addInstance)

local function deleteInstance()
  ioddInterpreter_Model.parameters.instances[selectedInstance] = nil
  selectedInstance = ''
  handleOnExpiredTmrInstances()
end
Script.serveFunction('CSK_IODDInterpreter.deleteInstance', deleteInstance)

---@param newInstanceName string New unique name of the selected instance.
local function setInstanceName(newInstanceName)
  ioddInterpreter_Model.parameters.instances[newInstanceName] = ioddInterpreter_Model.helperFuncs.copy(ioddInterpreter_Model.parameters.instances[selectedInstance])
  ioddInterpreter_Model.parameters.instances[selectedInstance] = nil
  selectedInstance = newInstanceName
  handleOnExpiredTmrInstances()
end
Script.serveFunction('CSK_IODDInterpreter.setInstanceName', setInstanceName)

---@param newSelectedInstance string 
local function setSelectedInstance(newSelectedInstance)
  if ioddInterpreter_Model.parameters.instances[newSelectedInstance] == nil then
    return false
  end
  if newSelectedInstance ~= '' then
    selectedInstance = newSelectedInstance
  end
  handleOnExpiredTmrInstances()
  return true
end
Script.serveFunction('CSK_IODDInterpreter.setSelectedInstance', setSelectedInstance)

---@param ioddName string Standartised IODD name.
local function setSelectedIodd(ioddName)
  selectedIodd = ioddName
  ioddInterpreter_Model.loadIodd(selectedInstance, ioddName)
  handleOnExpiredTmrInstances()
end
Script.serveFunction('CSK_IODDInterpreter.setSelectedIodd', setSelectedIodd)

---@param newSelectedIoddToHandle string IODD name.
local function setSelectedIoddToHandle(newSelectedIoddToHandle)
  selectedIoddToHandle = newSelectedIoddToHandle
end
Script.serveFunction('CSK_IODDInterpreter.setSelectedIoddToHandle', setSelectedIoddToHandle)


---@return bool success Success of deleting.
---@return string result Reason if deleting failed.
local function deleteIodd()
  if selectedIoddToHandle == '' then
    currentCalloutType = 'error'
    currentCalloutValue = 'Select file to delete'
    handleOnExpiredTmrInstances()
    return false, currentCalloutValue
  end
  for instanceId, instanceInfo in pairs(ioddInterpreter_Model.parameters.instances) do
    if instanceInfo.ioddName == selectedIoddToHandle then
      setSelectedInstance(instanceId)
      deleteInstance()
    end
  end
  setSelectedInstance('')
  ioddInterpreter_Model.deleteIoddFile(selectedIoddToHandle)
  currentCalloutType = 'success'
  currentCalloutValue = 'Deleted IODD ' .. selectedIoddToHandle
  selectedIoddToHandle = ''
  Script.notifyEvent('IODDInterpreter_OnIoddListChanged')
  handleOnExpiredTmrInstances()
  return true, 'SUCCESS'
end
Script.serveFunction('CSK_IODDInterpreter.deleteIodd', deleteIodd)

--**************************************************************************
--******************** End IODDs and Instances Scope ***********************
--**************************************************************************
--************************* Start Data Scope *******************************
--**************************************************************************

Script.serveEvent('CSK_IODDInterpreter.OnNewProcessDataStructureOptionsDropdownContent', 'IODDInterpreter_OnNewProcessDataStructureOptionsDropdownContent')
Script.serveEvent('CSK_IODDInterpreter.OnNewSelectedProcessDataStructureOption', 'IODDInterpreter_OnNewSelectedProcessDataStructureOption')
Script.serveEvent('CSK_IODDInterpreter.isProcessDataStructureVariable', 'IODDInterpreter_isProcessDataStructureVariable')

---@param jsonSelectedRow string JSON row data.
---@param jsonSelectedProcessDataTable string JSON object with current selected process data table.
---@return string newJsonSelectedProcessDataTable JSON object with new selected process data table.
local function updateSelectedProcessDataTable(jsonSelectedRow, jsonSelectedProcessDataTable)
  local selectedProcessDataTable = json.decode(jsonSelectedProcessDataTable)
  local selectedRow = json.decode(jsonSelectedRow)
  local state = selectedRow.selected
  local subindex = selectedRow.colPD1
  if subindex ~= "0" then
    if state == false and selectedProcessDataTable["0"] == true then
      selectedProcessDataTable["0"] = false
    end
    if selectedProcessDataTable.subindexAccessSupported == true then
      selectedProcessDataTable[subindex] = state
    else
      for tempSubndex, _ in pairs(selectedProcessDataTable) do
        if tempSubndex ~= "subindexAccessSupported" then
          selectedProcessDataTable[tempSubndex] = state
        end
      end
    end
  else
    for tempSubndex, _ in pairs(selectedProcessDataTable) do
      if tempSubndex ~= "subindexAccessSupported" then
        selectedProcessDataTable[tempSubndex] = state
      end
    end
  end
  return json.encode(selectedProcessDataTable)
end
Script.serveFunction('CSK_IODDInterpreter.updateSelectedProcessDataTable', updateSelectedProcessDataTable)

---@param jsonSelectedRow string JSON row data.
---@param jsonSelectedParametersTable string JSON object with current selected parameters table.
---@return string newJsonSelectedParametersTable JSON object with new selected parameters table.
local function updateSelectedParametersTable(jsonSelectedRow, jsonSelectedParametersTable)
  local selectedParametersTable = json.decode(jsonSelectedParametersTable)
  local selectedRow = json.decode(jsonSelectedRow)
  local state = selectedRow.selected
  local index = selectedRow.colSD1
  local subindex = selectedRow.colSD2
  if subindex ~= "0" then
    if state == false and selectedParametersTable[index]["0"] == true then
      selectedParametersTable[index]["0"] = false
    end
    if selectedParametersTable[index].subindexAccessSupported == true then
      selectedParametersTable[index][subindex] = state
    else
      for subindex1, _ in pairs(selectedParametersTable[index]) do
        if subindex1 ~= "subindexAccessSupported" then
          selectedParametersTable[index][subindex1] = state
        end
      end
    end
  else
    for subindex1, _ in pairs(selectedParametersTable[index]) do
      if subindex1 ~= "subindexAccessSupported" then
        selectedParametersTable[index][subindex1] = state
      end
    end
  end
  return json.encode(selectedParametersTable)
end
Script.serveFunction('CSK_IODDInterpreter.updateSelectedParametersTable', updateSelectedParametersTable)

---@param instanceId string Instance name.
---@param index int Index of the parameter.
---@param subindex int Subindex of the parameter.
---@return string? jsonDataPointInfo JSON object with description of index or subindex of the parameter. Nil if the parameter does not exist.
local function getParameterDataPointInfo(instanceId, index, subindex)
  local dataPointInfo
  if subindex == 0 then
    dataPointInfo = ioddInterpreter_Model.parameters.instances[instanceId].iodd:getParameterInfoFromIndex(index)
  else
    dataPointInfo = ioddInterpreter_Model.parameters.instances[instanceId].iodd:getSubIndexParameter(index, subindex)
  end
  if not dataPointInfo then
    return nil
  end
  local jsonDataPointInfo = json.encode(dataPointInfo)
  return jsonDataPointInfo
end
Script.serveFunction('CSK_IODDInterpreter.getParameterDataPointInfo', getParameterDataPointInfo)



--**************************************************************************
--*********************** Start Read Data Scope ****************************
--**************************************************************************
local readPreficesToInclude = {"read_"}

Script.serveEvent('CSK_IODDInterpreter.OnNewProcessDataInTableContent', 'IODDInterpreter_OnNewProcessDataInTableContent')
Script.serveEvent('CSK_IODDInterpreter.OnNewReadParametersTableContent', 'IODDInterpreter_OnNewReadParametersTableContent')

-- Function to send all relevant values to UI on resume
--@handleOnExpiredTmrIODDInterpreter()
local function handleOnExpiredTmrReadData()
  Script.notifyEvent("IODDInterpreter_OnNewSelectedInstance", selectedInstance)
  local isSelected = (selectedInstance ~= '')
  Script.notifyEvent("IODDInterpreter_isInstanceSelected", isSelected)
  if isSelected and ioddInterpreter_Model.parameters.instances[selectedInstance].ioddName ~= nil then
    local currentInstance = ioddInterpreter_Model.parameters.instances[selectedInstance]
    local isProcessDataStructureVariable = currentInstance.IsProcessDataStructureVariable

    Script.notifyEvent("IODDInterpreter_isProcessDataStructureVariable", isProcessDataStructureVariable)
    if isProcessDataStructureVariable then
      Script.notifyEvent('IODDInterpreter_OnNewProcessDataStructureOptionsDropdownContent', json.encode(currentInstance.processDataConditionList))
      Script.notifyEvent('IODDInterpreter_OnNewSelectedProcessDataStructureOption', currentInstance.currentProcessDataConditionName)
    end
    Script.notifyEvent('IODDInterpreter_OnNewProcessDataInTableContent',
      dynamicTableHelper.makeProcessDataTableContent(
        readPreficesToInclude,
        currentInstance.processDataInInfo,
        currentInstance.selectedProcessDataIn
      )
    )
    Script.notifyEvent('IODDInterpreter_OnNewReadParametersTableContent',
      dynamicTableHelper.makeIODDParameterTableContent(
        readPreficesToInclude,
        currentInstance.allReadParameterInfo,
        currentInstance.selectedReadParameters
      )
    )
  end
end


-- Timer to update UI via events after page was loaded
local tmrReadData = Timer.create()
tmrReadData:setExpirationTime(1000)
tmrReadData:setPeriodic(false)
Timer.register(tmrReadData, "OnExpired", handleOnExpiredTmrReadData)

---@return string empty
local function pageCalledReadData()
  updateUserLevel() -- try to hide user specific content asap
  tmrReadData:start()
  return ''
end
Script.serveFunction('CSK_IODDInterpreter.pageCalledReadData', pageCalledReadData)

---@param jsonReadDataInfo string JSON object with selected data points for process data (ProcessData) and for parameters (Parameters).
local function setReadSelectedData(jsonReadDataInfo)
  local readDataInfo = json.decode(jsonReadDataInfo)
  for subindex, _ in pairs(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataIn) do
    ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataIn[subindex] = false
  end
  if readDataInfo.ProcessData then
    for _, processDatainfo in pairs(readDataInfo.ProcessData) do
      if processDatainfo.Datatype.type == "ArrayT" or processDatainfo.Datatype.type == "RecordT" then
        for _, dataPointInfo in pairs(processDatainfo.Datatype.RecordItem) do
          ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataIn[dataPointInfo.subindex] = true
        end
        if helperFuncs.getTableSize(processDatainfo.Datatype.RecordItem) == helperFuncs.getTableSize(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataIn) - 2 then
          ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataIn["0"] = true
        end
      else
        ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataIn["0"] = true
      end
    end
  end
  for index, indexInfo in pairs(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedReadParameters) do
    for subindex, _ in pairs(indexInfo) do
      ioddInterpreter_Model.parameters.instances[selectedInstance].selectedReadParameters[index][subindex] = false
    end
  end
  if readDataInfo.Parameters then
    for _, dataPointInfo in pairs(readDataInfo.Parameters) do
      if dataPointInfo.subindex == 0 then
        for subindex, _ in pairs(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedReadParameters[tostring(dataPointInfo.index)]) do
          ioddInterpreter_Model.parameters.instances[selectedInstance].selectedReadParameters[tostring(dataPointInfo.index)][subindex] = true
        end
      else
        ioddInterpreter_Model.parameters.instances[selectedInstance].selectedReadParameters[tostring(dataPointInfo.index)][tostring(dataPointInfo.subindex)] = true
      end
    end
  end
  local jsonTemplate, jsonDataInfo = ioddInterpreter_Model.getReadDataJsonTemplateAndInfo(selectedInstance)
  Script.notifyEvent('IODDInterpreter_OnNewReadDataJsonTemplateAndInfo', selectedInstance, jsonTemplate, jsonDataInfo)
end
Script.serveFunction('CSK_IODDInterpreter.setReadSelectedData', setReadSelectedData)


---@param jsonSelectedRow string JSON row data.
local function processDataInRowSelected(jsonSelectedRow)
  jsonSelectedRow = dynamicTableHelper.removePrefixFromColumnNames(jsonSelectedRow, readPreficesToInclude[1])
  ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataIn = json.decode(
    updateSelectedProcessDataTable(
      jsonSelectedRow,
      json.encode(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataIn)
    )
  )
  handleOnExpiredTmrReadData()
  local jsonTemplate, jsonDataInfo = ioddInterpreter_Model.getReadDataJsonTemplateAndInfo(selectedInstance)
  Script.notifyEvent('IODDInterpreter_OnNewReadDataJsonTemplateAndInfo', selectedInstance, jsonTemplate, jsonDataInfo)
end
Script.serveFunction('CSK_IODDInterpreter.processDataInRowSelected', processDataInRowSelected)

---@param jsonSelectedRow string
local function readParameterRowSelected(jsonSelectedRow)
  jsonSelectedRow = dynamicTableHelper.removePrefixFromColumnNames(jsonSelectedRow, readPreficesToInclude[1])
  print(jsonSelectedRow)
  ioddInterpreter_Model.parameters.instances[selectedInstance].selectedReadParameters = json.decode(
    updateSelectedParametersTable(
      jsonSelectedRow,
      json.encode(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedReadParameters)
    )
  )
  handleOnExpiredTmrReadData()
  local jsonTemplate, jsonDataInfo = ioddInterpreter_Model.getReadDataJsonTemplateAndInfo(selectedInstance)
  Script.notifyEvent('IODDInterpreter_OnNewReadDataJsonTemplateAndInfo', selectedInstance, jsonTemplate, jsonDataInfo)
end
Script.serveFunction('CSK_IODDInterpreter.readParameterRowSelected', readParameterRowSelected)


--**************************************************************************
--************************* End Read Data Scope ****************************
--**************************************************************************
--************************ Start Write Data Scope **************************
--**************************************************************************
local writePreficesToInclude = {"write_"}

Script.serveEvent('CSK_IODDInterpreter.OnNewProcessDataOutTableContent', 'IODDInterpreter_OnNewProcessDataOutTableContent')
Script.serveEvent('CSK_IODDInterpreter.OnNewWriteParametersTableContent', 'IODDInterpreter_OnNewWriteParametersTableContent')

-- Function to send all relevant values to UI on resume
--@handleOnExpiredTmrIODDInterpreter()
local function handleOnExpiredTmrWriteData()
  Script.notifyEvent("IODDInterpreter_OnNewSelectedInstance", selectedInstance)
  local isSelected = (selectedInstance ~= '')
  Script.notifyEvent("IODDInterpreter_isInstanceSelected", isSelected)
  if isSelected and ioddInterpreter_Model.parameters.instances[selectedInstance].ioddName ~= nil then
    local currentInstance = ioddInterpreter_Model.parameters.instances[selectedInstance]
    local isProcessDataStructureVariable = currentInstance.IsProcessDataStructureVariable
    Script.notifyEvent("IODDInterpreter_isProcessDataStructureVariable", isProcessDataStructureVariable)
    if isProcessDataStructureVariable then
      Script.notifyEvent('IODDInterpreter_OnNewProcessDataStructureOptionsDropdownContent', json.encode(currentInstance.processDataConditionList))
      Script.notifyEvent('IODDInterpreter_OnNewSelectedProcessDataStructureOption', currentInstance.currentProcessDataConditionName)
    end
    Script.notifyEvent('IODDInterpreter_OnNewProcessDataOutTableContent',
      dynamicTableHelper.makeProcessDataTableContent(
        writePreficesToInclude,
        currentInstance.processDataOutInfo,
        currentInstance.selectedProcessDataOut
      )
    )
    Script.notifyEvent('IODDInterpreter_OnNewWriteParametersTableContent',
      dynamicTableHelper.makeIODDParameterTableContent(
        writePreficesToInclude,
        currentInstance.allWriteParameterInfo,
        currentInstance.selectedWriteParameters
      )
    )
  end
end

-- Timer to update UI via events after page was loaded
local tmrWriteData = Timer.create()
tmrWriteData:setExpirationTime(1000)
tmrWriteData:setPeriodic(false)
Timer.register(tmrWriteData, "OnExpired", handleOnExpiredTmrWriteData)

---@return string empty
local function pageCalledWriteData()
  updateUserLevel() -- try to hide user specific content asap
  tmrWriteData:start()
  return ''
end
Script.serveFunction('CSK_IODDInterpreter.pageCalledWriteData', pageCalledWriteData)

---@param jsonWriteDataInfo string Set selected read data datapoints externally both for process data out and parameters.
local function setWriteSelectedData(jsonWriteDataInfo)
  local writeDataInfo = json.decode(jsonWriteDataInfo)
  for subindex, _ in pairs(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataOut) do
    ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataOut[subindex] = false
  end
  if writeDataInfo.ProcessData then
    for _, processDatainfo in pairs(writeDataInfo.ProcessData) do
      if processDatainfo.Datatype.type == "ArrayT" or processDatainfo.Datatype.type == "RecordT" then
        for _, dataPointInfo in pairs(processDatainfo.Datatype.RecordItem) do
          ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataOut[dataPointInfo.subindex] = true
        end
        if helperFuncs.getTableSize(processDatainfo.Datatype.RecordItem) == helperFuncs.getTableSize(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataOut) - 2 then
          ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataOut["0"] = true
        end
      else
        ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataOut["0"] = true
      end
    end
  end
  for index, indexInfo in pairs(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedWriteParameters) do
    for subindex, _ in pairs(indexInfo) do
      ioddInterpreter_Model.parameters.instances[selectedInstance].selectedWriteParameters[index][subindex] = false
    end
  end
  if writeDataInfo.Parameters then
    for _, dataPointInfo in pairs(writeDataInfo.Parameters) do
      if dataPointInfo.subindex == 0 then
        for subindex, _ in pairs(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedWriteParameters[tostring(dataPointInfo.index)]) do
          ioddInterpreter_Model.parameters.instances[selectedInstance].selectedWriteParameters[tostring(dataPointInfo.index)][subindex] = true
        end
      else
        ioddInterpreter_Model.parameters.instances[selectedInstance].selectedWriteParameters[tostring(dataPointInfo.index)][tostring(dataPointInfo.subindex)] = true
      end
    end
  end
  local jsonTemplate, jsonDataInfo = ioddInterpreter_Model.getWriteDataJsonTemplateAndInfo(selectedInstance)
  Script.notifyEvent('IODDInterpreter_OnNewWriteDataJsonTemplateAndInfo', selectedInstance, jsonTemplate, jsonDataInfo)
end
Script.serveFunction('CSK_IODDInterpreter.setWriteSelectedData', setWriteSelectedData)

---@param jsonSelectedRow string
local function processDataOutRowSelected(jsonSelectedRow)
  jsonSelectedRow = dynamicTableHelper.removePrefixFromColumnNames(jsonSelectedRow, writePreficesToInclude[1])
  ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataOut = json.decode(
    updateSelectedProcessDataTable(
      jsonSelectedRow,
      json.encode(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataOut)
    )
  )
  handleOnExpiredTmrWriteData()
  local jsonTemplate, jsonDataIndo = ioddInterpreter_Model.getWriteDataJsonTemplateAndInfo(selectedInstance)
  Script.notifyEvent('IODDInterpreter_OnNewWriteDataJsonTemplateAndInfo', selectedInstance, jsonTemplate, jsonDataIndo)
end
Script.serveFunction('CSK_IODDInterpreter.processDataOutRowSelected', processDataOutRowSelected)

---@param jsonSelectedRow string JSON row data.
local function writeParameterRowSelected(jsonSelectedRow)
  jsonSelectedRow = dynamicTableHelper.removePrefixFromColumnNames(jsonSelectedRow, writePreficesToInclude[1])
  ioddInterpreter_Model.parameters.instances[selectedInstance].selectedWriteParameters = json.decode(
    updateSelectedParametersTable(
      jsonSelectedRow,
      json.encode(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedWriteParameters)
    )
  )
  handleOnExpiredTmrWriteData()
  local jsonTemplate, jsonDataIndo = ioddInterpreter_Model.getWriteDataJsonTemplateAndInfo(selectedInstance)
  Script.notifyEvent('IODDInterpreter_OnNewWriteDataJsonTemplateAndInfo', selectedInstance, jsonTemplate, jsonDataIndo)
end
Script.serveFunction('CSK_IODDInterpreter.writeParameterRowSelected', writeParameterRowSelected)

--**************************************************************************
--************************* End Write Data Scope ***************************
--**************************************************************************
---@param newPDStructureOptionName string String process data structure name option from IODD file.
local function changeProcessDataStructureOptionName(newPDStructureOptionName)
  ioddInterpreter_Model.changeProcessDataStructureOptionName(selectedInstance, newPDStructureOptionName)
  handleOnExpiredTmrWriteData()
  handleOnExpiredTmrReadData()
  local jsonTemplate, jsonDataIndo = ioddInterpreter_Model.getReadDataJsonTemplateAndInfo(selectedInstance)
  Script.notifyEvent('IODDInterpreter_OnNewReadDataJsonTemplateAndInfo', selectedInstance, jsonTemplate, jsonDataIndo)
  jsonTemplate, jsonDataIndo = ioddInterpreter_Model.getWriteDataJsonTemplateAndInfo(selectedInstance)
  Script.notifyEvent('IODDInterpreter_OnNewWriteDataJsonTemplateAndInfo', selectedInstance, jsonTemplate, jsonDataIndo)
end
Script.serveFunction('CSK_IODDInterpreter.changeProcessDataStructureOptionName', changeProcessDataStructureOptionName)

---@param newPDStructureOptionValue auto Process data structure value option from IODD file.
local function changeProcessDataStructureOptionValue(newPDStructureOptionValue)
  ioddInterpreter_Model.changeProcessDataStructureOptionValue(selectedInstance, tostring(newPDStructureOptionValue))
  handleOnExpiredTmrWriteData()
  handleOnExpiredTmrReadData()
  local jsonTemplate, jsonDataIndo = ioddInterpreter_Model.getReadDataJsonTemplateAndInfo(selectedInstance)
  Script.notifyEvent('IODDInterpreter_OnNewReadDataJsonTemplateAndInfo', selectedInstance, jsonTemplate, jsonDataIndo)
  jsonTemplate, jsonDataIndo = ioddInterpreter_Model.getWriteDataJsonTemplateAndInfo(selectedInstance)
  Script.notifyEvent('IODDInterpreter_OnNewWriteDataJsonTemplateAndInfo', selectedInstance, jsonTemplate, jsonDataIndo)
end
Script.serveFunction('CSK_IODDInterpreter.changeProcessDataStructureOptionValue', changeProcessDataStructureOptionValue)
--**************************************************************************
--*************************** End Data Scope *******************************
--**************************************************************************
--********************* Start external use Scope ***************************
--**************************************************************************


---@return table? ioddList String array with names of loaded IODD files.
local function getIoddList()
  return ioddInterpreter_Model.availableIODDs
end
Script.serveFunction('CSK_IODDInterpreter.getIoddList', getIoddList)

---@return string? jsonSelectedProcessDataIn JSON object with information about selected datapoints.
local function getSelectedProcessDataIn()
  if not ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataIn then
    return nil
  end
  return json.encode(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataIn)
end
Script.serveFunction('CSK_IODDInterpreter.getSelectedProcessDataIn', getSelectedProcessDataIn)

---@return string? jsonSelectedProcessDataOut JSON object with information about selected datapoints.
local function getSelectedProcessDataOut()
  if not ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataOut then
    return nil
  end
  return json.encode(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataOut)
end
Script.serveFunction('CSK_IODDInterpreter.getSelectedProcessDataOut', getSelectedProcessDataOut)

---@return string? jsonSelectedReadParameters 
local function getSelectedReadParameters()
  if not ioddInterpreter_Model.parameters.instances[selectedInstance].selectedReadParameters then
    return nil
  end
  return json.encode(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedReadParameters)
end
Script.serveFunction('CSK_IODDInterpreter.getSelectedReadParameters', getSelectedReadParameters)
 
---@return string? jsonSelectedWriteParameters JSON object with information about selected datapoints.
local function getSelectedWriteParameters()
  if not ioddInterpreter_Model.parameters.instances[selectedInstance].selectedWriteParameters then
    return nil
  end
  return json.encode(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedWriteParameters)
end
Script.serveFunction('CSK_IODDInterpreter.getSelectedWriteParameters', getSelectedWriteParameters)

---@param vendorId auto Vendor ID.
---@param deviceId auto Device ID.
---@param version auto? Optional IODD version.
---@return bool success True if matching IODD file is found.
---@return string result IODD file name if match is found.
local function findIoddMatchingVendorIdDeviceIdVersion(vendorId, deviceId, version)
  local success, result =  ioddInterpreter_Model.checkVendorIdDeviceIdVersionMatchIODD(tostring(vendorId), tostring(deviceId), version)
  return success, result
end
Script.serveFunction('CSK_IODDInterpreter.findIoddMatchingVendorIdDeviceIdVersion', findIoddMatchingVendorIdDeviceIdVersion)

---@param productName string 
---@return bool success 
---@return string result
local function findIoddMatchingProductName(productName)
  local success, result =  ioddInterpreter_Model.checkProductNameMatchIODD(productName)
  return success, result
end
Script.serveFunction('CSK_IODDInterpreter.findIoddMatchingProductName', findIoddMatchingProductName)

---@return string path
local function getIoddFilesStorage()
  return ioddInterpreter_Model.ioddFilesStorage
end
Script.serveFunction('CSK_IODDInterpreter.getIoddFilesStorage', getIoddFilesStorage)

---@return bool isVariable True if process data structure is variable.
local function getIsProcessDataVariable()
  return ioddInterpreter_Model.parameters.instances[selectedInstance].iodd.IsProcessDataStructureVariable
end
Script.serveFunction('CSK_IODDInterpreter.getIsProcessDataVariable', getIsProcessDataVariable)

---@return string jsonProcessDataConditionInfo JSON object with description of index or subindex of the parameter.
local function getProcessDataConditionInfo()
  local jsonProcessDataConditionInfo = json.encode(ioddInterpreter_Model.parameters.instances[selectedInstance].iodd.ProcessDataCondition)
  return jsonProcessDataConditionInfo
end
Script.serveFunction('CSK_IODDInterpreter.getProcessDataConditionInfo', getProcessDataConditionInfo)

---@return string jsonProcessDataConditionList JSON list of options.
local function getProcessDataConditionList()
  return json.encode(ioddInterpreter_Model.parameters.instances[selectedInstance].iodd:getProcessDataConditionList())
end
Script.serveFunction('CSK_IODDInterpreter.getProcessDataConditionList', getProcessDataConditionList)

---@param conditionValue string Value of the parameter.
---@return string conditionName Name of the process data structure option.
local function getProcessDataConditionNameFromValue(conditionValue)
  return ioddInterpreter_Model.parameters.instances[selectedInstance].iodd:getProcessDataConditionNameFromValue(conditionValue)
end
Script.serveFunction('CSK_IODDInterpreter.getProcessDataConditionNameFromValue', getProcessDataConditionNameFromValue)

---@param conditionName string Name of the process data structure option.
---@return string conditionValue Value of the parameter.
local function getProcessDataConditionValueFromName(conditionName)
  return ioddInterpreter_Model.parameters.instances[selectedInstance].iodd:getProcessDataConditionValueFromName(conditionName)
end
Script.serveFunction('CSK_IODDInterpreter.getProcessDataConditionValueFromName', getProcessDataConditionValueFromName)

---@return string jsonProcessDataInInfo JSON object with description of process data in.
local function getProcessDataInInfo()
  local jsonProcessDataInInfo = json.encode(ioddInterpreter_Model.parameters.instances[selectedInstance].processDataInInfo)
  return jsonProcessDataInInfo
end
Script.serveFunction('CSK_IODDInterpreter.getProcessDataInInfo', getProcessDataInInfo)

---@return string jsonProcessDataOutInfo JSON object with description of process data out.
local function getProcessDataOutInfo()
  local jsonProcessDataOutInfo = json.encode(ioddInterpreter_Model.parameters.instances[selectedInstance].processDataOutInfo)
  return jsonProcessDataOutInfo
end
Script.serveFunction('CSK_IODDInterpreter.getProcessDataOutInfo', getProcessDataOutInfo)

---@param vendorId string 
---@param deviceId string 
---@return bool success 
local function loadIoddFromInternetWithReturn(vendorId, deviceId)
  local ioddFinderURL = "https://ioddfinder.io-link.com/api/ioddarchive?vendorId=%s&deviceId=%s&ioLinkRev=1.1&format=xml"
  local request = HTTPClient.Request.create()
  request:setMethod("GET")
  request:setURL(
    string.format(
      ioddFinderURL,
      tostring(vendorId),
      tostring(deviceId)
    )
  )
  request:addHeader("X-API-KEY", keyAPI)
  local client = HTTPClient.create()
  client:setHostnameVerification(false)
  client:setPeerVerification(false)
  local response = client:execute(request)
  local success = response:getSuccess()
  local statusCode = response:getStatusCode()
  if success and tostring(statusCode) == "200" then
    Script.notifyEvent('ioddInterpreter_announceNoInternetConnections', false)
    local ioddContent = response:getContent()
    local successLoad = ioddInterpreter_model:addIoddXmlString(ioddContent)
    handleOnExpiredTmr()
    return successLoad
  else
    Script.notifyEvent('ioddInterpreter_announceNoInternetConnections', true)
  end
  return false
end

--**************************************************************************
--*********************** End external use Scope ***************************
--**************************************************************************
-- *****************************************************************
-- Following function can be adapted for PersistentData module usage
-- *****************************************************************

--@setParameterName(name:string):
local function setParameterName(name)
  _G.logger:info(nameOfModule .. ": Set parameter name: " .. tostring(name))
  ioddInterpreter_Model.parametersName = name
end
Script.serveFunction("CSK_IODDInterpreter.setParameterName", setParameterName)

--@sendParameters():
local function sendParameters()
  if ioddInterpreter_Model.persistentModuleAvailable then
    CSK_PersistentData.addParameter(ioddInterpreter_Model.helperFuncs.convertTable2Container(ioddInterpreter_Model.parameters), ioddInterpreter_Model.parametersName)
    CSK_PersistentData.setModuleParameterName(nameOfModule, ioddInterpreter_Model.parametersName, ioddInterpreter_Model.parameterLoadOnReboot)
    _G.logger:info(nameOfModule .. ": Send IODDInterpreter parameters with name '" .. ioddInterpreter_Model.parametersName .. "' to PersistentData module.")
    CSK_PersistentData.saveData()
  else
    _G.logger:warning(nameOfModule .. ": PersistentData Module not available.")
  end
end
Script.serveFunction("CSK_IODDInterpreter.sendParameters", sendParameters)

--@loadParameters():
local function loadParameters()
  if ioddInterpreter_Model.persistentModuleAvailable then
    local data = CSK_PersistentData.getParameter(ioddInterpreter_Model.parametersName)
    if data then
      _G.logger:info(nameOfModule .. ": Loaded parameters from PersistentData module.")
      local parameterSet = ioddInterpreter_Model.helperFuncs.convertContainer2Table(data)
      for instanceId, instanceInfo in pairs(parameterSet.instances) do
        ioddInterpreter_Model.parameters.instances[instanceId] = {}
        ioddInterpreter_Model.loadIodd(instanceId, instanceInfo.ioddName)
        if instanceInfo.IsProcessDataStructureVariable then
          ioddInterpreter_Model.changeProcessDataStructureOptionValue(instanceId, instanceInfo.currentProcessDataConditionValue)
        end
        for instanceParameter, instanceParameterInfo in pairs(instanceInfo) do
            --print(json.encode(currentInstance.allReadParameterInfo))
            --print(json.encode(currentInstance.selectedReadParameters))
          if instanceParameter ~= 'iodd' then
            ioddInterpreter_Model.parameters.instances[instanceId][instanceParameter] = instanceParameterInfo
            --print(instanceParameter)
          end
        end
      end
      -- If something needs to be configured/activated with new loaded data, place this here:
      -- ...
      -- ...

      CSK_IODDInterpreter.pageCalledInstances()
    else
      _G.logger:warning(nameOfModule .. ": Loading parameters from PersistentData module did not work.")
    end
  else
    _G.logger:warning(nameOfModule .. ": PersistentData Module not available.")
  end
end
Script.serveFunction("CSK_IODDInterpreter.loadParameters", loadParameters)

--@setLoadOnReboot(status:bool):
local function setLoadOnReboot(status)
  ioddInterpreter_Model.parameterLoadOnReboot = status
  _G.logger:info(nameOfModule .. ": Set new status to load setting on reboot: " .. tostring(status))
end
Script.serveFunction("CSK_IODDInterpreter.setLoadOnReboot", setLoadOnReboot)

--@handleOnInitialDataLoaded()
local function handleOnInitialDataLoaded()

  if string.sub(CSK_PersistentData.getVersion(), 1, 1) == '1' then

    _G.logger:warning(nameOfModule .. ': CSK_PersistentData module is too old and will not work. Please update CSK_PersistentData module.')

    ioddInterpreter_Model.persistentModuleAvailable = false
  else

    local parameterName, loadOnReboot = CSK_PersistentData.getModuleParameterName(nameOfModule)

    if parameterName then
      ioddInterpreter_Model.parametersName = parameterName
      ioddInterpreter_Model.parameterLoadOnReboot = loadOnReboot
    end

    if ioddInterpreter_Model.parameterLoadOnReboot then
      loadParameters()
    end
    Script.notifyEvent('IODDInterpreter_OnDataLoadedOnReboot')
  end
end
Script.register("CSK_PersistentData.OnInitialDataLoaded", handleOnInitialDataLoaded)

-- *************************************************
-- END of functions for PersistentData module usage
-- *************************************************

return setIODDInterpreter_Model_Handle

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************

