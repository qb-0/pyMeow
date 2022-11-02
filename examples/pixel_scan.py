import pyMeow as pm
from time import sleep
from random import choice

"""
This script will search an area of 150x150 Pixels for green and red pixels at the mouse position and 
the overlay will draw random lines between the pixels which are found.
"""

resolution = pm.get_display_resolution()
search_colors = [pm.get_color("green"), pm.get_color("red")]
mark_color = pm.get_color("gold")
mark_density = 50
search_area = 150
pm.overlay_init()

def out_of_bounds(mouse_pos):
    return mouse_pos["x"] + search_area > resolution[0] or mouse_pos["y"] + search_area > resolution[1] or \
    mouse_pos["x"] - search_area < 0 or mouse_pos["y"] - search_area < 0

while pm.overlay_loop():
    sleep(0.001)
    m = pm.mouse_position()
    x = m["x"] - search_area / 2
    y = m["y"] - search_area / 2

    if not out_of_bounds(m):
        match = list(
            pm.pixel_search_colors(
                x=x, y=y,
                width=search_area, height=search_area,
                colors=search_colors,
                similarity=92
            )
        )
        
        pm.begin_drawing()
        pm.draw_fps(10, 10)
        if match:
            for _ in range(mark_density):
                p1 = choice(match)
                p2 = choice(match)
                pm.draw_line(p1["x"] + x, p1["y"] + y, p2["x"] + x, p2["y"] + y, mark_color)
        pm.end_drawing()