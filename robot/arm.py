from __future__ import absolute_import
import usb.core, usb.util, time
from threading import Lock


__all__ = ['move_arm', 'set_light']


class RobotState(object):
    base = None
    shoulder = None
    elbow = None
    wrist = None
    grip = None
    light = False


device = usb.core.find(idVendor=0x1267, idProduct=0x0000)
state = RobotState()
lock = Lock()


if device is None:
    raise ValueError("Arm not found")


def move_arm(duration, joint, value):
    with lock:
        setattr(state, joint, value)
        command_robot()
    
    time.sleep(duration)
        
    with lock:
        setattr(state, joint, None)
        command_robot()
        

def set_light(value):
    with lock:
        setattr(state, 'light', value)
        command_robot()


def command_robot():
    a = 0
    b = 0
    c = 0
    
    if state.base == "clockwise":
        b += 2
    elif state.base == "anti-clockwise":
        b += 1
    
    if state.shoulder == "up":
        a += 64
    elif state.shoulder == "down":
        a += 128
    
    if state.elbow == "up":
        a += 16
    elif state.elbow == "down":
        a += 32
    
    if state.wrist == "up":
        a += 4
    elif state.wrist == "down":
        a += 8
    
    if state.grip == "open":
        a += 2
    elif state.grip == "close":
        a += 1
    
    if state.light == "on":
        c = 1
    else:
        c = 0
    
    device.ctrl_transfer(0x40, 6, 0x100, 0, [a, b, c], 1000)
