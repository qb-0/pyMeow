import pyMeow as pm
from ctypes import *


class Vec3(Structure):
    _fields_ = [
        ('x', c_float),
        ('y', c_float),
        ('z', c_float)
    ]


class Entity(Structure):
    _fields_ = [
        ("", 0x4 * c_byte),
        ("pos", Vec3),
        ("", 0xDC * c_byte),
        ("health", c_int),
        ("", 0x115 * c_byte),
        ("name", 0x50 * c_char),
        ("", 0xB7 * c_byte),
        ("team", c_int)
    ]

    @property
    def pos_vec(self):
        return pm.vec3(self.pos.x, self.pos.y, self.pos.z)


class Pointer:
    player_count = 0x18AC0C
    entity_list = 0x18AC04
    view_matrix = 0x17DFD0


class Colors:
    white = pm.get_color("white")
    blue = pm.fade_color(pm.get_color("blue"), 0.15)
    red = pm.fade_color(pm.get_color("red"), 0.15)


def main():
    proc = pm.open_process("ac_client.exe")
    base = pm.get_module(proc, "ac_client.exe")["base"]
    pm.overlay_init("AssaultCube", trackTarget=True)
    pm.set_fps(pm.get_monitor_refresh_rate())
    
    while pm.overlay_loop():
        pm.begin_drawing()
        pm.draw_fps(10, 10)
        player_count = pm.r_ctype(proc, base + Pointer.player_count, c_int()).value
        if player_count > 1:
            ent_buffer = pm.r_ctype(
                proc, pm.r_ctype(proc, base + Pointer.entity_list, c_int()).value, (player_count * c_int)()
            )[1:]
            v_matrix = pm.r_ctype(proc, base + Pointer.view_matrix, (16 * c_float)())[:]
            for ent_addr in ent_buffer:
                ent = pm.r_ctype(proc, ent_addr, Entity())
                if ent.health > 0:
                    try:
                        wts = pm.world_to_screen(v_matrix, ent.pos_vec)
                    except:
                        continue

                    pm.draw_text(ent.name, wts["x"], wts["y"], 12, Colors.white)
                    pm.draw_line(
                        pm.get_screen_width() / 2, pm.get_screen_height(),
                        wts["x"], wts["y"],
                        Colors.blue if ent.team else Colors.red, 5
                    )

        pm.end_drawing()


if __name__ == "__main__":
    main()