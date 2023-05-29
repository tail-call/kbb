return {
  new = function (props)
    local compressedData = love.data.decode('data', 'base64', props.base64)
    local data = love.data.decompress('string', 'zlib', compressedData)
    ---@cast data string
    local array = loadstring(data)()
    return array
  end
}