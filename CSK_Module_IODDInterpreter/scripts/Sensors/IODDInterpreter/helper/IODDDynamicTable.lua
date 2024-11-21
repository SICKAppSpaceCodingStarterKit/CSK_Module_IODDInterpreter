local json = require "Sensors.IODDInterpreter.helper.Json"

local IODDDynamicTable = {}

local function compileDataTypeInfo(dataType)
  local dataTypeDescr = dataType['xsi:type'] .. '; '
  if dataType['xsi:type'] == "BooleanT" then
    if dataType.SingleValue then
      for _, singleVal in ipairs(dataType.SingleValue) do
        dataTypeDescr = dataTypeDescr .. '\n' .. singleVal.value
        if singleVal.Name then dataTypeDescr = dataTypeDescr .. ': '.. singleVal.Name .. ';' end
      end
    end
  elseif dataType['xsi:type'] == "UIntegerT" or dataType['xsi:type'] == "IntegerT" or dataType['xsi:type'] == "Float32T" then
    if dataType['xsi:type'] == "UIntegerT" or dataType['xsi:type'] == "IntegerT" then
      dataTypeDescr = dataTypeDescr .. 'bitLength:' .. dataType.bitLength .. '; '
    end
    if dataType.SingleValue then
      for _, singleVal in ipairs(dataType.SingleValue) do
        dataTypeDescr = dataTypeDescr .. '\n' .. singleVal.value
        if singleVal.Name then dataTypeDescr = dataTypeDescr .. ': ' .. singleVal.Name .. '; ' end
      end
    end
    if dataType.ValueRange then
      dataTypeDescr = dataTypeDescr .. '\n'
      if dataType.ValueRange.Name then
        dataTypeDescr = dataTypeDescr .. dataType.ValueRange.Name
      end
      dataTypeDescr = dataTypeDescr .. ' Value range: ' .. dataType.ValueRange.lowerValue .. ' - ' .. dataType.ValueRange.upperValue .. '; '
    end
  elseif dataType['xsi:type'] == "StringT" then
    dataTypeDescr = dataTypeDescr .. 'length: ' .. dataType.fixedLength .. '; encoding: '.. dataType.encoding .. '; '
  elseif dataType['xsi:type'] == "OctetStringT" then
    dataTypeDescr = dataTypeDescr .. 'length: ' .. dataType.fixedLength .. '; '
  elseif dataType['xsi:type'] == "ArrayT" then
    dataTypeDescr = dataTypeDescr .. 'count: ' .. dataType.count .. '; '
    local subindexAccessSupported
    if dataType.subindexAccessSupported == nil then
      subindexAccessSupported = "true"
    else
      subindexAccessSupported = dataType.subindexAccessSupported
    end
    dataTypeDescr = dataTypeDescr .. '\nsubindexAccessSupported: ' .. subindexAccessSupported .. '; '
  elseif dataType['xsi:type'] == "RecordT" then
    dataTypeDescr = dataTypeDescr .. 'bitLength: ' .. dataType.bitLength .. '; '
    local subindexAccessSupported
    if dataType.subindexAccessSupported == nil then
      subindexAccessSupported = "true"
    else
      subindexAccessSupported = dataType.subindexAccessSupported
    end
    dataTypeDescr = dataTypeDescr .. '\nsubindexAccessSupported: ' .. subindexAccessSupported .. '; '
  end
  return dataTypeDescr
end
IODDDynamicTable.compileDataTypeInfo = compileDataTypeInfo

local function addPrefixesToRowData(preficesToInclude, rowData)
  local newRowData = {}
  for _, prefix in ipairs(preficesToInclude) do
    for key, value in pairs(rowData) do
      if string.sub(key,1,3) == 'col' then
        newRowData[prefix .. key] = value
      else
        newRowData[key] = value
      end
    end
  end
  return newRowData
end

