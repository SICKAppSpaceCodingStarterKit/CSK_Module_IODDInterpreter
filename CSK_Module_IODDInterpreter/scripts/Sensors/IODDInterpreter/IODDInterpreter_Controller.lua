---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter

--***************************************************************
-- Inside of this script, you will find the necessary functions,
-- variables and events to communicate with the IODDInterpreter_Model
--***************************************************************

--**************************************************************************
--************************ Start Global Scope ******************************
--**************************************************************************
local nameOfModule = 'CSK_IODDInterpreter'

-- Reference to global handle
local ioddInterpreter_Model

local selectedIODDToHandle = '' -- IODD file that is selected in UI to be deleted
local currentCalloutType = 'info' -- Type of the status callot in UI
local currentCalloutValue = 'Application started' -- Callout message to be shown in UI
local selectedInstance = '' -- Current selected instance

-- Timer to update UI via events after page was loaded
local tmrInstances = Timer.create()
tmrInstances:setExpirationTime(300)
tmrInstances:setPeriodic(false)

--************************** Read Data Scope *******************************
local readPreficesToInclude = {"read_"} -- prefix to be included in colum names of dynamic table content for read data

-- Timer to update UI via events after page was loaded
local tmrReadData = Timer.create()
tmrReadData:setExpirationTime(1000)
tmrReadData:setPeriodic(false)

--*************************** Write Data Scope *****************************
local writePreficesToInclude = {"write_"} -- prefix to be included in colum names of dynamic table content for write data

-- Timer to update UI via events after page was loaded
local tmrWriteData = Timer.create()
tmrWriteData:setExpirationTime(1000)
tmrWriteData:setPeriodic(false)

-- ************************ UI Events Start ********************************

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

--********************** IODDs and Instances Scope *************************
Script.serveEvent('CSK_IODDInterpreter.OnIODDListChanged', 'IODDInterpreter_OnIODDListChanged')
Script.serveEvent('CSK_IODDInterpreter.OnNewCalloutValue', 'IODDInterpreter_OnNewCalloutValue')
Script.serveEvent('CSK_IODDInterpreter.OnNewCalloutType', 'IODDInterpreter_OnNewCalloutType')
Script.serveEvent('CSK_IODDInterpreter.OnNewListIODD', 'IODDInterpreter_OnNewListIODD')
Script.serveEvent('CSK_IODDInterpreter.OnNewSelectedIODD', 'IODDInterpreter_OnNewSelectedIODD')
Script.serveEvent('CSK_IODDInterpreter.OnNewListIntances', 'IODDInterpreter_OnNewListIntances')
Script.serveEvent('CSK_IODDInterpreter.OnNewSelectedInstance', 'IODDInterpreter_OnNewSelectedInstance')
Script.serveEvent('CSK_IODDInterpreter.isInstanceSelected', 'IODDInterpreter_isInstanceSelected')
Script.serveEvent('CSK_IODDInterpreter.OnNewInstanceName', 'IODDInterpreter_OnNewInstanceName')
Script.serveEvent('CSK_IODDInterpreter.OnNewSelectedIODDToHandle', 'IODDInterpreter_OnNewSelectedIODDToHandle')

--**************************** Data Scope **********************************
Script.serveEvent('CSK_IODDInterpreter.OnNewProcessDataStructureOptionsDropdownContent', 'IODDInterpreter_OnNewProcessDataStructureOptionsDropdownContent')
Script.serveEvent('CSK_IODDInterpreter.OnNewSelectedProcessDataStructureOption', 'IODDInterpreter_OnNewSelectedProcessDataStructureOption')
Script.serveEvent('CSK_IODDInterpreter.isProcessDataStructureVariable', 'IODDInterpreter_isProcessDataStructureVariable')

--************************** Read Data Scope *******************************
Script.serveEvent('CSK_IODDInterpreter.OnNewProcessDataInTableContent', 'IODDInterpreter_OnNewProcessDataInTableContent')
Script.serveEvent('CSK_IODDInterpreter.OnNewReadParametersTableContent', 'IODDInterpreter_OnNewReadParametersTableContent')

