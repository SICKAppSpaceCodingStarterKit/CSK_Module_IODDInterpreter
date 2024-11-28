local payloadHandler = require("Sensors.IODDInterpreter.helper.payloadHandler")
local helperFuncs = require("Sensors.IODDInterpreter.helper.funcs")
local json = require("Sensors.IODDInterpreter.helper.Json")

local tableCompiler = {}

local function renameDatatype(dataPointInfo)
    if dataPointInfo.SimpleDatatype then
      dataPointInfo.Datatype = helperFuncs.copy(dataPointInfo.SimpleDatatype)
      dataPointInfo.SimpleDatatype = nil
    elseif dataPointInfo.Datatype.SimpleDatatype then
      dataPointInfo.Datatype.Datatype = helperFuncs.copy(dataPointInfo.Datatype.SimpleDatatype)
      dataPointInfo.Datatype.SimpleDatatype = nil
      if dataPointInfo.Datatype.Datatype["xsi:type"] then
        dataPointInfo.Datatype.Datatype.type = dataPointInfo.Datatype.Datatype["xsi:type"]
        dataPointInfo.Datatype.Datatype["xsi:type"] = nil
      end
    elseif dataPointInfo.Datatype.RecordItem then
      for recordItemID, recordItemInfo in ipairs(dataPointInfo.Datatype.RecordItem) do
        if recordItemInfo.SimpleDatatype then
          dataPointInfo.Datatype.RecordItem[recordItemID].Datatype = helperFuncs.copy(recordItemInfo.SimpleDatatype)
          dataPointInfo.Datatype.RecordItem[recordItemID].SimpleDatatype = nil
          if recordItemInfo.Datatype["xsi:type"] then
            dataPointInfo.Datatype.RecordItem[recordItemID].Datatype.type = recordItemInfo.Datatype["xsi:type"]
            dataPointInfo.Datatype.RecordItem[recordItemID].Datatype["xsi:type"] = nil
          end
        end
      end
    end
    if dataPointInfo.Datatype["xsi:type"] then
      dataPointInfo.Datatype.type = dataPointInfo.Datatype["xsi:type"]
      dataPointInfo.Datatype["xsi:type"] = nil
    end
  return dataPointInfo
end

local function getDatatypeBitlength(datatypeInfo)
  if datatypeInfo.type == "BooleanT" then
    return 1
  elseif datatypeInfo.type == "IntegerT" or datatypeInfo.type == "UIntegerT" or datatypeInfo.type == "RecordT" then
    return tonumber(datatypeInfo.bitLength)
  elseif datatypeInfo.type == "Float32T" then
    return 32
  elseif datatypeInfo.type == "StringT" or datatypeInfo.type == "OctetStringT" then
    return tonumber(datatypeInfo.fixedLength)
  elseif datatypeInfo.type == "ArrayT" then
    return tonumber(datatypeInfo.count)*getDatatypeBitlength(datatypeInfo.Datatype)
  end
end

local defaultValueForSimpleType = {
  ['BooleanT'] = false,
  ['UIntegerT'] = 1,
  ['IntegerT'] = -1,
  ['StringT'] = 'text',
  ['OctetStringT'] = 'text',
  ['Float32T'] = 0.01
}

local typeMap = {
  ['BooleanT'] = 'boolean',
  ['UIntegerT'] = 'number',
  ['IntegerT'] = 'number',
  ['StringT'] = 'string',
  ['OctetStringT'] = 'string',
  ['Float32T'] = 'number'
}

local function addValueToExpectedPayload(expectedPayload, path, valueIODDType)
  payloadHandler.addPathToObject(
    expectedPayload,
    path
  )
  local value = payloadHandler.toPayloadObjectFromSingleValue(
    typeMap[valueIODDType],
    defaultValueForSimpleType[valueIODDType]
  )
  payloadHandler.copyObjectValueAsElementValue(
    expectedPayload,
    value,
    path,
    true
  )
end

local function makeExpectedPayload(compiledTable, order)
  local expectedPayload = payloadHandler.toPayloadObjectFromSingleValue('table', {})
  local dataPointInfo
  for _, dataPointName in ipairs(order) do
    dataPointInfo = compiledTable[dataPointName]
    dataPointInfo = renameDatatype(dataPointInfo)
    if dataPointInfo.Datatype.type == 'ArrayT' then
      for i = 1, dataPointInfo.Datatype.count do
        addValueToExpectedPayload(
          expectedPayload,
          {dataPointInfo.Name, "element_" .. tostring(i), 'value'},
          dataPointInfo.Datatype.Datatype.type
        )
      end
    elseif dataPointInfo.Datatype.type =='RecordT' then
      for _, recordInfo in ipairs(dataPointInfo.Datatype.RecordItem) do
        addValueToExpectedPayload(
          expectedPayload,
          {dataPointInfo.Name, recordInfo.Name, 'value'},
          recordInfo.Datatype.type
        )
      end
    else
      addValueToExpectedPayload(
        expectedPayload,
        {dataPointInfo.Name, 'value'},
        dataPointInfo.Datatype.type
      )
    end
  end
  return expectedPayload
end



