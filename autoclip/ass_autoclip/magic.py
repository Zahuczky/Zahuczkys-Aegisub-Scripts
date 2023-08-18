import math
import numpy as np
from pathlib import Path
from PySide6.QtCore import QReadWriteLock
from PySide6.QtGui import QImage
from skimage import measure, segmentation # ⛷️ Ski!
                                          # ⛷️ Dashing through the snow, on a pair of broken skies
                                          # ⛷️ O' the hills we go, crashing into trees
                                          # ⛷️ The snow is turing red, I think I might be dead
                                          # ⛷️ I woke up in the hospital with stitches in my head, oh!
import tempfile
import vapoursynth as vs
from vapoursynth import core

from .base import threads, logger


class Video:
    def __init__(self, video, clipping, first, last, active):
        # Load video
        clip = core.lsmas.LWLibavSource(video.expanduser().as_posix(), cachedir=tempfile.gettempdir()) \
                    [first:last]

        # clip the clip and take reference
        diff_clips = clip.std.CropAbs(left=clipping[0], top=clipping[1], width=clipping[2] - clipping[0], height=clipping[3] - clipping[1])
        if diff_clips.format.subsampling_h and diff_clips.format.subsampling_w:
            diff_clips = diff_clips.resize.Bicubic(format=vs.YUV420P16, range_in=vs.RANGE_LIMITED, range=vs.RANGE_FULL) \
                                   .dfttest.DFTTest() \
                                   .resize.Bicubic(format=vs.YUV444P16, matrix_in=vs.MATRIX_BT709, matrix=vs.MATRIX_BT709, transfer_in=vs.TRANSFER_BT709, transfer=vs.TRANSFER_LINEAR)
        else:
            diff_clips = diff_clips.resize.Bicubic(format=vs.YUV444P16, range_in=vs.RANGE_LIMITED, range=vs.RANGE_FULL) \
                                   .dfttest.DFTTest() \
                                   .resize.Bicubic(matrix_in=vs.MATRIX_BT709, matrix=vs.MATRIX_BT709, transfer_in=vs.TRANSFER_BT709, transfer=vs.TRANSFER_LINEAR)
        diff_clips = diff_clips.std.SplitPlanes()
        for i in range(3):
            diff_clips.append(diff_clips[i].std.FreezeFrames(first=[0], last=[last-first-1], replacement=[active-first]))

        # Convert to 8-bit RGB
        clip = clip.resize.Bilinear(format=vs.RGB24, matrix_in=vs.MATRIX_BT709, transfer_in=vs.TRANSFER_BT709, dither_type="none")

        # Write-protected variables
        self._clip = clip
        self._diff_clips = diff_clips
        self.clipping = clipping

        # Variables with RwLock
        self.diff_clip2s = [None] * threads
        self.diff_clip2_settings = [None] * threads
        self.diff_clip2_locks = []
        for i in range(threads):
            self.diff_clip2_locks.append(QReadWriteLock())

    # Write-protected variables
    @property
    def clip(self):
        return self._clip
    @property
    def diff_clips(self):
        return self._diff_clips

    def get_frame(self, frame, settings):
        i = 0
        for i in range(threads):
            locked = self.diff_clip2_locks[i].tryLockForRead()
            if locked:
                if self.diff_clip2_settings[i] == settings:
                    break
                else:
                    self.diff_clip2_locks[i].unlock()
        else:
            for i in range(threads):
                # There are equal number of threads and clip2s, so it is
                # guaranteed to at least get a lock
                locked = self.diff_clip2_locks[i].tryLockForWrite()
                if locked:
                    # Thanks arch1t3cht for giving the ideas
                    self.diff_clip2s[i] = core.std.Expr(self.diff_clips, \
                                                        f"x a - abs {math.ceil(settings.l_threshold * 65535)} >= y b - abs 2 pow z c - abs 2 pow + sqrt {math.ceil(settings.c_threshold * 65535)} >= and 65535 0 ?") \
                                              .resize.Bilinear(format=vs.GRAY8, dither_type="none") \
                                              .std.AddBorders(left=1, right=1, top=1, bottom=1, color=0)

                    self.diff_clip2_settings[i] = settings
                    break

        # Get the frame from the diff_clip2 clip
        diff_frame = self.diff_clip2s[i].get_frame(frame)
        self.diff_clip2_locks[i].unlock()
        diff_image = np.array(diff_frame[0], dtype=np.uint8)

        # Show difference (for debug use)
        # return QImage(diff_image.data, self.clipping[2] - self.clipping[0], self.clipping[3] - self.clipping[1], QImage.Format.Format_Grayscale8)

        # Find the boundaries in the image
        if np.any(diff_image):
            boundaries = segmentation.find_boundaries(diff_image, mode="inner")[1:-1, 1:-1]
        else:
            boundaries = None

        # Get the frame from original clip
        vsframe = self.clip.get_frame(frame)
        r = np.array(vsframe[0], dtype=np.uint8)
        g = np.array(vsframe[1], dtype=np.uint8)
        b = np.array(vsframe[2], dtype=np.uint8)
        if boundaries is not None:
            # Draw the boundaries on original image in red
            # maybe not read this clip from VS but just with ski
            r[self.clipping[1]:self.clipping[3], self.clipping[0]:self.clipping[2]][boundaries] = 253 # 55, 78, 60
            g[self.clipping[1]:self.clipping[3], self.clipping[0]:self.clipping[2]][boundaries] = 30
            b[self.clipping[1]:self.clipping[3], self.clipping[0]:self.clipping[2]][boundaries] = 32
        image = np.hstack((r.reshape((-1, 1)), g.reshape((-1, 1)), b.reshape((-1, 1)))).reshape((self.clip.height, self.clip.width, 3))

        return QImage(image.data, self.clip.width, self.clip.height, QImage.Format.Format_RGB888)

    def apply_clips(self, file, settings):
        logger.info("Saving clip data")
        file.parent.mkdir(parents=True, exist_ok=True)
        with file.open("w") as f:
            # Get all frames and run the findcontours on all of them
            for frame in range(self.clip.num_frames):
                logger.info(f"  Frame {frame}")
                # Get the diff_clip2 clip with the settings
                i = 0
                for i in range(threads):
                    locked = self.diff_clip2_locks[i].tryLockForRead()
                    if locked:
                        if self.diff_clip2_settings[i] == settings:
                            break
                        else:
                            self.diff_clip2_locks[i].unlock()
                else:
                    for i in range(threads):
                        # There are equal number of threads and clip2s, so it is
                        # guaranteed to at least get a lock
                        locked = self.diff_clip2_locks[i].tryLockForWrite()
                        if locked:
                            # Thanks arch1t3cht for giving the ideas
                            self.diff_clip2s[i] = core.std.Expr(self.diff_clips, \
                                                                f"x a - abs {math.ceil(settings.l_threshold * 65535)} >= y b - abs 2 pow z c - abs 2 pow + sqrt {math.ceil(settings.c_threshold * 65535)} >= and 65535 0 ?") \
                                                      .resize.Bilinear(format=vs.GRAY8, dither_type="none") \
                                                      .std.AddBorders(left=1, right=1, top=1, bottom=1, color=0)

                            self.diff_clip2_settings[i] = settings
                            break

                # Get the corresponding frame from the diff_clip2 clip
                diff_frame = self.diff_clip2s[i].get_frame(frame)
                self.diff_clip2_locks[i].unlock()
                diff_image = np.array(diff_frame[0], dtype=np.uint8)

                # Find the contours in the image
                contours = measure.find_contours(diff_image, level=0.5)

                if contours:
                    f.write("\\iclip(")
                    for i in range(len(contours)):
                        contour = np.ceil(contours[i], out=contours[i])
                        if i == 0:
                            f.write("m")
                        else:
                            f.write(" m")


                        # Simplify the clip similar to Shape Simplify in zf.EverythingShape
                        to_write_x = None
                        to_write_y = None
                        # The start is set to x because ski output always starts from bottom right corner,
                        # and thus the first point after start is always the one to the left of the start
                        prev_axis = None
                        def simplified_write(x, y):
                            nonlocal to_write_x
                            nonlocal to_write_y
                            nonlocal prev_axis
                            if to_write_x is None:
                                to_write_x = x
                                to_write_y = y
                            elif to_write_x == x:
                                if prev_axis == "x":
                                    to_write_y = y
                                elif prev_axis == None:
                                    to_write_y = y
                                    prev_axis = "x"
                                else:
                                    f.write(f" {to_write_x + self.clipping[0] - 1} {to_write_y + self.clipping[1] - 1}")
                                    to_write_y = y
                                    prev_axis = "x"
                            elif to_write_y == y:
                                if prev_axis == "y":
                                    to_write_x = x
                                elif prev_axis == None:
                                    to_write_x = x
                                    prev_axis = "y"
                                else:
                                    f.write(f" {to_write_x + self.clipping[0] - 1} {to_write_y + self.clipping[1] - 1}")
                                    to_write_x = x
                                    prev_axis = "y"
                            else:
                                f.write(f" {to_write_x + self.clipping[0] - 1} {to_write_y + self.clipping[1] - 1}")
                                to_write_x = x
                                to_write_y = y
                        def simplified_write_last():
                            f.write(f" {to_write_x + self.clipping[0] - 1} {to_write_y + self.clipping[1] - 1}")
                            
                        # Fix the top left and bottom right corner
                        prev_x = None
                        prev_y = None
                        def write(x, y):
                            nonlocal prev_x
                            nonlocal prev_y
                            if prev_x is None:
                                simplified_write(x, y)
                                simplified_write_last()
                                f.write(" l")
                            # Top left corner
                            elif prev_x == x and prev_y == y:
                                return
                            # Bottom right corners
                            elif (prev_x == x + 1 and prev_y + 1 == y) or \
                                 (prev_x + 1 == x and prev_y == y + 1):
                                simplified_write(x + 1, y)
                                simplified_write(x, y)
                            # Regular point
                            else:
                                simplified_write(x, y)
                            prev_x = x
                            prev_y = y


                        for j in range(contour.shape[0]):
                            write(int(contour[j, 1]), int(contour[j, 0]))

                        # So it loops back to the starting point
                        write(int(contour[0, 1]), int(contour[0, 0]))
                        simplified_write_last()

                    f.write(")\n")
                else:
                    f.write("empty\n")
