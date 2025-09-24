-- A* Pathfinding Implementation in Lua

---@class AstarNode
---@field x number The x-coordinate of the node.
---@field y number The y-coordinate of the node.
---@field g number The cost from the start node to this node.
---@field h number The heuristic (estimated cost) from this node to the goal node.
---@field f number The total cost (g + h) of this node.
---@field parent AstarNode? The parent node in the path (nil if it's the start node).

-- Define a simple Node class
local AstarNode = {
  x = 0,
  y = 0,
  g = 0,       -- Cost from start node to this node
  h = 0,       -- Heuristic (estimated cost from this node to the goal)
  f = 0,       -- Total cost (g + h)
  parent = nil -- Parent node in the path
}

-- Creates a new node
---@param x number The x-coordinate of the node.
---@param y number The y-coordinate of the node.
---@return AstarNode
local function createNode(x, y)
  local newNode = {}
  setmetatable(newNode, { __index = AstarNode })
  newNode.x = x
  newNode.y = y
  return newNode
end

---@param node AstarNode
---@param goal AstarNode
---@return number
local function manhattanDistance(node, goal)
  return math.abs(node.x - goal.x) + math.abs(node.y - goal.y)
end

-- Function to reconstruct the path from the goal node to the start node
local function reconstructPath(node)
  local path = {}
  while node ~= nil do
    table.insert(path, 1, { x = node.x, y = node.y }) -- Insert at the beginning to reverse the path
    node = node.parent
  end
  return path
end

-- A* Pathfinding function.
-- Takes the grid, start node, goal node, and a function to check if a node is walkable (returns true if walkable)
---@param maxX integer
---@param maxY integer
---@param startNode AstarNode
---@param goalNode AstarNode
---@param isWalkable function
---@return AstarNode?, string?
local function aStar(maxX, maxY, startNode, goalNode, isWalkable)
  if not isWalkable(startNode.x, startNode.y) or not isWalkable(goalNode.x, goalNode.y) then
    return nil, "Start and goal node must be walkable"
  end

  local openSet = { startNode }
  local closedSet = {}

  startNode.g = 0
  startNode.h = manhattanDistance(startNode, goalNode)
  startNode.f = startNode.g + startNode.h

  while #openSet > 0 do
    -- Find the node in openSet with the lowest f cost
    local currentNode = openSet[1]
    local currentIndex = 1
    for i = 2, #openSet do
      if openSet[i].f < currentNode.f then
        currentNode = openSet[i]
        currentIndex = i
      end
    end

    -- If we reached the goal, reconstruct the path and return it
    if currentNode.x == goalNode.x and currentNode.y == goalNode.y then
      return reconstructPath(currentNode)
    end

    -- Remove the current node from the open set and add it to the closed set
    table.remove(openSet, currentIndex)
    table.insert(closedSet, currentNode)

    -- Get neighboring nodes (up, down, left, right)
    local neighbors = {}
    local neighborPositions = {
      { x = currentNode.x,     y = currentNode.y - 1 }, -- Up
      { x = currentNode.x,     y = currentNode.y + 1 }, -- Down
      { x = currentNode.x - 1, y = currentNode.y },   -- Left
      { x = currentNode.x + 1, y = currentNode.y }    -- Right
    }

    for _, pos in ipairs(neighborPositions) do
      local x, y = pos.x, pos.y
      -- Check if the neighbor is within the grid bounds
      if x >= 1 and x <= maxX and y >= 1 and y <= maxY then
        -- Check if the neighbor is walkable
        if isWalkable(x, y) then
          table.insert(neighbors, createNode(x, y))
        end
      end
    end

    -- Iterate through the neighbors
    for _, neighbor in ipairs(neighbors) do
      -- Skip if the neighbor is already in the closed set
      local inClosedSet = false
      for _, closedNode in ipairs(closedSet) do
        if neighbor.x == closedNode.x and neighbor.y == closedNode.y then
          inClosedSet = true
          break
        end
      end
      if inClosedSet then
        goto continue_neighbors
      end


      -- Calculate tentative g cost
      local tentativeG = currentNode.g + 1     -- Assuming cost of 1 to move to a neighbor

      -- If the neighbor is not in the open set, add it
      local inOpenSet = false
      local openSetIndex = nil
      for i, openNode in ipairs(openSet) do
        if neighbor.x == openNode.x and neighbor.y == openNode.y then
          inOpenSet = true
          openSetIndex = i
          break
        end
      end

      -- If the tentative g cost is better than the current g cost, or the neighbor is not in the open set
      if not inOpenSet or tentativeG < neighbor.g then
        -- Update the neighbor's costs and parent
        neighbor.g = tentativeG
        neighbor.h = manhattanDistance(neighbor, goalNode)
        neighbor.f = neighbor.g + neighbor.h
        neighbor.parent = currentNode

        -- Add the neighbor to the open set if it's not already there
        if not inOpenSet then
          table.insert(openSet, neighbor)
        end
      end
      ::continue_neighbors::
    end
  end

  -- If we reach here, it means no path was found
  return nil, "No path found"
end

return {
  createNode = createNode,
  aStar = aStar,
}
