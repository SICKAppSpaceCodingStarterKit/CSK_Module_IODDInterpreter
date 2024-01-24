local xml2lua = require "Sensors.IODDInterpreter.helper.xml2lua"
local json = require "Sensors.IODDInterpreter.helper.Json"

local IODDInterpreter = {}

local function copy(origTable, seen)
  if type(origTable) ~= 'table' then return origTable end
  if seen and seen[origTable] then return seen[origTable] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(origTable))
  s[origTable] = res
  for k, v in pairs(origTable) do res[copy(k, s)] = copy(v, s) end
  return res
end

function IODDInterpreter:new(object)
  object = object or {}
  setmetatable(object, self)
  self.__index = self
  return object
end

--------------------------------------------------------------------------------------------------------------------
local function makeIdValueMap(langugeTextTable)
  local IdValueMap = {}
  for _, idValue in ipairs(langugeTextTable) do
    IdValueMap[idValue.id] = idValue.value
  end
  return IdValueMap
end

--------------------------------------------------------------------------------------------------------------------
local function changeTextIDtoText(rawTable, languageIdValueMap)
  for key, value in pairs(rawTable) do
    if key == "textId" then
      return languageIdValueMap[value]
    end
    if type(value) == "table" then
      local result = changeTextIDtoText(value, languageIdValueMap)
      if result then
        rawTable[key] = result
      end
    end
  end
  return nil
end

function IODDInterpreter:getSubIndexParameter(index, subindex)
  if self.ParamIndexMap[index] and self.ParamIndexSubindexMap[index][subindex] then
    local tempTable = copy(self.Variable[self.ParamIndexMap[index]].Datatype.RecordItem[self.ParamIndexSubindexMap[index][subindex]])
    changeTextIDtoText(tempTable, self.languages[self.currentLanguage])
    return tempTable
  else
    return false
  end
end



--[[
  Original IODD groups:
  -DocumentInfo
  -ProfileHeader
  -ProfileBody
    -DeviceIdentity
    -DeviceFunction
      -Features
      -DatatypeCollection (optional)
      -VariableCollection
        -StdVariableRef
        -Variable (optional)
        -DirectParameterOverlay (optional)
      -ProcessDataCollection
      -ErrorTypeCollection (optional)
      -EventCollection (optional)
      -UserInterface
        -ProcessDataRefCollection
        -MenuCollection
        -ObserverRoleMenuSet
        -MaintananceRoleMenuSet
        -SpecialistRoleMenuSet
  -CommNetworkProfile
  -ExternalTextCollection
  -Stamp
]]

--making a list in Lua table to iterate over it for convenience in future
local function makeListOutOfSingleTable(rawTable)
  if #rawTable == 0 then
    local tableCopy = copy(rawTable)
    rawTable = {}
    rawTable[1] = tableCopy
  end
  return rawTable
end

local function modifyRecordOrArray(ParameterInfo, dataType2IdRefMap, ParamIndexSubindexMap)
  if ParameterInfo.Datatype and ParameterInfo.Datatype["xsi:type"] == "RecordT" then
    --Making list out of RecordItem in case there is only one subindex for further convenience
    ParameterInfo.Datatype.RecordItem = makeListOutOfSingleTable(ParameterInfo.Datatype.RecordItem)
    if ParamIndexSubindexMap then
      ParamIndexSubindexMap[ParameterInfo.index] = {}
    end
    for j, ParameterSubindexInfo in ipairs(ParameterInfo.Datatype.RecordItem) do
      --Inserting Datatypes as SimpleDatatype instead of their references in Varible table for further convenience
      if ParameterSubindexInfo.DatatypeRef then
        ParameterInfo.Datatype.RecordItem[j].SimpleDatatype = dataType2IdRefMap[ParameterSubindexInfo.DatatypeRef.datatypeId]
      end
      if ParamIndexSubindexMap then
        ParamIndexSubindexMap[ParameterInfo.index][ParameterSubindexInfo.subindex] = j
      end
    end
  elseif ParameterInfo.Datatype and ParameterInfo.Datatype["xsi:type"] == "ArrayT" and ParameterInfo.Datatype.DatatypeRef then
    ParameterInfo.Datatype.SimpleDatatype = dataType2IdRefMap[ParameterInfo.Datatype.DatatypeRef.datatypeId]
  end
