# Version: v1.3.0.2

import pyMeow as pm

DEBUG = False
RAPID_FIRE = True
AMMO_HACK = True


class Pointer:
    entity_list = 0x1A3520
    local_player = 0x1A3518
    view_matrix = 0x1B4FCC


class Offsets:
    name = 0x219
    health = 0x100
    team = 0x320
    pos = 0x8


class Colors:
    cyan = pm.get_color("cyan")
    orange = pm.get_color("orange")
    white = pm.get_color("white")


class Entity:
    def __init__(self, addr, mem):
        self.mem = mem
        self.addr = addr

        self.name = pm.r_string(self.mem, self.addr + Offsets.name)
        self.health = pm.r_int(self.mem, self.addr + Offsets.health)
        self.team = pm.r_int(self.mem, self.addr + Offsets.team)
        self.pos3d = pm.r_vec3(self.mem, self.addr + Offsets.pos)
        self.color = Colors.cyan if self.team == 1 else Colors.orange
        self.pos2d = None

    def render_snapline(self):
        pm.draw_line(
            startPosX=pm.get_screen_width() / 2,
            startPosY=pm.get_screen_height(),
            endPosX=self.pos2d["x"],
            endPosY=self.pos2d["y"],
            color=self.color,
        )

    def render_info(self):
        pm.draw_text(
            text=self.name,
            posX=self.pos2d["x"],
            posY=self.pos2d["y"],
            fontSize=15,
            color=Colors.white,
        )


def main():
    proc = pm.open_process("linux_64_client", debug=DEBUG)
    base = pm.get_module(proc, "linux_64_client")["base"]
    entity_list = pm.r_int(proc, base + Pointer.entity_list)

    if RAPID_FIRE:
        rapidScan = pm.aob_scan_module(proc, "linux_64_client", "89 01 48 8B 43")
        if rapidScan:
            pm.page_protection(proc, rapidScan[0], 7)
            pm.w_bytes(proc, rapidScan[0], [0x90, 0x90])

    if AMMO_HACK:
        ammoScan = pm.aob_scan_module(proc, "linux_64_client", "83 00 FF 48 8B 43")
        if ammoScan:
            pm.page_protection(proc, ammoScan[0], 7)
            pm.w_bytes(proc, ammoScan[0], [0x90, 0x90, 0x90])

    pm.overlay_init(target="AssaultCube", fps=144)
    while pm.overlay_loop():
        local_player_addr = pm.r_int(proc, base + Pointer.local_player)
        matrix = pm.r_floats(proc, base + Pointer.view_matrix, 16)

        pm.begin_drawing()
        pm.draw_fps(0, 0)
        for i in range(31):
            ent_addr = pm.r_int(proc, entity_list + i * 8)
            if ent_addr != 0 and ent_addr != local_player_addr:
                try:
                    ent_obj = Entity(ent_addr, proc)
                except:
                    continue

                if ent_obj.health > 0:
                    try:
                        ent_obj.pos2d = pm.world_to_screen(matrix, ent_obj.pos3d)
                        ent_obj.render_snapline()
                        ent_obj.render_info()
                    except:
                        continue
        pm.end_drawing()


if __name__ == "__main__":
    main()
