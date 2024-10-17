local payloadHandler = {}


-- Function to create a deep copy of a table
--@copy(table):table
local function copy(origTable, seen)
  if type(origTable) ~= 'table' then return origTable end
  if seen and seen[origTable] then return seen[origTable] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(origTable))
  s[origTable] = res
  for k, v in pairs(origTable) do res[copy(k, s)] = copy(v, s) end
  return res
end


-------------------------------------------------------------------------------
-- Convert payload object to json 
-------------------------------------------------------------------------------

local encode



local escape_char_map = {
  [ "\\" ] = "\\",
  [ "\"" ] = "\"",
  [ "\b" ] = "b",
  [ "\f" ] = "f",
  [ "\n" ] = "n",
  [ "\r" ] = "r",
  [ "\t" ] = "t",
}

local escape_char_map_inv = { [ "/" ] = "/" }
for k, v in pairs(escape_char_map) do
  escape_char_map_inv[v] = k
end


local function escape_char(c)
  return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte()))
end


local function encode_nil(val)
  return "null"
end


local function encode_table(val, stack)
  local res = {}
  stack = stack or {}

  -- Circular reference?
  if stack[val] then error("circular reference") end

  stack[val] = true

  for _, tableElement in ipairs(val) do
    if type(tableElement.Key) ~= "string" then
      error("invalid table: mixed or invalid key types")
    end
    table.insert(res, encode(tableElement.Key, "string", stack) .. ":" .. encode(tableElement.ValueRef.Value, tableElement.Type, stack))
  end
  stack[val] = nil
  return "{" .. table.concat(res, ",") .. "}"
end


local function encode_array(val, stack)
  local res = {}
  stack = stack or {}

  -- Circular reference?
  if stack[val] then error("circular reference") end

  stack[val] = true

  for _, arrayElement in ipairs(val) do
    table.insert(res, encode(arrayElement.ValueRef.Value, arrayElement.Type, stack))
  end
  stack[val] = nil
  return "[" .. table.concat(res, ",") .. "]"
end


local function encode_string(val)
  return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end


local function encode_number(val)
  -- Check for NaN, -inf and inf
  if val ~= val or val <= -math.huge or val >= math.huge then
    error("unexpected number value '" .. tostring(val) .. "'")
  end
  return string.format("%.14g", val)
end


local str2bool = {
  ['true'] = true,
  ['false'] = false,
  ['0'] = false,
  ['1'] = true
}
local num2bool = {
  false, true
}
local bool2num = {
  ['false'] = 0,
  ['true'] = 1
}

local function encode_str2bool(val)
  if str2bool[val] then
    return val
  end
  return "null"
end

local function encode_str2num(val)
  local num = tonumber(val)
  if num then
    return num
  end
  return "null"
end

local function encode_num2str(val)
  return encode_string(tostring(val))
end

local function encode_num2bool(val)
  if num2bool[val+1] then
    return tostring(num2bool[val+1])
  end
  return "null"
end

local function encode_bool2str(val)
  return encode_string(tostring(val))
end

local function encode_bool2num(val)
  return encode_number(bool2num[tostring(val)])
end

local function encode_table2str(val)
  if val[1] and val[1].Key then
    return encode_table(val)
  elseif val[1] and val[1].Index then
    return encode_array(val)
  else
    return "null"
  end
end

local encoderFunctionsMap = {
  string = {
    string = encode_string,
    boolean = encode_str2bool,
    number = encode_str2num,
    table = encode_nil,
    array = encode_nil
  },
  number = {
    string = encode_num2str,
    boolean = encode_num2bool,
    number = encode_number,
    table = encode_nil,
    array = encode_nil
  },
  boolean = {
    string = encode_bool2str,
    boolean = tostring,
    number = encode_bool2num,
    table = encode_nil,
    array = encode_nil
  },
  table = {
    table = encode_table,
    array = encode_array,
    string = encode_table2str,
    boolean = encode_nil,
    number = encode_nil
  }
}

encode = function(val, valType, stack)
--local f = type_func_map[valType]
  local f = encoderFunctionsMap[type(val)][valType]
  if f then
    return f(val, stack)
  end
  error("unexpected type '" .. tostring(valType) .. "'")
end

