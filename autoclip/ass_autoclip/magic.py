import cv2
import numpy as np
from pathlib import Path
from PySide6.QtCore import QReadWriteLock
from PySide6.QtGui import QImage
import tempfile
import vapoursynth as vs
from vapoursynth import core
from vsmasktools import replace_squaremask
import vstools as vst

from base import threads



class Video:
    def __init__(self, video, clipping, first, last, active):
        # Load, cut and filter the video
        # no touchie unless you really know what you're doing
        clip = core.lsmas.LWLibavSource(video.expanduser().as_posix(), cachedir=tempfile.gettempdir())
        clip = clip[first:last]
        black_clip = clip.std.BlankClip(color=[0, 128, 128])
        maskk = replace_squaremask(clipa=black_clip, clipb=clip, mask_params=(clipping), ranges=(None, None))
        ref_frame = maskk.std.FreezeFrames(first=[0], last=[maskk.num_frames - 1], replacement=[active])
        clip = vst.depth(clip, 16, range_out=vst.ColorRange.FULL, range_in=vst.ColorRange.FULL)

        # Write-protected variables
        self._clip = clip
        self._maskk = maskk
        self._ref_frame = ref_frame

        # Variables with RwLock
        self.diff_clip2s = [None] * threads
        self.diff_clip2_differences = [None] * threads
        self.diff_clip2_locks = []
        for i in range(threads):
            self.diff_clip2_locks.append(QReadWriteLock())

    # Write-protected variables
    @property
    def clip(self):
        return self._clip
    @property
    def maskk(self):
        return self._maskk
    @property
    def ref_frame(self):
        return self._ref_frame

    def get_frame(self, frame, difference, show_difference):
        i = 0
        for i in range(threads):
            locked = self.diff_clip2_locks[i].tryLockForRead()
            if locked:
                if self.diff_clip2_differences[i] == difference:
                    break
                else:
                    self.diff_clip2_locks[i].unlock()
        else:
            for i in range(threads):
                # There are equal number of threads and clip2s, so it is
                # guaranteed to at least get a lock
                locked = self.diff_clip2_locks[i].tryLockForWrite()
                if locked:
                    self.diff_clip2s[i] = core.std.Expr([vst.depth(self.maskk, 32), vst.depth(self.ref_frame, 32)], f"x y - abs {difference} < 0 1 ?")
                    self.diff_clip2s[i] = vst.depth(self.diff_clip2s[i], 16, range_out=vst.ColorRange.FULL, range_in=vst.ColorRange.FULL)

                    self.diff_clip2_differences[i] = difference
                    break

        # Get frame
        if not show_difference:
            # Get the frame from the diff_clip2 clip
            diff_frame = self.diff_clip2s[i].get_frame(frame)
            self.diff_clip2_locks[i].unlock()
            diff_image = self._vsvideoframe_to_image(diff_frame)

            # Get the frame from original clip
            vsframe = self.clip.get_frame(frame)
            image = self._vsvideoframe_to_image(vsframe)

            # Apply thresholding to the grayscale image
            _, thresh = cv2.threshold(diff_image, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

            # Find the contours in the thresholded image
            self.contours, _ = cv2.findContours(thresh, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)

            # Find the longest contour, this is janky but what do? Maybe I should combine them. TODO maybe?
            longest_contour = max(self.contours, key=cv2.contourArea)

            # Draw the longest contour on the original image in red. The image is greyscale so it's black. lol. Should add all planes at some point,
            # maybe not read this clip from VS but just with cv2
            cv2.drawContours(image, [longest_contour], -1, (0, 0, 255), 2)

        else: # show_difference
            frame = self.diff_clip2s[i].get_frame(frame)
            self.diff_clip2_locks[i].unlock()
            image = self._vsvideoframe_to_image(vsframe)

        return self._convert_image_to_qimage(image)

    def _vsvideoframe_to_image(self, frame: vs.VideoFrame):
        npframe = np.asarray(frame[0]) # I guess this is fastest way afterall, but it's only the luma plane. TODO Have to figure out how to merge the Y U V planes. I couldn't so far.
        cvImage = cv2.convertScaleAbs(npframe, alpha=(255.0 / 65535.0)) # It's 16 bit initially, convert to 8 bit
        return cvImage

    def _convert_image_to_qimage(self, image):
        height, width = image.shape
        bytes_per_line = width * 1
        return QImage(image.data, width, height, bytes_per_line, QImage.Format.Format_Grayscale8)

    # TODO
    def apply_clips(self):
        # Get all frames and run the findcontours on all of them
        ass_clip = []
        for frame_number in range(self.clip.num_frames):
            # Get the corresponding frame from the diff_clip2 clip
            diff_frame = self.diff_clip2.get_frame(frame_number)
            diff_image = self._vsvideoframe_to_image(diff_frame)

            _, thresh = cv2.threshold(diff_image, 60, 255, cv2.THRESH_BINARY)

            # Find the contours in the thresholded image
            contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
            
            if contours:
                # Find the longest contour, this is janky but what do? Maybe I should combine them. TODO maybe
                longest_contour = max(contours, key=len)
                contour_string = self.assemble_contour_string(longest_contour.tolist())
                ass_clip.append(contour_string + "\n")
            else:
                ass_clip.append("empty\n")

        # Write the ass_clip to a file called zahuczky/autoclip.txt in the OS's temp folder.
        tempdir = tempfile.gettempdir()
        folder_path = os.path.join(tempdir, "zahuczky")

        if not os.path.exists(folder_path):
            os.makedirs(folder_path)

        f = open(f"{folder_path}\\autoclip.txt", 'w')
        for line in ass_clip:
            f.write(f"{line}")
        f.close

        # pop up a windows that says "applying finished"
        msg_box = QMessageBox()
        msg_box.setText("Applying finished")
        msg_box.buttonClicked.connect(self.on_message_box_button_clicked)
        msg_box.exec()
