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
local selectedInstance = '' -- Current selected instance+
local copyReadDataMessageContent -- temporary selected data copy to duplicate read messages between instances 
local copyWriteDataMessageContent -- temporary selected data copy to duplicate write messages between instances

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

Script.serveEvent('CSK_IODDInterpreter.OnNewStatusModuleVersion', 'IODDInterpreter_OnNewStatusModuleVersion')
Script.serveEvent('CSK_IODDInterpreter.OnNewStatusCSKStyle', 'IODDInterpreter_OnNewStatusCSKStyle')
Script.serveEvent('CSK_IODDInterpreter.OnNewStatusModuleIsActive', 'IODDInterpreter_OnNewStatusModuleIsActive')

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

  updateUserLevel()

  Script.notifyEvent("IODDInterpreter_OnNewStatusModuleVersion", ioddInterpreter_Model.version)
  Script.notifyEvent("IODDInterpreter_OnNewStatusCSKStyle", ioddInterpreter_Model.styleForUI)
  Script.notifyEvent("IODDInterpreter_OnNewStatusModuleIsActive", _G.availableAPIs.default)

  Script.notifyEvent('IODDInterpreter_OnNewCalloutType', currentCalloutType)
  Script.notifyEvent('IODDInterpreter_OnNewCalloutValue', currentCalloutValue)
  local availableList = {}
  for ioddName, _ in pairs(ioddInterpreter_Model.parameters.availableIODDs) do
    table.insert(availableList, ioddName)
  end
  Script.notifyEvent("IODDInterpreter_OnNewListIODD", ioddInterpreter_Model.json.encode(availableList))
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
    local ioddList = {}
    for ioddName in pairs(ioddInterpreter_Model.parameters.availableIODDs) do
      table.insert(ioddList, ioddName)
    end
    Script.notifyEvent('IODDInterpreter_OnIODDListChanged', ioddList)
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
  ioddInterpreter_Model.deactivateNotUsedActiveIodds()
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
  local ioddList = {}
  for ioddName in pairs(ioddInterpreter_Model.parameters.availableIODDs) do
    table.insert(ioddList, ioddName)
  end
  Script.notifyEvent('IODDInterpreter_OnIODDListChanged', ioddList)
  handleOnExpiredTmrInstances()
  return true, 'SUCCESS'
end
Script.serveFunction('CSK_IODDInterpreter.deleteIODD', deleteIODD)

--**************************************************************************
--******************** End IODDs and Instances Scope ***********************
--**************************************************************************
--************************* Start Data Scope *******************************
--**************************************************************************

local function updateSelectedProcessDataTable(selectedRow, selectedProcessDataTable)
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
end