local convertSingleValue

local function convert_str2bool(val)
  local value = str2bool[val]
  if value ~= nil then
    return value
  end
  return "null"
end

local function convert_str2num(val)
  local value = tonumber(val)
  if value ~= nil then
    return value
  end
  return "null"
end


local function convert_num2bool(val)
  local value = num2bool[val+1]
  if value ~= nil then
    return value
  end
  return "null"
end

local function convert_bool2num(val)
  local value = bool2num[tostring(val)]
  if value ~= nil then
    return value
  end
  return "null"
end

local function convert_Table2str(val)
  local tempPayloadObject = {
    Type = "table",
    ValueRef = {
      Value = val
    }
  }
  return payloadHandler.fromPayloadObject(tempPayloadObject)
end

local converterFunctionsMap = {
  table = {
    string = convert_Table2str
  },
  string = {
    boolean = convert_str2bool,
    number = convert_str2num
  },
  number = {
    string = tostring,
    boolean = convert_num2bool,
  },
  boolean = {
    string = tostring,
    number = convert_bool2num
  },
  ["nil"] = {}
}

convertSingleValue = function(val, valType)
  local f = converterFunctionsMap[type(val)][valType]
  if f then
    return f(val)
  end
  return val
end

local convertSingleValueOrEncode = {
  string = convertSingleValue,
  boolean = convertSingleValue,
  number = convertSingleValue,
  table = encode,
  array = encode
}

---Converts payload object to value depending on its type. If the type is table or array, returns JSON string
---@param payloadObject table Payload object to unpack
---@return auto Unpacked Json string or boolean value or number or string
local function fromPayloadObject(payloadObject)
  if payloadObject.Type == nil or payloadObject.ValueRef.Value == nil then
    return nil
  end
  return ( convertSingleValueOrEncode[payloadObject.Type](payloadObject.ValueRef.Value, payloadObject.Type) )
end
payloadHandler.fromPayloadObject = fromPayloadObject

-------------------------------------------------------------------------------
-- Convert from json to payload object
-------------------------------------------------------------------------------

local function create_set(...)
  local res = {}
  for i = 1, select("#", ...) do
    res[ select(i, ...) ] = true
  end
  return res
end

local space_chars   = create_set(" ", "\t", "\r", "\n")
local delim_chars   = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
local escape_chars  = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
local literals      = create_set("true", "false", "null")

local literal_map = {
  [ "true"  ] = true,
  [ "false" ] = false,
  [ "null"  ] = nil,
}


local function next_char(str, idx, set, negate)
  for i = idx, #str do
    if set[str:sub(i, i)] ~= negate then
      return i
    end
  end
  return #str + 1
end


local function decode_error(str, idx, msg)
  local line_count = 1
  local col_count = 1
  for i = 1, idx - 1 do
    col_count = col_count + 1
    if str:sub(i, i) == "\n" then
      line_count = line_count + 1
      col_count = 1
    end
  end
  error( string.format("%s at line %d col %d", msg, line_count, col_count) )
end


local function codepoint_to_utf8(n)
  -- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa
  local f = math.floor
  if n <= 0x7f then
    return string.char(n)
  elseif n <= 0x7ff then
    return string.char(f(n / 64) + 192, n % 64 + 128)
  elseif n <= 0xffff then
    return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
  elseif n <= 0x10ffff then
    return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128,
                       f(n % 4096 / 64) + 128, n % 64 + 128)
  end
  error( string.format("invalid unicode codepoint '%x'", n) )
end


local function parse_unicode_escape(s)
  local n1 = tonumber( s:sub(1, 4),  16 )
  local n2 = tonumber( s:sub(7, 10), 16 )
   -- Surrogate pair?
  if n2 then
    return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
  else
    return codepoint_to_utf8(n1)
  end
end


