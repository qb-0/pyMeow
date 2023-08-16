import pyMeow as pm
from random import randint


def main():
    pm.overlay_init()
    fps = pm.get_monitor_refresh_rate()
    pm.set_fps(fps)
    pm.toggle_mouse()
    pm.gui_fade(0.9)
    radius = 50
    width, height = pm.get_screen_width(), pm.get_screen_height()
    x, y = width // 2, height // 2
    speed = 5
    max_speed = 100
    ball_left, ball_down = False, False
    circle_color = pm.get_color("#000000")
    stars = [pm.vec2(randint(0, width), randint(0, height)) for _ in range(300)]

    while pm.overlay_loop():
        if ball_left:
            if x > width - radius:
                ball_left = False
            else:
                x += speed
        else:
            if x < -1 + radius:
                ball_left = True
            else:
                x -= speed

        if ball_down:
            if y > height - radius:
                ball_down = False
            else:
                y += speed
        else:
            if y < -1 + radius:
                ball_down = True
            else:
                y -= speed

        pm.begin_drawing()
        [pm.draw_pixel(vec["x"], vec["y"], pm.get_color("#ffffff")) for vec in stars]
        pm.draw_circle(x, y, radius, circle_color)
        pm.draw_fps(width / 2, height / 2)

        if pm.gui_button(0, 0, 100, 50, "Increase speed"):
            if speed != max_speed:
                speed += 5
        elif pm.gui_button(0, 50, 100, 50, "Decrease speed"):
            if speed != 0:
                speed -= 5
        elif pm.gui_button(100, 0, 100, 50, "Change Color"):
            circle_color = pm.new_color(
                randint(0, 255),
                randint(0, 255),
                randint(0, 255),
                randint(0, 255)
            )
        elif pm.gui_button(100, 50, 100, 50, "Mouse passthrough"):
            pm.toggle_mouse()
        elif pm.gui_button(200, 0, 100, 50, "Increase FPS"):
            fps += 1
            pm.set_fps(fps)
        elif pm.gui_button(200, 50, 100, 50, "Decrease FPS"):
            fps -= 1
            pm.set_fps(fps)

        pm.gui_progress_bar(350, 10, 200, 30, "Speed: ", str(speed), speed, 0, max_speed)
        radius = pm.gui_slider(350, 60, 200, 30, "Radius", str(radius), radius, 0, 150)
        pm.draw_text("Exit with 'END'", 50, 100, 25, pm.get_color("#ffffff"))
        pm.end_drawing()


if __name__ == "__main__":
    main()
