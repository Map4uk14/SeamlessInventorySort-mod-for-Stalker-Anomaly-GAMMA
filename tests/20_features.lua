local function supplies_fixture(overrides)
    local config, values = options(overrides)
    local f = { values = values, slots = {}, calls = 0, junk = {}, favorites = {} }
    f.supplies = siss_supplies.new(config, {
        slot = function(id) return f.slots[id] end, weapon = function() return true end,
        fake = function() return false end,
        param = function(kind, sec, key)
            if key == "is_component" then return sec == "powder" end
            if key == "scopes" then return " scope_a, scope_b " end
        end,
        ammo = function() f.calls = f.calls + 1; return { ammo = true } end,
        addon = function(_, key) if key == "silencer_name" then return " silencer " end end,
        axis = function() return { h = 40 } end,
        color = 123, favorite = function(sec) return f.favorites[sec] end,
        junk = function(sec) return f.junk[sec] end,
    })
    f.slots[1] = object(1, "weapon")
    return f
end
test("supplies scan only changed equipment; forced identical scan does not request sort", function()
    local f = supplies_fixture()
    eq(f.supplies.refresh(), true); eq(f.supplies.refresh(), false); eq(f.calls, 1)
    eq(f.supplies.refresh(true), false); eq(f.calls, 2)
    f.slots[1] = object(2, "another_weapon")
    eq(f.supplies.refresh(), false); eq(f.calls, 3)
end)
test("vacant second slot and changing equipment cannot corrupt the supplies signature", function()
    local f = supplies_fixture()
    f.slots[3], f.slots[5] = object(3, "sidearm"), object(5, "knife")
    eq(f.supplies.refresh(), true) -- slot 2 is empty between occupied slots
    eq(f.supplies.kind({ ID = "actor_bag" }, "ammo", "ammo"), "favorites")
    setmetatable(f.slots, { __index = function(_, slot)
        if slot == 2 then error("equipment unavailable") end
    end })
    eq(f.supplies.refresh(), false)
    setmetatable(f.slots, nil)
    f.slots[1] = { id = function() return 1 end, section = function() return nil end }
    eq(f.supplies.refresh(), false) -- provisional clone must not erase the last good set
    eq(f.supplies.kind({ ID = "actor_bag" }, "ammo", "ammo"), "favorites")
    f.slots[1] = { id = function() error("clone changing") end }
    eq(f.supplies.refresh(), false)
    f.slots[1] = object(6, "replacement")
    eq(f.supplies.refresh(), false) -- weapon changed, same compatible sections
    f.slots[2] = object(2, "backup")
    eq(f.supplies.refresh(), false)
end)
test("temporary categories respect own-bag toggle, junk, favorites, and unknown contexts", function()
    local f = supplies_fixture({ auto_fav_own = false }); f.supplies.refresh()
    eq(f.supplies.kind({ ID = "actor_bag" }, "ammo", "ammo"), "ammo")
    eq(f.supplies.kind({ ID = "npc_bag" }, "ammo", "ammo"), "favorites")
    eq(f.supplies.kind(nil, "ammo", "ammo"), "ammo")
    eq(f.supplies.kind({ ID = "actor_trade" }, "ammo", "ammo"), "ammo")
    f.junk.ammo = true
    eq(f.supplies.kind({ ID = "npc_bag" }, "ammo", "ammo"), "ammo")
    f.junk.ammo = nil; f.favorites.ammo = true
    eq(f.supplies.kind({ ID = "npc_bag" }, "ammo", "ammo"), "ammo")
    eq(f.supplies.kind(nil, "powder", "ammo"), "ammo_parts")
end)
test("supplies trim attachment lists and reuse icon geometry", function()
    local f = supplies_fixture(); f.supplies.refresh()
    local cc = container("npc_bag")
    eq(f.supplies.kind(cc, "scope_b", "addon"), "favorites")
    eq(f.supplies.kind(cc, "silencer", "addon"), "favorites")
    local cell = { container = cc, section = "ammo" }
    eq(f.supplies.highlight(cell), 123)
    eq(f.supplies.icon(cell), f.supplies.icon(cell))
    f.junk.ammo = true; eq(f.supplies.icon(cell), nil)
end)
test("disabling compatible supplies clears inferred categories without saved-state writes", function()
    local f = supplies_fixture(); f.supplies.refresh()
    f.values.auto_fav = false; eq(f.supplies.refresh(), true)
    eq(f.supplies.kind(container(), "ammo", "ammo"), "ammo")
    eq(next(f.favorites), nil); eq(next(f.junk), nil)
end)
test("first pickup in an initially empty bag gets a loot mark", function()
    local config = options(); local loot = siss_loot.new(config, { color = function() return 7 end })
    local cc = container(); loot.begin(cc)
    local cell = cc:add(1); eq(loot.detect(cc), true); eq(loot.highlight(cell), 7)
    loot.clear(); eq(loot.highlight(cell), nil)
end)
test("new stacked child marks its parent and losing that child clears the tint", function()
    local config = options(); local loot = siss_loot.new(config, { color = function() return 7 end })
    local cc = container("actor_bag", 1); loot.begin(cc)
    cc.indx_id[2] = 1; loot.detect(cc); eq(loot.highlight(cc.cell[1]), 7)
    cc.indx_id[2] = nil; loot.detect(cc); eq(loot.highlight(cc.cell[1]), nil)
    eq(cc.cell[1].highlights, 1)
end)
test("loot baseline and marks do not leak across sessions or disabled options", function()
    local config, values = options(); local loot = siss_loot.new(config, { color = function() return 7 end })
    local cc = container("actor_bag", 1); loot.begin(cc); cc:add(2); loot.detect(cc)
    loot.begin(cc); eq(loot.detect(cc), false); eq(loot.highlight(cc.cell[2]), nil)
    cc:add(3); loot.detect(cc); values.hl_new = false; loot.options()
    eq(loot.highlight(cc.cell[3]), nil)
end)