end

local function addStandardDefinitions(stdReferences, variableTable, languageTable)
  local standardDefinitionsFile = File.open('resources/CSK_Module_IODDInterpreter/IODD-StandardDefinitions1.1.xml', 'r')
  local standardDefinitionsXml = standardDefinitionsFile:read()
  standardDefinitionsFile:close()
  local standardDefinitions = xml2lua.convert(standardDefinitionsXml)
  local idMap = {}
  local stDefVaiable = standardDefinitions.IODDStandardDefinitions.VariableCollection.Variable
  for i, v in ipairs(stDefVaiable) do
    idMap[v.id] = i
  end
  for _, reference in ipairs(stdReferences) do
    table.insert(variableTable, stDefVaiable[idMap[reference.id]])
  end
  for language, _ in pairs(languageTable) do
    if language == "en" then
      local tableToAdd = makeIdValueMap(standardDefinitions.IODDStandardDefinitions.ExternalTextCollection.PrimaryLanguage.Text)
      for id, value in pairs(tableToAdd) do
        languageTable[language][id] = value
      end
    elseif language ~= "Primary" and File.exists("resources/CSK_Module_IODDInterpreter/IODD-StandardDefinitions1.1-" .. language .. ".xml") then
      local stdLanguagePackFile = File.open("resources/CSK_Module_IODDInterpreter/IODD-StandardDefinitions1.1-" .. language .. ".xml", 'r')
      local stdLanguagePack = xml2lua.convert(stdLanguagePackFile:read())
      stdLanguagePackFile:close()
      local tableToAdd = makeIdValueMap(stdLanguagePack.ExternalTextDocument.Language.Text)
      for id, value in pairs(tableToAdd) do
        languageTable[language][id] = value
      end
    end
  end
end


