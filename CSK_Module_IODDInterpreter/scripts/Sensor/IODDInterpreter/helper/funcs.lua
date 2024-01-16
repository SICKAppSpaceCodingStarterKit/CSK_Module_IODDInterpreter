--luacheck: no max line length
--*****************************************************************
-- Inside of this script, you will find helper functions
--*****************************************************************

--**************************************************************************
--**********************Start Global Scope *********************************
--**************************************************************************

local funcs = {}
-- Providing standard JSON functions
funcs.json = require('Sensor/IODDInterpreter/helper/Json')

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

-- Function to create a list from table
--@createStringListBySize(size:int):string
local function createStringListBySize(size)
  local list = "["
  if size >= 1 then
    list = list .. '"' .. tostring(1) .. '"'
  end
  if size >= 2 then
    for i=2, size do
      list = list .. ', ' .. '"' .. tostring(i) .. '"'
    end
  end
  list = list .. "]"
  return list
end
funcs.createStringListBySize = createStringListBySize

local function getTableSize(someTable)
  if not someTable then
    return 0
  end
  local size = 0
  for _,_ in pairs(someTable) do
    size = size + 1
  end
  return size
end
funcs.getTableSize = getTableSize

local function copy(origTable, seen)
  if type(origTable) ~= 'table' then return origTable end
  if seen and seen[origTable] then return seen[origTable] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(origTable))
  s[origTable] = res
  for k, v in pairs(origTable) do res[copy(k, s)] = copy(v, s) end
  return res
end
funcs.copy = copy


local function renameDatatype(dataPointInfo)
    if dataPointInfo.SimpleDatatype then
      dataPointInfo.Datatype = copy(dataPointInfo.SimpleDatatype)
      dataPointInfo.SimpleDatatype = nil
    elseif dataPointInfo.Datatype.SimpleDatatype then
      dataPointInfo.Datatype.Datatype = copy(dataPointInfo.Datatype.SimpleDatatype)
      dataPointInfo.Datatype.SimpleDatatype = nil
      if dataPointInfo.Datatype.Datatype["xsi:type"] then
        dataPointInfo.Datatype.Datatype.type = dataPointInfo.Datatype.Datatype["xsi:type"]
        dataPointInfo.Datatype.Datatype["xsi:type"] = nil
      end
    elseif dataPointInfo.Datatype.RecordItem then
      for recordItemID, recordItemInfo in ipairs(dataPointInfo.Datatype.RecordItem) do
        if recordItemInfo.SimpleDatatype then
          dataPointInfo.Datatype.RecordItem[recordItemID].Datatype = copy(recordItemInfo.SimpleDatatype)
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
funcs.renameDatatype = renameDatatype

local function checkIfKeyListFormArray(keyList)
  local success, _ = pcall(
    table.sort,
    keyList,
    function(left,right)
      return tonumber(left) < tonumber(right)
    end
  )
  if not success then
    return false, keyList
  end
  local i = 0
  for _, key in ipairs(keyList) do
    if tonumber(key) and tonumber(key)-i == 1 then
      i = i + 1
    else
      return false, keyList
    end
  end
  if i ~= #keyList then
    return false, keyList
  end
  return true, keyList
end

-- Function to convert a table into a Container object
--@convertTable2Container(data:table):Container
local function convertTable2Container(data)
  local cont = Container.create()
  for key, val in pairs(data) do
    local valType = nil
    local val2add = val
    if type(val) == 'function' or type(val) == 'userdata' then
      goto nextKey
    end
    --if type(val) == 'userdata' and Object.getType(val) == Script.Queue
    if type(val) == 'table' then
      val2add = convertTable2Container(val)
      valType = 'OBJECT'
    end
    --if type(val) == 'string' then
    --  valType = 'STRING'
    --end
    cont:add(key, val2add, valType)
    ::nextKey::
  end
  return cont
end
funcs.convertTable2Container = convertTable2Container

