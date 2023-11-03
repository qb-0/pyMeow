from pyMeow import *
from time import sleep
pyMeow.overlay_init()
pyMeow.set_fps(60)
while pyMeow.overlay_loop():
    pyMeow.begin_drawing()
    pyMeow.draw_fps(10, 10)

    pyMeow.end_drawing()