local function weapon_fixture()
    local config, values = options(); local clock = clock_fixture()
    local f = { slots = {}, values = values, clock = clock, open = true, moves = 0, known = {} }
    f.guard = siss_weapons.new(config, {
        weapon = function(o) return type(o) == "table" and o.id end,
        owned = function(o) return not o.foreign end,
        slot = function(id) return f.slots[id] end, now = clock.now, schedule = clock.schedule,
        family = function(sec) return sec:match("^[^_]+") end,
        open = function() return f.open end, known_ids = function() return f.known end,
        ruck = function(obj)
            f.moves = f.moves + 1
            for id, current in pairs(f.slots) do if current == obj then f.slots[id] = nil end end
        end,
    }, siss_util)
    return f
end
test("clone guard matches scope child/parent family and preserves nil return values", function()
    local f = weapon_fixture()
    local wrap = f.guard.wrap(function() return nil, 8, nil end)
    local r = siss_util.pack(wrap(object(1, "ak")))
    eq(r.n, 3); eq(r[2], 8)
    f.slots[1] = object(9, "ak_scope"); f.clock.tick(); eq(f.moves, 1)
    f.clock.tick(500); f.clock.tick(500); eq(f.clock.count(), 0)
end)
test("clone guard ignores equipped, foreign, unknown and preexisting same-family weapons", function()
    local f = weapon_fixture(); local w = object(1, "ak")
    f.slots[1] = w; f.guard.wrap(function() end)(w); eq(f.clock.count(), 0)
    f.slots[1] = nil; w.foreign = true; f.guard.wrap(function() end)(w); eq(f.clock.count(), 0)
    f.guard.wrap(function() end)(123); eq(f.clock.count(), 0)
    w.foreign = nil; f.known[7] = true; f.guard.wrap(function() end)(w)
    f.slots[1] = object(7, "ak_scope"); f.slots[2] = object(8, "svd")
    f.clock.tick(); eq(f.moves, 0)
end)
test("nested clone wrappers coalesce; thrown originals do not arm guards", function()
    local f = weapon_fixture(); local w = object(1, "ak")
    local inner = f.guard.wrap(function() return 8 end)
    local outer = f.guard.wrap(function(obj) return inner(obj) end)
    eq(outer(w), 8); eq(f.clock.scheduled, 1)
    f.guard.clear(); f.clock.tick()
    eq(pcall(f.guard.wrap(function() error("clone failed") end), w), false)
    eq(f.clock.count(), 0)
end)
test("weapon watcher stops on close, disable, or three-second deadline", function()
    for _, stop in ipairs({ "close", "disable", "timeout" }) do
        local f = weapon_fixture(); f.guard.wrap(function() end)(object(1, "ak"))
        if stop == "close" then f.open = false elseif stop == "disable" then f.values.no_slot_jump = false end
        f.clock.tick(stop == "timeout" and 3000 or 50); eq(f.clock.count(), 0)
    end
end)