-- Function to convert a Container into a table
--@convertContainer2Table(cont:Container):table
local function convertContainer2Table(cont)
  local arrayInside, keyList = checkIfKeyListFormArray(cont:list())
  local tab = {}
  for _, key in ipairs(keyList) do
    local tempVal = cont:get(key, cont:getType(key))
    local keyToAdd = key
    if arrayInside then
      keyToAdd = tonumber(key)
    end
    if cont:getType(key) == 'OBJECT' then
      if Object.getType(tempVal) == 'Container' then
        tab[keyToAdd] = convertContainer2Table(tempVal)
      else
        tab[keyToAdd] = tempVal
      end
    else
      tab[keyToAdd] = tempVal
    end
  end
  return tab
end
funcs.convertContainer2Table = convertContainer2Table


-- Function to get content list
--@createContentList(data:table):string
local function createContentList(data)
  local sortedTable = {}
  for key, _ in pairs(data) do
    table.insert(sortedTable, key)
  end
  table.sort(sortedTable)
  return table.concat(sortedTable, ',')
end
funcs.createContentList = createContentList

-- Function to get content list
--@createContentList(data:table):string
local function createJsonList(data)
  local sortedTable = {}
  for key, _ in pairs(data) do
    table.insert(sortedTable, key)
  end
  table.sort(sortedTable)
  return funcs.json.encode(sortedTable)
end
funcs.createJsonList = createJsonList
-- Function to create a list from table
--@createStringListBySimpleTable(content:table):string
local function createStringListBySimpleTable(content)
  local list = "["
  if #content >= 1 then
    list = list .. '"' .. content[1] .. '"'
  end
  if #content >= 2 then
    for i=2, #content do
      list = list .. ', ' .. '"' .. content[i] .. '"'
    end
  end
  list = list .. "]"
  return list
end
funcs.createStringListBySimpleTable = createStringListBySimpleTable


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

local function makeExpectedPayload(compiledTable)
  local expectedTable = {}
  for _, dataPointInfo in pairs(compiledTable) do
    dataPointInfo = renameDatatype(dataPointInfo)
    if dataPointInfo.Datatype.type == 'ArrayT' then
      expectedTable[dataPointInfo.Name] = {}
      for i = 1, dataPointInfo.Datatype.count do
        expectedTable[dataPointInfo.Name]["element_" .. tostring(i)] = {}
        expectedTable[dataPointInfo.Name]["element_" .. tostring(i)].value = defaultValueForSimpleType[dataPointInfo.Datatype.Datatype.type]
      end
    elseif dataPointInfo.Datatype.type =='RecordT' then
      expectedTable[dataPointInfo.Name] = {}
      local repeatedNames = {}
      for _, recordInfo in ipairs(dataPointInfo.Datatype.RecordItem) do
        local recordName = recordInfo.Name
        if expectedTable[dataPointInfo.Name][recordInfo.Name] then
          table.insert(repeatedNames, recordInfo.Name)
          expectedTable[dataPointInfo.Name][recordInfo.Name..'_1'] = copy(expectedTable[dataPointInfo.Name][recordInfo.Name])
          local repeatedIndex = 2
          recordName = recordInfo.Name .. '_' .. tostring(repeatedIndex)
          while expectedTable[dataPointInfo.Name][recordName] do
            recordName = recordInfo.Name .. '_' .. tostring(repeatedIndex)
            repeatedIndex = repeatedIndex + 1
          end
        end
        expectedTable[dataPointInfo.Name][recordName] = {}
        expectedTable[dataPointInfo.Name][recordName].value = defaultValueForSimpleType[recordInfo.Datatype.type]
      end
      for i, recordName in ipairs(repeatedNames) do
        expectedTable[dataPointInfo.Name][recordName] = nil
      end
    else
      expectedTable[dataPointInfo.Name] = {}
      if dataPointInfo.Datatype then
        expectedTable[dataPointInfo.Name].value = defaultValueForSimpleType[dataPointInfo.Datatype.type]
      elseif dataPointInfo.Datatype then
        expectedTable[dataPointInfo.Name].value = defaultValueForSimpleType[dataPointInfo.Datatype.type]
      end
    end
  end
  return expectedTable
