# Version: v1.3.0.2

import pyMeow as pm
from ctypes import *


class Pointer:
    entity_list = 0x1A3520
    view_matrix = 0x1B4FCC


class Vec3(Structure):
    _fields_ = [
        ('x', c_float),
        ('y', c_float),
        ('z', c_float)
    ]


class Entity(Structure):
    _fields_ = [
        ("", 8 * c_byte),
        ("pos", Vec3),
        ("", 236 * c_byte),
        ("health", c_int),
        ("", 277 * c_byte),
        ("name", 30 * c_char),
        ("", 233 * c_byte),
        ("team", c_int),
    ]

    @property
    def pos_vec(self):
        return pm.vec3(self.pos.x, self.pos.y, self.pos.z)


class Colors:
    white = pm.get_color("white")
    blue = pm.fade_color(pm.get_color("blue"), 0.15)
    red = pm.fade_color(pm.get_color("red"), 0.15)


def main():
    proc = pm.open_process("linux_64_client")
    base = pm.get_module(proc, "linux_64_client")["base"]
    entity_list = pm.r(proc, base + Pointer.entity_list, "int")

    pm.overlay_init(target="AssaultCube")
    pm.set_fps(pm.get_monitor_refresh_rate())
    while pm.overlay_loop():
        v_matrix = pm.r(proc, base + Pointer.view_matrix, "float", 16)

        pm.begin_drawing()
        pm.draw_fps(0, 0)
        for i in range(1, 32):
            ent_addr = pm.r(proc, entity_list + i * 8, "int")
            if ent_addr > 0:
                try:
                    ent = Entity()
                    ent = pm.r_ctype(proc, ent_addr, Entity())
                except:
                    continue

                _, wts = pm.world_to_screen_noexc(v_matrix, ent.pos_vec)
                if ent.health > 0:
                    pm.draw_text(ent.name, wts["x"], wts["y"], 12, Colors.white)
                    pm.draw_line(
                        pm.get_screen_width() / 2, pm.get_screen_height(),
                        wts["x"], wts["y"],
                        Colors.blue if ent.team else Colors.red, 5
                    )
        pm.end_drawing()


if __name__ == "__main__":
    main()