local function makeIODDParameterTableContent(preficesToInclude, parameterTable, selectedTable)
  local tableContent = {}
  for _, indexParam in ipairs(parameterTable) do
    --TODO remove this workaround in future
    if indexParam.index~="40" and indexParam.index~="41" then
      local singleIndexParam = {
        colSD1 = indexParam.index,
        colSD2 = "0",
        colSD3 = indexParam.id,
        colSD4 = indexParam.Name,
        colSD6 = indexParam.accessRights,
        selected = false or selectedTable[indexParam.index]["0"]
      }
      if indexParam.Datatype then
        singleIndexParam.colSD5 = compileDataTypeInfo(indexParam.Datatype)
      elseif indexParam.DatatypeRef then
        singleIndexParam.colSD5 = json.encode(indexParam.DatatypeRef)
      end
      if indexParam.Description then
        singleIndexParam.colSD7 = indexParam.Description
      end
      table.insert(tableContent, addPrefixesToRowData(preficesToInclude, singleIndexParam))
      if indexParam.Datatype and indexParam.Datatype['xsi:type'] == "ArrayT" then
        for i = 1, indexParam.Datatype.count do
          local singleSubindex = {
            colSD1 = indexParam.index,
            colSD2 = i,
            selected = false or selectedTable[indexParam.index][tostring(i)]
          }
          if indexParam.Datatype.SimpleDatatype then
            singleSubindex.colSD4 = compileDataTypeInfo(indexParam.Datatype.SimpleDatatype)
          elseif indexParam.Datatype.DataTypeRef then
            singleSubindex.colSD4 = json.encode(indexParam.Datatype.DataTypeRef)
          end
          table.insert(tableContent, addPrefixesToRowData(preficesToInclude, singleSubindex))
        end
      end
      if indexParam.Datatype and indexParam.Datatype['xsi:type'] == "RecordT" then
        for _, subindexParam in ipairs(indexParam.Datatype.RecordItem) do
          local singleSubindex = {
            colSD1 = indexParam.index,
            colSD2 = subindexParam.subindex,
            colSD4 = subindexParam.Name,
            selected = false or selectedTable[indexParam.index][subindexParam.subindex]
          }
          if subindexParam.SimpleDatatype then
            singleSubindex.colSD5 = 'Bit offset: ' .. subindexParam.bitOffset .. '; ' .. compileDataTypeInfo(subindexParam.SimpleDatatype)
          elseif subindexParam.DataTypeRef then
            singleSubindex.colSD5 = 'Bit offset: ' .. subindexParam.bitOffset .. '; ' .. json.encode(subindexParam.DataTypeRef)
          else
            singleSubindex.colSD5 = 'Bit offset: ' .. subindexParam.bitOffset
          end
          table.insert(tableContent, addPrefixesToRowData(preficesToInclude, singleSubindex))
        end
      end
    end
  end
  return json.encode(tableContent)
end
IODDDynamicTable.makeIODDParameterTableContent = makeIODDParameterTableContent


local str2bool = {
  ["true"] = true,
  ["false"]  = false
}

local function makeDefaultSelectedParameterTable(parameterTable)
  local selectedTable = {}
  for _, indexParam in ipairs(parameterTable) do
    selectedTable[indexParam.index] = {}
    selectedTable[indexParam.index]["0"] = false
    if indexParam.Datatype and (indexParam.Datatype['xsi:type'] == "ArrayT" or indexParam.Datatype['xsi:type'] == "RecordT") then
      if indexParam.Datatype.subindexAccessSupported == nil then
          selectedTable[indexParam.index].subindexAccessSupported = true
        else
          selectedTable[indexParam.index].subindexAccessSupported = str2bool[indexParam.Datatype.subindexAccessSupported]
        end
      if indexParam.Datatype['xsi:type'] == "ArrayT" then
        for i = 1, indexParam.Datatype.count do
          selectedTable[indexParam.index][tostring(i)] = false
        end
      elseif indexParam.Datatype['xsi:type'] == "RecordT" then
        for _, subindexParam in ipairs(indexParam.Datatype.RecordItem) do
          selectedTable[indexParam.index][subindexParam.subindex] = false
        end
      end
    end
  end
  --TODO remove this workaround in future
  selectedTable["40"] = nil
  selectedTable["41"] = nil
  return selectedTable
end
IODDDynamicTable.makeDefaultSelectedParameterTable = makeDefaultSelectedParameterTable

