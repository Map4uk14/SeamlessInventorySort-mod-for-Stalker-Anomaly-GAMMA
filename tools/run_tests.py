"""Run production .script namespaces and regression tests on real Lua 5.1.

Developer-only dependency: python -m pip install -r requirements-dev.txt
Nothing from Python/Lupa is included in the game archive.
"""
from pathlib import Path
import argparse
import sys
from urllib.request import urlopen
import xml.etree.ElementTree as ET

try:
    from lupa.lua51 import LuaRuntime
except ImportError:
    sys.exit("Lua 5.1 tests require Lupa: python -m pip install -r requirements-dev.txt")

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--upstream", action="store_true", help="also test the pinned upstream sea-ex comparator (network required)")
args = parser.parse_args()
lua = LuaRuntime(unpack_returned_tuples=True)
assert lua.eval("_VERSION") == "Lua 5.1"
compile_lua = lua.eval("function(code, name) return assert(loadstring(code, '@' .. name)) end")
load_module = lua.eval("""function(code, name)
    local env = setmetatable({}, { __index = _G })
    local chunk = assert(loadstring(code, '@' .. name))
    setfenv(chunk, env)
    chunk()
    _G[name] = env
    return env
end""")
lua.globals().load_module = load_module
sources = lua.table()
scripts = sorted((ROOT / "gamedata/scripts").glob("*.script"))
for path in scripts:
    source = path.read_text(encoding="utf-8-sig")
    compile_lua(source, path.name)
    sources[path.stem] = source
    if path.stem.startswith("siss_"):
        load_module(source, path.stem)
lua.globals().sources = sources

strings = {node.attrib["id"] for node in ET.parse(
    ROOT / "gamedata/configs/text/eng/ui_mcm_seamless_sort.xml"
).getroot().findall("string")}
menu = lua.globals().siss_config.mcm()
option_count = 0
for _, page in menu.gr.items():
    for _, option in page.gr.items():
        if option.type not in ("check", "track", "list"):
            assert option.text in strings, option.text
            continue
        option_count += 1
        key = f"ui_mcm_seamless_sort_{page.id}_{option.id}"
        assert key in strings and key + "_desc" in strings, key
        if option.type == "list":
            for _, value in option.content.items():
                assert f"seamless_sort_{page.id}_{option.id}_lst_{value[1]}" in strings
assert option_count == 22, option_count
unlocalizer = (ROOT / "gamedata/configs/unlocalizers/unlocalizer_siss_sortingplus.ltx").read_text(encoding="utf-8")
assert "[zzz_rax_sortingplus_mcm]" in unlocalizer
assert {"item_order", "ab_k"}.issubset(set(unlocalizer.splitlines()))
if args.upstream:
    revision = "ab0f743af42a3b3b0b0ee853b3676f5189f7f0d0"
    url = (f"https://raw.githubusercontent.com/Grokitach/Stalker_GAMMA/{revision}/"
           "G.A.M.M.A/modpack_addons/464-%20Inventory%20Open%20Lag%20Reducer%20-%20sea-ex/"
           "gamedata/scripts/seax_sortingplus_opt_sort_by_kind.script")
    with urlopen(url, timeout=30) as response:
        lua.globals().upstream_source = response.read().decode("utf-8-sig")
    print(f"Loaded upstream sea-ex source at {revision}", flush=True)
print(f"PASS: {len(scripts)} Lua 5.1 scripts compile; XML and {option_count} MCM options validated", flush=True)
for path in sorted((ROOT / "tests").glob("*.lua")):
    chunk = compile_lua(path.read_text(encoding="utf-8"), path.name)
    chunk()
lua.globals().finish_tests()