local function parse_string(str, i)
  local res = ""
  local j = i + 1
  local k = j

  while j <= #str do
    local x = str:byte(j)

    if x < 32 then
      decode_error(str, j, "control character in string")

    elseif x == 92 then -- `\`: Escape
      res = res .. str:sub(k, j - 1)
      j = j + 1
      local c = str:sub(j, j)
      if c == "u" then
        local hex = str:match("^[dD][89aAbB]%x%x\\u%x%x%x%x", j + 1)
                 or str:match("^%x%x%x%x", j + 1)
                 or decode_error(str, j - 1, "invalid unicode escape in string")
        res = res .. parse_unicode_escape(hex)
        j = j + #hex
      else
        if not escape_chars[c] then
          decode_error(str, j - 1, "invalid escape char '" .. c .. "' in string")
        end
        res = res .. escape_char_map_inv[c]
      end
      k = j + 1

    elseif x == 34 then -- `"`: End of string
      res = res .. str:sub(k, j - 1)
      return res, j + 1 , "string"
    end

    j = j + 1
  end

  decode_error(str, i, "expected closing quote for string")
end


local function parse_number(str, i)
  local x = next_char(str, i, delim_chars)
  local s = str:sub(i, x - 1)
  local n = tonumber(s)
  if not n then
    decode_error(str, i, "invalid number '" .. s .. "'")
  end
  return n, x, "number"
end


local function parse_literal(str, i)
  local x = next_char(str, i, delim_chars)
  local word = str:sub(i, x - 1)
  if not literals[word] then
    decode_error(str, i, "invalid literal '" .. word .. "'")
  end
  if literal_map[word] == nil then
    return literal_map[word], x, "nil"
  end
  return literal_map[word], x, "boolean"
end

-------------------------------------------------------------------------------
-- Convert from json to payload object where each element(subobject) contains array with path to itself
-------------------------------------------------------------------------------

local parse_with_path


local function parse_array_with_path(str, i, path)
  if not path then path = {} end
  local res = {}
  local n = 1
  i = i + 1
  local valType
  while 1 do
    local x, elementPath, keyIndexMap
    i = next_char(str, i, space_chars, true)
    -- Empty / end of array?
    if str:sub(i, i) == "]" then
      i = i + 1
      break
    end
    -- Read token
    elementPath = copy(path)
    table.insert(elementPath, n)
    x, i, valType, keyIndexMap = parse_with_path(str, i, elementPath)
    res[n] = {
      Index = n,
      Type = valType,
      ValueRef = {Value = x},
      Path = elementPath,
      KeyIndexMap = keyIndexMap
    }
    if valType ~= "table" and valType ~= "array" then
      res[n].DefaultValue = x 
    end
    n = n + 1
    -- Next token
    i = next_char(str, i, space_chars, true)
    local chr = str:sub(i, i)
    i = i + 1
    if chr == "]" then break end
    if chr ~= "," then decode_error(str, i, "expected ']' or ','") end
  end
  return res, i, "array"
end


local function parse_table_with_path(str, i, path)
  local addElementToPath = true
  if not path then 
    path = {}
    addElementToPath = false
  end
  local res = {}
  i = i + 1
  local tempKeyIndexMap = {}
  while 1 do
    local key, val, valType, elementPath, keyIndexMap
    i = next_char(str, i, space_chars, true)
    -- Empty / end of object?
    if str:sub(i, i) == "}" then
      i = i + 1
      break
    end
    -- Read key
    if str:sub(i, i) ~= '"' then
      decode_error(str, i, "expected string for key")
    end
    key, i = parse_with_path(str, i)
    -- Read ':' delimiter
    i = next_char(str, i, space_chars, true)
    if str:sub(i, i) ~= ":" then
      decode_error(str, i, "expected ':' after key")
    end
    i = next_char(str, i + 1, space_chars, true)
    -- Read value
    elementPath = copy(path)
    if addElementToPath then
      table.insert(elementPath, key)
    end
    val, i, valType, keyIndexMap = parse_with_path(str, i, elementPath)
    -- Set
    local setTable = {
      Key = key,
      Type = valType,
      ValueRef = {Value = val},
      Path = elementPath,
      KeyIndexMap = keyIndexMap
    }
    if valType ~= "table" and valType ~= "array" then
      setTable.DefaultValue = val
    end
    table.insert(res, setTable)
    tempKeyIndexMap[key] = #res
    --res[key] = val

    -- Next token
    i = next_char(str, i, space_chars, true)
    local chr = str:sub(i, i)
    i = i + 1
    if chr == "}" then break end
    if chr ~= "," then decode_error(str, i, "expected '}' or ','") end
  end
  return res, i, "table", tempKeyIndexMap
