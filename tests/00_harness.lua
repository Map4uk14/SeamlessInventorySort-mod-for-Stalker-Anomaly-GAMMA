local passed, failed = 0, 0
function eq(actual, expected, message)
    if actual ~= expected then error((message or "values differ") .. ": " .. tostring(actual)
        .. " ~= " .. tostring(expected), 2) end
end
function test(name, fn)
    local ok, message = xpcall(fn, debug.traceback)
    if ok then passed = passed + 1; print("PASS: " .. name)
    else failed = failed + 1; print("FAIL: " .. name .. "\n" .. message) end
end
function finish_tests()
    print(string.format("%d passed, %d failed", passed, failed))
    assert(failed == 0, "regression tests failed")
end
function options(overrides)
    local default = siss_config.new(function() end)
    local values = overrides or {}
    return { get = function(key) if values[key] ~= nil then return values[key] end
        return default.get(key) end, npc_sort = function() return "kind" end }, values
end
function clock_fixture()
    local clock = { time = 0, jobs = {}, scheduled = 0 }
    function clock.now() return clock.time end
    function clock.schedule(name, fn) clock.jobs[name] = fn; clock.scheduled = clock.scheduled + 1 end
    function clock.tick(ms)
        clock.time = clock.time + (ms or 50)
        local pending = {}
        for name, fn in pairs(clock.jobs) do pending[name] = fn end
        for name, fn in pairs(pending) do if fn() then clock.jobs[name] = nil end end
    end
    function clock.count() local n = 0; for _ in pairs(clock.jobs) do n = n + 1 end; return n end
    return clock
end
function object(id, sec)
    return { id = function() return id end, section = function() return sec or "item" end }
end
function sorted_pairs(t, cmp)
    local keys = {}
    for key in pairs(t) do keys[#keys + 1] = key end
    table.sort(keys, function(a, b) return cmp(t, a, b) end)
    local i = 0
    return function() i = i + 1; local key = keys[i]; if key then return key, t[key] end end
end
function container(id, count)
    local cc = { ID = id or "actor_bag", sort_method = "kind", cell = {}, indx_id = {},
        grid = { { false, false, true, true } }, rKind = { last = false, row = 1, extra = 8 },
        row_end = 1, col_end = count or 0, shown = true, sets = 0, scrolls = 0, objects = {} }
    function cc:IsShown() return self.shown end
    function cc:GetSortMethod() return function(t, a, b) return t[a]:id() < t[b]:id() end end
    function cc:FindFreeCell(obj)
        self.col_end = self.col_end + 1
        self.row_end = 1
        self.grid[1][self.col_end] = false
        return { x = obj:id(), y = 1, w = 1, h = 1 }
    end
    function cc:Scroll_Reinit() self.scrolls = self.scrolls + 1 end
    function cc:Scroll_SetPos(pos) self.position = pos end
    cc.scroll = { GetCurrentScrollPos = function() return 42 end }
    function cc:add(item_id, x, index)
        index = index or item_id
        local cell = { ID = item_id, section = "item", container = self,
            area = { x = x or item_id, y = 1, w = 1, h = 1 }, highlights = 0 }
        function cell:Set(obj, area) self.area = area; cc.sets = cc.sets + 1; return true end
        function cell:Highlight() self.highlights = self.highlights + 1 end
        self.cell[index], self.indx_id[item_id], self.objects[item_id] = cell, index, object(item_id)
        return cell
    end
    for i = 1, count or 0 do cc:add(i) end
    return cc
end
function controller_fixture(overrides)
    local config, values = options(overrides)
    local clock, cc = clock_fixture(), container("actor_bag", 2)
    local menu = { mode = "inventory", CC = { actor_bag = cc } }
    local f = { config = config, values = values, clock = clock, cc = cc, menu = menu,
        current = menu, sorts = 0, moved = 0, shift = false, animations = false, errors = {} }
    f.policy = siss_policy.new(config, {
        now = clock.now, invbox = function(npc) return npc.box end,
        animations = function() return f.animations end,
        shift = function() return f.shift end, ltt = function() return f.hidden end,
    })
    f.sorter = { sort = function()
        f.sorts = f.sorts + 1
        return f.result or { ok = true, moved = true }
    end }
    f.controller = siss_controller.new(config, f.policy, f.sorter, {
        menu = function() return f.current end, now = clock.now, schedule = clock.schedule,
        scroll = function() return 42 end, restore_scroll = function(c, p) c.position = p end,
        moved = function() f.moved = f.moved + 1 end,
        report = function(k, v) f.errors[#f.errors + 1] = { k, v } end,
    })
    f.controller.reset(menu, cc)
    return f
end
