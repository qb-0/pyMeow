import sys
import pyMeow as pm
from requests import get


class Colors:
    orange = pm.get_color("orange")
    cyan = pm.get_color("cyan")


class Offsets:
    pass


try:
    # Credits to https://github.com/frk1/hazedumper
    haze = get(
        "https://raw.githubusercontent.com/frk1/hazedumper/master/csgo.json"
    ).json()

    [setattr(Offsets, k, v) for k, v in haze["signatures"].items()]
    [setattr(Offsets, k, v) for k, v in haze["netvars"].items()]
except:
    sys.exit("Unable to fetch Hazedumper's Offsets")

csgo_proc = pm.open_process("csgo.exe")
client = pm.get_module(csgo_proc, "client.dll")["base"]

while True:
    try:
        local_player = pm.r_int(csgo_proc, client + Offsets.dwLocalPlayer)
    except:
        continue

    if local_player:
            ent_addrs = pm.r_ints(csgo_proc, client + Offsets.dwEntityList, 128)[0::4]
            for ent in ent_addrs:
                if ent and ent != local_player:
                    glow_addr = (
                        pm.r_uint(csgo_proc, client + Offsets.dwGlowObjectManager)
                        + pm.r_int(csgo_proc, ent + Offsets.m_iGlowIndex) * 0x38
                    )
                    team = pm.r_int(csgo_proc, ent + Offsets.m_iTeamNum)
                    c = Colors.cyan if team != 2 else Colors.orange
                    pm.w_floats(csgo_proc, glow_addr + 8, list(c.values()))
                    pm.w_bytes(csgo_proc, glow_addr + 0x28, [1, 0])