end


local char_func_map_with_path = {
  [ '"' ] = parse_string,
  [ "0" ] = parse_number,
  [ "1" ] = parse_number,
  [ "2" ] = parse_number,
  [ "3" ] = parse_number,
  [ "4" ] = parse_number,
  [ "5" ] = parse_number,
  [ "6" ] = parse_number,
  [ "7" ] = parse_number,
  [ "8" ] = parse_number,
  [ "9" ] = parse_number,
  [ "-" ] = parse_number,
  [ "t" ] = parse_literal,
  [ "f" ] = parse_literal,
  [ "n" ] = parse_literal,
  [ "[" ] = parse_array_with_path,
  [ "{" ] = parse_table_with_path,
}


parse_with_path = function(str, idx, path)
  local chr = str:sub(idx, idx)
  local f = char_func_map_with_path[chr]
  if f then
    return f(str, idx, path)
  end
  decode_error(str, idx, "unexpected character '" .. chr .. "'")
end

-------------------------------------------------------------------------------
-- Convert from json to payload object without creating path for faster processing
-------------------------------------------------------------------------------

local parse_without_path


local function parse_array_without_path(str, i)
  local res = {}
  local n = 1
  i = i + 1
  local valType
  while 1 do
    local x, keyIndexMap
    i = next_char(str, i, space_chars, true)
    -- Empty / end of array?
    if str:sub(i, i) == "]" then
      i = i + 1
      break
    end
    -- Read token
    x, i, valType, keyIndexMap = parse_without_path(str, i)
    res[n] = {
      Index = n,
      Type = valType,
      ValueRef = {Value = x},
      KeyIndexMap = keyIndexMap
    }
    if valType ~= "table" and valType ~= "array" then
      res[n].DefaultValue = x 
    end
    n = n + 1
    -- Next token
    i = next_char(str, i, space_chars, true)
    local chr = str:sub(i, i)
    i = i + 1
    if chr == "]" then break end
    if chr ~= "," then decode_error(str, i, "expected ']' or ','") end
  end
  return res, i, "array"
end


local function parse_table_without_path(str, i)
  local res = {}
  i = i + 1
  local tempKeyIndexMap = {}
  while 1 do
    local key, val, valType, keyIndexMap
    i = next_char(str, i, space_chars, true)
    -- Empty / end of object?
    if str:sub(i, i) == "}" then
      i = i + 1
      break
    end
    -- Read key
    if str:sub(i, i) ~= '"' then
      decode_error(str, i, "expected string for key")
    end
    key, i = parse_without_path(str, i)
    -- Read ':' delimiter
    i = next_char(str, i, space_chars, true)
    if str:sub(i, i) ~= ":" then
      decode_error(str, i, "expected ':' after key")
    end
    i = next_char(str, i + 1, space_chars, true)
    -- Read value

    val, i, valType, keyIndexMap = parse_without_path(str, i)
    -- Set
    local setTable = {
      Key = key,
      Type = valType,
      ValueRef = {Value = val},
      KeyIndexMap = keyIndexMap
    }
    if valType ~= "table" and valType ~= "array" then
      setTable.DefaultValue = val
    end
    table.insert(res, setTable)
    tempKeyIndexMap[key] = #res
    --res[key] = val

    -- Next token
    i = next_char(str, i, space_chars, true)
    local chr = str:sub(i, i)
    i = i + 1
    if chr == "}" then break end
    if chr ~= "," then decode_error(str, i, "expected '}' or ','") end
  end
  return res, i, "table", tempKeyIndexMap
end


local char_func_map_without_path = {
  [ '"' ] = parse_string,
  [ "0" ] = parse_number,
  [ "1" ] = parse_number,
  [ "2" ] = parse_number,
  [ "3" ] = parse_number,
  [ "4" ] = parse_number,
  [ "5" ] = parse_number,
  [ "6" ] = parse_number,
  [ "7" ] = parse_number,
  [ "8" ] = parse_number,
  [ "9" ] = parse_number,
  [ "-" ] = parse_number,
  [ "t" ] = parse_literal,
  [ "f" ] = parse_literal,
  [ "n" ] = parse_literal,
  [ "[" ] = parse_array_without_path,
  [ "{" ] = parse_table_without_path,
}