local function compileProcessDataTable(processDataInfo, selectedTable)
  local order = {}
  local compiledTable = {}
  if selectedTable["0"] == true then
    local singleProcessData = helperFuncs.copy(processDataInfo)
    singleProcessData.bitOffset = 0
    compiledTable[singleProcessData.Name] = singleProcessData
    table.insert(order, singleProcessData.Name)
  elseif selectedTable["1"] ~= nil then
    for subindex, selected in pairs(selectedTable) do
      if selected == true and subindex ~= "0" and subindex ~= "subindexAccessSupported" then
        if processDataInfo.Datatype["xsi:type"] == "ArrayT" then
          local singleProcessData = helperFuncs.copy(processDataInfo.Datatype)
          singleProcessData.subindex = subindex
          singleProcessData.bitOffset = tonumber(subindex) * getDatatypeBitlength(singleProcessData.SimpleDatatype)
          singleProcessData.Name = processDataInfo.Name.. '_element' .. tostring(subindex)
          compiledTable[singleProcessData.Name] = singleProcessData
          table.insert(order, singleProcessData.Name)
        elseif processDataInfo.Datatype["xsi:type"] == "RecordT" then
          local subindexMap = {}
          for i, subindexInfo in ipairs(processDataInfo.Datatype.RecordItem) do
            subindexMap[subindexInfo.subindex] = i
          end
          local singleProcessData = helperFuncs.copy(processDataInfo.Datatype.RecordItem[subindexMap[subindex]])
          compiledTable[singleProcessData.Name] = singleProcessData
          table.insert(order, singleProcessData.Name)
        end
      end
    end
  end
  if helperFuncs.getTableSize(compiledTable) == 0 then
    return nil
  end
  return compiledTable, order
end

local function getOrderedIndeces(selectedTable)
  local orderedIndeces = {}
  for strIndex in pairs(selectedTable) do
    table.insert(orderedIndeces, tonumber(strIndex))
  end
  table.sort(orderedIndeces)
  return orderedIndeces
end

local function compileParametersTable(iodd, selectedTable)
  local orderedIndeces = getOrderedIndeces(selectedTable)
  local order = {}
  local compiledTable = {}
  local index, subindeces
  for _, indexNum in ipairs(orderedIndeces) do
    index = tostring(indexNum)
    subindeces = selectedTable[index]
    if subindeces["0"] == true then
      local ioddIndexdata = iodd:getParameterInfoFromIndex(index)
      ioddIndexdata.subindex = "0"
      compiledTable[ioddIndexdata.Name] = ioddIndexdata
      table.insert(order, ioddIndexdata.Name)
    elseif subindeces["1"] ~= nil then
      for subindex, selected in pairs(subindeces) do
        if selected == true and subindex ~= "0" and subindex ~= "subindexAccessSupported" then
          local ioddIndexdata = iodd:getParameterInfoFromIndex(index)
          if ioddIndexdata.Datatype["xsi:type"] == "ArrayT" then
            local ioddSubIndexdata = ioddIndexdata.Datatype
            ioddSubIndexdata.index = index
            ioddSubIndexdata.subindex = subindex
            ioddSubIndexdata.Name = ioddIndexdata.Name.. '_element' .. tostring(subindex)
            compiledTable[ioddIndexdata.Name] = ioddSubIndexdata
            table.insert(order, ioddIndexdata.Name)
          elseif ioddIndexdata.Datatype["xsi:type"] == "RecordT" then
            local ioddSubIndexdata = iodd:getSubIndexParameter(index, subindex)
            ioddSubIndexdata.index = index
            compiledTable[ioddSubIndexdata.Name] = ioddSubIndexdata
            table.insert(order, ioddSubIndexdata.Name)
          end
        end
      end
    end
  end
  if helperFuncs.getTableSize(compiledTable) == 0 then
    return nil
  end
  return compiledTable, order
end

local function getJsonTemplateAndInfoTables(processDataInfo, processDataSelected, iodd, parametersSelected)
  local compiledTableProcessData, processDataOrder = compileProcessDataTable(
    processDataInfo,
    processDataSelected
  )
  local compiledTableParameters, parametersOrder = compileParametersTable(
    iodd,
    parametersSelected
  )
  local infoTable = {
    ProcessData = compiledTableProcessData,
    Parameters = compiledTableParameters
  }
  local templatePayload = payloadHandler.toPayloadObjectFromSingleValue('table', {})
  if compiledTableProcessData and compiledTableParameters then
    payloadHandler.addPathToObject(
      templatePayload,
      {'ProcessData'}
    )
    payloadHandler.copyObjectValueAsElementValue(
      templatePayload,
      makeExpectedPayload(compiledTableProcessData, processDataOrder),
      {'ProcessData'},
      true
    )
    payloadHandler.addPathToObject(
      templatePayload,
      {'Parameters'}
    )
    payloadHandler.copyObjectValueAsElementValue(
      templatePayload,
      makeExpectedPayload(compiledTableParameters, parametersOrder),
      {'Parameters'},
      true
    )
  elseif compiledTableProcessData then
    templatePayload = makeExpectedPayload(compiledTableProcessData, processDataOrder)
  elseif compiledTableParameters then
    templatePayload = makeExpectedPayload(compiledTableParameters, parametersOrder)
  end
  return payloadHandler.fromPayloadObject(templatePayload), json.encode(infoTable)
end
tableCompiler.getJsonTemplateAndInfoTables = getJsonTemplateAndInfoTables

return tableCompiler