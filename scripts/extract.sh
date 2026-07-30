#! /usr/bin/bash

user_feedback_path="$HOME/jira/o3-feedback"

# if number of arguments is less than 2, print help mesage and exit
if [ $# -lt 2 ]; then
  echo "Usage: $0 <feedback_id> <bugreport_zip>"
  exit 1
fi

# store the arguments in variables
feedback_id=$1
bugreport_zip=$2

# extract and remove the bugreport zip
unzip -d "$user_feedback_path/$feedback_id" "$bugreport_zip"
rm "$bugreport_zip"

# fine the bugreport zip and unzip it to a folder with the same name as the zip file
cd "$user_feedback_path/$feedback_id"
# find the file starts with "bugreport" and ends with ".zip"
bugreport_zip=$(find . -name "bugreport*.zip")
bugreport_dir=$(basename -s .zip "$bugreport_zip")
echo "$bugreport_dir" "$bugreport_zip"
# exit 0
echo A | unzip -d "$bugreport_dir" "$bugreport_zip"
rm "$bugreport_zip"

# check if a specific bugreport folder exists
reboot_mqs_dir="$bugreport_dir/FS/data/miuilog/stability/reboot"
if [ -d "$reboot_mqs_dir" ]; then
  cd "$reboot_mqs_dir"
  echo $(pwd)
  # unzip every zip file in this folder into a folder with the same name as the zip file
  # and remove the zip file
  for zip_file in $(ls ./*.zip); do
    echo "$zip_file"
    unzip -d ./$(basename -s .zip ./$zip_file) ./$zip_file
    rm ./$zip_file
  done
else
  # if it does not, create a new folder with the feedback id and move the bugreport zip to it
  echo "No reboot mqs folder found"
fi