parse_without_path = function(str, idx)
  local chr = str:sub(idx, idx)
  local f = char_func_map_without_path[chr]
  if f then
    return f(str, idx)
  end
  decode_error(str, idx, "unexpected character '" .. chr .. "'")
end


---Converts JSON string into a payload object. If includePath = true then elements of the object contain key "Path" with array of keys of how this element can be accessed. Otherwise object is created without adding path to each element for faster conversion
---@param str auto JSON string to convert
---@param initKey string? Optional Key of the highest level element
---@param includePath bool? Optional flag to include path or not
---@return table payloadObject Resulting payload object
local function toPayloadObjectFromJson(str, initKey, includePath)
  if type(str) ~= "string" then
    error("expected argument of type string, got " .. type(str))
  end
  if str == "" or str:sub(1,1) ~= "{" and str:sub(1,1) ~= "[" then
    error("no opening bracket found for json")
  end
  if not initKey then
    initKey = "payload"
  end
  str = [[{"]] .. initKey ..[[":]] .. str .. [[}]]
  local res, idx
  if not includePath then
    res, idx = parse_without_path(str, next_char(str, 1, space_chars, true))
  else
    res, idx = parse_with_path(str, next_char(str, 1, space_chars, true))
  end
  idx = next_char(str, idx, space_chars, true)
  if idx <= #str then
    decode_error(str, idx, "trailing garbage")
  end
  return res[1]
end
payloadHandler.toPayloadObjectFromJson = toPayloadObjectFromJson

-------------------------------------------------------------------------------
-- Create payload object from single value
-------------------------------------------------------------------------------

local defaultValuesMap = {
  string = "string_value",
  boolean = "boolean_value",
  number = "numeric_value",
  table = {},
  array =  {}
}

---Creates payload object description of a single value based on its type.
---@param valueType string Type of value
---@param initValue auto? Optional value of the created payload object
---@param initKey string? Optional initial key of the created payload object
---@return table? payloadObject Created payload object
local function toPayloadObjectFromSingleValue(valueType, initValue, initKey)
  local defaultValue = defaultValuesMap[valueType]
  if defaultValue == nil then
    return nil
  end
  if initValue ~= nil then
    defaultValue = convertSingleValue(initValue, valueType)
  end
  
  local newPayloadObject = {
    Key = initKey or "payload",
    Type = valueType,
    Path = {},
    DefaultValue = defaultValue,
    ValueRef = {Value = defaultValue}
  }
  if valueType == 'table' then
    newPayloadObject.KeyIndexMap = {}
  end
  return newPayloadObject
end
payloadHandler.toPayloadObjectFromSingleValue = toPayloadObjectFromSingleValue

-------------------------------------------------------------------------------
-- Navigation in payload object
-------------------------------------------------------------------------------

---Get link to an element of payload object by providing a path represented as array of keys/indeces
---@param origObject table Payload object of interest 
---@param pathArray any[] Array of keys and indexes representing path 
---@return table? link Link to the element of the array or nil if path does not exist for this payload object
local function getObjectElementLink(origObject, pathArray)
  if not origObject.ValueRef or not origObject.ValueRef.Value then
    return nil
  end
  if #pathArray == 0 then
    return origObject
  end
  local link = origObject.ValueRef.Value
  for pathIndex,pathElement in ipairs(pathArray) do
    if type(pathElement) == 'number' then
      if not link[pathElement] then
        return nil
      end
      if pathIndex == #pathArray then
        link = link[pathElement]
      else
        link = link[pathElement].ValueRef.Value
      end
    elseif type(pathElement) == 'string' then
      local found = false
      for i, tableElement in ipairs(link) do
        if tableElement.Key == pathElement then
          found = true
          if pathIndex == #pathArray then
            link = link[i]
          else
            link = link[i].ValueRef.Value
          end
          break
        end
      end
      if found == false then
        return nil
      end
    end
  end
  return link
end
payloadHandler.getObjectElementLink = getObjectElementLink