function IODDInterpreter:interpretXMLFile(path)
  local ioddFile = File.open(path, 'r')
  if not ioddFile then
    _G.logger:warning(_APPNAME..': failed to open xml file for iodd interpretation ' .. tostring(path))
    return false
  end
  local ioddXMLStr = File.read(ioddFile)
  ioddFile:close()
  local ioddFullTable = xml2lua.convert(ioddXMLStr)
  self.DocumentInfo = ioddFullTable.IODevice.DocumentInfo
  self.ProfileHeader = ioddFullTable.IODevice.ProfileHeader
  self.CommNetworkProfile = ioddFullTable.IODevice.CommNetworkProfile
  self.Stamp = ioddFullTable.IODevice.Stamp
  self.DeviceIdentity = ioddFullTable.IODevice.ProfileBody.DeviceIdentity
  self.Variable = ioddFullTable.IODevice.ProfileBody.DeviceFunction.VariableCollection.Variable
  self.ProcessData = ioddFullTable.IODevice.ProfileBody.DeviceFunction.ProcessDataCollection.ProcessData
  self.UserInterface = ioddFullTable.IODevice.ProfileBody.DeviceFunction.UserInterface
  self.DeviceIdentity.DeviceVariantCollection.DeviceVariant = makeListOutOfSingleTable(self.DeviceIdentity.DeviceVariantCollection.DeviceVariant)
  --Creating a languages map of the following structure for fast access:  
  --  self.languages = {
  --    Pramary = Language1,
  --    Language1 = {
  --      "textId1" = "text1 in language 1",
  --      "textId2" = "text2 in language 1"
  --      ...
  --    },
  --    Language2 = {
  --      "textId1" = "text1 in language 2",
  --      "textId2" = "text2 in language 2"
  --      ...
  --    },
  --    ...
  --  }
  local languages = {}
  languages.Primary = ioddFullTable.IODevice.ExternalTextCollection.PrimaryLanguage["xml:lang"]
  languages[languages.Primary] = makeIdValueMap(ioddFullTable.IODevice.ExternalTextCollection.PrimaryLanguage.Text)
  if ioddFullTable.IODevice.ExternalTextCollection.Language then
    for _, languageData in ipairs(ioddFullTable.IODevice.ExternalTextCollection.Language) do
      languages[languageData["xml:lang"]] = makeIdValueMap(languageData.Text)
    end
  end
  self.languages = languages
  self.currentLanguage = self.languages.Primary
  addStandardDefinitions(
    ioddFullTable.IODevice.ProfileBody.DeviceFunction.VariableCollection.StdVariableRef,
    self.Variable,
    self.languages
  )

  --Creating tables to map parameter ID or parameter index or parameter name to the parameter for fast access 
  local ParamIDMap = {}
  local ParamIndexMap = {}
  local ParamIndexSubindexMap = {}

  --Creating a map of Datatype reference id and respective Datatypes from DatatypeCollection
  local dataType2IdRefMap = {}
  if ioddFullTable.IODevice.ProfileBody.DeviceFunction.DatatypeCollection then
    for _, rawDataType in ipairs(ioddFullTable.IODevice.ProfileBody.DeviceFunction.DatatypeCollection.Datatype) do
      local referenceId = rawDataType.id
      local DataTypeWOId = copy(rawDataType)
      DataTypeWOId.id = nil
      dataType2IdRefMap[rawDataType.id] = DataTypeWOId
    end
  end
  if self.Variable then
    for i, ParameterInfo in ipairs(self.Variable) do
      ParamIDMap[ParameterInfo.id] = i
      ParamIndexMap[ParameterInfo.index] = i
      --Inserting Datatypes instead of their references in Varible table for further convenience
      if ParameterInfo.DatatypeRef then
        self.Variable[i].Datatype = dataType2IdRefMap[ParameterInfo.DatatypeRef.datatypeId]
      end
      modifyRecordOrArray(self.Variable[i], dataType2IdRefMap, ParamIndexSubindexMap)
    end
    self.ParamIDMap = ParamIDMap
    self.ParamIndexMap = ParamIndexMap
    self.ParamIndexSubindexMap = ParamIndexSubindexMap
  end

  if #self.ProcessData > 1 then
    --Inserting Datatypes instead of their references in ProcessData table for further convenience
    for i, ProcessDataOption in ipairs(self.ProcessData) do
      if ProcessDataOption.ProcessDataIn then
        if ProcessDataOption.ProcessDataIn.DatatypeRef then
          self.ProcessData[i].ProcessDataIn.Datatype = dataType2IdRefMap[ProcessDataOption.ProcessDataIn.DatatypeRef.datatypeId]
        end
        modifyRecordOrArray(self.ProcessData[i].ProcessDataIn, dataType2IdRefMap)
      end
      --print(json.encode(self.ProcessData))

      if ProcessDataOption.ProcessDataOut then
        if ProcessDataOption.ProcessDataOut.DatatypeRef then
          self.ProcessData[i].ProcessDataOut.Datatype = dataType2IdRefMap[ProcessDataOption.ProcessDataOut.DatatypeRef.datatypeId]
        end
        modifyRecordOrArray(self.ProcessData[i].ProcessDataOut, dataType2IdRefMap)
      end
    end

    self.IsProcessDataStructureVariable = true
    self.ProcessDataCondition = {}
    self.ProcessDataCondition.ID = self.ProcessData[1].Condition.variableId

    self.ProcessDataCondition.Index = self.Variable[self.ParamIDMap[self.ProcessDataCondition.ID]].index
    local ConditionInfo = {}
    local ConditionTypeInfo = {}
    self.ProcessDataCondition.Info = {}

    if self.ProcessData[1].Condition.subindex then

      self.ProcessDataCondition.Subindex = self.ProcessData[1].Condition.subindex
      ConditionInfo = self.Variable[self.ParamIDMap[self.ProcessDataCondition.ID]].Datatype.RecordItem[self.ParamIndexSubindexMap[self.ProcessDataCondition.Index][self.ProcessDataCondition.Subindex]]
      ConditionTypeInfo = ConditionInfo.SimpleDatatype
    else

      self.ProcessDataCondition.Subindex = "0"
      ConditionInfo = self.Variable[self.ParamIDMap[self.ProcessDataCondition.ID]]
      ConditionTypeInfo = ConditionInfo.Datatype
    end
    self.ProcessDataCondition.DefaultValue = ConditionInfo.defaultValue
    self.ProcessDataCondition.Type = ConditionTypeInfo["xsi:type"]
    self.ProcessDataCondition.Info = ConditionInfo

    if ConditionTypeInfo.SingleValue ~= nil and ConditionTypeInfo.SingleValue[1].Name ~= nil then
      self.ProcessDataCondition.Value2TextIdMap = {}
      for _, SingleValueInfo in ipairs(ConditionTypeInfo.SingleValue) do
        self.ProcessDataCondition.Value2TextIdMap[SingleValueInfo.value] = SingleValueInfo.Name.textId
      end
    ---TODO ELSE
    end
    self.ProcessDataCondition.Value2InfoMap = {}
    for _, info in ipairs(self.ProcessData) do
      self.ProcessDataCondition.Value2InfoMap[info.Condition.value] = info
    end
  else
    self.IsProcessDataStructureVariable = false
    --Inserting Datatypes instead of their references in ProcessData table for further convenience
    if self.ProcessData.ProcessDataIn and self.ProcessData.ProcessDataIn.DatatypeRef then
      self.ProcessData.ProcessDataIn.Datatype = dataType2IdRefMap[self.ProcessData.ProcessDataIn.DatatypeRef.datatypeId]
    end
    if self.ProcessData.ProcessDataIn then
      modifyRecordOrArray(self.ProcessData.ProcessDataIn, dataType2IdRefMap)
    end
    if self.ProcessData.ProcessDataOut and self.ProcessData.ProcessDataOut.DatatypeRef then
      self.ProcessData.ProcessDataOut.Datatype = dataType2IdRefMap[self.ProcessData.ProcessDataOut.DatatypeRef.datatypeId]
    end
    if self.ProcessData.ProcessDataOut then
      modifyRecordOrArray(self.ProcessData.ProcessDataOut, dataType2IdRefMap)
    end
  end

  return true