local function updateSelectedParametersTable(selectedRow, selectedParametersTable)
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
end

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
  Script.notifyEvent("IODDInterpreter_OnNewStatusCSKStyle", ioddInterpreter_Model.styleForUI)
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
    local processDataInfo = currentInstance.iodd:getProcessDataInfo(currentInstance.currentProcessDataConditionValue)
    Script.notifyEvent('IODDInterpreter_OnNewProcessDataInTableContent',
      ioddInterpreter_Model.dynamicTableHelper.makeProcessDataTableContent(
        readPreficesToInclude,
        processDataInfo.ProcessDataIn,
        currentInstance.selectedProcessDataIn
      )
    )
    Script.notifyEvent('IODDInterpreter_OnNewReadParametersTableContent',
      ioddInterpreter_Model.dynamicTableHelper.makeIODDParameterTableContent(
        readPreficesToInclude,
        currentInstance.iodd:getAllReadParameterInfo(),
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

local function processDataInRowSelectedUI(jsonSelectedRow)
  updateSelectedProcessDataTable(
    ioddInterpreter_Model.dynamicTableHelper.removePrefixFromColumnNames(jsonSelectedRow, readPreficesToInclude[1]),
    ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataIn
  )
  handleOnExpiredTmrReadData()
end
Script.serveFunction('CSK_IODDInterpreter.processDataInRowSelectedUI', processDataInRowSelectedUI)

local function readParameterRowSelectedUI(jsonSelectedRow)
  updateSelectedParametersTable(
    ioddInterpreter_Model.dynamicTableHelper.removePrefixFromColumnNames(jsonSelectedRow, readPreficesToInclude[1]),
    ioddInterpreter_Model.parameters.instances[selectedInstance].selectedReadParameters
  )
  handleOnExpiredTmrReadData()
end
Script.serveFunction('CSK_IODDInterpreter.readParameterRowSelectedUI', readParameterRowSelectedUI)

--**************************************************************************
--************************* End Read Data Scope ****************************
--**************************************************************************
--************************ Start Write Data Scope **************************
--**************************************************************************

-- Function to send all relevant values to UI on resume
local function handleOnExpiredTmrWriteData()
  Script.notifyEvent("IODDInterpreter_OnNewStatusCSKStyle", ioddInterpreter_Model.styleForUI)
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
    local processDataInfo = currentInstance.iodd:getProcessDataInfo(currentInstance.currentProcessDataConditionValue)
    Script.notifyEvent('IODDInterpreter_OnNewProcessDataOutTableContent',
      ioddInterpreter_Model.dynamicTableHelper.makeProcessDataTableContent(
        writePreficesToInclude,
        processDataInfo.ProcessDataOut,
        currentInstance.selectedProcessDataOut
      )
    )
    Script.notifyEvent('IODDInterpreter_OnNewWriteParametersTableContent',
      ioddInterpreter_Model.dynamicTableHelper.makeIODDParameterTableContent(
        writePreficesToInclude,
        currentInstance.iodd:getAllWriteParameterInfo(),
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

local function processDataOutRowSelectedUI(jsonSelectedRow)
  updateSelectedProcessDataTable(
    ioddInterpreter_Model.dynamicTableHelper.removePrefixFromColumnNames(jsonSelectedRow, writePreficesToInclude[1]),
    ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataOut
  )
  handleOnExpiredTmrWriteData()
end
Script.serveFunction('CSK_IODDInterpreter.processDataOutRowSelectedUI', processDataOutRowSelectedUI)

local function writeParameterRowSelectedUI(jsonSelectedRow)
  updateSelectedParametersTable(
    ioddInterpreter_Model.dynamicTableHelper.removePrefixFromColumnNames(jsonSelectedRow, writePreficesToInclude[1]),
    ioddInterpreter_Model.parameters.instances[selectedInstance].selectedWriteParameters
  )
  handleOnExpiredTmrWriteData()
end
Script.serveFunction('CSK_IODDInterpreter.writeParameterRowSelectedUI', writeParameterRowSelectedUI)

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
  local availableList = {}
  for ioddName, _ in pairs(ioddInterpreter_Model.parameters.availableIODDs) do
    table.insert(availableList, ioddName)
  end
  return availableList
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


local function processDataInRowSelected(jsonSelectedRow, prefix)
  updateSelectedProcessDataTable(
    ioddInterpreter_Model.dynamicTableHelper.removePrefixFromColumnNames(jsonSelectedRow, prefix),
    ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataIn
  )
  local jsonTemplate, jsonDataInfo = ioddInterpreter_Model.getReadDataJsonTemplateAndInfo(selectedInstance)
  print(jsonDataInfo)
  return jsonTemplate, jsonDataInfo
end
Script.serveFunction('CSK_IODDInterpreter.processDataInRowSelected', processDataInRowSelected)

local function processDataOutRowSelected(jsonSelectedRow, prefix)
  updateSelectedProcessDataTable(
    ioddInterpreter_Model.dynamicTableHelper.removePrefixFromColumnNames(jsonSelectedRow, prefix),
    ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataOut
  )
  local jsonTemplate, jsonDataInfo = ioddInterpreter_Model.getWriteDataJsonTemplateAndInfo(selectedInstance)
  return jsonTemplate, jsonDataInfo
end
Script.serveFunction('CSK_IODDInterpreter.processDataOutRowSelected', processDataOutRowSelected)

local function readParameterRowSelected(jsonSelectedRow, prefix)
  updateSelectedParametersTable(
    ioddInterpreter_Model.dynamicTableHelper.removePrefixFromColumnNames(jsonSelectedRow, prefix),
    ioddInterpreter_Model.parameters.instances[selectedInstance].selectedReadParameters
  )
  local jsonTemplate, jsonDataInfo = ioddInterpreter_Model.getReadDataJsonTemplateAndInfo(selectedInstance)
  return jsonTemplate, jsonDataInfo
end
Script.serveFunction('CSK_IODDInterpreter.readParameterRowSelected', readParameterRowSelected)

local function writeParameterRowSelected(jsonSelectedRow, prefix)
  updateSelectedParametersTable(
    ioddInterpreter_Model.dynamicTableHelper.removePrefixFromColumnNames(jsonSelectedRow, prefix),
    ioddInterpreter_Model.parameters.instances[selectedInstance].selectedWriteParameters
  )
  local jsonTemplate, jsonDataInfo = ioddInterpreter_Model.getWriteDataJsonTemplateAndInfo(selectedInstance)
  return jsonTemplate, jsonDataInfo
end
Script.serveFunction('CSK_IODDInterpreter.writeParameterRowSelected', writeParameterRowSelected)

local function copyReadDataMessage()
  if not selectedInstance or not ioddInterpreter_Model.parameters.instances[selectedInstance] or not ioddInterpreter_Model.parameters.instances[selectedInstance].iodd then
    return
  end
  copyReadDataMessageContent = {}
  copyReadDataMessageContent.vendorId, copyReadDataMessageContent.deviceId = ioddInterpreter_Model.parameters.instances[selectedInstance].iodd:getVendorIdDeviceIdVersion()
  if ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataIn then
    copyReadDataMessageContent.selectedProcessDataIn = ioddInterpreter_Model.helperFuncs.copy(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataIn)
  end
  if ioddInterpreter_Model.parameters.instances[selectedInstance].selectedReadParameters then
    copyReadDataMessageContent.selectedReadParameters = ioddInterpreter_Model.helperFuncs.copy(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedReadParameters)
  end
end
Script.serveFunction('CSK_IODDInterpreter.copyReadDataMessage', copyReadDataMessage)

---@return string? jsonTemplate 
---@return string? jsonDataInfo 
local function pasteReadDataMessage()
  if not copyReadDataMessageContent or not selectedInstance or not ioddInterpreter_Model.parameters.instances[selectedInstance] or not ioddInterpreter_Model.parameters.instances[selectedInstance].iodd then
    return nil, nil
  end
  local vendorId, deviceId = ioddInterpreter_Model.parameters.instances[selectedInstance].iodd:getVendorIdDeviceIdVersion()
  if vendorId ~= copyReadDataMessageContent.vendorId or deviceId ~= copyReadDataMessageContent.deviceId then
    return nil, nil
  end
  if copyReadDataMessageContent.selectedProcessDataIn then
    ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataIn = ioddInterpreter_Model.helperFuncs.copy(copyReadDataMessageContent.selectedProcessDataIn)
  end
  if copyReadDataMessageContent.selectedReadParameters then
    ioddInterpreter_Model.parameters.instances[selectedInstance].selectedReadParameters = ioddInterpreter_Model.helperFuncs.copy(copyReadDataMessageContent.selectedReadParameters)
  end
  local jsonTemplate, jsonDataInfo = ioddInterpreter_Model.getReadDataJsonTemplateAndInfo(selectedInstance)
  return jsonTemplate, jsonDataInfo
end
Script.serveFunction('CSK_IODDInterpreter.pasteReadDataMessage', pasteReadDataMessage)

local function copyWriteDataMessage()
  if not selectedInstance or not ioddInterpreter_Model.parameters.instances[selectedInstance] or not ioddInterpreter_Model.parameters.instances[selectedInstance].iodd then
    return
  end
  copyWriteDataMessageContent = {}
  copyWriteDataMessageContent.vendorId, copyWriteDataMessageContent.deviceId = ioddInterpreter_Model.parameters.instances[selectedInstance].iodd:getVendorIdDeviceIdVersion()
  if ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataOut then
    copyWriteDataMessageContent.selectedProcessDataOut = ioddInterpreter_Model.helperFuncs.copy(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataOut)
  end
  if ioddInterpreter_Model.parameters.instances[selectedInstance].selectedWriteParameters then
    copyWriteDataMessageContent.selectedWriteParameters = ioddInterpreter_Model.helperFuncs.copy(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedWriteParameters)
  end
end
Script.serveFunction('CSK_IODDInterpreter.copyWriteDataMessage', copyWriteDataMessage)

local function pasteWriteDataMessage()
  if not copyWriteDataMessageContent or not selectedInstance or not ioddInterpreter_Model.parameters.instances[selectedInstance] or not ioddInterpreter_Model.parameters.instances[selectedInstance].iodd then
    return nil, nil
  end
  local vendorId, deviceId = ioddInterpreter_Model.parameters.instances[selectedInstance].iodd:getVendorIdDeviceIdVersion()
  if vendorId ~= copyWriteDataMessageContent.vendorId or deviceId ~= copyWriteDataMessageContent.deviceId then
    return nil, nil
  end
  if copyWriteDataMessageContent.selectedProcessDataOut then
    ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataOut = ioddInterpreter_Model.helperFuncs.copy(copyWriteDataMessageContent.selectedProcessDataOut)
  end
  if copyWriteDataMessageContent.selectedWriteParameters then
    ioddInterpreter_Model.parameters.instances[selectedInstance].selectedWriteParameters = ioddInterpreter_Model.helperFuncs.copy(copyWriteDataMessageContent.selectedWriteParameters)
  end
  local jsonTemplate, jsonDataInfo = ioddInterpreter_Model.getWriteDataJsonTemplateAndInfo(selectedInstance)
  return jsonTemplate, jsonDataInfo
end
Script.serveFunction('CSK_IODDInterpreter.pasteWriteDataMessage', pasteWriteDataMessage)


local function getReadDataTableContents(prefix)
  local currentInstance = ioddInterpreter_Model.parameters.instances[selectedInstance]
  local processDataInfo = currentInstance.iodd:getProcessDataInfo(currentInstance.currentProcessDataConditionValue)
  local processDataTableContent = ioddInterpreter_Model.dynamicTableHelper.makeProcessDataTableContent(
    {prefix},
    processDataInfo.ProcessDataIn,
    currentInstance.selectedProcessDataIn
  )
  local parameterTableContent = ioddInterpreter_Model.dynamicTableHelper.makeIODDParameterTableContent(
    {prefix},
    currentInstance.iodd:getAllReadParameterInfo(),
    currentInstance.selectedReadParameters
  )
  return processDataTableContent, parameterTableContent
end
Script.serveFunction('CSK_IODDInterpreter.getReadDataTableContents', getReadDataTableContents)

local function getWriteDataTableContents(prefix)
  local currentInstance = ioddInterpreter_Model.parameters.instances[selectedInstance]
  local processDataInfo = currentInstance.iodd:getProcessDataInfo(currentInstance.currentProcessDataConditionValue)
  local processDataTableContent = ioddInterpreter_Model.dynamicTableHelper.makeProcessDataTableContent(
    {prefix},
    processDataInfo.ProcessDataOut,
    currentInstance.selectedProcessDataOut
  )
  local parameterTableContent = ioddInterpreter_Model.dynamicTableHelper.makeIODDParameterTableContent(
    {prefix},
    currentInstance.iodd:getAllWriteParameterInfo(),
    currentInstance.selectedWriteParameters
  )
  return processDataTableContent, parameterTableContent
end
Script.serveFunction('CSK_IODDInterpreter.getWriteDataTableContents', getWriteDataTableContents)

local function selectAllProcessDataIn(state)
  for subIndex, _ in pairs(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataIn) do
    ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataIn[subIndex] = state
  end
  local jsonTemplate, jsonDataInfo = ioddInterpreter_Model.getReadDataJsonTemplateAndInfo(selectedInstance)
  return jsonTemplate, jsonDataInfo
end
Script.serveFunction('CSK_IODDInterpreter.selectAllProcessDataIn', selectAllProcessDataIn)

local function selectAllProcessDataOut(state)
  for subIndex, _ in pairs(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataOut) do
    ioddInterpreter_Model.parameters.instances[selectedInstance].selectedProcessDataOut[subIndex] = state
  end
  local jsonTemplate, jsonDataInfo = ioddInterpreter_Model.getReadDataJsonTemplateAndInfo(selectedInstance)
  return jsonTemplate, jsonDataInfo
end
Script.serveFunction('CSK_IODDInterpreter.selectAllProcessDataOut', selectAllProcessDataOut)

local function selectAllReadParameters(state)
  for index, indexInfo in pairs(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedReadParameters) do
    for subIndex, _ in pairs(indexInfo) do
      ioddInterpreter_Model.parameters.instances[selectedInstance].selectedReadParameters[index][subIndex] = state
    end
  end
  local jsonTemplate, jsonDataInfo = ioddInterpreter_Model.getReadDataJsonTemplateAndInfo(selectedInstance)
  return jsonTemplate, jsonDataInfo
end
Script.serveFunction('CSK_IODDInterpreter.selectAllReadParameters', selectAllReadParameters)

local function selectAllWriteParameters(state)
  for index, indexInfo in pairs(ioddInterpreter_Model.parameters.instances[selectedInstance].selectedWriteParameters) do
    for subIndex, _ in pairs(indexInfo) do
      ioddInterpreter_Model.parameters.instances[selectedInstance].selectedWriteParameters[index][subIndex] = state
    end
  end
  local jsonTemplate, jsonDataInfo = ioddInterpreter_Model.getWriteDataJsonTemplateAndInfo(selectedInstance)
  return jsonTemplate, jsonDataInfo
end
Script.serveFunction('CSK_IODDInterpreter.selectAllWriteParameters', selectAllWriteParameters)

local function copyInstanceSelectedTable(fromInstanceId, toInstanceId)
  ioddInterpreter_Model.parameters.instances[toInstanceId].selectedProcessDataIn = ioddInterpreter_Model.helperFuncs.copy(ioddInterpreter_Model.parameters.instances[fromInstanceId].selectedProcessDataIn)
  ioddInterpreter_Model.parameters.instances[toInstanceId].selectedProcessDataOut = ioddInterpreter_Model.helperFuncs.copy(ioddInterpreter_Model.parameters.instances[fromInstanceId].selectedProcessDataOut)
  ioddInterpreter_Model.parameters.instances[toInstanceId].selectedReadParameters = ioddInterpreter_Model.helperFuncs.copy(ioddInterpreter_Model.parameters.instances[fromInstanceId].selectedReadParameters)
  ioddInterpreter_Model.parameters.instances[toInstanceId].selectedWriteParameters = ioddInterpreter_Model.helperFuncs.copy(ioddInterpreter_Model.parameters.instances[fromInstanceId].selectedWriteParameters)
end
Script.serveFunction('CSK_IODDInterpreter.copyInstanceSelectedTable', copyInstanceSelectedTable)

local function getStatusModuleActive()
  return _G.availableAPIs.default
end
Script.serveFunction('CSK_IODDInterpreter.getStatusModuleActive', getStatusModuleActive)

local function getParameters()
  return ioddInterpreter_Model.json.encode(ioddInterpreter_Model.parameters)
end
Script.serveFunction('CSK_IODDInterpreter.getParameters', getParameters)

--**************************************************************************
--*********************** End external use Scope ***************************
--**************************************************************************
-- *****************************************************************
-- Following function can be adapted for CSK_PersistentData module usage
-- *****************************************************************

local function setParameterName(name)
  _G.logger:fine(nameOfModule .. ": Set parameter name: " .. tostring(name))
  ioddInterpreter_Model.parametersName = name
end
Script.serveFunction("CSK_IODDInterpreter.setParameterName", setParameterName)

local function sendInstancesListParameters(parameterName, instancesList)
  if ioddInterpreter_Model.persistentModuleAvailable then
    local parametersToSave =  ioddInterpreter_Model.helperFuncs.copy(ioddInterpreter_Model.parameters)
    parametersToSave.instances = nil
    local instancesToSave = {}
    for _,instanceId in ipairs(instancesList) do
      if not ioddInterpreter_Model.parameters.instances[instanceId] then
        goto nextInstance
      end
      instancesToSave[instanceId] = ioddInterpreter_Model.helperFuncs.copy(ioddInterpreter_Model.parameters.instances[instanceId])
      instancesToSave[instanceId].iodd = nil
      ::nextInstance::
    end
    parametersToSave.jsonInstances = ioddInterpreter_Model.json.encode(instancesToSave)
    local contTosave = ioddInterpreter_Model.helperFuncs.convertTable2Container(parametersToSave)
    CSK_PersistentData.addParameter(contTosave, parameterName)
  else
    _G.logger:warning(nameOfModule .. ": CSK_PersistentData module not available.")
  end
end
Script.serveFunction('CSK_IODDInterpreter.sendInstancesListParameters', sendInstancesListParameters)

local function loadInstancesListParameters(parameterName)
  ioddInterpreter_Model.updateAvailableIODDs()
  if ioddInterpreter_Model.persistentModuleAvailable then
    local data = CSK_PersistentData.getParameter(parameterName)
    if data then
      local parameterSet = ioddInterpreter_Model.helperFuncs.convertContainer2Table(data)
      local instances = ioddInterpreter_Model.json.decode(parameterSet.jsonInstances)
      for instanceId, instanceInfo in pairs(instances) do
        if ioddInterpreter_Model.parameters.availableIODDs[instanceInfo.ioddName] then
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
        else
          _G.logger:warning(nameOfModule .. ' instance ' .. instanceId .. ": Loading IODD file failed with name " .. tostring(instanceInfo.ioddName) .. ".")
        end
      end
      parameterSet = nil
      data = nil
    else
      _G.logger:warning(nameOfModule .. ' instance ' .. instanceId .. ": Loading parameters from CSK_PersistentData module did not work.")
    end
  else
    _G.logger:warning(nameOfModule .. ": CSK_PersistentData Module not available.")
  end
end
Script.serveFunction('CSK_IODDInterpreter.loadInstancesListParameters', loadInstancesListParameters)


local function sendParameters(noDataSave)
  if ioddInterpreter_Model.persistentModuleAvailable then
    local parametersToSave =  ioddInterpreter_Model.helperFuncs.copy(ioddInterpreter_Model.parameters)
    for instanceId, _ in pairs(parametersToSave.instances) do
      parametersToSave.instances[instanceId].iodd = nil
    end
    parametersToSave.jsonInstances = ioddInterpreter_Model.json.encode(parametersToSave.instances)
    parametersToSave.instances = nil

    CSK_PersistentData.addParameter(ioddInterpreter_Model.helperFuncs.convertTable2Container(parametersToSave), ioddInterpreter_Model.parametersName)
    CSK_PersistentData.setModuleParameterName(nameOfModule, ioddInterpreter_Model.parametersName, ioddInterpreter_Model.parameterLoadOnReboot)
    _G.logger:fine(nameOfModule .. ": Send IODDInterpreter parameters with name '" .. ioddInterpreter_Model.parametersName .. "' to CSK_PersistentData module.")
    if not noDataSave then
      CSK_PersistentData.saveData()
    end
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
      local parameterSet = ioddInterpreter_Model.helperFuncs.convertContainer2Table(data)
      ioddInterpreter_Model.parameters.availableIODDs = parameterSet.availableIODDs
      parameterSet.instances = ioddInterpreter_Model.json.decode(parameterSet.jsonInstances)
      parameterSet.jsonInstances = nil
      ioddInterpreter_Model.updateAvailableIODDs()
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
      return true
    else
      ioddInterpreter_Model.updateAvailableIODDs()
      _G.logger:warning(nameOfModule .. ": Loading parameters from CSK_PersistentData module did not work.")
      return false
    end
  else
    ioddInterpreter_Model.updateAvailableIODDs()
    _G.logger:warning(nameOfModule .. ": CSK_PersistentData Module not available.")
    return false
  end
end
Script.serveFunction("CSK_IODDInterpreter.loadParameters", loadParameters)

local function setLoadOnReboot(status)
  ioddInterpreter_Model.parameterLoadOnReboot = status
  _G.logger:fine(nameOfModule .. ": Set new status to load setting on reboot: " .. tostring(status))
end
Script.serveFunction("CSK_IODDInterpreter.setLoadOnReboot", setLoadOnReboot)

--- Function to react on initial load of persistent parameters
local function handleOnInitialDataLoaded()
  if _G.availableAPIs.default then
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
end
Script.register("CSK_PersistentData.OnInitialDataLoaded", handleOnInitialDataLoaded)

-- *************************************************
-- END of functions for CSK_PersistentData module usage
-- *************************************************

return setIODDInterpreter_Model_Handle

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************

