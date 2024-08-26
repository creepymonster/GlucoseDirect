# FAQ

## Glucose Direct keeps losing the connection to the sensor

Check if other apps (such as LibreLink) are allowed to use Bluetooth, and thus take away Glucose Direct's connection to the sensor !

This can be done under the iOS app "Settings" > "LibreLink" (or other app that can connect sensors), disable Bluetooth there.

## No more minute-by-minute notifications, but glucose alarms continue to sound
Go to Settings, disable the Glucose Badge under "Other Settings", but leave all alarms enabled. With the glucose badge also minutely notifications disappear. Without the notifications, however, it is also unfortunately not possible to display mmol values on the app icon.

## Display glucose values on the Apple Watch !
Create a new calendar in the Apple "Calendar" app, e.g. "Glucose Direct".  Activate the calendar export in the Glucose Direct app, also select the created calendar there.

On the Apple Watch, activate a complication with the calendar selection "Your Schedule" on your Watch Face.

## Libre 3 connection problems ("No data" or "Missing patient id")
The first part is to connect the "Libre 3" app with the "LibreLinkUp" app. The matching video is https://youtube.com/shorts/Ljj-eQ4Jl30

1. In the "Libre 3" app under "Connected Apps" > "LibreLink Up" > "Manage" > "Add Connection" enter your LibreView account.
2. In the "LibreLinkUp" app, log in with your LibreView account.
3. Then you get in the "LibreLinkUp" app a notice that data is shared with you. After a short time data will appear in "LibreLinkUp". Only after you see data in "LibreLinkUp" you can continue with the next part.

The second part is to connect the sensor in "Glucose Direct". The matching video is https://youtube.com/shorts/Xn5jM2rJcb0

1. In "Glucose Direct" on the "Overview" select "Scan Sensor" and scan the Libre 3 sensor on the arm with it. Attention, the scanning process takes longer than with the Libre 2 - it can take 5-8 seconds until the sensor is scanned. While scanning, hold the phone as still as possible over the sensor - you will hear a beep when the scan is complete.
2. Under "Overview", at the bottom "Sensor details" you should now see that a Libre 3 sensor was found.
3. In "Glucose Direct" switch to "Settings" and enter the same LibreView data as in "LibreLinkUp" under "Connection Settings" at the top.
4. Switch back to the overview and press "Connect sensor". After a short time, data will also appear in "Glucose Direct".
.
