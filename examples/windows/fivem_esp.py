# Credits to https://github.com/gabsroot
# Offsets by https://unknowncheats.me
# Version 1.0

import pyMeow as pm
import psutil, re, math

offsets = {
    "FiveM_b1604_GTAProcess.exe": {"world": 0x247F840, "replay": 0x1EFD4C8, "viewport": 0x2087780},
    "FiveM_b2060_GTAProcess.exe": {"world": 0x24C8858, "replay": 0x1EC3828, "viewport": 0x1F6A7E0},
    "FiveM_b2189_GTAProcess.exe": {"world": 0x24E6D90, "replay": 0x1EE18A8, "viewport": 0x1F888C0},
    "FiveM_b2372_GTAProcess.exe": {"world": 0x252DCD8, "replay": 0x1F05208, "viewport": 0x1F9F5C8},
    "FiveM_b2545_GTAProcess.exe": {"world": 0x25667E8, "replay": 0x1F2E7A8, "viewport": 0x1FD6F70},
    "FiveM_b2612_GTAProcess.exe": {"world": 0x2567DB0, "replay": 0x1F77EF0, "viewport": 0x1FD8570},
    "FiveM_b2699_GTAProcess.exe": {"world": 0x26684D8, "replay": 0x20304C8, "viewport": 0x20D8C90},
    "FiveM_b2802_GTAProcess.exe": {"world": 0x254D448, "replay": 0x1F5B820, "viewport": 0x1FBC100},
    "FiveM_b3095_GTAProcess.exe": {"world": 0x2593320, "replay": 0x1F58B58, "viewport": 0x20019E0}
}

process_name = next((p.info["name"] for p in psutil.process_iter(["name"]) if re.search(r"^FiveM_b\d+_GTAProcess\.exe$", p.info.get("name", ""))), None)
process = pm.open_process(process_name)
module = pm.get_module(process, process_name)["base"]

replay = pm.r_int64(process, module + offsets[process_name]["replay"])
world = pm.r_int64(process, module + offsets[process_name]["world"])
viewport = pm.r_int64(process, module + offsets[process_name]["viewport"])

class Entity:
    def __init__(self, process, ptr):
        self.process = process
        self.ptr = ptr

    @property
    def pos(self):
        return pm.r_vec3(self.process, self.ptr + 0x90)

    @property
    def health(self):
        return pm.r_float(self.process, self.ptr + 0x280)

    def world_to_screen(self, view_matrix):
        width = pm.get_screen_width()
        height = pm.get_screen_height()

        vmt = [[[view_matrix[i:i+4] for i in range(0, 16, 4)][j][i] for j in range(4)] for i in range(4)]

        screen = [
            vmt[1][0] * self.pos["x"] + vmt[1][1] * self.pos["y"] + vmt[1][2] * self.pos["z"] + vmt[1][3],
            vmt[2][0] * self.pos["x"] + vmt[2][1] * self.pos["y"] + vmt[2][2] * self.pos["z"] + vmt[2][3],
            vmt[3][0] * self.pos["x"] + vmt[3][1] * self.pos["y"] + vmt[3][2] * self.pos["z"] + vmt[3][3],
        ]

        if screen[2] <= 0.1:
            return None

        screen[2] = 1.0 / screen[2]
        screen[0] *= screen[2]
        screen[1] *= screen[2]
        screen[0] = (width / 2) + 0.5 * screen[0] * width + 0.5
        screen[1] = (height / 2) - 0.5 * screen[1] * height - 0.5

        return {"x": screen[0], "y": screen[1]}
    
    def distance(self, local_pos):
        return math.sqrt((local_pos["x"] - self.pos["x"]) ** 2 + (local_pos["y"] - self.pos["y"]) ** 2 + (local_pos["z"] - self.pos["z"]) ** 2)

    @staticmethod
    def enumerate(process, replay_interface):
        entities = pm.r_int64(process, replay_interface + 0x100)
        max_entities = pm.r_int64(process, replay_interface + 0x108)

        for i in range(max_entities):
            entity = pm.r_int64(process, entities + (i * 0x10))

            if entity:
                yield Entity(process, entity)


def main():
    pm.overlay_init(title="FiveM", fps=144, exitKey=0)

    while pm.overlay_loop():
        try:
            pm.begin_drawing()

            local_player = pm.r_int64(process, world + 0x8)
            local_player_pos = pm.r_vec3(process, local_player + 0x90)
            replay_interface = pm.r_int64(process, replay + 0x18)
            view_matrix = pm.r_floats(process, viewport + 0x24C, 16)
            max_distance = 300 # m

            for entity in Entity.enumerate(process, replay_interface):
                if entity.ptr == local_player:
                    continue
                
                pos2d = entity.world_to_screen(view_matrix)

                if not pos2d:
                    continue

                if entity.distance(local_player_pos) > max_distance:
                    continue

                pm.draw_line(
                    startPosX=pm.get_screen_width() / 2,
                    startPosY=pm.get_screen_height() - 50,
                    endPosX=pos2d["x"],
                    endPosY=pos2d["y"],
                    color=pm.fade_color(pm.get_color("red"), 0.5),
                    thick=1
                )          
            
            pm.end_drawing()

        except:
            continue

if __name__ == "__main__":
    main()
