from typing import List, Iterable, Union, Any, Tuple, Dict, NamedTuple, NewType, Optional, Callable, TypeVar, Generic, Type, TypeAlias

cc_path = "../cheatsheet.txt"
classes_experimental = """
Vector2 = NamedTuple('Vector2', [('x', float), ('y', float)])
Vector3 = NamedTuple('Vector3', [('x', float), ('y', float), ('z', float)])
Process = NamedTuple('Process', [('name', str), ('pid', int), ('debug', bool), ('handle', int)])
Color = NamedTuple('Color', [('r', int), ('g', int), ('b', int), ('a', int)])
Pixel = NamedTuple('Pixel', [('x', int), ('y', int), ('color', Color)])
Module = NamedTuple('Module', [('name', str), ('base', int), ('end', int), ('size', int)])
"""
classes = """
class Vector2(NamedTuple):
    x: float
    y: float
    
class Vector3(NamedTuple):
    x: float
    y: float
    z: float
    
class Process(NamedTuple):
    name: str
    pid: int
    debug: bool
    handle: int
    
class Color(NamedTuple):
    r: int
    g: int
    b: int
    a: int
    
class Pixel(NamedTuple):
    x: int
    y: int
    color: Color
    
class Module(NamedTuple):
    name: str
    base: int
    end: int
    size: int
"""

common_vars_without_type = {
    "rangeStart": "rangeStart: int ",
    "width": "width: int ",
    "height": "height: int ",
    "posX": "posX: float ",
    "posY": "posY: float ",
    "x": "x: int ",
    "y": "y: int ",
    "v1": "v1: int ",
    "color1": "color1: Color ",
    "rec1": "rec1: Rectangle ",
    "startPosX": "startPosX: float ",
    "startPosY": "startPosY: float ",
    "endPosX": "endPosX: float ",
    "endPosY": "endPosY: float ",
    "centerX": "centerX: float ",
    "centerY": "centerY: float ",
    "radius": "radius: float ",
    "startAngle": "startAngle: float ",
    "endAngle": "endAngle: float ",
    "segments": "segments: float ",
    "innerRadius": "innerRadius: float ",
    "outerRadius": "outerRadius: float ",
    "radiusH": "radiusHeight: float ",
    "pos1X": "pos1X: float ",
    "pos1Y": "pos1Y: float ",
    "pos1Z": "pos1Z: float ",
    "pos2X": "pos2X: float ",
    "pos2Y": "pos2Y: float ",
    "pos2Z": "pos2Z: float ",
    "pos3X": "pos3X: float ",
    "pos3Y": "pos3Y: float ",
    "pos3Z": "pos3Z: float ",
    "r": "r: int",
    "g": "g: int",
    "b": "b: int",
    "a": "a: int",
    "pointX": "pointX: float ",
    "pointY": "pointY: float ",
    "startPos1X": "startPos1X: float ",
    "startPos1Y": "startPos1Y: float ",
    "endPos1X": "endPos1X: float ",
    "endPos1Y": "endPos1Y: float ",
    "startPos2X": "startPos2X: float ",
    "startPos2Y": "startPos2Y: float ",
    "endPos2X": "endPos2X: float ",
    "endPos2Y": "endPos2Y: float ",
    "title": "title: str ",
    "message": "message: str ",
    "value": "value: float ",
    "fontSize": "fontSize: int ",
}

replace_dict = {
    "uint array": "List[int]",
    "int array": "List[int]",
    "int8 array": "List[int]",
    "int16 array": "List[int]",
    "int32 array": "List[int]",
    "int64 array": "List[int]",
    "float array": "List[float]",
    "float64 array": "List[float]",
    "byte": "bytes",
    "string": "str",
    "bytes array": "bytearray",
    "str|int": "Union[str, int]",
    "ByteAddress": "int",
    "(x, y, width, height: int)": "Tuple[int, int, int, int]",
    "(int, int)": "Tuple[int, int]",
    "(x, y)": "Tuple[int, int]",
    "(int, str)": "Tuple[int, str]",
    "world_to_screen(matrix: float array (16), pos: Vector3, algo: int = 0): Vector2": "world_to_screen(matrix: List[float], pos: "
                                                                                       "Vector3, algo: int = 0) -> Vector2",
    "Vector2 array": "List[Vector2]",
    "Vector3 array": "List[Vector3]",
    "Color array": "List[Color]",
    "Process (iterator)": "Iterable[Process]",
    "Module (iterator)": "Iterable[Module]",
    "Pixel (iterator)": "Iterable[Pixel]",
    "string|int": "Union[str, int]",
    "any": "Any",
    "v1, v2: Vector3": "v1: Vector3, v2: Vector3",
    "v1, v2: Vector2": "v1: Vector2, v2: Vector2",
}


def convert(input_file: str, output_file: str) -> None:
    with open(input_file, 'r') as f, open(output_file, 'w') as f2:
        f2.write(classes)
        for line in f:
            if "##" in line or not "(" in line or "when defined" in line:
                continue
            for k in replace_dict:
                if k in line:
                    line = line.replace(k, str(replace_dict[k]))
            func_name = line.split("(")[0].strip()

            func_args = line.split("(")[1].split(")")[0].strip()
            for arg in func_args.split(","):
                if arg.strip() in common_vars_without_type:
                    func_args = func_args.replace(arg, common_vars_without_type[arg.strip()])

            split_return_type = line.split(")"[-1].strip().partition(":")[0].strip())
            func_return_type = split_return_type[1].strip(":").strip()
            if func_name == "world_to_screen":
                func_args = "matrix: List[float], pos: Vector3, algo: int = 0"
                func_return_type = "Vector2"

            if func_return_type == "":
                func_return_type = " -> None: ..."
            else:
                func_return_type = " -> " + func_return_type + ": ..."
            f2.write("def " + func_name + "(" + func_args + ")" + func_return_type + "\n")


if __name__ == "__main__":
    convert(cc_path, "../python/pyMeow/pyMeow.pyi")
