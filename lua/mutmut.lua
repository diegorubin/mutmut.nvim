local M = {}
local namespace = vim.api.nvim_create_namespace("mutmut")

local prescript
local ft
local sqlite3_command
local mutmut_cache_file

function M.mutmut_cache_exists()
    local f = io.open(mutmut_cache_file, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

function M.find_mutations(buf)
    local mutations = {}

    local filename = vim.api.nvim_buf_get_name(buf)
    filename = filename:gsub(vim.fn.getcwd():gsub("%-", ".") .. "/", "")

    local query =
        'SELECT Line.line_number, Mutant.id FROM Mutant INNER JOIN Line ON Line.id = Mutant.line INNER JOIN SourceFile ON Line.sourcefile = SourceFile.id WHERE Mutant.status <> "ok_killed" AND SourceFile.filename = "FILENAME";'

    query = query:gsub('FILENAME', filename)

    local command = assert(io.popen(
                               sqlite3_command .. " " .. mutmut_cache_file ..
                                   " '" .. query .. "'"))
    for line in command:lines() do
        for line_number, value in string.gmatch(line, "(%d+)|(%d+)") do
            mutations[line_number] = value
        end
    end
    command.close()
    return mutations
end

function M.apply()
    local buf = vim.api.nvim_get_current_buf()
    local mutations = M.find_mutations(buf)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row = cursor[1]

    if mutations[tostring(row - 1)] then
        os.execute("mutmut apply " .. mutations[tostring(row - 1)])
        vim.api.nvim_command("windo e")
    else
        vim.api.nvim_echo({{"Mutation not found in this line!"}}, false, {})
    end
end

function M.showdiff()
    local buf = vim.api.nvim_get_current_buf()
    local mutations = M.find_mutations(buf)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row = cursor[1]

    if mutations[tostring(row - 1)] then
        local output = vim.api.nvim_create_buf(false, true)
        local command = assert(io.popen("mutmut show " ..
                                            mutations[tostring(row - 1)]))
        local content = {}
        for line in command:lines() do table.insert(content, line) end

        vim.api.nvim_buf_set_lines(output, 0, -1, true, content)
        vim.api.nvim_open_win(output, 0, {
            relative = "cursor",
            width = 100,
            height = 15,
            bufpos = {100, 10}
        })

        command.close()
    else
        vim.api.nvim_echo({{"Mutation not found in this line!"}}, false, {})
    end

end

function M.setup(c)
    prescript = c.prescript or "Mutation: "
    ft = c.ft or '*.py'
    sqlite3_command = c.sqlite3_command or "sqlite3"
    mutmut_cache_file = c.mutmut_cache_file or "./.mutmut-cache"

    vim.api.nvim_command('autocmd BufEnter ' .. ft ..
                             ' lua require("mutmut").draw(0)')
    vim.api.nvim_command('autocmd InsertLeave ' .. ft ..
                             ' lua require("mutmut").redraw(0)')
    vim.api.nvim_command('autocmd TextChanged ' .. ft ..
                             ' lua require("mutmut").redraw(0)')
    vim.api.nvim_command('autocmd TextChangedI ' .. ft ..
                             ' lua require("mutmut").redraw(0)')
end

function M.draw(buf)
    if M.mutmut_cache_exists() then
        local mutations = M.find_mutations(buf)
        for key in pairs(vim.api.nvim_buf_get_lines(buf, 0, -1, {})) do
            if mutations[tostring(key)] then
                vim.api.nvim_buf_set_virtual_text(buf, namespace, key, {
                    {prescript, 'Comment'},
                    {mutations[tostring(key)], 'Comment'}
                }, {})
            end

        end
    end
end

function M.clear(buf) vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1) end

function M.redraw(buf)
    M.clear(buf)
    M.draw(buf)
end

return M
