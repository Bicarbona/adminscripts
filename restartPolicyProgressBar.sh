#!/bin/bash
# Reboot script with progress bar for use with Casper policies
# Fork of https://jamfnation.jamfsoftware.com/discussion.html?id=14940
# Jacob Salmela
# 2015-08-21
cocoaDialogPath="/etc/CocoaDialog/CocoaDialog.app/Contents/MacOS/CocoaDialog"
rebootSeconds=300
restartTitle="Software Update Completed"

initRestart() {
# Create restart script
echo > /tmp/restartscript.sh '#!/bin/bash
timerSeconds=$1
cdPath=$2
cdTitle=$3
rm -f /tmp/hpipe
mkfifo /tmp/hpipe
sleep 0.2
$cdPath progressbar --title "$cdTitle" --text "Preparing to reboot this Mac..." \
--posX "left" --posY "top" --width 300 --float \
--icon-file "/System/Library/CoreServices/loginwindow.app/Contents/Resources/Restart.tiff" \
--icon-height 48 --icon-width 48 --height 90 < /tmp/hpipe &
exec 3<> /tmp/hpipe
echo "100" >&3
sleep 1.5
startTime=`date +%s`
stopTime=$((startTime+timerSeconds))
secsLeft=$timerSeconds
progLeft="100"
barTick=$((timerSeconds/progLeft))
while [[ "$secsLeft" -gt 0 ]]; do
    sleep 1
    currTime=`date +%s`
    progLeft=$((secsLeft*100/timerSeconds))
    secsLeft=$((stopTime-currTime))
    minRem=$((secsLeft/60))
    secRem=$((secsLeft%60))
    echo "$progLeft $minRem minute(s) $secRem seconds until restart." >&3
done
shutdown -r now'

# Create and load a LaunchDaemon to fork a restart
echo "<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.company.restart</string>
    <key>UserName</key>
    <string>root</string>
    <key>ProgramArguments</key>
    <array>
        <string>sh</string>
        <string>/tmp/restartscript.sh</string>
        <string>$rebootSeconds</string>
        <string>$cocoaDialogPath</string>
        <string>$restartTitle</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>" > /tmp/restart.plist
launchctl load /tmp/restart.plist
}

initRestart
