# Version 1.0.1
# Even when this file doesn't change, version numbering is kept consistent with the lua script.

import vapoursynth as vs
from vsmasktools import replace_squaremask
import vstools as vst
import numpy as np
import cv2
from PyQt6.QtWidgets import QApplication, QWidget, QLabel, QSlider, QVBoxLayout, QSizePolicy, QCheckBox, QPushButton, QMessageBox
from PyQt6.QtCore import Qt, QSize
import qdarktheme
import os
import sys
import tempfile
import argparse as ap

from PyQt6.QtGui import QImage, QPixmap
class VideoPlayer(QWidget):
    def __init__(self, video_path, first_frame, last_frame, target_clip, act):
        super().__init__()
        self.setWindowTitle("AutoClip")

        # target clip is the top left and bottom right coordinates of the clip in the format "x1 y1 x2 y2"
        # let's convert this into "width, height, x1, y1"
        clip_params = target_clip.split(" ")
        clip_params = [int(float(x)) for x in clip_params]
        clip_params = [clip_params[2] - clip_params[0], clip_params[3] - clip_params[1], clip_params[0], clip_params[1]]


    # Load, cut and filter the video
        # no touchie unless you really know what you're doing
        self.core = vs.core
        self.clip = self.core.lsmas.LWLibavSource(video_path)
        self.clip = self.clip[int(first_frame):int(last_frame)]
        self.black_clip = self.clip.std.BlankClip(width=1920, height=1080, color=[0, 128, 128])
        self.maskk = replace_squaremask(clipa=self.black_clip, clipb=self.clip, mask_params=(clip_params), ranges=(None, None))
        self.ref_frame = self.maskk.std.FreezeFrames(first=[0], last=[self.maskk.num_frames - 1], replacement=[int(act)])
        self.diff_treshold = 0.04
        self.diff_clip2 = self.core.std.Expr([vst.depth(self.maskk, 32), vst.depth(self.ref_frame, 32)], f"x y - abs {self.diff_treshold} < 0 1 ?")
        self.diff_clip2 = vst.depth(self.diff_clip2, 16, range_out=vst.ColorRange.FULL, range_in=vst.ColorRange.FULL)
        self.clip = vst.depth(self.clip, 16, range_out=vst.ColorRange.FULL, range_in=vst.ColorRange.FULL)

        # Create the GUI elements
        self.image_label = QLabel(self) # Maybe it shouldn't be a QLabel but QGraphicView instead? But I couldn't figure out how to not pan the image when zooming with the wheel
        self.image_label.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
        self.image_label.setAlignment(Qt.AlignmentFlag.AlignCenter)  # Center the image
        self.slider = QSlider(Qt.Orientation.Horizontal, self)
        # Set default value for slider
        self.slider.setValue(int(act)) # Let's set this to act from aegisub, probably this is a sane thing.
        self.slider.setRange(0, self.diff_clip2.num_frames - 1) # I hate 0 indexing. 
        self.slider.valueChanged.connect(self.update_image)
        self.contours = None

        # Set the slider's style to resemble a progress bar
        self.slider.setStyleSheet("""
            QSlider {
                background: #202124;
                height: 20px;
            }

            QSlider::groove {
                background: qlineargradient(x1:0, y1:0, x2:1, y2:0, stop:0 #aaa, stop:1 #ddd);
                border: 1px solid #777;
                height: 10px;
                border-radius: 2px;
            }

            QSlider::handle {
                background: qlineargradient(x1:0, y1:0, x2:1, y2:1, stop:0 #eee, stop:1 #ccc);
                border: 1px solid #777;
                width: 8px;
                border-radius: 4px;
            }
        """)
        self.setWindowFlags(Qt.WindowType.Window | Qt.WindowType.WindowMinimizeButtonHint | Qt.WindowType.WindowMaximizeButtonHint | Qt.WindowType.WindowCloseButtonHint)

        self.frame_label = QLabel(self)
        self.frame_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.frame_label.setText(f"Frame {int(act)+1} / {self.diff_clip2.num_frames}")
        self.slider.valueChanged.connect(self.update_frame_label)


        # Create the slider for diff_treshold
        self.diff_treshold_slider = QSlider(Qt.Orientation.Horizontal, self)
        self.diff_treshold_slider.setRange(1, 2000)  # Set the range of the slider (0.01 to 0.2 with a step of 0.01). Maybe experiment more with the range and step. TODO
        self.diff_treshold_slider.setValue(int(self.diff_treshold * 10000))  # Set the initial value based on self.diff_treshold
        self.diff_treshold_slider.valueChanged.connect(self.update_diff_treshold)

        self.diff_label = QLabel(self)
        self.diff_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.diff_label.setText(f"Required difference: 400")
        self.diff_treshold_slider.valueChanged.connect(self.update_diff_label)
        
        self.show_diff_checkbox = QCheckBox("Show Difference", self)
        self.show_diff_checkbox.stateChanged.connect(self.update_image)

        appply_button = QPushButton("Apply Clips")
        appply_button.clicked.connect(self.apply_clips)

        # Set the layout
        layout = QVBoxLayout()
        layout.addWidget(self.image_label)
        layout.addWidget(self.frame_label)
        layout.addWidget(self.slider)
        layout.addWidget(self.diff_label)
        layout.addWidget(self.diff_treshold_slider)
        layout.addWidget(self.show_diff_checkbox)
        layout.addWidget(appply_button)
        self.setLayout(layout)

        self.setMinimumSize(640, 360) # Why would you go smaller. To draw out some bugs? Nah-uh, not on my watch
        self.current_zoom = 1.0  # 100% (no zoom)
        self.zoom_step = 0.1  # Adjust the zoom step as desired

        self.update_image()



    def update_frame_label(self, value):
        self.frame_label.setText(f"Frame {value+1} / {self.diff_clip2.num_frames}")
    
    def update_diff_label(self, value):
        self.diff_label.setText(f"Required difference: {value}")

    def update_image(self):
        mask = self.show_diff_checkbox.isChecked()

        if mask:
            clip = self.diff_clip2
        else:
            clip = self.clip

        frame_number = self.slider.value() 
        frame = clip.get_frame(frame_number)
        image = self.vsvideoframe_to_image(frame)

        if not mask:
            # Get the corresponding frame from the diff_clip2 clip
            diff_frame = self.diff_clip2.get_frame(frame_number)
            diff_image = self.vsvideoframe_to_image(diff_frame)

            # Apply thresholding to the grayscale image
            _, thresh = cv2.threshold(diff_image, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

            # Find the contours in the thresholded image
            self.contours, _ = cv2.findContours(thresh, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)

            # Find the longest contour, this is janky but what do? Maybe I should combine them. TODO maybe?
            longest_contour = max(self.contours, key=cv2.contourArea)

            # Draw the longest contour on the original image in red. The image is greyscale so it's black. lol. Should add all planes at some point, 
            # maybe not read this clip from VS but just with cv2
            cv2.drawContours(image, [longest_contour], -1, (0, 0, 255), 2)

        qimage = self.convert_image_to_qimage(image)

        # Calculate the zoomed size based on the current_zoom
        zoomed_width = int(qimage.width() * self.current_zoom)
        zoomed_height = int(qimage.height() * self.current_zoom)

        # Resize the pixmap to the zoomed size
        zoomed_pixmap = qimage.scaled(zoomed_width, zoomed_height, Qt.AspectRatioMode.IgnoreAspectRatio)

        # Set the pixmap with scaled contents
        self.image_label.setPixmap(zoomed_pixmap)


    def update_diff_treshold(self, value):
        # Update the diff_treshold variable when the slider value changes
        self.diff_treshold = value / 10000
        #print(self.diff_treshold)
        # Re-run the code that calculates self.diff_clip2 using the updated self.diff_treshold
        self.diff_clip2 = self.core.std.Expr([vst.depth(self.maskk, 32), vst.depth(self.ref_frame, 32)], f"x y - abs {self.diff_treshold} < 0 1 ?")
        self.diff_clip2 = vst.depth(self.diff_clip2, 16, range_out=vst.ColorRange.FULL, range_in=vst.ColorRange.FULL)

        self.update_image()

    def wheelEvent(self, event):
        # Implement zooming with the mouse scroll wheel
        num_degrees = event.angleDelta().y() / 8
        num_steps = num_degrees / 15  # Determine the number of steps for zooming

        # Adjust the zoom level based on the zoom step
        new_zoom = self.current_zoom + (num_steps * self.zoom_step)

        # Clamp the zoom level between 10% and 500%
        new_zoom = max(0.1, min(5.0, new_zoom))

        # Update the zoom level and the displayed image
        if new_zoom != self.current_zoom:
            self.current_zoom = new_zoom
            self.update_image()

        # Accept the event to prevent further handling
        event.accept()

    def resizeEvent(self, event):
        # Override the resize event to maintain the aspect ratio
        base_size = QSize(640, 360) 
        aspect_ratio = base_size.width() / base_size.height()

        new_size = event.size()
        new_ratio = new_size.width() / new_size.height()

        if new_ratio > aspect_ratio:
            # Aspect ratio can change, calculate new height
            new_width = int(new_size.height() * aspect_ratio)
            self.resize(new_width, new_size.height())
        else:
            # new width
            new_height = int(new_size.width() / aspect_ratio)
            self.resize(new_size.width(), new_height)

        # Call the base class implementation to resize the widget. There should be a better way. TODO
        super().resizeEvent(event)



        
    def vsvideoframe_to_image(self, frame: vs.VideoFrame):
        npframe = np.asarray(frame[0]) # I guess this is fastest way afterall, but it's only the luma plane. TODO Have to figure out how to merge the Y U V planes. I couldn't so far.
        cvImage = cv2.convertScaleAbs(npframe, alpha=(255.0 / 65535.0)) # It's 16 bit initially, convert to 8 bit
        return cvImage
    
    def convert_image_to_qimage(self, image):
        height, width = image.shape
        bytes_per_line = width * 1   
        qimage = QImage(image.data, width, height, bytes_per_line, QImage.Format.Format_Grayscale8)
        return QPixmap.fromImage(qimage)
    
    def assemble_contour_string(self, contour):
        contour_string = "\\iclip(m"
        for i, point in enumerate(contour):
            x, y = point[0]
            contour_string += f" {x} {y}"
            if i == 0:
                contour_string += " l"
        contour_string += ")"
        return contour_string
    
    def on_message_box_button_clicked(self, button):
        if button.text() == "OK":
            app.quit()

        
    def apply_clips(self):
        # Get all frames and run the findcontours on all of them
        ass_clip = []
        for frame_number in range(self.clip.num_frames):
            # Get the corresponding frame from the diff_clip2 clip
            diff_frame = self.diff_clip2.get_frame(frame_number)
            diff_image = self.vsvideoframe_to_image(diff_frame)

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



# class DevNull:
#     def write(self, msg):
#         pass

# sys.stderr = DevNull()



if __name__ == '__main__':
    parser = ap.ArgumentParser()
    parser.add_argument("-i", "--input", dest="video", help="input file", metavar="FILE")
    parser.add_argument("-f", "--first", dest="first", help="first frame", metavar="STRING")
    parser.add_argument("-l", "--last", dest="last", help="last frame", metavar="STRING")
    parser.add_argument("-c", "--clip", dest="clip", help="clip", metavar="STRING")
    parser.add_argument("-a", "--active-frame", dest="active", help="current video frame in aegi", metavar="STRING")
    args = parser.parse_args()

    video = str(args.video)
    video_path = video.replace("\\", "/")

    app = QApplication([])
    # set fany window name
    app.setStyleSheet(qdarktheme.load_stylesheet())
    gui = VideoPlayer(video_path, args.first, args.last, args.clip, args.active)
    gui.show()
    app.exec()