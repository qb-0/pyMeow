import requests
import pyMeow as pm


class Offsets:
    m_pBoneArray = 480


class Colors:
    orange = pm.get_color("orange")
    black = pm.get_color("black")
    cyan = pm.get_color("cyan")
    white = pm.get_color("white")
    grey = pm.fade_color(pm.get_color("#242625"), 0.7)


class Entity:
    def __init__(self, ptr, pawn_ptr, proc):
        self.ptr = ptr
        self.pawn_ptr = pawn_ptr
        self.proc = proc
        self.pos2d = None
        self.head_pos2d = None

    @property
    def name(self):
        return pm.r_string(self.proc, self.ptr + Offsets.m_iszPlayerName)

    @property
    def health(self):
        return pm.r_int(self.proc, self.pawn_ptr + Offsets.m_iHealth)

    @property
    def team(self):
        return pm.r_int(self.proc, self.pawn_ptr + Offsets.m_iTeamNum)

    @property
    def pos(self):
        return pm.r_vec3(self.proc, self.pawn_ptr + Offsets.m_vOldOrigin)

    def bone_pos(self, bone):
        game_scene = pm.r_int64(self.proc, self.pawn_ptr + Offsets.m_pGameSceneNode)
        bone_array_ptr = pm.r_int64(self.proc, game_scene + Offsets.m_pBoneArray)
        return pm.r_vec3(self.proc, bone_array_ptr + bone * 32)
    
    def wts(self, view_matrix):
        try:
            self.pos2d = pm.world_to_screen(view_matrix, self.pos, 1)
            self.head_pos2d = pm.world_to_screen(view_matrix, self.bone_pos(6), 1)
        except:
            return False
        return True


class CS2Esp:
    def __init__(self):
        self.proc = pm.open_process("cs2.exe")
        self.mod = pm.get_module(self.proc, "client.dll")["base"]

        offsets_name = ["dwViewMatrix", "dwEntityList", "dwLocalPlayerController", "dwLocalPlayerPawn", "dwForceJump"]
        offsets = requests.get("https://raw.githubusercontent.com/a2x/cs2-dumper/main/generated/offsets.json").json()
        [setattr(Offsets, k, offsets["client_dll"]["data"][k]["value"]) for k in offsets_name]

        client_dll_name = {
            "m_iIDEntIndex": "C_CSPlayerPawnBase",
            "m_hPlayerPawn": "CCSPlayerController",
            "m_fFlags": "C_BaseEntity",
            "m_iszPlayerName": "CBasePlayerController",
            "m_iHealth": "C_BaseEntity",
            "m_iTeamNum": "C_BaseEntity",
            "m_vOldOrigin": "C_BasePlayerPawn",
            "m_pGameSceneNode": "C_BaseEntity",
        }
        clientDll = requests.get("https://raw.githubusercontent.com/a2x/cs2-dumper/generated/client.dll.json").json()
        [setattr(Offsets, k, clientDll[client_dll_name[k]]["data"][k]["value"]) for k in client_dll_name]

    def it_entities(self):
        ent_list = pm.r_int64(self.proc, self.mod + Offsets.dwEntityList)
        local = pm.r_int64(self.proc, self.mod + Offsets.dwLocalPlayerController)
        for i in range(1, 65):
            try:
                entry_ptr = pm.r_int64(self.proc, ent_list + (8 * (i & 0x7FFF) >> 9) + 16)
                controller_ptr = pm.r_int64(self.proc, entry_ptr + 120 * (i & 0x1FF))
                if controller_ptr == local:
                    continue
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
                if ent.wts(view_matrix) and ent.health > 0:
                    color = Colors.cyan if ent.team != 2 else Colors.orange
                    head = ent.pos2d["y"] - ent.head_pos2d["y"]
                    width = head / 2
                    center = width / 2
                    
                    # Snapline
                    pm.draw_line(
                        pm.get_screen_width() / 2,
                        pm.get_screen_height() / 2,
                        ent.head_pos2d["x"] - center,
                        ent.head_pos2d["y"] - center / 2,
                        Colors.black,
                        3
                    )
                    pm.draw_line(
                        pm.get_screen_width() / 2,
                        pm.get_screen_height() / 2,
                        ent.head_pos2d["x"] - center,
                        ent.head_pos2d["y"] - center / 2,
                        color,
                    )
                    # Box
                    pm.draw_rectangle(
                        ent.head_pos2d["x"] - center,
                        ent.head_pos2d["y"] - center / 2,
                        width,
                        head + center / 2,
                        Colors.grey,
                    )
                    pm.draw_rectangle_lines(
                        ent.head_pos2d["x"] - center,
                        ent.head_pos2d["y"] - center / 2,
                        width,
                        head + center / 2,
                        color,
                        1.2,
                    )
                    # Info
                    txt = f"{ent.name} ({ent.health}%)"
                    pm.draw_text(
                        txt,
                        ent.head_pos2d["x"] - pm.measure_text(txt, 15) // 2,
                        ent.pos2d["y"],
                        15,
                        Colors.white,
                    )
            pm.end_drawing()


if __name__ == "__main__":
    esp = CS2Esp()
    esp.run()
