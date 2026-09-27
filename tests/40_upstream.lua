-- Optional integration uses pinned, unmodified upstream sea-ex source in a
-- restricted environment, never installed in the game or copied into releases.
if not upstream_source then
    print("NOTE: upstream comparator tests require --upstream (network)")
    return
end
local function fixture()
    local sections = { ammo = { 1, 1, "ammo" }, rifle = { 2, 2, "weapon" },
        powder = { 1, 1, "ammo_parts" }, bandage = { 1, 1, "medical" } }
    local env = {
        pairs = pairs, type = type,
        SYS_GetParam = function(_, sec, param)
            return sections[sec][param == "inv_grid_width" and 1 or 2]
        end,
        zzz_rax_sortingplus_mcm = {
            SORTFAVS = true, SORTJUNK = true, favorite_itms = {}, junk_itms = {},
            item_order = { weapon = 1, ammo = 9, ammo_parts = 9.5, medical = 12, na = 30, favorites = 0, junk = 40 },
            get_sort_kind = function(sec) return sections[sec][3] end,
        },
    }
    local chunk = assert(loadstring(upstream_source, "@pinned_upstream_seax"))
    setfenv(chunk, env); chunk()
    local cc = container("actor_bag")
    cc.cols, cc.grid = 4, { { true, true, true, true } }
    function cc:Print() end
    function cc:Grow()
        local row = {}; for c = 1, self.cols do row[c] = true end
        self.grid[#self.grid + 1] = row
    end
    function cc:IsFreeRoom(row, col, w, h)
        for r = row, row + h - 1 do
            if not self.grid[r] then return false end
            for c = col, col + w - 1 do if not self.grid[r][c] then return false end end
        end
        return true
    end
    function cc:TakeRoom(row, col, w, h)
        for r = row, row + h - 1 do
            for c = col, col + w - 1 do self.grid[r][c] = false end
        end
        self.row_end, self.col_end = math.max(self.row_end, row + h - 1), math.max(self.col_end, col + w - 1)
        return { x = col, y = row, w = w, h = h }
    end
    for id, sec in ipairs({ "ammo", "rifle", "powder", "ammo", "bandage" }) do
        local cell = cc:add(id, 8); cell.section = sec; cc.objects[id] = object(id, sec)
    end
    local sorter = siss_sort.new({ object = function(id) return cc.objects[id] end,
        iter = sorted_pairs, context = siss_util.context(),
        order = function(_, items) return env.sort_by_kind_factory(items) end })
    return cc, sorter, env
end
test("real sea-ex comparator/placement integrates with the detached-grid sorter", function()
    local cc, sorter = fixture(); local find = cc.FindFreeCell
    local result = sorter.sort(cc); eq(result.ok, true); eq(result.repainted, 5)
    local expected = { {2,3}, {1,1}, {1,4}, {1,3}, {1,5} }
    for id, pos in ipairs(expected) do
        eq(cc.cell[id].area.x, pos[1], "x of " .. id)
        eq(cc.cell[id].area.y, pos[2], "y of " .. id)
    end
    eq(cc.cell[2].area.h, 2); eq(cc.FindFreeCell, find)
    eq(sorter.sort(cc).repainted, 0); eq(cc.sets, 5)
end)
test("real sea-ex respects saved favorite and junk precedence", function()
    local cc, sorter, env = fixture()
    env.zzz_rax_sortingplus_mcm.favorite_itms.bandage = "favorites"
    env.zzz_rax_sortingplus_mcm.junk_itms.ammo = "junk"
    eq(sorter.sort(cc).ok, true)
    eq(cc.cell[5].area.y, 1); eq(cc.cell[2].area.y, 2)
    assert(cc.cell[1].area.y > cc.cell[3].area.y)
end)
test("real sea-ex oversized item fails planning without touching live UI", function()
    local cc, sorter = fixture(); cc.cols = 1
    local grid, find = cc.grid, cc.FindFreeCell
    local result = sorter.sort(cc)
    eq(result.ok, false); eq(result.rollback_ok, true)
    eq(cc.grid, grid); eq(cc.FindFreeCell, find); eq(cc.sets, 0)
end)