end

function IODDInterpreter:getStandardFileName()
  local vendorName = self.DeviceIdentity.vendorName
  local deviceNameTextId = self.DeviceIdentity.DeviceName.textId
  local deviceName = self.languages[self.languages.Primary][deviceNameTextId]
  local releaseDateRaw = self.DocumentInfo.releaseDate
  local releaseDate = string.gsub(releaseDateRaw, '-', '')
  local profileRevision = self.ProfileHeader.ProfileRevision
  local standardFileNameRaw = string.format('%s-%s-%s-IODD%s', vendorName, deviceName, releaseDate, profileRevision)
  local standardFileName = string.gsub(standardFileNameRaw, ' ', '_')
  local standardFileName = string.gsub(standardFileName, '/', '_')
  return standardFileName
end

function IODDInterpreter:getVendorIdDeviceIdVersion()
  return self.DeviceIdentity.vendorId, self.DeviceIdentity.deviceId, self.DocumentInfo.version
end

function IODDInterpreter:saveAsJSON(path, fileName)
  if not File.exists(path) then
    if File.mkdir(path) == false then
      return false
    end
  end
  local newIODDjsonFile = File.open(path .. '/' .. fileName, 'w')
  local IODDcontent = {}
  for key,value in pairs(self) do
    if type(value) ~= "function" then
      IODDcontent[key] = value
    end
  end
  newIODDjsonFile:write(json.encode(IODDcontent))
  newIODDjsonFile:close()
  return true
end