--*************************** Write Data Scope *****************************
Script.serveEvent('CSK_IODDInterpreter.OnNewProcessDataOutTableContent', 'IODDInterpreter_OnNewProcessDataOutTableContent')
Script.serveEvent('CSK_IODDInterpreter.OnNewWriteParametersTableContent', 'IODDInterpreter_OnNewWriteParametersTableContent')

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

--- Function to get access to the ioddInterpreter_Model object
---@param handle handle Handle of ioddInterpreter_Model object
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

--- Function to update user levels
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

--- Function to send all relevant values to UI on resume
local function handleOnExpiredTmrInstances()
  Script.notifyEvent('IODDInterpreter_OnNewCalloutType', currentCalloutType)
  Script.notifyEvent('IODDInterpreter_OnNewCalloutValue', currentCalloutValue)
  Script.notifyEvent("IODDInterpreter_OnNewListIODD", ioddInterpreter_Model.json.encode(ioddInterpreter_Model.availableIODDs))
  Script.notifyEvent("IODDInterpreter_OnNewSelectedIODDToHandle", ioddInterpreter_Model.json.encode(selectedIODDToHandle))
  Script.notifyEvent("IODDInterpreter_OnPersistentDataModuleAvailable", (CSK_PersistentData ~= nil))
  Script.notifyEvent("IODDInterpreter_OnNewStatusLoadParameterOnReboot", ioddInterpreter_Model.parameterLoadOnReboot)
  Script.notifyEvent("IODDInterpreter_OnNewParameterName", ioddInterpreter_Model.parametersName)
  local instancesList = {}
  for instanceId, _ in pairs(ioddInterpreter_Model.parameters.instances) do
    table.insert(instancesList, instanceId)
  end
  table.sort(instancesList)
  Script.notifyEvent("IODDInterpreter_OnNewListIntances", ioddInterpreter_Model.json.encode(instancesList))
  Script.notifyEvent("IODDInterpreter_OnNewSelectedInstance", selectedInstance)
  local isSelected = (selectedInstance ~= '')
  Script.notifyEvent("IODDInterpreter_isInstanceSelected", isSelected)
  if isSelected then
    Script.notifyEvent("IODDInterpreter_OnNewInstanceName", selectedInstance)
    if ioddInterpreter_Model.parameters.instances[selectedInstance].ioddName then
      Script.notifyEvent("IODDInterpreter_OnNewSelectedIODD", ioddInterpreter_Model.parameters.instances[selectedInstance].ioddName)
    end
  end
end
Timer.register(tmrInstances, "OnExpired", handleOnExpiredTmrInstances)

local function pageCalledInstances()
  updateUserLevel() -- try to hide user specific content asap
  tmrInstances:start()
  return ''
end
Script.serveFunction("CSK_IODDInterpreter.pageCalledInstances", pageCalledInstances)

local function addIODDFile(path)
  local success, result = ioddInterpreter_Model.addNewIODDfile(path)
  if success then
    Script.notifyEvent('IODDInterpreter_OnIODDListChanged')
  end
  return success, result
end
Script.serveFunction('CSK_IODDInterpreter.addIODDFile', addIODDFile)

local function uploadFinished(uploadSuccess)
  currentCalloutType ='error'
  currentCalloutValue = 'Failed to upload IODD XML file'
  if uploadSuccess then
    local tempFilePath = 'public/tempIODD.xml'
    local interpretationSuccess, result = addIODDFile(tempFilePath)
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

local function setInstanceName(newInstanceName)
  ioddInterpreter_Model.parameters.instances[newInstanceName] = ioddInterpreter_Model.helperFuncs.copy(ioddInterpreter_Model.parameters.instances[selectedInstance])
  ioddInterpreter_Model.parameters.instances[selectedInstance] = nil
  selectedInstance = newInstanceName
  handleOnExpiredTmrInstances()
end
Script.serveFunction('CSK_IODDInterpreter.setInstanceName', setInstanceName)

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

