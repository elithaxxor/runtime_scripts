Motion Detection Security Camera

This Python program is designed to capture video from your webcam and detect motion in real time. The program uses OpenCV for image processing and displays a live security feed with motion-detected events highlighted with bounding boxes. Additionally, it logs the motion events with a timestamp into a log file.

Features

	•	Real-Time Motion Detection: Detects movement by comparing frames and identifying significant differences.
	•	Security Feed Display: The feed from the webcam is displayed with real-time motion tracking and timestamps.
	•	Bounding Box on Motion: When motion is detected, a green rectangle is drawn around the moving object.
	•	Log Motion Events: All detected motion events are logged into camera_log.txt with a timestamp.
	•	Multiple Windows Display: The program shows the security feed, the thresholded image (binary image), and the frame delta used for motion detection.

How It Works

	1.	Video Capture: The program starts by capturing video from your webcam using OpenCV.
	2.	Frame Processing: Each frame is converted to greyscale, blurred to reduce noise, and compared to an initial reference frame (the first frame captured).
	3.	Motion Detection: The difference between the current frame and the reference frame is used to detect motion. If significant changes (contours) are found in the frame, the motion is marked as detected.
	4.	Bounding Box: A green bounding box is drawn around the detected motion area.
	5.	Logging: The timestamp and detection event are recorded in camera_log.txt.
	6.	Live Feed: A live feed with detected motion is shown to the user with real-time timestamps.

Installation

Prerequisites:

	1.	Install Python (if not already installed)
	2.	Install required libraries:
	•	OpenCV
•	Imutils
	•	Numpy

To Install the Required Libraries:

    1.	Clone the Repository:
        ``` git clone
    2. pip install -r requirements.txt

Steps:

Usage

	•	When the program runs, it captures video from your webcam.
	•	If motion is detected, the program will display a bounding box around the moving object and log the event.
	•	Press the q key at any time to quit the program and close all windows.

Motion Detection Process:

	•	Frame Comparison: The first frame is taken as a reference. Each subsequent frame is compared to this reference using a difference calculation (frame delta).
	•	Thresholding: Any significant differences are highlighted in the thresholded image.

	•	Contours: Contours are drawn around detected areas of motion. If the area is large enough (above 800 pixels), it is considered a motion event.
	•	Log File: Each motion event is logged into camera_log.txt with a timestamp for tracking purposes.

Customization:

	•	You can adjust the threshold level and contour area sensitivity in the code to detect smaller or larger movements as per your requirements.

File Log

	•	camera_log.txt: This file logs the detected motion events with timestamps.

Example Output:

	•	Security Feed: Displays the live webcam feed with a bounding box around detected motion.
	•	Threshold Image: Shows the binary image after thresholding, highlighting areas of motion.
	•	Frame Delta: Displays the difference between the current frame and the reference frame.

License

This project is free to use under the MIT License.

This project provides a basic motion detection system using Python and OpenCV, which can be further expanded for home security, surveillance, or other applications involving real-time motion tracking.# Security-Camera-Motion-Detection
