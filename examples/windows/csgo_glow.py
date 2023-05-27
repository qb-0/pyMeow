import sys
import pyMeow as pm
from requests import get
from ctypes import *


class Offsets:
    pass


class Colors:
    orange = pm.get_color("orange")
    cyan = pm.get_color("cyan")


class GlowStruct(Structure):
    _fields_ = [
        ("", 8 * c_byte),
        ("r", c_float),
        ("g", c_float),
        ("b", c_float),
        ("a", c_float),
        ("", 16 * c_byte),
        ("renderOccluded", c_bool),
        ("renderUnoccluded", c_bool)
    ]


def main():
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
            local_player = pm.r(csgo_proc, client + Offsets.dwLocalPlayer, "int")
        except:
            continue

        if local_player:
            ent_addrs = pm.r(csgo_proc, client + Offsets.dwEntityList, "int", 128)[0::4]
            for ent in ent_addrs:
                if ent and ent != local_player:
                    glow_addr = (
                        pm.r(csgo_proc, client + Offsets.dwGlowObjectManager, "uint")
                        + pm.r(csgo_proc, ent + Offsets.m_iGlowIndex, "int") * 0x38
                    )
                    team = pm.r(csgo_proc, ent + Offsets.m_iTeamNum, "int")
                    c = Colors.cyan if team != 2 else Colors.orange
                    glow_struct = pm.r_ctype(csgo_proc, glow_addr, GlowStruct())
                    glow_struct.r = c["r"]
                    glow_struct.g = c["g"]
                    glow_struct.b = c["b"]
                    glow_struct.a = c["a"]
                    glow_struct.renderOccluded = True
                    glow_struct.renderUnoccluded = False
                    pm.w_ctype(csgo_proc, glow_addr, glow_struct)


if __name__ == "__main__":
    main()