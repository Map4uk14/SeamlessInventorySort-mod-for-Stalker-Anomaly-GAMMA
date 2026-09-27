test("settings validate booleans, clamp numbers, reject NaN and enums", function()
    local data = { enable = "false", osc_limit = 999, body_mode = "bogus", hl_new_a = 0/0 }
    local config = siss_config.new(function(path) return data[path:match("([^/]+)$")] end)
    eq(config.refresh(), true); eq(config.refresh(), false)
    eq(config.get("enable"), false); eq(config.get("osc_limit"), 20)
    eq(config.get("body_mode"), "sort"); eq(config.get("hl_new_a"), 60)
    data.osc_limit = -4; data.enable = "nonsense"; config.refresh()
    eq(config.get("osc_limit"), 3); eq(config.get("enable"), true)
end)
test("missing or failing MCM uses defaults", function()
    local config = siss_config.new(function() error("no MCM") end)
    config.refresh(); eq(config.get("ap_order"), 9.5); eq(config.npc_sort(), "kind")
end)
test("wrapper context preserves nil returns, nesting, and errors", function()
    local c = siss_util.context()
    local r = siss_util.pack(c.call("outer", function()
        eq(c.get(), "outer")
        c.call("inner", function() eq(c.get(), "inner") end)
        eq(c.get(), "outer"); return nil, 2, nil
    end))
    eq(r.n, 3); eq(r[2], 2); eq(c.get(), nil)
    eq(pcall(c.call, "bad", function() error("original failure") end), false)
    eq(c.get(), nil)
end)
test("hook registration is idempotent and retries missing functions", function()
    local hook, t, count = siss_util.hooks(error), {}, 0
    local wrap = function(orig) return function() count = count + 1; return orig() end end
    hook(t, "fn", wrap)
    t.fn = function() return 9 end
    hook(t, "fn", wrap); hook(t, "fn", wrap); eq(t.fn(), 9); eq(count, 1)
    local ours = t.fn; t.fn = function() return ours() end
    hook(t, "fn", wrap); t.fn(); eq(count, 2)
end)

local function sort_fixture()
    local cc, context = container("actor_bag", 2), siss_util.context()
    local deps = { object = function(id) return cc.objects[id] end, iter = sorted_pairs,
        order = function(c) return c:GetSortMethod() end, context = context }
    return cc, siss_sort.new(deps), deps, context
end
test("unchanged layout never calls the cell renderer or scrollbar", function()
    local cc, sorter = sort_fixture()
    local result = sorter.sort(cc)
    eq(result.ok, true); eq(result.moved, false); eq(cc.sets, 0); eq(cc.scrolls, 0)
    eq(cc.rKind.extra, 8)
end)
test("sort only repaints moved parents, not stacked children", function()
    local cc, sorter = sort_fixture()
    cc.cell[1].area.x = 9
    for id = 3, 1002 do cc.indx_id[id] = 1 end
    local result = sorter.sort(cc)
    eq(result.cells, 2); eq(result.repainted, 1); eq(cc.sets, 1); eq(cc.scrolls, 1)
    eq(cc.indx_id[1002], 1)
end)
test("comparator factory failure leaves original grid and context untouched", function()
    local cc, sorter, deps, context = sort_fixture()
    local grid = cc.grid
    deps.order = function() error("factory") end
    local result = sorter.sort(cc)
    eq(result.ok, false); eq(cc.grid, grid); eq(cc.sets, 0); eq(context.get(), nil)
end)
test("planning failure restores grid, metadata, and temporary placement closure", function()
    local cc, sorter, deps, context = sort_fixture()
    local grid, kind, find = cc.grid, cc.rKind, cc.FindFreeCell
    deps.order = function(c) return c:GetSortMethod(), function(self)
        self.grid[1][4] = false; self.row_end = 99; error("placement")
    end end
    local result = sorter.sort(cc)
    eq(result.ok, false); eq(cc.grid, grid); eq(grid[1][4], true)
    eq(cc.rKind, kind); eq(cc.row_end, 1); eq(cc.FindFreeCell, find); eq(context.get(), nil)
end)
for _, failure in ipairs({ "throw", "false" }) do
    test("rollback includes a renderer that mutates then " .. failure, function()
        local cc, sorter = sort_fixture()
        cc.cell[1].area.x, cc.cell[2].area.x = 8, 9
        local grid, cell, calls = cc.grid, cc.cell[2], 0
        function cell:Set(obj, area)
            self.area = area; calls = calls + 1
            if calls == 1 then if failure == "throw" then error("renderer") else return false end end
            return true
        end
        local result = sorter.sort(cc)
        eq(result.ok, false); eq(result.rollback_ok, true); eq(cc.grid, grid)
        eq(cc.cell[1].area.x, 8); eq(cc.cell[2].area.x, 9); eq(calls, 2)
    end)
