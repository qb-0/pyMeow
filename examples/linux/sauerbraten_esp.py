import sys
import pyMeow as pm

try:
    mem = pm.open_process("linux_64_client")
    base = pm.get_module(mem, "linux_64_client")["base"]
    pm.overlay_init(target="Cube 2: Sauerbraten", fps=200)
    local_entity = None
except Exception as e:
    sys.exit(e)


class Offsets:
    EntityList = 0x5EDB70
    Local = 0x53A600
    PlayerCount = 0x5EDB7C
    ViewMatrix = 0x5D06E0
    GameMode = 0x52940C

    Health = 0x178
    Armor = 0x180
    State = 0x77
    Name = 0x274
    Team = 0x378
    ViewAngles = 0x3C


class Colors:
    white = pm.get_color("white")
    cyan = pm.get_color("cyan")
    orange = pm.get_color("orange")


class Entity:
    def __init__(self, addr):
        self.addr = addr
        self.alive = pm.r_byte(mem, addr + Offsets.State) == 0
        if not self.alive:
            raise Exception("Entity not alive")
        self.health = pm.r_int(mem, addr + Offsets.Health)
        self.hpos3d = pm.r_vec3(mem, addr)
        self.fpos3d = pm.vec3(self.hpos3d["x"], self.hpos3d["y"], self.hpos3d["z"] - 15)
        self.armor = pm.r_int(mem, addr + Offsets.Armor)
        self.name = pm.r_string(mem, addr + Offsets.Name)
        self.team = pm.r_string(mem, addr + Offsets.Team)
        self.view_angles = pm.r_vec2(mem, addr + Offsets.ViewAngles)
        self.color = None
        self.hpos2d = None
        self.fpos2d = None
        self.distance = 0
    
    def draw_rec(self):
        head = self.fpos2d["y"] - self.hpos2d["y"]
        width = head / 2
        center = width / 2
        self.rec = pm.draw_rectangle(
            posX=self.hpos2d["x"] - center,
            posY=self.hpos2d["y"] - center / 2,
            width=width,
            height=head + center / 2,
            color=pm.fade_color(self.color, 0.2),
        )
        self.rec = pm.draw_rectangle_lines(
            posX=self.hpos2d["x"] - center,
            posY=self.hpos2d["y"] - center / 2,
            width=width,
            height=head + center / 2,
            color=self.color,
        )

    def draw_info(self):
        text = f"{self.name} ({self.distance}m)"
        size = pm.measure_text(text, 10) / 2
        pm.draw_text(text, self.fpos2d["x"] - size, self.fpos2d["y"] + 10, 10, Colors.white)



def ent_loop():
    player_count = pm.r_int(mem, base + Offsets.PlayerCount)
    if player_count > 1:
        ent_buffer = pm.r_ints64(mem, pm.r_int64(mem, base + Offsets.EntityList), player_count)

        try:
            global local_entity
            local_entity = Entity(ent_buffer[0])
        except Exception:
            return

        vm = pm.r_floats(mem, base + Offsets.ViewMatrix, 16)
        for addr in ent_buffer[1:]:
            try:
                ent = Entity(addr)
                if ent.alive:
                    ent.hpos2d = pm.world_to_screen(vm, ent.hpos3d)
                    ent.fpos2d = pm.world_to_screen(vm, ent.fpos3d)
                    ent.distance = int(pm.vec3_distance(local_entity.hpos3d, ent.hpos3d) / 3)
                    ent.color = Colors.cyan if ent.team == local_entity.team else Colors.orange
                    yield ent
            except:
                continue

def main():
    while pm.overlay_loop():
        pm.begin_drawing()
        pm.draw_fps(10, 10)
        for ent in ent_loop():
            ent.draw_rec()
            ent.draw_info()
        pm.end_drawing()


if __name__ == "__main__":
    main()