local function setSelectedIODD(ioddName)
  ioddInterpreter_Model.loadIODD(selectedInstance, ioddName)
  handleOnExpiredTmrInstances()
end
Script.serveFunction('CSK_IODDInterpreter.setSelectedIODD', setSelectedIODD)

local function setSelectedIODDToHandle(newSelectedIODDToHandle)
  selectedIODDToHandle = newSelectedIODDToHandle
end
Script.serveFunction('CSK_IODDInterpreter.setSelectedIODDToHandle', setSelectedIODDToHandle)

local function deleteIODD()
  if selectedIODDToHandle == '' then
    currentCalloutType = 'error'
    currentCalloutValue = 'Select file to delete'
    handleOnExpiredTmrInstances()
    return false, currentCalloutValue
  end
  for instanceId, instanceInfo in pairs(ioddInterpreter_Model.parameters.instances) do
    if instanceInfo.ioddName == selectedIODDToHandle then
      setSelectedInstance(instanceId)
      deleteInstance()
    end
  end
  setSelectedInstance('')
  ioddInterpreter_Model.deleteIODDFile(selectedIODDToHandle)
  currentCalloutType = 'success'
  currentCalloutValue = 'Deleted IODD ' .. selectedIODDToHandle
  selectedIODDToHandle = ''
  Script.notifyEvent('IODDInterpreter_OnIODDListChanged')
  handleOnExpiredTmrInstances()
  return true, 'SUCCESS'
end
Script.serveFunction('CSK_IODDInterpreter.deleteIODD', deleteIODD)

--**************************************************************************
--******************** End IODDs and Instances Scope ***********************
--**************************************************************************
--************************* Start Data Scope *******************************
--**************************************************************************

local function updateSelectedProcessDataTable(jsonSelectedRow, jsonSelectedProcessDataTable)
  local selectedProcessDataTable = ioddInterpreter_Model.json.decode(jsonSelectedProcessDataTable)
  local selectedRow = ioddInterpreter_Model.json.decode(jsonSelectedRow)
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
  return ioddInterpreter_Model.json.encode(selectedProcessDataTable)
end
Script.serveFunction('CSK_IODDInterpreter.updateSelectedProcessDataTable', updateSelectedProcessDataTable)

local function updateSelectedParametersTable(jsonSelectedRow, jsonSelectedParametersTable)
  local selectedParametersTable = ioddInterpreter_Model.json.decode(jsonSelectedParametersTable)
  local selectedRow = ioddInterpreter_Model.json.decode(jsonSelectedRow)
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
  return ioddInterpreter_Model.json.encode(selectedParametersTable)
end
Script.serveFunction('CSK_IODDInterpreter.updateSelectedParametersTable', updateSelectedParametersTable)

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
  local jsonDataPointInfo = ioddInterpreter_Model.json.encode(dataPointInfo)
  return jsonDataPointInfo
end
Script.serveFunction('CSK_IODDInterpreter.getParameterDataPointInfo', getParameterDataPointInfo)

--**************************************************************************
--*********************** Start Read Data Scope ****************************
--**************************************************************************

--- Function to send all relevant values to UI on resume
local function handleOnExpiredTmrReadData()
  Script.notifyEvent("IODDInterpreter_OnNewSelectedInstance", selectedInstance)
  local isSelected = (selectedInstance ~= '')
  Script.notifyEvent("IODDInterpreter_isInstanceSelected", isSelected)
  if isSelected and ioddInterpreter_Model.parameters.instances[selectedInstance].ioddName ~= nil then
    local currentInstance = ioddInterpreter_Model.parameters.instances[selectedInstance]
    local isProcessDataStructureVariable = currentInstance.IsProcessDataStructureVariable

    Script.notifyEvent("IODDInterpreter_isProcessDataStructureVariable", isProcessDataStructureVariable)
    if isProcessDataStructureVariable then
      Script.notifyEvent('IODDInterpreter_OnNewProcessDataStructureOptionsDropdownContent', ioddInterpreter_Model.json.encode(currentInstance.processDataConditionList))
      Script.notifyEvent('IODDInterpreter_OnNewSelectedProcessDataStructureOption', currentInstance.currentProcessDataConditionName)
    end
    Script.notifyEvent('IODDInterpreter_OnNewProcessDataInTableContent',
      ioddInterpreter_Model.dynamicTableHelper.makeProcessDataTableContent(
        readPreficesToInclude,
        currentInstance.processDataInInfo,
        currentInstance.selectedProcessDataIn
      )
    )
    Script.notifyEvent('IODDInterpreter_OnNewReadParametersTableContent',
      ioddInterpreter_Model.dynamicTableHelper.makeIODDParameterTableContent(
        readPreficesToInclude,
        currentInstance.allReadParameterInfo,
        currentInstance.selectedReadParameters
      )
    )
  end
