-- Contract-shaped game doubles exercise the production composition root.
-- These are not an emulator for Anomaly's C++ UI userdata.
function runtime_fixture(values, without_seax)
    local f = { values = values or {}, clock = clock_fixture(), callbacks = {},
        logs = {}, slots = {}, favorites = {}, junk = {}, registrations = 0, highlight_checks = {}, owned = {}, ownership_scans = 0,
        original_refresh = 0, paints = 0, resets = 0, factories = 0, objects = {}, shift = false }
    local g = setmetatable({}, { __index = _G })
    f.g = g
    g.printf = function(msg) f.logs[#f.logs + 1] = msg end
    g.GetARGB = function(a, r, green, b) return a * 16777216 + r * 65536 + green * 256 + b end
    g.time_global = f.clock.now
    g.CreateTimeEvent = function(a, b, delay, fn) f.clock.schedule(a .. b, fn) end
    g.RegisterScriptCallback = function(name, fn)
        assert(not f.callbacks[name], "duplicate callback " .. name); f.callbacks[name] = fn
    end
    g.ui_mcm = { get = function(path)
        local key = path:match("([^/]+)$"); return f.values[key]
    end }
    g.GetActorMenu = function() return f.current end
    g.IsWeapon = function(obj) return type(obj) == "table" and obj.weapon end
    g.IsInvbox = function(obj) return obj.box end
    g.IsItem = function() return false end
    g.SYS_GetParam = function(_, sec, key)
        if key == "is_component" then return sec == "powder" end
        if key == "parent_section" then return sec:match("^[^_]+") end
    end
    g.DIK_keys = { DIK_LSHIFT = 1, DIK_RSHIFT = 2 }
    g.key_state = function() return f.shift and 1 or 0 end
    g.spairs = sorted_pairs
    g.level = { object_by_id = function(id) return f.objects[id] end }
    g.db = { actor = {
        id = function() return 0 end, item_in_slot = function(_, id) return f.slots[id] end,
        iterate_inventory = function(self, fn)
            f.ownership_scans = f.ownership_scans + 1
            for _, obj in pairs(f.owned) do fn(self, obj) end
        end,
        move_to_ruck = function(_, obj) for id, w in pairs(f.slots) do if w == obj then f.slots[id] = nil end end end,
    } }
    g.utils_xml = { get_item_axis = function() return { w = 1, h = 1 } end }
    g.utils_item = {
        get_ammo = function() return { item = true } end, get_wpn_param = function() end,
        attach_addon = function() return nil, 2, nil end, detach_addon = function() end,
    }
    g.item_weapon = { attach_scope = function() end, detach_scope = function() end }
    g.item_parts = { disassembly_item = function() return nil, 4, nil end }
    g.ammo_maker = { breakdown = function() end }
    local rax = { item_order = { ammo = 9, favorites = 1 }, ab_k = {} }
    g.zzz_rax_sortingplus_mcm = rax
    rax.get_sort_kind = function() return "ammo" end
    rax.is_favorite = function(sec) return f.favorites[sec] end
    rax.is_junk = function(sec) return f.junk[sec] end
    rax.set_favorite = function(sec, value) f.favorites[sec] = value end
    rax.set_junk = function(sec, value) f.junk[sec] = value end
    rax.loadsettings = function() rax.item_order = {}; rax.ab_k = {}; return nil, 7, nil end
    local function registration() f.registrations = f.registrations + 1 end
    g.rax_persistent_highlight = { register = function(id, fn)
        registration(); f.highlight_checks[id] = fn
    end }
    g.rax_icon_layers = { register = registration, refresh = function(mode)
        f.original_refresh = f.original_refresh + 1
        if mode == 1 then f.current:TMode_ResetInventories() else f.current:UpdateItems() end
        return nil, 3, nil
    end }
    if not without_seax then
        g.seax_sortingplus_opt_sort_by_kind = { get_sort_kind = rax.get_sort_kind,
            sort_by_kind_factory = function(items)
                f.factories = f.factories + 1
                return function(t, a, b) return t[a]:id() < t[b]:id() end
            end }
    end
    local cell_class = {}
    function cell_class:Reinit()
        self.open_kind = rax.get_sort_kind("item")
        rax.ab_k.item = self.open_kind
        if f.throw_reinit then error("original Reinit") end
        return nil, 5, nil
    end
    function cell_class:GetSortOrder() return rax.get_sort_kind("item") end
    g.utils_ui = { UICellContainer = cell_class }
    local ui = {}
    local function reset(self, ids)
        f.resets = f.resets + 1
        for _, id in ipairs(ids) do self.CC[id]:Reinit() end
        return nil, 9, nil
    end
    function ui:IMode_ResetInventories() return reset(self, { "actor_bag" }) end
    function ui:LMode_ResetInventories(only_reset)
        if only_reset then f.resets = f.resets + 1; return end
        return reset(self, { "actor_bag", "npc_bag" })
    end
    function ui:LMode_ResetNPCInventory() return reset(self, { "npc_bag" }) end
    function ui:TMode_ResetInventories() return reset(self, { "actor_trade_bag", "npc_trade_bag" }) end
    local function refresh(self)
        if f.refresh_action then f.refresh_action(self) end
        if f.throw_refresh then error("original Refresh") end
        return nil, 6, nil
    end
    ui.IMode_RefreshInventories, ui.LMode_RefreshInventories, ui.TMode_RefreshInventories = refresh, refresh, refresh
    function ui:UpdateItems() f.paints = f.paints + 1 end
    function ui:UnHighlight_All() end
    g.ui_inventory = { UIInventory = ui }
    f.menu = setmetatable({ mode = "inventory", CC = {}, GetPartner = function() return f.partner end }, { __index = ui })
    f.current = f.menu
    for _, id in ipairs({ "actor_bag", "npc_bag", "actor_trade_bag", "npc_trade_bag", "actor_trade", "npc_trade" }) do
        local cc = container(id, 2)
        setmetatable(cc, { __index = cell_class })
        cc.shown = id == "actor_bag"
        f.menu.CC[id] = cc
        for item_id, obj in pairs(cc.objects) do f.objects[item_id] = obj end
    end
    for id, obj in pairs(f.objects) do f.owned[id] = obj end
    function f.mode(mode)
        f.menu.mode = mode
        for id, cc in pairs(f.menu.CC) do
            cc.shown = (mode == "inventory" and id == "actor_bag")
                or (mode == "loot" and (id == "actor_bag" or id == "npc_bag"))
                or (mode == "trade" and id:find("trade") ~= nil)
        end
    end
    local w = object(77, "ak"); w.weapon = true; w.parent = function() return g.db.actor end
    f.slots[1] = w
    f.runtime = siss_runtime.new(g); f.runtime.start()
    return f
end

test("opening supplies are prepared before stock Reinit with no second sort or redraw", function()
    local f = runtime_fixture()
    local r = siss_util.pack(f.menu:IMode_ResetInventories())
    eq(r.n, 3); eq(r[2], 9)
    eq(f.menu.CC.actor_bag.open_kind, "favorites")
    f.runtime.show("UIInventory"); f.clock.tick(); f.menu:IMode_RefreshInventories()
    eq(f.factories, 0); eq(f.paints, 0); eq(f.runtime.stats().sorted, 0)
    eq(#f.logs, 0)
end)
test("runtime owns startup callbacks once and retries late optional dependencies", function()
    local f = runtime_fixture(); local installed = f.g.utils_item.attach_addon
    f.runtime.start(); f.runtime.install(); f.runtime.show("UIInventory"); f.runtime.install()
    eq(f.registrations, 3); eq(f.g.utils_item.attach_addon, installed)
    local called = 0
    f.g.item_parts.disassembly_weapon = function() called = called + 1 end
    f.runtime.install(); f.g.item_parts.disassembly_weapon(); eq(called, 1)
end)
test("ordinary icon-only refresh preserves original returns and does not sort", function()
    local f = runtime_fixture(); f.menu:IMode_ResetInventories()
    local r = siss_util.pack(f.g.rax_icon_layers.refresh(false))
    eq(r.n, 3); eq(r[2], 3); eq(f.original_refresh, 1); eq(f.factories, 0)
end)
test("favorite setters sort even with SortingPlus RESORT off, without duplicate callback work", function()
    local f = runtime_fixture(); f.menu:IMode_ResetInventories()
    f.g.zzz_rax_sortingplus_mcm.set_favorite("item", true)
    f.g.rax_icon_layers.refresh(false)
    eq(f.original_refresh, 0); eq(f.factories, 1); eq(f.paints, 1)
    f.clock.tick(); eq(f.factories, 1); eq(f.paints, 1)
end)
test("direct favorite setter without refresh still coalesces a sort", function()
    local f = runtime_fixture(); f.menu:IMode_ResetInventories()
    f.g.zzz_rax_sortingplus_mcm.set_favorite("item", true)
    f.g.zzz_rax_sortingplus_mcm.set_junk("powder", true)
    f.clock.tick(); eq(f.factories, 1); eq(f.paints, 1)
end)
test("favorite sorting defers through Shift and never rebuilds trade baskets", function()
    local f = runtime_fixture(); f.mode("trade"); f.menu:TMode_ResetInventories()
    local actor_basket, npc_basket = f.menu.CC.actor_trade, f.menu.CC.npc_trade
    local actor_cells, npc_cells = actor_basket.cell, npc_basket.cell
    f.shift = true; f.g.rax_icon_layers.refresh(1)
    eq(f.factories, 0); eq(f.original_refresh, 0); eq(f.resets, 1)
    f.shift = false; f.clock.tick(); eq(f.factories, 2); eq(f.resets, 1)
    eq(actor_basket.cell, actor_cells); eq(npc_basket.cell, npc_cells)
    eq(actor_basket.sets, 0); eq(npc_basket.sets, 0)
end)
test("runtime preserves original refresh errors and multiple returns", function()
    local f = runtime_fixture(); f.menu:IMode_ResetInventories()
    local r = siss_util.pack(f.menu:IMode_RefreshInventories())
    eq(r.n, 3); eq(r[2], 6)
    f.throw_refresh = true
    local ok, message = pcall(f.menu.IMode_RefreshInventories, f.menu)
    eq(ok, false); assert(message:find("original Refresh"))
end)
test("SortingPlus fallback uses isolated bag caches and restores context on Reinit errors", function()
    local f = runtime_fixture({ auto_fav_own = false }, true)
    f.mode("loot"); f.partner = { box = true }
    local original_cache = f.g.zzz_rax_sortingplus_mcm.ab_k
    f.menu:LMode_ResetInventories()
    eq(f.menu.CC.actor_bag.open_kind, "ammo"); eq(f.menu.CC.npc_bag.open_kind, "favorites")
    eq(f.g.zzz_rax_sortingplus_mcm.ab_k, original_cache)
    f.g.rax_icon_layers.refresh(1); eq(f.runtime.stats().sorted, 2); eq(f.factories, 0)
    f.throw_reinit = true
    eq(pcall(f.menu.CC.npc_bag.Reinit, f.menu.CC.npc_bag), false)
    eq(f.g.zzz_rax_sortingplus_mcm.ab_k, original_cache)
    eq(f.g.zzz_rax_sortingplus_mcm.get_sort_kind("item"), "ammo")
end)
test("runtime settings remove owned ranks, preserve third-party values, and clear pending sorts", function()
    local f = runtime_fixture(); f.menu:IMode_ResetInventories()
    local rax = f.g.zzz_rax_sortingplus_mcm
    eq(rax.item_order.ammo_parts, 9.5)
    f.shift = true; f.g.rax_icon_layers.refresh(1)
    f.values.enable = false; f.runtime.options(); f.shift = false; f.clock.tick()
    eq(rax.item_order.ammo_parts, nil); eq(f.factories, 0)
    f.values.enable = true; f.runtime.options(); rax.item_order.ammo_parts = 99
    f.values.ammo_parts_row = false; f.runtime.options(); eq(rax.item_order.ammo_parts, 99)
    f.values.ammo_parts_row = true; f.runtime.options()
    local r = siss_util.pack(rax.loadsettings()); eq(r.n, 3); eq(r[2], 7); eq(rax.item_order.ammo_parts, 9.5)
end)
test("menu close invalidates pending equipment work", function()
    local f = runtime_fixture(); f.menu:IMode_ResetInventories()
    f.callbacks.actor_item_to_slot(); f.runtime.hide("UIInventory")
    f.clock.tick(); eq(f.paints, 0); eq(f.factories, 0)
end)
test("MCM changes settle after other listeners replace SortingPlus tables and modes", function()
    local f = runtime_fixture({ body_mode = "never" }); f.mode("loot")
    f.partner = { alive = function() return false end }
    f.menu:LMode_ResetInventories(); eq(f.menu.CC.npc_bag.sort_method, "sizekind")
    f.callbacks.on_option_change(); f.callbacks.on_option_change()
    f.g.zzz_rax_sortingplus_mcm.loadsettings()
    f.menu.CC.npc_bag.sort_method = "kind" -- a later SortingPlus listener
    eq(f.factories, 0)
    f.clock.tick(); eq(f.factories, 1); eq(f.menu.CC.npc_bag.sort_method, "sizekind")
    eq(f.clock.count(), 0)
end)
test("loot refresh highlights only newly affected cells on unchanged follow-up", function()
    local f = runtime_fixture(); f.mode("loot"); f.partner = { box = true }; f.menu:LMode_ResetInventories()
    local cc = f.menu.CC.actor_bag
    f.refresh_action = function() cc.indx_id[3] = 1 end
    f.menu:LMode_RefreshInventories(); local paints = cc.cell[1].highlights
    assert(paints > 0)
    f.refresh_action = nil; f.menu:LMode_RefreshInventories()
    eq(cc.cell[1].highlights, paints); eq(f.paints, 0)
end)
test("storage opening with empty UI cells does not mark existing actor items as loot", function()
    local f = runtime_fixture(); f.mode("loot"); f.partner = { box = true }
    local cc = f.menu.CC.actor_bag
    cc.cell, cc.indx_id = {}, {} -- Reset clears the UI before storage initialization
    f.menu:LMode_ResetInventories(true)
    f.refresh_action = function() cc:add(1); cc:add(2) end
    f.menu:LMode_RefreshInventories()
    local highlight = f.highlight_checks.zz_seamless_new_loot
    eq(highlight(cc.cell[1]), nil); eq(highlight(cc.cell[2]), nil)
    eq(cc.cell[1].highlights, 0); eq(cc.cell[2].highlights, 0)
    f.refresh_action = function() cc:add(3); f.objects[3] = cc.objects[3] end
    f.menu:LMode_RefreshInventories()
    assert(highlight(cc.cell[3]) ~= nil, "actual subsequent pickup must still highlight")
    eq(highlight(cc.cell[1]), nil); eq(f.ownership_scans, 1)
end)
test("staggered opening population and already-owned stacked children are not new loot", function()
    local f = runtime_fixture(); f.mode("loot"); f.partner = { box = true }
    f.owned[3] = object(3)
    local cc = f.menu.CC.actor_bag; cc.cell, cc.indx_id = {}, {}
    f.menu:LMode_ResetInventories(true)
    f.refresh_action = function() cc:add(1) end; f.menu:LMode_RefreshInventories()
    f.refresh_action = function() cc:add(2); cc.indx_id[3] = 1 end
    f.menu:LMode_RefreshInventories()
    local highlight = f.highlight_checks.zz_seamless_new_loot
    eq(highlight(cc.cell[1]), nil); eq(highlight(cc.cell[2]), nil)
    f.refresh_action = function() cc.indx_id[4] = 1 end
    f.menu:LMode_RefreshInventories(); assert(highlight(cc.cell[1]) ~= nil)
    eq(f.ownership_scans, 1)
end)
test("opening with genuinely empty ownership still highlights the first pickup", function()
    local f = runtime_fixture(); f.mode("loot"); f.partner = { box = true }
    f.owned = {}
    local cc = f.menu.CC.actor_bag; cc.cell, cc.indx_id = {}, {}
    f.menu:LMode_ResetInventories(true)
    f.refresh_action = function() cc:add(3); f.objects[3] = cc.objects[3] end
    f.menu:LMode_RefreshInventories()
    assert(f.highlight_checks.zz_seamless_new_loot(cc.cell[3]) ~= nil)
end)
test("missing optional backends do not prevent startup or normal refresh", function()
    local f = runtime_fixture({}, true)
    f.g.rax_icon_layers, f.g.rax_persistent_highlight, f.g.ui_mcm = nil, nil, nil
    f.runtime.install(); f.runtime.options(); f.menu:IMode_ResetInventories()
    f.menu:IMode_RefreshInventories(); eq(#f.logs, 0)
end)

test("synthetic large-stack no-change workload does zero sorts and zero renderer calls", function()
    local f = controller_fixture()
    for id = 3, 1000 do f.cc:add(id) end
    for id = 1001, 10000 do f.cc.indx_id[id] = (id % 1000) + 1 end
    f.controller.reset(f.menu, f.cc)
    local start = os.clock()
    for _ = 1, 250 do f.controller.refresh(f.menu, f.cc) end
    local elapsed = os.clock() - start
    eq(f.sorts, 0); eq(f.cc.sets, 0); eq(f.clock.count(), 0)
    print(string.format("BENCH: 250 unchanged refreshes, 1000 parent cells / 10000 IDs: %.3fs (Lua 5.1 mock, not game FPS)", elapsed))
end)
