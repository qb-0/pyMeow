import pyMeow as pm


class Offsets:
    # Thanks to https://github.com/a2x/cs2-dumper
    dwEntityList = 24688792
    dwViewMatrix = 25663216
    m_iPawnHealth = 2056
    m_hPlayerPawn = 2044
    m_iszPlayerName = 1552
    m_iTeamNum = 959
    m_vOldOrigin = 4628


class Colors:
    orange = pm.get_color("orange")
    cyan = pm.get_color("cyan")
    white = pm.get_color("white")


class Entity:
    def __init__(self, ptr, pawn_ptr, proc):
        self.ptr = ptr
        self.pawn_ptr = pawn_ptr
        self.proc = proc
        self.pos2d = None

    @property
    def name(self):
        return pm.r_string(self.proc, self.ptr + Offsets.m_iszPlayerName)

    @property
    def health(self):
        return pm.r_int(self.proc, self.ptr + Offsets.m_iPawnHealth)

    @property
    def team(self):
        return pm.r_int(self.proc, self.pawn_ptr + Offsets.m_iTeamNum)

    @property
    def pos(self):
        return pm.r_vec3(self.proc, self.pawn_ptr + Offsets.m_vOldOrigin)


class CS2Esp:
    def __init__(self):
        self.proc = pm.open_process("cs2.exe")
        self.mod = pm.get_module(self.proc, "client.dll")["base"]

    def it_entities(self):
        ent_list = pm.r_int64(self.proc, self.mod + Offsets.dwEntityList)
        for i in range(2, 65):
            try:
                entry_ptr = pm.r_int64(self.proc, ent_list + (8 * (i & 0x7FFF) >> 9) + 16)
                controller_ptr = pm.r_int64(self.proc, entry_ptr + 120 * (i & 0x1FF))
                controller_pawn_ptr = pm.r_int64(self.proc, controller_ptr + Offsets.m_hPlayerPawn)
                list_entry_ptr = pm.r_int64(self.proc, ent_list + 0x8 * ((controller_pawn_ptr & 0x7FFF) >> 9) + 16)
                pawn_ptr = pm.r_int64(self.proc, list_entry_ptr + 120 * (controller_pawn_ptr & 0x1FF))
            except:
                continue

            yield Entity(controller_ptr, pawn_ptr, self.proc)

    def run(self):
        pm.overlay_init("Counter-Strike 2", fps=144)
        while pm.overlay_loop():
            view_matrix = pm.r_floats(self.proc, self.mod + Offsets.dwViewMatrix, 16)
            pm.begin_drawing()
            pm.draw_fps(0, 0)
            for ent in self.it_entities():
                try:
                    ent.pos2d = pm.world_to_screen(view_matrix, ent.pos, 1)
                except:
                    continue

                if ent.health > 0:
                    color = Colors.cyan if ent.team != 2 else Colors.orange
                    # Snapline
                    pm.draw_line(
                        pm.get_screen_width() / 2,
                        pm.get_screen_height() / 2,
                        ent.pos2d["x"],
                        ent.pos2d["y"],
                        color,
                    )
                    # Info
                    txt = f"{ent.name} ({ent.health}%)"
                    pm.draw_text(
                        txt,
                        ent.pos2d["x"] - pm.measure_text(txt, 15) // 2,
                        ent.pos2d["y"],
                        15,
                        Colors.white,
                    )
            pm.end_drawing()


if __name__ == "__main__":
    esp = CS2Esp()
    esp.run()