end
Timer.register(tmrReadData, "OnExpired", handleOnExpiredTmrReadData)

local function pageCalledReadData()
  updateUserLevel() -- try to hide user specific content asap
  tmrReadData:start()
  return ''
end
Script.serveFunction('CSK_IODDInterpreter.pageCalledReadData', pageCalledReadData)

local function setReadSelectedData(jsonReadDataInfo)
  local readDataInfo = ioddInterpreter_Model.json.decode(jsonReadDataInfo)
  for subindex, _ in pairs(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataIn) do
    ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataIn[subindex] = false
  end
  if readDataInfo.ProcessData then
    for _, processDatainfo in pairs(readDataInfo.ProcessData) do
      if processDatainfo.Datatype.type == "ArrayT" or processDatainfo.Datatype.type == "RecordT" then
        for _, dataPointInfo in pairs(processDatainfo.Datatype.RecordItem) do
          ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataIn[dataPointInfo.subindex] = true
        end
        if ioddInterpreter_Model.helperFuncs.getTableSize(processDatainfo.Datatype.RecordItem) == ioddInterpreter_Model.helperFuncs.getTableSize(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataIn) - 2 then
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

local function processDataInRowSelected(jsonSelectedRow)
  jsonSelectedRow = ioddInterpreter_Model.dynamicTableHelper.removePrefixFromColumnNames(jsonSelectedRow, readPreficesToInclude[1])
  ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataIn = ioddInterpreter_Model.json.decode(
    updateSelectedProcessDataTable(
      jsonSelectedRow,
      ioddInterpreter_Model.json.encode(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataIn)
    )
  )
  handleOnExpiredTmrReadData()
  local jsonTemplate, jsonDataInfo = ioddInterpreter_Model.getReadDataJsonTemplateAndInfo(selectedInstance)
  Script.notifyEvent('IODDInterpreter_OnNewReadDataJsonTemplateAndInfo', selectedInstance, jsonTemplate, jsonDataInfo)
end
Script.serveFunction('CSK_IODDInterpreter.processDataInRowSelected', processDataInRowSelected)