local function makeDefaultSelectedProcessDataTable(processDataInfo, subindexAccessSupported)
  local selectedTable = {}
  if processDataInfo and processDataInfo.Datatype then
    selectedTable["0"] = false
    if processDataInfo.Datatype['xsi:type'] == "ArrayT" or processDataInfo.Datatype['xsi:type'] == "RecordT" then
      selectedTable.subindexAccessSupported = subindexAccessSupported
      if processDataInfo.Datatype['xsi:type'] == "ArrayT" then
        for i = 1, processDataInfo.Datatype.count do
          selectedTable[tostring(i)] = false
        end
      elseif processDataInfo.Datatype['xsi:type'] == "RecordT" then
          for _, subindexInfo in ipairs(processDataInfo.Datatype.RecordItem) do
            selectedTable[subindexInfo.subindex] = false
          end
      end
    end
  end
  return selectedTable
end
IODDDynamicTable.makeDefaultSelectedProcessDataTable = makeDefaultSelectedProcessDataTable

local function makeSingleRowContent(subindexInfo, selectedTable)
  local singleSubindex = {
    colPD1 = subindexInfo.subindex,
    colPD2 = subindexInfo.Name,
    selected = false or selectedTable[subindexInfo.subindex]
  }
  if subindexInfo.SimpleDatatype then
    singleSubindex.colPD3 = 'Bit offset: ' .. subindexInfo.bitOffset .. '; ' .. compileDataTypeInfo(subindexInfo.SimpleDatatype)
  elseif subindexInfo.DataTypeRef then
    singleSubindex.colPD3 = 'Bit offset: ' .. subindexInfo.bitOffset .. '; ' ..json.encode(subindexInfo.DataTypeRef)
  else
    singleSubindex.colPD3 = 'Bit offset: ' .. subindexInfo.bitOffset
  end
  return singleSubindex
end

local function makeProcessDataTableContent(preficesToInclude, parameterTable, selectedTable)
  local tableContent = {}
  if parameterTable then
    local FirstParam = {
      colPD1 = "0",
      colPD2 = parameterTable.Name,
      colPD3 = compileDataTypeInfo(parameterTable.Datatype),
      selected = false or selectedTable["0"]
    }
    table.insert(tableContent, addPrefixesToRowData(preficesToInclude, FirstParam))
    if parameterTable.Datatype['xsi:type'] == "ArrayT" then
      for i = 1, parameterTable.Datatype.count do
        local singleSubindex = {
          colPD1 = i,
          selected = false or selectedTable[tostring(i)]
        }
        if parameterTable.Datatype.SimpleDatatype then
          singleSubindex.colPD3 = compileDataTypeInfo(parameterTable.Datatype.SimpleDatatype)
        elseif parameterTable.Datatype.DataTypeRef then
          singleSubindex.colPD3 = json.encode(parameterTable.Datatype.DataTypeRef)
        end
        table.insert(tableContent, addPrefixesToRowData(preficesToInclude, singleSubindex))
      end
    elseif parameterTable.Datatype['xsi:type'] == "RecordT" then
        for _, subindexInfo in ipairs(parameterTable.Datatype.RecordItem) do
          table.insert(tableContent, addPrefixesToRowData(preficesToInclude, makeSingleRowContent(subindexInfo, selectedTable)))
        end
    end
  end
  return json.encode(tableContent)
end
IODDDynamicTable.makeProcessDataTableContent = makeProcessDataTableContent

local function addPrefixToColumnNames(jsonTableContent, prefixToAdd)
  local newTableContent = {}
  local tableContent = json.decode(jsonTableContent)
  for rowIndex, rowContent in ipairs(tableContent) do
    newTableContent[rowIndex] = {}
    for colName, colContent in pairs(rowContent) do
      if colName == 'selected' then
        newTableContent[rowIndex][colName] = colContent
      else
        newTableContent[rowIndex][prefixToAdd..colName] = colContent
      end
    end
  end
  return json.encode(newTableContent)
end
IODDDynamicTable.addPrefixToColumnNames = addPrefixToColumnNames

local function removePrefixFromColumnNames(jsonRowContent, prefixToRemove)
  local rowContent = json.decode(jsonRowContent)
  if not prefixToRemove then
    return rowContent
  end
  local newRowContent = {}
  for colName, colContent in pairs(rowContent) do
    if string.sub(colName, 1, #prefixToRemove) == prefixToRemove then
      newRowContent[string.sub(colName, #prefixToRemove+1)] = colContent
    else
      newRowContent[colName] = colContent
    end
  end
  return newRowContent
end
IODDDynamicTable.removePrefixFromColumnNames = removePrefixFromColumnNames

return IODDDynamicTable