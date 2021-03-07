local api = vim.api

-- import treesitter utils
local ts_utils = require'nvim-treesitter.ts_utils'

-- Get the current selection position
local function visual_selection_range()
    local _, startline, startcol, _ = unpack(vim.fn.getpos("'<"))
    local _, endline, endcol, _ = unpack(vim.fn.getpos("'>"))
    if startline < endline or (startline == endline and startcol <= endcol) then
        return {startline, startcol, endline, endcol}
    else
        return {endline, endcol, startline, startcol}
    end
end

-- return parent or node itself if there is no parent
local function get_parent(node)
    return node:parent() or node
end

local function get_node_text(buf, node)
    return unpack(ts_utils.get_node_text(node, buf))
end

-- convert node to text and return the first character
local function get_first_char(buf, node)
    return (get_node_text(buf, node)):sub(1, 1)
end

local function select_in_node(buf, node, char)
    -- get start position of node
    local startline, startcol, _, _ = node:range()

    -- range() indices start at 0, so add 1
    startline = startline + 1
    startcol = startcol + 1

    -- move cursor to start
    vim.fn.setpos(".", { buf, startline, startcol, 0 })

    -- select in node
    vim.cmd("normal vi"..char)
end

local function expsel()
    -- get current buffer
    local buf = api.nvim_get_current_buf()
    -- get start of selection
    local startline, startcol, _, _ = unpack(visual_selection_range())

    -- set cursor on start delimiter of selection, i.e. the {, (, [, "
    if startcol == 1 then
        -- if we are at the start of the line currently the delimeter should be at the end of the last line
        vim.fn.setpos(".", { buf, startline - 1, 0, 0 })
        vim.cmd("normal $")
    else
        -- otherwise it should just be one columns backwards
        vim.fn.setpos(".", { buf, startline, startcol - 1, 0 })
    end

    local node = ts_utils.get_node_at_cursor()
    local node_startline, node_startcol, node_endline, node_endcol = node:range()
    local char = get_first_char(buf, node)

    local parent = get_parent(node)
    local parent_startline, parent_startcol, parent_endline, parent_endcol = parent:range()

    -- find a parent node that starts with the same first character as the current node
    -- by looping over parents
    local has_parent = false
    while get_first_char(buf, parent) ~= char or
          -- if the start positions are equal it's not a parent
          (node_startline == parent_startline and node_startcol == parent_startcol) or
          -- if the end positions are equal it's not a parent
          (node_endline == parent_endline and node_endcol == parent_endcol) do

        local oldparent = parent
        parent = get_parent(parent)
        parent_startline, parent_startcol, parent_endline, parent_endcol = parent:range()

        -- this stops the loop once there are no more parents
        if parent == oldparent then
            break
        end

        -- if we find a parent with the same first character once it means there is a parent
        if get_first_char(buf, parent) == char then
            has_parent = true
        end
    end

    --select_in_node(buf, parent, char)
    if has_parent then
        print("has parent")
        -- if there is a parent, select inside that
        select_in_node(buf, parent, char)
    else
        print("no parent")
        -- otherwise select original node again
        select_in_node(buf, node, char)
    end
end

return {
    expsel = expsel
}
