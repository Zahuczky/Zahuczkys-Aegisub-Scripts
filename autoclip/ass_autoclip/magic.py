import cv2
import math
import numpy as np
from pathlib import Path
from PySide6.QtCore import QReadWriteLock
from PySide6.QtGui import QImage
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
        diff_clips = clip.std.CropAbs(left=clipping[0], top=clipping[1], width=clipping[2] - clipping[0], height=clipping[3] - clipping[1]) \
                         .fmtc.bitdepth(bits=16, fulld=True) \
                         .dfttest.DFTTest() \
                         .fmtc.resample(css="444", kernel="bicubic") \
                         .std.SplitPlanes()
        diff_clips[0] = diff_clips[0].fmtc.transfer(transs="709", transd="linear")
        for i in range(3):
            diff_clips.append(diff_clips[i].std.FreezeFrames(first=[0], last=[last-first-1], replacement=[active-first]))

        # Convert to 8-bit RGB
        clip = clip.fmtc.bitdepth(bits=16) \
                   .fmtc.resample(css="444", kernel="bilinear") \
                   .fmtc.matrix(mat="709", col_fam=vs.RGB) \
                   .fmtc.bitdepth(bits=8, dmode=2)

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
                                              .fmtc.bitdepth(bits=8, dmode=2)

                    self.diff_clip2_settings[i] = settings
                    break

        # Get the frame from the diff_clip2 clip
        diff_frame = self.diff_clip2s[i].get_frame(frame)
        self.diff_clip2_locks[i].unlock()
        diff_image = np.array(diff_frame[0], dtype=np.uint8)

        # Show difference (for debug use)
        # return QImage(diff_image.data, self.clipping[2] - self.clipping[0], self.clipping[3] - self.clipping[1], QImage.Format.Format_Grayscale8)

        # Get the frame from original clip
        vsframe = self.clip.get_frame(frame)
        r = np.array(vsframe[0], dtype=np.uint8).reshape((-1, 1))
        g = np.array(vsframe[1], dtype=np.uint8).reshape((-1, 1))
        b = np.array(vsframe[2], dtype=np.uint8).reshape((-1, 1))
        image = np.hstack((r, g, b)).reshape((self.clip.height, self.clip.width, 3))
        clipped_image = image[self.clipping[1]:self.clipping[3], self.clipping[0]:self.clipping[2]]

        # Apply thresholding to the grayscale image
        _, thresh = cv2.threshold(diff_image, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

        # Find the contours in the thresholded image
        contours, _ = cv2.findContours(thresh, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)

        if contours:
            # Find the longest contour, this is janky but what do? Maybe I should combine them. TODO maybe?
            longest_contour = max(contours, key=cv2.contourArea)

            # Draw the longest contour on the original image in red. The image is greyscale so it's black. lol. Should add all planes at some point,
            # maybe not read this clip from VS but just with cv2
            cv2.drawContours(clipped_image, [longest_contour], -1, (253, 30, 32), 1) # 55, 78, 60

        return QImage(image.data, self.clip.width, self.clip.height, QImage.Format.Format_RGB888)

    def apply_clips(self, file, settings):
        logger.info("Saving clip data")
        file.parent.mkdir(parents=True, exist_ok=True)
        with file.open("w") as f:
            # Get all frames and run the findcontours on all of them
            for frame in range(self.clip.num_frames):
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
                                                      .fmtc.bitdepth(bits=8, dmode=2)

                            self.diff_clip2_settings[i] = settings
                            break

                # Get the corresponding frame from the diff_clip2 clip
                diff_frame = self.diff_clip2s[i].get_frame(frame)
                self.diff_clip2_locks[i].unlock()
                diff_image = np.array(diff_frame[0], dtype=np.uint8)

                # Apply thresholding to the grayscale image
                _, thresh = cv2.threshold(diff_image, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

                # Find the contours in the thresholded image
                contours, _ = cv2.findContours(thresh, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)

                if contours:
                    # Find the longest contour, this is janky but what do? Maybe I should combine them. TODO maybe
                    longest_contour = max(contours, key=len)
                    f.write("\\iclip(m")
                    for i, point in enumerate(longest_contour):
                        x, y = point[0]
                        f.write(f" {x + self.clipping[0]} {y + self.clipping[1]}")
                        if i == 0:
                            f.write(" l")
                    f.write(")\n")
                else:
                    f.write("empty\n")
