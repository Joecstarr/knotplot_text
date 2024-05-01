--- Include the QR code lua code.
local figlet = dofile("lua/knotplot_text/figlet.lua")
figlet.readfont("lua/knotplot_text/clb8x8.flf")
--- Include the table object
require("table")

--- Function to print table contents to console taken from
--- https://stackoverflow.com/questions/9168058/how-to-dump-a-table-to-console
function tprint(tbl, indent)
    if not indent then
        indent = 0
    end
    local toprint = string.rep(" ", indent) .. "{\r\n"
    indent = indent + 2
    for k, v in pairs(tbl) do
        toprint = toprint .. string.rep(" ", indent)
        if (type(k) == "number") then
            toprint = toprint .. "[" .. k .. "] = "
        elseif (type(k) == "string") then
            toprint = toprint .. k .. "= "
        end
        if (type(v) == "number") then
            toprint = toprint .. v .. ",\r\n"
        elseif (type(v) == "string") then
            toprint = toprint .. "\"" .. v .. "\",\r\n"
        elseif (type(v) == "table") then
            toprint = toprint .. tprint(v, indent + 2) .. ",\r\n"
        else
            toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
        end
    end
    toprint = toprint .. string.rep(" ", indent - 2) .. "}"
    return toprint
end

--- This function extends L1 with L2. I'm sure there's a way to do this natively
--- in lua but I don't know how.
function str_to_array(letter_str, size)
    local L1 = {}
    local row = 1
    local col = 1
    L1[row] = {}
    for i = 1, #letter_str do
        local c = letter_str:sub(i, i)
        if c == " " then
            for j = 0, size - 1 do
                L1[row][col + j] = 0xff
            end
            col = col + size
        elseif c == "#" then
            for j = 0, size - 1 do
                L1[row][col + j] = 0x00
            end
            col = col + size
        elseif c == "\n" then

            for j = 1, size do
                L1[row + j] = {}
                for k = 1, #L1[row] do
                    L1[row + j][k] = L1[row][k]
                end
            end
            row = row + size
            col = 1
        end
    end
    for j = 1, size - 1 do
        L1[row + j] = {}
        for k = 1, #L1[row] do
            L1[row + j][k] = L1[row][k]
        end
    end
    row = row + size
    col = 1

    return L1, #L1
end
--- This function takes the qr data from the QR library and converts to the .k
--- file ugrid data.
function array_to_bin(qr_dat)
    local bin_dat = {}

    for i = 1, #qr_dat do
        str = ""

        for j = 1, #qr_dat[i] do
            bin_dat[#bin_dat + 1] = qr_dat[i][j]
        end
    end
    return bin_dat
end

--- This function writes a temp .k file with the celtic grid for the given
--- string.
--- @@@TODO: This should be using the OS temp system but knotplot doesn't have access.
function write_temp(bin_dat)
    -- f = assert (io.tmpfile("wb")) -- open temporary file
    f = assert(io.open("temp.k", "wb")) -- open temporary file
    -- for j=1,#qr_dat[i] do
    --     bin_dat[#bin_dat+1]=square_bin(qr_dat[i][j])
    -- end
    local str = string.char(table.unpack(bin_dat))
    f:write(str)
    f:close() -- close file
end

--- This function extends L1 with L2. I'm sure there's a way to do this natively
--- in lua but I don't know how.
function extend_list(L1, L2)
    for i = 1, #L2 do
        L1[#L1 + 1] = L2[i]
    end
    return L1
end
--------------------------------------------------------------------------------
------------- Main body  -------------------------------------------------------
--------------------------------------------------------------------------------

--- Binary header for the .k file. Next expect bytes are Uint32xUint32 grid size
local header = {0x4B, 0x6E, 0x6F, 0x74, 0x50, 0x6C, 0x6F, 0x74, 0x20, 0x31, 0x2E, 0x30, 0x20, 0x20, 0x0C, 0x0A, 0x4E,
                0x41, 0x4D, 0x45, 0x00, 0x00, 0x00, 0x33, 0x42, 0x61, 0x73, 0x65, 0x64, 0x20, 0x6F, 0x6E, 0x20, 0x41,
                0x2E, 0x53, 0x6C, 0x6F, 0x73, 0x73, 0x20, 0x60, 0x48, 0x6F, 0x77, 0x20, 0x74, 0x6F, 0x20, 0x44, 0x72,
                0x61, 0x77, 0x20, 0x43, 0x65, 0x6C, 0x74, 0x69, 0x63, 0x20, 0x4B, 0x6E, 0x6F, 0x74, 0x77, 0x6F, 0x72,
                0x6B, 0x27, 0x2C, 0x20, 0x70, 0x36, 0x30, 0x43, 0x45, 0x4C, 0x54, 0x00, 0x00, 0x00, 0xB5, 0x67, 0x72,
                0x69, 0x64}
--- Binary footer for the .k file
local footer = {0x65, 0x6E, 0x64, 0x66, 0x0A, 0x0A, 0x0A, 0x0A}
--- Table for binary version of QR data with header and footer.
local bin_dat = {}
--- Object string
local qr_str = ""

if #arg > 1 then

    --- first argument is expected to be the string to convert.
    qr_str = arg[1]
    text_scale = arg[2]
    --- Try to encode string as QR code with high error tolerance. x
    local ok, n = str_to_array(figlet.getString(qr_str), text_scale)

    --- If success
    local size = {0x00, 0x00, 0x00, #ok, 0x00, 0x00, 0x00, #ok[1]} --- set grid size

    --- Build binary file
    extend_list(bin_dat, header)
    extend_list(bin_dat, size)
    extend_list(bin_dat, array_to_bin(ok))
    extend_list(bin_dat, footer)

    --- Write binary file
    write_temp(bin_dat)

    --- Get filename for qr code
    file_name = string.gsub(qr_str, "[#$%&'()_*+,/:;<=>?@\\^`{|}~]", "")

    --- Knotplot commands
    executeKP(file_name, [[
    reset all
    load temp.k
    celt diagram
    celt copy
    sradius = 0.45
    vscale = 0.1
    nseg = 50
    background = white
    color all red
    matrgb s 0 0 0 s
    ortho
    psmode=40
    psout ctext_ARG1
    ]])

    --- change line thickness for ps file
    f = assert(io.open("ctext_" .. file_name .. ".eps", "r"))
    local str = ""
    while true do
        local line = f:read()
        if line == nil then
            break
        end
        if line == "/thin 2.114883 def" then
            str = str .. "/thin 9 def" .. "\n"
        end
        if line == "/thin 1.654187 def" then
            str = str .. "/thin 7 def" .. "\n"
        elseif line == "/thick {thin 2.000000 mul} def" then
            str = str .. "/thick {thin 1.1 mul} def" .. "\n"
        else
            str = str .. line .. "\n"
        end
    end
    f:close() -- close file

    f = assert(io.open("qr_" .. file_name .. ".eps", "w"))
    f:write(str)
    f:close() -- close file
else
    executeKP([[
        echo You need an argument.
        ]])
end