end
test("failed rollback is reported explicitly", function()
    local cc, sorter = sort_fixture()
    cc.cell[1].area.x = 8
    cc.cell[1].Set = function() return false end
    eq(sorter.sort(cc).rollback_ok, false)
end)
test("missing live parent object fails before mutation", function()
    local cc, sorter = sort_fixture()
    cc.objects[2] = nil
    eq(sorter.sort(cc).ok, false); eq(cc.sets, 0)
end)
test("unsupported sort modes are left to the game", function()
    local cc, sorter = sort_fixture(); cc.sort_method = "sizekind"
    eq(sorter.sort(cc).skipped, true); eq(cc.sets, 0)
end)

test("opening snapshot avoids duplicate work on unchanged refreshes", function()
    local f = controller_fixture()
    for _ = 1, 50 do f.controller.refresh(f.menu, f.cc) end
    eq(f.sorts, 0); eq(f.clock.count(), 0); eq(f.controller.stats().unchanged, 50)
end)
test("exact mappings catch ID replacements with equal counts and sums", function()
    local f = controller_fixture()
    f.cc:add(5); f.controller.reset(f.menu, f.cc) -- 1, 2, 5 sum 8
    f.cc.indx_id[2], f.cc.indx_id[5] = nil, nil
    f.cc:add(3); f.cc:add(4) -- 1, 3, 4 sum 8
    f.controller.refresh(f.menu, f.cc); eq(f.sorts, 1)
end)
test("a stacked child's new parent invalidates the snapshot", function()
    local f = controller_fixture(); f.cc.indx_id[3] = 1; f.controller.reset(f.menu, f.cc)
    f.cc.indx_id[3] = 2; f.controller.refresh(f.menu, f.cc); eq(f.sorts, 1)
end)
test("keep-gaps skips pure removal but not moved remaining cells", function()
    local f = controller_fixture({ keep_gaps = true })
    f.cc.indx_id[2] = nil; f.controller.refresh(f.menu, f.cc); eq(f.sorts, 0)
    f.cc.cell[1].area.x = 5; f.controller.refresh(f.menu, f.cc); eq(f.sorts, 1)
end)
test("Shift coalesces changed and forced requests into one release sort", function()
    local f = controller_fixture(); f.shift = true; f.cc:add(3)
    for _ = 1, 10 do f.controller.refresh(f.menu, f.cc, nil, true) end
    eq(f.sorts, 0); eq(f.clock.count(), 1)
    f.clock.tick(); eq(f.sorts, 0)
    f.shift = false; f.clock.tick(); eq(f.sorts, 1); eq(f.clock.count(), 0); eq(f.cc.position, 42)
end)
test("disassembly extends its deadline and settles once", function()
    local f = controller_fixture({ keep_gaps = true, disasm_delay = 1 })
    f.policy.disassemble(); f.cc.indx_id[2] = nil; f.controller.refresh(f.menu, f.cc)
    f.clock.tick(700); f.policy.disassemble(); f.clock.tick(500); eq(f.sorts, 0)
    f.clock.tick(600); eq(f.sorts, 1)
end)
test("zero-delay disassembly still freezes the synchronous callback burst", function()
    local f = controller_fixture(); f.policy.disassemble(); f.cc:add(3)
    f.controller.refresh(f.menu, f.cc); eq(f.sorts, 0)
    f.clock.tick(); eq(f.sorts, 1)
end)
test("animated disassembly includes the engine's three-second delay", function()
    local f = controller_fixture(); f.animations = true; f.policy.disassemble(); f.cc:add(3)
    f.controller.refresh(f.menu, f.cc); f.clock.tick(2999); eq(f.sorts, 0)
    f.clock.tick(51); eq(f.sorts, 1)
end)
test("close/reset invalidates old deferred callbacks", function()
    local f = controller_fixture(); f.shift = true; f.cc:add(3); f.controller.refresh(f.menu, f.cc)
    f.controller.clear(); f.shift = false; f.clock.tick(); eq(f.sorts, 0); eq(f.clock.count(), 0)
end)
test("partner or container replacement invalidates deferred work", function()
    for _, replace in ipairs({ "partner", "container", "menu" }) do
        local f = controller_fixture(); local npc = {}
        f.menu.GetPartner = function() return npc end; f.controller.reset(f.menu, f.cc)
        f.shift = true; f.controller.refresh(f.menu, f.cc, nil, true)
        if replace == "partner" then npc = {} elseif replace == "container" then f.menu.CC.actor_bag = container()
        else f.current = {} end
        f.shift = false; f.clock.tick(); eq(f.sorts, 0, replace)
    end
end)
test("deferred requests obey master and window switches at execution time", function()
    for _, option in ipairs({ "enable", "win_inventory" }) do
        local f = controller_fixture(); f.shift = true; f.controller.refresh(f.menu, f.cc, nil, true)
        f.values[option] = false; f.shift = false; f.clock.tick(); eq(f.sorts, 0)
    end
end)
test("sort failures retry at most three times; failed rollback suspends immediately", function()
    for _, rollback in ipairs({ true, false }) do
        local f = controller_fixture(); f.result = { ok = false, rollback_ok = rollback, error = "bad" }
        f.controller.refresh(f.menu, f.cc, nil, true)
        for _ = 1, 5 do f.clock.tick(1001) end
        eq(f.sorts, rollback and 3 or 1); eq(f.clock.count(), 0)
    end
end)
test("oscillation guard schedules a cooldown instead of dropping work", function()
    local f = controller_fixture({ osc_limit = 3, osc_cooldown = 0.5 })
    for _ = 1, 5 do f.controller.refresh(f.menu, f.cc, nil, true) end
    eq(f.sorts, 3); f.clock.tick(501); eq(f.sorts, 4); eq(f.clock.count(), 0)
end)

