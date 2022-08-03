import datetime
import os
import time
import logging
import glob
import re
from subprocess import Popen, PIPE
import picamera

VIDEO_DURATION = 300 # s
FPS = 2 # s
MIN_SPACE_BEFORE_DELETE_OLD = 10.0  # %
SPACE_TO_LEAVE_AFTER_DELETE = 20.0  # %
RESOLUTION = (1280, 972) # s
VIDEO_DIR = "/videos/"
PREVIEW = True

logging.basicConfig()
logging.getLogger().setLevel(logging.INFO)


def remove_old_files():

    if available_disk_space() > MIN_SPACE_BEFORE_DELETE_OLD:
        return
    all_files = []
    # should not be any , but remove them if the exist
    temp_files = []

    for g in sorted(glob.glob(os.path.join(VIDEO_DIR, '*.h264')), reverse=True):
        if g.startswith("tmp."):
            temp_files.append(g)
        elif g.endswith(".h264"):
            all_files.append(g)
            # remove all but last temp files, in case
    for r in temp_files[1: len(temp_files)]:
        os.remove(r)

    while available_disk_space() < SPACE_TO_LEAVE_AFTER_DELETE:
        # remove oldest images
        os.remove(all_files.pop())


def device_id():
    cpuserial = ""
    with open('/proc/cpuinfo', 'r') as f:
        for line in f:
            if line[0:6] == 'Serial':
                cpuserial = line[10:26]
                cpuserial_last_8bit = cpuserial[8:16]
                return cpuserial_last_8bit
    if not cpuserial:
        logging.warning("Could not read serial number setting to 00000000")
        cpuserial = "00000000"
    return cpuserial


def available_disk_space():
    command = "df %s --output=used,size | tail -1 | tr -s ' '" % VIDEO_DIR
    p = Popen(command,  shell=True, stderr=PIPE, stdout=PIPE)
    c = p.wait(timeout=10)
    output = p.stdout.read()
    match = re.findall(b"(\d+) (\d+)", output)
    if match:
        num, den = match[0]
        avail = 100 - (100 * int(num)) / int(den)
        return round(avail, 2)
    else:
        raise Exception("Cannot assess space left on device")


def make_video_name():
    now = time.time()
    prefix = datetime.datetime.utcfromtimestamp(now).strftime('%Y-%m-%d_%H-%M-%S')
    basename = "tmp." + device_id() + "." + prefix + ".h264"
    path = os.path.join(VIDEO_DIR, basename)
    return path, now


remove_old_files()

picam = picamera.PiCamera()
picam.framerate = FPS
picam.resolution = RESOLUTION
time.sleep(2)

video_path, video_start_time = make_video_name()
logging.warning(f"Starting {video_path}")

if PREVIEW:
    picam.start_preview()

picam.start_recording(video_path)
    #fixme set bitrate
    # ,
    #                   bitrate=)

while True:
    # if picam.recording:
    if time.time() - video_start_time > VIDEO_DURATION:
        new_video_path, new_video_time = make_video_name()
        picam.split_recording(new_video_path)
        logging.warning(f"Starting {new_video_path}")
        remove_old_files()

        video_path_final_name = os.path.join(VIDEO_DIR, os.path.basename(video_path)[4:])
        os.rename(video_path, video_path_final_name)
        logging.warning(f"Completed  {video_path_final_name}")
        video_path, video_start_time = new_video_path, new_video_time
    picam.wait_recording(1)

