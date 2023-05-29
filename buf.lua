---@class buf.props
---@field base64 string Buffer encoded as a zlib-compressed base64 string

return {
  ---@param props buf.props
  new = function (props)
    local compressedData = love.data.decode('data', 'base64', props.base64)
    local data = love.data.decompress('string', 'zlib', compressedData)
    ---@cast data string
    local array = loadstring(data)()
    return array
  end
}