end
funcs.makeExpectedPayload = makeExpectedPayload

local function compileProcessDataTable(processDataInfo, selectedTable)
  local compiledTable = {}
  if selectedTable["0"] == true then
    local singleProcessData = copy(processDataInfo)
    singleProcessData.bitOffset = 0
    singleProcessData.Frequency = 0
    singleProcessData.requested = false
    compiledTable[singleProcessData.Name] = singleProcessData
    --table.insert(compiledTable, singleProcessData)
  elseif selectedTable["1"] ~= nil then
    for subindex, selected in pairs(selectedTable) do
      if selected == true and subindex ~= "0" and subindex ~= "subindexAccessSupported" then
        if processDataInfo.Datatype["xsi:type"] == "ArrayT" then
          local singleProcessData = copy(processDataInfo.Datatype)
          singleProcessData.subindex = subindex
          singleProcessData.bitOffset = tonumber(subindex) * getDatatypeBitlength(singleProcessData.SimpleDatatype)
          singleProcessData.Frequency = 0
          singleProcessData.requested = false
          singleProcessData.Name = processDataInfo.Name.. '_element' .. tostring(subindex)
          compiledTable[singleProcessData.Name] = singleProcessData
          --table.insert(compiledTable, singleProcessData)
        elseif processDataInfo.Datatype["xsi:type"] == "RecordT" then
          local subindexMap = {}
          for i, subindexInfo in ipairs(processDataInfo.Datatype.RecordItem) do
            subindexMap[subindexInfo.subindex] = i
          end
          local singleProcessData = copy(processDataInfo.Datatype.RecordItem[subindexMap[subindex]])
          singleProcessData.Frequency = 0
          singleProcessData.requested = false
          compiledTable[singleProcessData.Name] = singleProcessData
          --table.insert(compiledTable, singleProcessData)
        end
      end
    end
  end
  if getTableSize(compiledTable) == 0 then
    return nil
  end
  return compiledTable
end
funcs.compileProcessDataTable = compileProcessDataTable


local function compileParametersTable(iodd, selectedTable)
  local compiledTable = {}
  for index, subindeces in pairs(selectedTable) do
    if subindeces["0"] == true then
      local ioddIndexdata = iodd:getParameterInfoFromIndex(index)
      ioddIndexdata.subindex = "0"
      ioddIndexdata.Frequency = 0
      ioddIndexdata.requested = false
      compiledTable[ioddIndexdata.Name] = ioddIndexdata
      --table.insert(compiledTable, ioddIndexdata)
    elseif subindeces["1"] ~= nil then
      for subindex, selected in pairs(subindeces) do
        if selected == true and subindex ~= "0" and subindex ~= "subindexAccessSupported" then
          local ioddIndexdata = iodd:getParameterInfoFromIndex(index)
          if ioddIndexdata.Datatype["xsi:type"] == "ArrayT" then
            local ioddSubIndexdata = ioddIndexdata.Datatype
            ioddSubIndexdata.index = index
            ioddSubIndexdata.subindex = subindex
            ioddSubIndexdata.Frequency = 0
            ioddSubIndexdata.requested = false
            ioddSubIndexdata.Name = ioddIndexdata.Name.. '_element' .. tostring(subindex)
            --table.insert(compiledTable, ioddSubIndexdata)
            compiledTable[ioddIndexdata.Name] = ioddSubIndexdata
          elseif ioddIndexdata.Datatype["xsi:type"] == "RecordT" then
            local ioddSubIndexdata = iodd:getSubIndexParameter(index, subindex)
            ioddSubIndexdata.index = index
            ioddSubIndexdata.Frequency = 0
            ioddSubIndexdata.requested = false
            --table.insert(compiledTable, ioddSubIndexdata)
            compiledTable[ioddSubIndexdata.Name] = ioddSubIndexdata
          end
        end
      end
    end
  end
  if getTableSize(compiledTable) == 0 then
    return nil
  end
  return compiledTable
end
funcs.compileParametersTable = compileParametersTable














return funcs

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************