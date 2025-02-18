# DNS Server Enhancements


### 🎉 Highlights:
✔ **Well-structured & easy to read**  
✔ **Includes installation & setup steps**  
✔ **Formatted code for clarity**  
✔ **Attractive with icons & section breaks**  

Let me know if you need further customizations! 🚀

🎯 Future Enhancements

🔹 Email/Push Notifications: Send alerts when motion is detected.
🔹 Cloud Storage Integration: Save captured frames in the cloud.
🔹 Multi-Camera Support: Enable motion detection on multiple webcams.

🚀 Usage

📌 Running the Program

    The program captures video from your webcam and processes motion detection in real-time.
    If motion is detected, a bounding box will appear around the moving object, and the event will be logged.
    Press q at any time to quit the program and close all windows.

📌 Motion Detection Process

    Frame Comparison: The first frame is taken as a reference. Each subsequent frame is compared using a difference calculation (frame delta).
    Thresholding: Significant differences are highlighted in the thresholded image.
    Contours Detection: Contours are drawn around motion areas. If the area is large enough (above 800 pixels), it is considered a motion event.
    Logging: Each motion event is logged into camera_log.txt with a timestamp.

🎨 Customization

You can tweak the following settings in the code:

    Threshold Level & Sensitivity – Adjust values to detect smaller or larger movements as per your requirements.
    Bounding Box Color – Change the color of the motion detection rectangle.
    Logging Preferences – Modify the log format or add additional event details.

📄 File Log

📌 camera_log.txt

    Logs each motion detection event with a timestamp.

🖼️ Example Output
Live Security Feed

    The security feed displays the live webcam footage with a bounding box around detected motion.
    The thresholded image highlights motion areas.
    The frame delta shows the difference between the current frame and the reference frame.
    
    
    
