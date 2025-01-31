import cv2
import time
import datetime
import imutils
import numpy as np
from datetime import date

def motion_detection():
    video_capture = cv2.VideoCapture(0)
    time.sleep(2)
    first_frame = None

    while True:
        ret, frame = video_capture.read()
        if not ret:
            break

        text = f'undetected {time.ctime()}'
        greyscale_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        gaussian_frame = cv2.GaussianBlur(greyscale_frame, (21, 21), 0)
        blur_frame = cv2.blur(gaussian_frame, (5, 5), 0)  # Blurs picture with 5x5 image kernel
        greyscale_image = blur_frame

        if first_frame is None:
            first_frame = greyscale_image
            continue

        frame = imutils.resize(frame, width=500)
        frame_delta = cv2.absdiff(first_frame, greyscale_image)
        thresh = cv2.threshold(frame_delta, 100, 255, cv2.THRESH_BINARY)[1]  # Thresholding
        dilate_image = cv2.dilate(thresh, None, iterations=2)  # Enlarge foreground pixels
        
        # Fix for OpenCV 4 (returns 2 values instead of 3)
        cnt, _ = cv2.findContours(dilate_image.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)  

        for c in cnt:
            if cv2.contourArea(c) > 800:
                (x, y, w, h) = cv2.boundingRect(c)
                cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 255, 0), 2)  # Draw green box

                text = f'[Detected] {time.ctime()} || {date.today()}'
                with open('camera_log.txt', 'a') as f:
                    f.write(text + "\n")

        font = cv2.FONT_HERSHEY_SIMPLEX
        cv2.putText(frame, f'Room Status: {text}', (10, 20), font, 0.5, (0, 0, 255), 2)
        cv2.putText(frame, f'Time: {time.ctime()}', (10, frame.shape[0] - 10), font, 0.35, (0, 0, 255), 1)
        
        cv2.imshow('[Security Feed]', frame)
        cv2.imshow('Threshold [Front-Image]', dilate_image)
        cv2.imshow('Frame_Delta', frame_delta)

        key = cv2.waitKey(1) & 0xFF  # 0xFF hex constant
        if key == ord('q'):
            break

    video_capture.release()
    cv2.destroyAllWindows()

if __name__ == '__main__':
    motion_detection()