---Add path to payload object
---@param origObject table Payload object of interest, can be empty table 
---@param pathArray any[] Array of keys and indexes representing path 
local function addPathToObject(origObject, pathArray)
  if getObjectElementLink(origObject, pathArray) ~= nil then
    return
  end
  if not origObject.Key then
    origObject.Key = "payload"
    origObject.Type = "table"
    origObject.ValueRef = {Value = {}}
    origObject.Path = {}
    origObject.KeyIndexMap = {}
  end
  if #pathArray == 0 then
    return
  end
  local currentPath = {}
  local link = origObject
  for index = 1, #pathArray do
    table.insert(currentPath,pathArray[index])
    if not link.KeyIndexMap[pathArray[index]] then
      link.KeyIndexMap[pathArray[index]] = #link.ValueRef.Value + 1
      table.insert(link.ValueRef.Value,
        {
          Key =  pathArray[index],
          Type = "table",
          Path = copy(currentPath),
          ValueRef = {Value = {}},
          KeyIndexMap = {}
        }
      )
    end
    link = link.ValueRef.Value[#link.ValueRef.Value]
  end
end
payloadHandler.addPathToObject = addPathToObject

---Remove path from existing paylaod object
---@param origObject table Payload object of interest, can be empty table 
---@param pathArray any[] Array of keys and indexes representing path
local function removePathFromObject(origObject, pathArray)
  local tempPath = copy(pathArray)
  if getObjectElementLink(origObject, tempPath) == nil then
    return
  end
  if #tempPath == 0 then
    origObject = nil
    return
  end
  local lastElement = tempPath[#tempPath]
  table.remove(tempPath)
  local link = getObjectElementLink(origObject, tempPath)
  if link.Type == "array" then
    table.remove(link.ValueRef.Value, lastElement)
  elseif link.Type == "table" then
    for i, v in ipairs(link.ValueRef.Value) do
      if v.Key == lastElement then
        table.remove(link.ValueRef.Value,i)
        return
      end
    end
  else
    return
  end
end
payloadHandler.removePathFromObject = removePathFromObject

-------------------------------------------------------------------------------
-- Table merge
-------------------------------------------------------------------------------

---Inserts some payload object as element of another object at a given path. Doesnt do anything if the path is not valid for given origObject
---@param origObject table Payload object where another object must be inserted as an element
---@param objectToLink table Payload object to be linked as an element
---@param pathArray any[] Path of origObject where the objectToAdd must be inserted
---@param updateType bool? If true then the type of original objects element will be set to a type of the linked one. False by default. 
local function linkValueObjectAsElementValue(origObject, objectToLink, pathArray, updateType)
  local link = getObjectElementLink(origObject, pathArray)
  if not link then
    return
  end
  if updateType == true then
    link.Type = objectToLink.Type
  end
  link.KeyIndexMap = objectToLink.KeyIndexMap
  link.DefaultValue = objectToLink.DefaultValue
  link.ValueRef = objectToLink.ValueRef
end
payloadHandler.linkValueObjectAsElementValue = linkValueObjectAsElementValue

local function concatenateObjectPaths(objectToUpdate, pathArray)
  if type(objectToUpdate) ~= "table" then
    return
  end
  for _, elementContent in ipairs(objectToUpdate) do
    if not elementContent.Path then
      return
    end
    for i = #pathArray, 1, -1 do
      table.insert(elementContent.Path, 1, pathArray[i])
    end
    concatenateObjectPaths(elementContent.ValueRef.Value, pathArray)
  end
end

---Makes a copy of payload object's Value field and pastes it as Value field of element of another object at a given pathArray. The element where the object is inserted must be of type array or table. Updates paths of each element as well. Doesnt do anything if the path is not valid for given origObject.
---@param origObject table Payload object where another object must be inserted as an element
---@param objectToCopy table Payload object to be inserted as an element
---@param pathArray any[] Path of origObject where the objectToAdd must be inserted
---@param updateType bool? If true then the type of original objects element will be set to a type of the linked one. False by default. 
local function copyObjectValueAsElementValue(origObject, objectToCopy, pathArray, updateType)
  local link = getObjectElementLink(origObject, pathArray)
  if not link then
    return
  end
  local objectCopy = copy(objectToCopy)
  if link.Path ~= nil and objectToCopy.Path ~= nil then
    concatenateObjectPaths(objectCopy.ValueRef.Value, pathArray)
  end
  if updateType == true then
    link.Type = objectToCopy.Type
  end
  link.KeyIndexMap = objectToCopy.KeyIndexMap
  link.DefaultValue = objectCopy.DefaultValue
  link.ValueRef = objectCopy.ValueRef
end
payloadHandler.copyObjectValueAsElementValue = copyObjectValueAsElementValue

-------------------------------------------------------------------------------
-- Forward values from one payload object to its copy
-------------------------------------------------------------------------------

local forwardValues

local function simple_type_forward(fromObject, toObject)
  toObject.ValueRef.Value = fromObject.ValueRef.Value
end

local function array_forward(fromObject, toObject)
  if not fromObject.ValueRef.Value or not toObject.ValueRef.Value then
    return
  end
  for i,v in ipairs(fromObject.ValueRef.Value) do
    forwardValues(v, toObject.ValueRef.Value[i])
  end
end

local function table_forward(fromObject, toObject)
  if not fromObject.ValueRef.Value or not toObject.ValueRef.Value then
    return
  end
  for i,v in ipairs(fromObject.ValueRef.Value) do
    if not toObject.KeyIndexMap or not toObject.KeyIndexMap[v.Key] then
      return
    else
      forwardValues(v, toObject.ValueRef.Value[toObject.KeyIndexMap[v.Key]])
    end
  end
end

local forward_type_func_map = {
  [ "string"  ] = simple_type_forward,
  [ "boolean" ] = simple_type_forward,
  [ "number"  ] = simple_type_forward,
  [ "array"   ] = array_forward,
  [ "table"   ] = table_forward,
}

forwardValues = function(fromObject, toObject)
  local f = forward_type_func_map[fromObject.Type]
  if not f then
    return
  end
  f(fromObject, toObject)
end

function payloadHandler.forwardValues(fromObject, toObject)
  forwardValues(fromObject, toObject)
end


-------------------------------------------------------------------------------
-- Dynamic table content creating out of payload object
-------------------------------------------------------------------------------
---Checks if two payload objects have same strucutre
---@param object1 table Payload object
---@param object2 table Payload object
---@return bool result Result of check
local function isObjectStructureMatched(object1, object2)
  if #object1 ~= #object2 then
    return false
  end
  if object1.Key == object2.Key and object1.Type == object2.Type and object1.Index == object2.Index then
    if object1.Type == 'array' then
      for i,v in ipairs(object1.ValueRef.Value) do
        if isObjectStructureMatched(v, object2.ValueRef.Value[i]) == false then
          return false
        end
      end
    elseif object1.Type == 'table' then
      for i,v in ipairs(object1.ValueRef.Value) do
        if not object2.KeyIndexMap or not object2.KeyIndexMap[v.Key] then
          return false
        end
        if isObjectStructureMatched(v, object2.ValueRef.Value[object2.KeyIndexMap[v.Key]]) == false then
          return false
        end
      end
    end
  else
    return false
  end
  return true
end
payloadHandler.isObjectStructureMatched = isObjectStructureMatched

-------------------------------------------------------------------------------
-- Dynamic table content creating out of payload object
-------------------------------------------------------------------------------
local function areArraysEqual(array1, array2)
  if #array1 ~= #array2 then
    return false
  end
  for i,v1 in ipairs(array1) do
    if v1 ~= array2[i] then
      return false
    end
  end
  return true
end


local function getRowContent(tableObject, tableContent, prefix, selectedPath)
  local nameToShow
  if tableObject.Index then
    nameToShow = tostring(tableObject.Index)..":"
  elseif tableObject.Key then
    nameToShow = [["]] .. tableObject.Key .. [[":]]
  end
  local rowContent = {}
  local colNumber = #tableObject.Path
  local colName = "col"
  if prefix then
    colName = tostring(prefix) .. colName
  end
  rowContent.Path = tableObject.Path
  rowContent[colName .. tostring(colNumber)] = nameToShow
  if selectedPath == nil then
    rowContent.selected = false
  else
    rowContent.selected = areArraysEqual(selectedPath, rowContent.Path)
  end
  
  if tableObject.Type ~= 'table' and tableObject.Type ~= 'array' then
    local valueToShow
    if tableObject.Link then
      if #tableObject.Link == 0 then
        valueToShow = 'Complete payload'
        rowContent[colName .. "type"] = "Complete payload"
      else
        valueToShow = table.concat(tableObject.Link, [[/]])
        rowContent[colName .. "type"] = "Link"
      end
    else
      if tableObject.DefaultValue ~= tableObject.ValueRef.Value then
        rowContent[colName .. "type"] = "Edited value"
      end
      valueToShow = tostring(tableObject.ValueRef.Value)
    end
    rowContent[colName .. tostring(colNumber+1)] = valueToShow
    table.insert(tableContent,  #tableContent+1, rowContent)
  else
    table.insert(tableContent,  #tableContent+1, rowContent)
    for _, element in ipairs(tableObject.ValueRef.Value) do
      getRowContent(element, tableContent, prefix, selectedPath)
    end
  end
end


---Creates a lua table that after conversion to json can be used as data input for dynamic table to represent payload in GUI 
---@param origObject table Payload object
---@param prefix string Prefix to add to column names
---@param selectedPath any[]? Path that highlights the selected row in payload dynamic table
---@return table Dynamic table content as a lua table - to be converted to JSON 
local function getDynamicTableContent(origObject, prefix, selectedPath)
  if origObject == nil or type(origObject) ~= 'table' or origObject.Type == nil then
    return {}
  end
  local tableContent = {}
  getRowContent(origObject, tableContent, prefix, selectedPath)
  table.remove(tableContent,1)
  return tableContent
end
payloadHandler.getDynamicTableContent = getDynamicTableContent

---Update links in the existing payload
---@param sourcesLatest table Payload object with latest sources payload
---@param oldDestinationsExpected table Payload object with old expected payload for destinations
---@param newDestinationsExpected table Payload object with expected destinations payload
---@param newDestinationsLatest table Payload object with latest destinations payload
local function updateLinks(sourcesLatest, oldDestinationsExpected, newDestinationsExpected, newDestinationsLatest)
  if not sourcesLatest then print('no sourcesLatest') end
  if not oldDestinationsExpected then print('no oldDestinationsExpected') end
  if not newDestinationsExpected then print('no newDestinationsExpected') end
  if not newDestinationsLatest then print('no newDestinationsLatest') end

  if newDestinationsExpected.Type ~= 'table' and  newDestinationsExpected.Type ~= 'array' then
    if oldDestinationsExpected.Link then
      local sourceLink = getObjectElementLink(sourcesLatest, oldDestinationsExpected.Link)
      if sourceLink ~= nil then
        newDestinationsExpected.Link = copy(oldDestinationsExpected.Link)
        newDestinationsLatest.ValueRef = sourceLink.ValueRef
      else
        newDestinationsExpected.Link = nil
        newDestinationsExpected.ValueRef = {Value = newDestinationsExpected.DefaultValue}
        newDestinationsLatest.ValueRef = {Value = newDestinationsExpected.DefaultValue}
      end
    elseif oldDestinationsExpected.DefaultValue then
      if oldDestinationsExpected.DefaultValue ~= oldDestinationsExpected.ValueRef.Value and convertSingleValue(oldDestinationsExpected.ValueRef.Value, newDestinationsExpected.Type) ~= "null" then
        newDestinationsExpected.ValueRef.Value = oldDestinationsExpected.ValueRef.Value
        newDestinationsLatest.ValueRef.Value = oldDestinationsExpected.ValueRef.Value
      end
    end
  end


  if oldDestinationsExpected.Type == 'table' or oldDestinationsExpected.Type == 'array'  then
    for oldIndex, oldValue in ipairs(oldDestinationsExpected.ValueRef.Value) do
      for newIndex, newValue in ipairs(newDestinationsExpected.ValueRef.Value) do
        if (oldValue.Key == newValue.Key and oldValue.Key ~= nil) or (oldValue.Index == newValue.Index and oldValue.Index ~= nil) then
          updateLinks(sourcesLatest, oldDestinationsExpected.ValueRef.Value[oldIndex], newDestinationsExpected.ValueRef.Value[newIndex], newDestinationsLatest.ValueRef.Value[newIndex])
          break
        end
      end
    end
  end
end
payloadHandler.updateLinks = updateLinks



return payloadHandler