test("only confirmed dead actors are classified as corpses", function()
    local f = controller_fixture(); local cc = container("npc_bag")
    local npc; f.menu.GetPartner = function() return npc end
    for _, value in ipairs({ {}, { alive = function() error("no member") end },
        { alive = function() return nil end }, { alive = function() return true end },
        { box = true, alive = function() return false end } }) do
        npc = value; eq(f.policy.corpse(f.menu, cc), false)
    end
    npc = { alive = function() return false end }; eq(f.policy.corpse(f.menu, cc), true)
end)
test("LTT reveal then Shift waits for both gates; missing LTT sorts normally", function()
    local f = controller_fixture({ body_mode = "ltt_after" })
    local cc, npc = container("npc_bag", 2), { id = function() return 99 end, alive = function() return false end }
    f.menu.mode = "loot"; f.menu.CC.npc_bag = cc; f.menu.GetPartner = function() return npc end
    local busy = true; f.hidden = function() return busy end
    f.controller.reset(f.menu, cc); f.clock.tick(); eq(f.sorts, 0)
    busy, f.shift = false, true; f.clock.tick(300); eq(f.sorts, 0)
    f.shift = false; f.clock.tick(); eq(f.sorts, 1)
    f.hidden = nil; eq(f.policy.gate(f.menu, cc, {}), "sort")
end)
test("newly hidden LTT items cannot reuse a stale finished-reveal result", function()
    local f = controller_fixture({ body_mode = "ltt_after" })
    local cc = container("npc_bag", 1)
    f.menu.GetPartner = function() return { id = function() return 99 end, alive = function() return false end } end
    local busy, state = false, {}
    f.hidden = function() return busy end
    eq(f.policy.gate(f.menu, cc, state), "sort")
    busy = true; eq(f.policy.gate(f.menu, cc, state), "wait")
end)
test("corpse override restores SortingPlus mode when disabled", function()
    local f = controller_fixture({ body_mode = "never" }); local cc = container("npc_bag")
    f.menu.mode, f.menu.CC.npc_bag = "loot", cc
    f.menu.GetPartner = function() return { alive = function() return false end } end
    f.policy.apply_body(f.menu); eq(cc.sort_method, "sizekind")
    f.values.win_loot = false; f.policy.apply_body(f.menu); eq(cc.sort_method, "kind")
end)