local function readParameterRowSelected(jsonSelectedRow)
  jsonSelectedRow = ioddInterpreter_Model.dynamicTableHelper.removePrefixFromColumnNames(jsonSelectedRow, readPreficesToInclude[1])
  ioddInterpreter_Model.parameters.instances[selectedInstance].selectedReadParameters = ioddInterpreter_Model.json.decode(
    updateSelectedParametersTable(
      jsonSelectedRow,
      ioddInterpreter_Model.json.encode(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedReadParameters)
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

-- Function to send all relevant values to UI on resume
local function handleOnExpiredTmrWriteData()
  Script.notifyEvent("IODDInterpreter_OnNewSelectedInstance", selectedInstance)
  local isSelected = (selectedInstance ~= '')
  Script.notifyEvent("IODDInterpreter_isInstanceSelected", isSelected)
  if isSelected and ioddInterpreter_Model.parameters.instances[selectedInstance].ioddName ~= nil then
    local currentInstance = ioddInterpreter_Model.parameters.instances[selectedInstance]
    local isProcessDataStructureVariable = currentInstance.IsProcessDataStructureVariable
    Script.notifyEvent("IODDInterpreter_isProcessDataStructureVariable", isProcessDataStructureVariable)
    if isProcessDataStructureVariable then
      Script.notifyEvent('IODDInterpreter_OnNewProcessDataStructureOptionsDropdownContent', ioddInterpreter_Model.json.encode(currentInstance.processDataConditionList))
      Script.notifyEvent('IODDInterpreter_OnNewSelectedProcessDataStructureOption', currentInstance.currentProcessDataConditionName)
    end
    Script.notifyEvent('IODDInterpreter_OnNewProcessDataOutTableContent',
      ioddInterpreter_Model.dynamicTableHelper.makeProcessDataTableContent(
        writePreficesToInclude,
        currentInstance.processDataOutInfo,
        currentInstance.selectedProcessDataOut
      )
    )
    Script.notifyEvent('IODDInterpreter_OnNewWriteParametersTableContent',
      ioddInterpreter_Model.dynamicTableHelper.makeIODDParameterTableContent(
        writePreficesToInclude,
        currentInstance.allWriteParameterInfo,
        currentInstance.selectedWriteParameters
      )
    )
  end
end
Timer.register(tmrWriteData, "OnExpired", handleOnExpiredTmrWriteData)

local function pageCalledWriteData()
  updateUserLevel() -- try to hide user specific content asap
  tmrWriteData:start()
  return ''
end
Script.serveFunction('CSK_IODDInterpreter.pageCalledWriteData', pageCalledWriteData)

local function setWriteSelectedData(jsonWriteDataInfo)
  local writeDataInfo = ioddInterpreter_Model.json.decode(jsonWriteDataInfo)
  for subindex, _ in pairs(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataOut) do
    ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataOut[subindex] = false
  end
  if writeDataInfo.ProcessData then
    for _, processDatainfo in pairs(writeDataInfo.ProcessData) do
      if processDatainfo.Datatype.type == "ArrayT" or processDatainfo.Datatype.type == "RecordT" then
        for _, dataPointInfo in pairs(processDatainfo.Datatype.RecordItem) do
          ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataOut[dataPointInfo.subindex] = true
        end
        if ioddInterpreter_Model.helperFuncs.getTableSize(processDatainfo.Datatype.RecordItem) == ioddInterpreter_Model.helperFuncs.getTableSize(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataOut) - 2 then
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

local function processDataOutRowSelected(jsonSelectedRow)
  jsonSelectedRow = ioddInterpreter_Model.dynamicTableHelper.removePrefixFromColumnNames(jsonSelectedRow, writePreficesToInclude[1])
  ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataOut = ioddInterpreter_Model.json.decode(
    updateSelectedProcessDataTable(
      jsonSelectedRow,
      ioddInterpreter_Model.json.encode(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataOut)
    )
  )
  handleOnExpiredTmrWriteData()
  local jsonTemplate, jsonDataIndo = ioddInterpreter_Model.getWriteDataJsonTemplateAndInfo(selectedInstance)
  Script.notifyEvent('IODDInterpreter_OnNewWriteDataJsonTemplateAndInfo', selectedInstance, jsonTemplate, jsonDataIndo)
end
Script.serveFunction('CSK_IODDInterpreter.processDataOutRowSelected', processDataOutRowSelected)

local function writeParameterRowSelected(jsonSelectedRow)
  jsonSelectedRow = ioddInterpreter_Model.dynamicTableHelper.removePrefixFromColumnNames(jsonSelectedRow, writePreficesToInclude[1])
  ioddInterpreter_Model.parameters.instances[selectedInstance].selectedWriteParameters = ioddInterpreter_Model.json.decode(
    updateSelectedParametersTable(
      jsonSelectedRow,
      ioddInterpreter_Model.json.encode(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedWriteParameters)
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

local function getIODDList()
  return ioddInterpreter_Model.availableIODDs
end
Script.serveFunction('CSK_IODDInterpreter.getIODDList', getIODDList)

local function getSelectedProcessDataIn()
  if not ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataIn then
    return nil
  end
  return ioddInterpreter_Model.json.encode(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataIn)
end
Script.serveFunction('CSK_IODDInterpreter.getSelectedProcessDataIn', getSelectedProcessDataIn)

local function getSelectedProcessDataOut()
  if not ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataOut then
    return nil
  end
  return ioddInterpreter_Model.json.encode(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataOut)
end
Script.serveFunction('CSK_IODDInterpreter.getSelectedProcessDataOut', getSelectedProcessDataOut)

local function getSelectedReadParameters()
  if not ioddInterpreter_Model.parameters.instances[selectedInstance].selectedReadParameters then
    return nil
  end
  return ioddInterpreter_Model.json.encode(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedReadParameters)
end
Script.serveFunction('CSK_IODDInterpreter.getSelectedReadParameters', getSelectedReadParameters)

local function getSelectedWriteParameters()
  if not ioddInterpreter_Model.parameters.instances[selectedInstance].selectedWriteParameters then
    return nil
  end
  return ioddInterpreter_Model.json.encode(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedWriteParameters)
end
Script.serveFunction('CSK_IODDInterpreter.getSelectedWriteParameters', getSelectedWriteParameters)

local function findIODDMatchingVendorIdDeviceIdVersion(vendorId, deviceId, version)
  local success, result =  ioddInterpreter_Model.checkVendorIdDeviceIdVersionMatchIODD(tostring(vendorId), tostring(deviceId), version)
  return success, result
end
Script.serveFunction('CSK_IODDInterpreter.findIODDMatchingVendorIdDeviceIdVersion', findIODDMatchingVendorIdDeviceIdVersion)

local function findIODDMatchingProductName(productName)
  local success, result =  ioddInterpreter_Model.checkProductNameMatchIODD(productName)
  return success, result
end
Script.serveFunction('CSK_IODDInterpreter.findIODDMatchingProductName', findIODDMatchingProductName)

local function getIODDFilesStorage()
  return ioddInterpreter_Model.ioddFilesStorage
end
Script.serveFunction('CSK_IODDInterpreter.getIODDFilesStorage', getIODDFilesStorage)

local function getIsProcessDataVariable()
  return ioddInterpreter_Model.parameters.instances[selectedInstance].iodd.IsProcessDataStructureVariable
end
Script.serveFunction('CSK_IODDInterpreter.getIsProcessDataVariable', getIsProcessDataVariable)

local function getProcessDataConditionInfo()
  local jsonProcessDataConditionInfo = ioddInterpreter_Model.json.encode(ioddInterpreter_Model.parameters.instances[selectedInstance].iodd.ProcessDataCondition)
  return jsonProcessDataConditionInfo
end
Script.serveFunction('CSK_IODDInterpreter.getProcessDataConditionInfo', getProcessDataConditionInfo)

local function getProcessDataConditionList()
  return ioddInterpreter_Model.json.encode(ioddInterpreter_Model.parameters.instances[selectedInstance].iodd:getProcessDataConditionList())
end
Script.serveFunction('CSK_IODDInterpreter.getProcessDataConditionList', getProcessDataConditionList)

local function getProcessDataConditionNameFromValue(conditionValue)
  return ioddInterpreter_Model.parameters.instances[selectedInstance].iodd:getProcessDataConditionNameFromValue(conditionValue)
end
Script.serveFunction('CSK_IODDInterpreter.getProcessDataConditionNameFromValue', getProcessDataConditionNameFromValue)

local function getProcessDataConditionValueFromName(conditionName)
  return ioddInterpreter_Model.parameters.instances[selectedInstance].iodd:getProcessDataConditionValueFromName(conditionName)
end
Script.serveFunction('CSK_IODDInterpreter.getProcessDataConditionValueFromName', getProcessDataConditionValueFromName)

local function getProcessDataInInfo()
  local jsonProcessDataInInfo = ioddInterpreter_Model.json.encode(ioddInterpreter_Model.parameters.instances[selectedInstance].processDataInInfo)
  return jsonProcessDataInInfo
end
Script.serveFunction('CSK_IODDInterpreter.getProcessDataInInfo', getProcessDataInInfo)

local function getProcessDataOutInfo()
  local jsonProcessDataOutInfo = ioddInterpreter_Model.json.encode(ioddInterpreter_Model.parameters.instances[selectedInstance].processDataOutInfo)
  return jsonProcessDataOutInfo
end
Script.serveFunction('CSK_IODDInterpreter.getProcessDataOutInfo', getProcessDataOutInfo)

--**************************************************************************
--*********************** End external use Scope ***************************
--**************************************************************************
-- *****************************************************************
-- Following function can be adapted for CSK_PersistentData module usage
-- *****************************************************************

local function setParameterName(name)
  _G.logger:info(nameOfModule .. ": Set parameter name: " .. tostring(name))
  ioddInterpreter_Model.parametersName = name
end
Script.serveFunction("CSK_IODDInterpreter.setParameterName", setParameterName)

local function sendParameters()
  if ioddInterpreter_Model.persistentModuleAvailable then
    CSK_PersistentData.addParameter(ioddInterpreter_Model.ioddInterpreter_Model.helperFuncs.convertTable2Container(ioddInterpreter_Model.parameters), ioddInterpreter_Model.parametersName)
    CSK_PersistentData.setModuleParameterName(nameOfModule, ioddInterpreter_Model.parametersName, ioddInterpreter_Model.parameterLoadOnReboot)
    _G.logger:info(nameOfModule .. ": Send IODDInterpreter parameters with name '" .. ioddInterpreter_Model.parametersName .. "' to CSK_PersistentData module.")
    CSK_PersistentData.saveData()
  else
    _G.logger:warning(nameOfModule .. ": CSK_PersistentData module not available.")
  end
end
Script.serveFunction("CSK_IODDInterpreter.sendParameters", sendParameters)

local function loadParameters()
  if ioddInterpreter_Model.persistentModuleAvailable then
    local data = CSK_PersistentData.getParameter(ioddInterpreter_Model.parametersName)
    if data then
      _G.logger:info(nameOfModule .. ": Loaded parameters from CSK_PersistentData module.")
      local parameterSet = ioddInterpreter_Model.ioddInterpreter_Model.helperFuncs.convertContainer2Table(data)
      for instanceId, instanceInfo in pairs(parameterSet.instances) do
        ioddInterpreter_Model.parameters.instances[instanceId] = {}
        ioddInterpreter_Model.loadIODD(instanceId, instanceInfo.ioddName)
        if instanceInfo.IsProcessDataStructureVariable then
          ioddInterpreter_Model.changeProcessDataStructureOptionValue(instanceId, instanceInfo.currentProcessDataConditionValue)
        end
        for instanceParameter, instanceParameterInfo in pairs(instanceInfo) do
          if instanceParameter ~= 'iodd' then
            ioddInterpreter_Model.parameters.instances[instanceId][instanceParameter] = instanceParameterInfo
          end
        end
      end

      CSK_IODDInterpreter.pageCalledInstances()
    else
      _G.logger:warning(nameOfModule .. ": Loading parameters from CSK_PersistentData module did not work.")
    end
  else
    _G.logger:warning(nameOfModule .. ": CSK_PersistentData Module not available.")
  end
end
Script.serveFunction("CSK_IODDInterpreter.loadParameters", loadParameters)

local function setLoadOnReboot(status)
  ioddInterpreter_Model.parameterLoadOnReboot = status
  _G.logger:info(nameOfModule .. ": Set new status to load setting on reboot: " .. tostring(status))
end
Script.serveFunction("CSK_IODDInterpreter.setLoadOnReboot", setLoadOnReboot)

--- Function to react on initial load of persistent parameters
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
-- END of functions for CSK_PersistentData module usage
-- *************************************************

return setIODDInterpreter_Model_Handle

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************