function IODDInterpreter:loadFromJson(path, fileName)
  if not File.exists(path.. '/' .. fileName) then
    return false
  end
  local IODDjsonFile = File.open(path .. '/' .. fileName, 'r')
  local jsonIODDContent = IODDjsonFile:read()
  IODDjsonFile:close()
  local IODDContent = json.decode(jsonIODDContent)
  for key, value in pairs(IODDContent) do
    self[key] = value
  end
  return true
end

function IODDInterpreter:getProcessDataInfo(conditionValue)
  if self.IsProcessDataStructureVariable then
    if conditionValue then
      local tempTable = copy(self.ProcessDataCondition.Value2InfoMap[conditionValue])
      changeTextIDtoText(tempTable, self.languages[self.currentLanguage])
      return tempTable
    else
      return false
    end
  else
    local tempTable = copy(self.ProcessData)
    changeTextIDtoText(tempTable, self.languages[self.currentLanguage])
    return tempTable
  end
end

function IODDInterpreter:getProcessDataConditionNameFromValue(value)
  return self.languages[self.currentLanguage][self.ProcessDataCondition.Value2TextIdMap[value]]
end

function IODDInterpreter:getProcessDataConditionValueFromName(name)
  for conditionVal, textID in pairs(self.ProcessDataCondition.Value2TextIdMap) do
    if name == self.languages[self.currentLanguage][textID] then
      return conditionVal
    end
  end
  return false
end

function IODDInterpreter:getProcessDataConditionList()
  local tempTable = {}
  for _, textID in pairs(self.ProcessDataCondition.Value2TextIdMap) do
    table.insert(tempTable, self.languages[self.currentLanguage][textID])
  end
  table.sort(tempTable)
  return tempTable
end

function IODDInterpreter:setLanguage(lang)
  if self.languages[lang] ~= nil then
    return false
  end
  if lang == 'Primary' then
    self.currentLanguage = self.languages.Primary
    return true
  end
  self.currentLanguage = lang
end

function IODDInterpreter:getAvailableLanguages()
  local availableLanguages = {}
  for lang,_ in pairs(IODDInterpreter.languages) do
    if lang~='Primary' then
      table.insert(availableLanguages, lang)
    end
  end
  return availableLanguages
end



function IODDInterpreter:getParameterInfoFromIndex(index)
  local strIndex = tostring(index)
  if self.ParamIndexMap[strIndex] then
    local parameterTable = copy(self.Variable[self.ParamIndexMap[strIndex]])
    changeTextIDtoText(parameterTable, self.languages[self.currentLanguage])
    return parameterTable
  else
    return false
  end
end

function IODDInterpreter:getParameterInfoFromID(id)
  if self.ParamIDMap[id] then
    local parameterTable = copy(self.Variable[self.ParamIDMap[id]])
    changeTextIDtoText(parameterTable, self.languages[self.currentLanguage])
    return parameterTable
  else
    return false
  end
end

function IODDInterpreter:getDeviceVariantCollection()
  local deviceVariantCollection = copy(self.DeviceIdentity.DeviceVariantCollection.DeviceVariant)
  changeTextIDtoText(deviceVariantCollection, self.languages[self.currentLanguage])
  return deviceVariantCollection
end

function IODDInterpreter:getAllReadParameterInfo()
  local tempTable = {}
  for i, param in ipairs(self.Variable) do
    if param.accessRights == "rw" or param.accessRights == "ro" then
      table.insert(tempTable, param)
    end
  end
  changeTextIDtoText(tempTable, self.languages[self.currentLanguage])
  return tempTable
end

function IODDInterpreter:getAllWriteParameterInfo()
  local tempTable = {}
  for i, param in ipairs(self.Variable) do
    if param.accessRights == "rw" or param.accessRights == "wo" then
      table.insert(tempTable, param)
    end
  end
  changeTextIDtoText(tempTable, self.languages[self.currentLanguage])
  return tempTable
end

function IODDInterpreter:getAllParameterInfo()
  local tempTable = copy(self.Variable)
  changeTextIDtoText(tempTable, self.languages[self.currentLanguage])
  return tempTable
end

return IODDInterpreter