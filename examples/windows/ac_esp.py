# Version: 1.3.0.2

import sys
import pyMeow as pm

try:
    proc = pm.open_process("ac_client.exe")
    base = pm.get_module(proc, "ac_client.exe")["base"]
except Exception as e:
    sys.exit(e)


class Pointer:
    player_count = 0x18AC0C
    entity_list = 0x18AC04
    local_player = 0x18AC00
    view_matrix = 0x17DFD0


class Offsets:
    name = 0x205
    health = 0xEC
    armor = 0xF0
    team = 0x30C
    pos = 0x4
    fpos = 0x28


class Colors:
    cyan = pm.get_color("cyan")
    orange = pm.get_color("orange")
    white = pm.get_color("white")
    black = pm.get_color("black")


class Entity:
    def __init__(self, addr):
        self.addr = addr
        self.health = pm.r_int(proc, addr + Offsets.health)
        if self.health <= 0:
            raise Exception("Entity is not alive.")
        self.name = pm.r_string(proc, addr + Offsets.name)
        self.armor = pm.r_int(proc, addr + Offsets.armor)
        self.team = pm.r_int(proc, addr + Offsets.team)
        self.color = Colors.cyan if self.team else Colors.orange
        self.pos3d = pm.r_vec3(proc, self.addr + Offsets.pos)
        self.fpos3d = pm.r_vec3(proc, self.addr + Offsets.fpos)
        self.pos2d = self.fpos2d = None
        self.head = self.width = self.center = None

    def wts(self, vm):
        try:
            self.pos2d = pm.world_to_screen(vm, self.pos3d)
            self.fpos2d = pm.world_to_screen(vm, self.fpos3d)
            self.head = self.fpos2d["y"] - self.pos2d["y"]
            self.width = self.head / 2
            self.center = self.width / 2
            return True
        except:
            return False

    def draw_box(self):
        pm.draw_rectangle(
            posX=self.pos2d["x"] - self.center,
            posY=self.pos2d["y"] - self.center / 2,
            width=self.width,
            height=self.head + self.center / 2,
            color=pm.fade_color(self.color, 0.3),
        )
        pm.draw_rectangle_lines(
            posX=self.pos2d["x"] - self.center,
            posY=self.pos2d["y"] - self.center / 2,
            width=self.width,
            height=self.head + self.center / 2,
            color=self.color,
            lineThick=1.2,
        )

    def draw_name(self):
        textSize = pm.measure_text(self.name, 15) / 2
        pm.draw_text(
            text=self.name,
            posX=self.pos2d["x"] - textSize,
            posY=self.pos2d["y"],
            fontSize=15,
            color=Colors.white,
        )

    def draw_health(self):
        pm.draw_circle_sector(
            centerX=self.pos2d["x"] - self.center,
            centerY=self.pos2d["y"] - self.center / 2,
            radius=self.center / 3 + 2,
            startAngle=0,
            endAngle=360,
            segments=0,
            color=Colors.black,
        )
        pm.draw_circle_sector(
            centerX=self.pos2d["x"] - self.center,
            centerY=self.pos2d["y"] - self.center / 2,
            radius=self.center / 3,
            startAngle=0,
            endAngle=360 / 100 * self.health,
            segments=0,
            color=self.color,
        )


def main():
    pm.overlay_init(target="AssaultCube", fps=144, trackTarget=True)
    while pm.overlay_loop():
        pm.begin_drawing()
        pm.draw_fps(10, 10)
        player_count = pm.r_int(proc, base + Pointer.player_count)
        if player_count > 1:
            ent_buffer = pm.r_ints(
                proc, pm.r_int(proc, base + Pointer.entity_list), player_count
            )[1:]
            v_matrix = pm.r_floats(proc, base + Pointer.view_matrix, 16)
            for addr in ent_buffer:
                try:
                    ent = Entity(addr)
                    if ent.wts(v_matrix):
                        ent.draw_box()
                        ent.draw_name()
                        ent.draw_health()
                except:
                    continue
        pm.end_drawing()


if __name__ == "__main__":
    main()
