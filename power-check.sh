#!/bin/sh
: << "About_THRESHOLD"
This script is designed to set a charge automation, 
LOWER_THRES is the battery level when the Plug should switch on,
UPPER_THRES is the battery level when the Plug should switch off.
About_THRESHOLD

LOWER_THRES=20
UPPER_THRES=80

if [ $LOWER_THRES -ge $UPPER_THRES ]; then
    echo "check THRESHOLD settings, probably something goes wrong."
    exit 1
fi


# getting root privileges to execute tlp-stat command
if [ $(id -u) -ne 0 ]; then
    echo "This script requires root privileges. Please run it with sudo."
    exit 1
fi


: << 'About_User_File'
"user_file" should be created by user, which contains the information below:
PYTHON_PATH="/path/to/user/python"
KASA_PATH="/path/to/kasa"
KASA_DEVICE_IP="/kasa/ip/on/lan"
KASA_DEVICE_PORT_NAME="name of port your want to control"

ex:
PYTHON_PATH="/home/user/anaconda3/bin/python"
KASA_PATH="/home/user/anaconda3/bin/kasa"
KASA_DEVICE_IP="123.123.123.123"
KASA_DEVICE_PORT_NAME="Laptop"
About_User_File

# read variables from /path/of/script/user_info
. $(dirname $0)/user_info

# execute every 5 mins until user interrupts
while true
do
  # get current charge level using tlp-stat -b, store the information to a file called state.
  sudo tlp-stat -b | grep "Charge" > $(dirname $0)/generated/charge_level
  $KASA_PATH --username $USERNAME --password $PASSWD --host $KASA_DEVICE_IP state | grep "Device state:" > $(dirname $0)/generated/plug_state

  # exetract exact level using python, could probably be done by bash file.
  battery_level=$($PYTHON_PATH $(dirname $0)/python/battery_level.py)
  smartplug_state=$($PYTHON_PATH $(dirname $0)/python/plug_state.py)

  # Check if battery level is lower than LOWER_THRES
  if [ "`echo "${battery_level} < $LOWER_THRES" | bc`" -eq 1 ] && [ $smartplug_state = "False" ]
  then
    echo "Current: ${battery_level}, Turning ${KASA_DEVICE_PORT_NAME} on."
    $KASA_PATH --username $USERNAME --password $PASSWD --host $KASA_DEVICE_IP on # --name $KASA_DEVICE_PORT_NAME
  
  # Check if battery level is higher than UPPER_THRES
  elif [ "`echo "${battery_level} > ${UPPER_THRES}" | bc`" -eq 1 ] && [ $smartplug_state = "True" ]
  then
    echo "Current: ${battery_level}, Turning ${KASA_DEVICE_PORT_NAME} off."
    $KASA_PATH --username $USERNAME --password $PASSWD --host $KASA_DEVICE_IP off # --name $KASA_DEVICE_PORT_NAME
  
  # If none of both is true, report the current battery_level
  else
    if [ $smartplug_state = "False" ]; then
      echo "Plug Status Keep: OFF"
    else
      echo "Plug Status Keep: ON"
    fi
    echo "Current Charge Level: ${battery_level} [%]"
    echo "LOWER_THRES: ${LOWER_THRES} [%], UPPER_THRES: ${UPPER_THRES} [%]"
  fi
  
  # Wait for 5 mins to continue the next round.
  sleep 300
done

