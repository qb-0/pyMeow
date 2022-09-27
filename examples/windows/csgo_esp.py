import sys
from pyMeow import *
from requests import get


class Offsets:
    pass


class Colors:
    orange = get_color("orange")
    cyan = get_color("cyan")
    white = get_color("white")


class Entity:
    def __init__(self, addr, mem, gmod):
        self.wts = None
        self.addr = addr
        self.mem = mem
        self.gmod = gmod

        self.id = r_int(self.mem, self.addr + 0x64)
        self.health = r_int(self.mem, self.addr + Offsets.m_iHealth)
        self.dormant = r_int(self.mem, self.addr + Offsets.m_bDormant)
        self.team = r_int(self.mem, self.addr + Offsets.m_iTeamNum)
        self.bone_base = r_int(self.mem, self.addr + Offsets.m_dwBoneMatrix)
        self.pos = r_vec3(self.mem, self.addr + Offsets.m_vecOrigin)
        self.color = Colors.cyan if self.team == 3 else Colors.orange

    @property
    def name(self):
        radar_base = r_int(self.mem, self.gmod + Offsets.dwRadarBase)
        hud_radar = r_int(self.mem, radar_base + 0x78)
        return r_string(self.mem, hud_radar + 0x300 + (0x174 * (self.id - 1)))

    def bone_pos(self, bone_id):
        return vec3(
            r_float(self.mem, self.bone_base + 0x30 * bone_id + 0x0C),
            r_float(self.mem, self.bone_base + 0x30 * bone_id + 0x1C),
            r_float(self.mem, self.bone_base + 0x30 * bone_id + 0x2C),
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

    csgo_proc = open_process(processName="csgo.exe")
    game_module = get_module(csgo_proc, "client.dll")["base"]
    overlay_init(fps=144)

    while overlay_loop():
        try:
            local_player_addr = r_int(csgo_proc, game_module + Offsets.dwLocalPlayer)
        except:
            continue

        begin_drawing()
        draw_fps(10, 10)

        if local_player_addr:
            ent_addrs = r_ints(csgo_proc, game_module + Offsets.dwEntityList, 128)[0::4]
            view_matrix = r_floats(csgo_proc, game_module + Offsets.dwViewMatrix, 16)
            for ent_addr in ent_addrs:
                if ent_addr > 0 and ent_addr != local_player_addr:
                    ent = Entity(ent_addr, csgo_proc, game_module)
                    if not ent.dormant and ent.health > 0:
                        try:
                            ent.wts = wts_dx(view_matrix, ent.pos)
                            head_pos = wts_dx(view_matrix, ent.bone_pos(8))

                            head = ent.wts["y"] - head_pos["y"]
                            width = head / 2
                            center = width / 2

                            # Box
                            draw_rectangle_lines(
                                posX=int(head_pos["x"] - center),
                                posY=int(head_pos["y"] - center / 2),
                                width=int(width),
                                height=int(head + center / 2),
                                color=ent.color,
                                lineThick=1.2,
                            )

                            # Snapline
                            draw_line(
                                startPosX=get_screen_width() // 2,
                                startPosY=0,
                                endPosX=int(head_pos["x"] - center),
                                endPosY=int(head_pos["y"] - center / 2),
                                color=ent.color,
                                thick=1.2,
                            )

                            # Health
                            gui_progress_bar(
                                posX=int(head_pos["x"] - center),
                                posY=int(ent.wts["y"]),
                                width=int(width),
                                height=10,
                                textLeft="HP: ",
                                textRight=f" {ent.health}",
                                value=ent.health,
                                minValue=0,
                                maxValue=100,
                            )

                            # Name
                            draw_text(
                                text=ent.name,
                                posX=int(head_pos["x"] - center + 4),
                                posY=int(head_pos["y"] - center / 2 + 4),
                                fontSize=15,
                                color=Colors.white,
                            )
                        except:
                            continue

        end_drawing()


if __name__ == "__main__":
    main()
