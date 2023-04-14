import sys
import pyMeow as pm
from requests import get


class Offsets:
    pass


class Colors:
    orange = pm.get_color("orange")
    cyan = pm.get_color("cyan")
    white = pm.get_color("white")


class Entity:
    def __init__(self, addr, mem, gmod):
        self.wts = None
        self.addr = addr
        self.mem = mem
        self.gmod = gmod

        self.id = pm.r_int(self.mem, self.addr + 0x64)
        self.health = pm.r_int(self.mem, self.addr + Offsets.m_iHealth)
        self.dormant = pm.r_int(self.mem, self.addr + Offsets.m_bDormant)
        self.team = pm.r_int(self.mem, self.addr + Offsets.m_iTeamNum)
        self.bone_base = pm.r_int(self.mem, self.addr + Offsets.m_dwBoneMatrix)
        self.pos = pm.r_vec3(self.mem, self.addr + Offsets.m_vecOrigin)
        self.color = Colors.cyan if self.team == 3 else Colors.orange

    @property
    def name(self):
        radar_base = pm.r_int(self.mem, self.gmod + Offsets.dwRadarBase)
        hud_radar = pm.r_int(self.mem, radar_base + 0x78)
        return pm.r_string(self.mem, hud_radar + 0x300 + (0x174 * (self.id - 1)))

    def bone_pos(self, bone_id):
        return pm.vec3(
            pm.r_float(self.mem, self.bone_base + 0x30 * bone_id + 0x0C),
            pm.r_float(self.mem, self.bone_base + 0x30 * bone_id + 0x1C),
            pm.r_float(self.mem, self.bone_base + 0x30 * bone_id + 0x2C),
        )


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
    game_module = pm.get_module(csgo_proc, "client.dll")["base"]
    pm.overlay_init("Counter-Strike: Global Offensive - Direct3D 9", fps=144)

    while pm.overlay_loop():
        try:
            local_player_addr = pm.r_int(csgo_proc, game_module + Offsets.dwLocalPlayer)
        except:
            continue

        pm.begin_drawing()
        pm.draw_fps(10, 10)

        if local_player_addr:
            ent_addrs = pm.r_ints(csgo_proc, game_module + Offsets.dwEntityList, 128)[0::4]
            view_matrix = pm.r_floats(csgo_proc, game_module + Offsets.dwViewMatrix, 16)
            for ent_addr in ent_addrs:
                if ent_addr > 0 and ent_addr != local_player_addr:
                    ent = Entity(ent_addr, csgo_proc, game_module)
                    if not ent.dormant and ent.health > 0:
                        try:
                            ent.wts = pm.world_to_screen(view_matrix, ent.pos, 1)
                            head_pos = pm.world_to_screen(view_matrix, ent.bone_pos(8), 1)

                            head = ent.wts["y"] - head_pos["y"]
                            width = head / 2
                            center = width / 2

                            # Box
                            pm.draw_rectangle(
                                posX=head_pos["x"] - center,
                                posY=head_pos["y"] - center / 2,
                                width=width,
                                height=head + center / 2,
                                color=pm.fade_color(ent.color, 0.3),
                            )
                            pm.draw_rectangle_lines(
                                posX=head_pos["x"] - center,
                                posY=head_pos["y"] - center / 2,
                                width=width,
                                height=head + center / 2,
                                color=ent.color,
                                lineThick=1.2,
                            )

                            # Snapline
                            pm.draw_line(
                                startPosX=pm.get_screen_width() // 2,
                                startPosY=0,
                                endPosX=head_pos["x"] - center,
                                endPosY=head_pos["y"] - center / 2,
                                color=ent.color,
                                thick=1.2,
                            )

                            # Health
                            pm.gui_progress_bar(
                                posX=head_pos["x"] - center,
                                posY=ent.wts["y"],
                                width=width,
                                height=10,
                                textLeft="HP: ",
                                textRight=f" {ent.health}",
                                value=ent.health,
                                minValue=0,
                                maxValue=100,
                            )

                            # Name
                            pm.draw_text(
                                text=ent.name,
                                posX=head_pos["x"] - center + 4,
                                posY=head_pos["y"] - center / 2 + 4,
                                fontSize=15,
                                color=Colors.white,
                            )
                        except:
                            continue

        pm.end_drawing()


if __name__ == "__main__":
    main()
