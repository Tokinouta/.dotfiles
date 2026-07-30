#!/bin/bash

OTOP="$PWD"

SCRIPT=$0

function parser_help() {
  echo $SCRIPT "<JIRA_ID>" \"<Feedback log URL>\"
}

function download_feedback_log_and_extract() {
  cd "$OTOP"
  mkdir -p $1
  cd $1
  if [[ ! -f output.zip ]] ; then
    wget "$2" -O output.zip
  fi

  mkdir extract
  cd extract
  unzip -u ../output.zip
  mkdir bugreport
  cd bugreport
  unzip -u ../bugreport*.zip
  cd "$OTOP"
}

function parse_rhythmic_hang() {
  local watchdog_dead_lock_found="$(grep -rh -A 15 -B 15 RhythmicEyeCareManager.registerReceiver $1)"
  echo
  if [[ -n "$watchdog_dead_lock_found" ]] ; then
    echo "============================"
    echo "  Found deadlock watchdog  "
    echo "============================"
    echo "JIRA: $(echo $1 | cut -d '/' -f 1)"
    echo "$1"
    echo
    echo "$watchdog_dead_lock_found"
  else
    echo "Other type watchdog found: $1"
  fi
}

function find_dpue_msg() {
  local found=$(egrep -m 100 -rh '(DPU E|dequeueBuffer failed|present failed|xdm.*Failed to commit ret)' $1)
  if [[ -n "$found" ]] ; then
      echo
      echo
      echo "JIRA: $(echo $1 | cut -d '/' -f 1)"
      echo
      echo "DPU E msg in $1"
      echo "$found"
  fi
}

function find_sensor_hang_risk() {
  local found=$(egrep -m 512 -rh '(SensorHal: sendRequest:[0-9]*, sem wait timeout|Screen on took|Going to sleep|Waking up from|Blocking screen|unblocked screen|intercept_power|dvm_lock_sample:.*system_server.*Sensor)' $1)
  local anrMsgFound=$(egrep -rh -A 10 -B 10 'SensorEventConnection::enableDisable' $1)
  if [ -n "$found" -o -n "$anrMsgFound" ] ; then
    echo
    jira_id="$(echo $1 | sed -e 's?^./??g' | cut -d '/' -f 1)"
    
    if [[ "$last_jira_id" != "$jira_id" ]] ; then
      echo "JIRA: $jira_id"
      last_jira_id=$jira_id
    fi
    
    echo
    echo "$1"
    echo
    echo "$found"
    echo "$anrMsgFound"
  fi
}

function find_reboot_risk() {
  echo "=========="
  echo " Reoot risk"
  echo "=========="
  egrep -r -A 25 -B 5 '(Cmdline: system_server|Cmdline: /system/bin/surfaceflinger|Cmdline: /vendor/bin/hw/android.hardware.graphics.composer3-service.xring|Cmdline: /system/bin/netd)' extract/bugreport/FS/data/tombstones/*
  egrep -rh -A 6 'reason.history' extract/bugreport/bugreport*.txt
  local system_server_je=$(egrep -rh -A 25 -B 5 'FATAL EXCEPTION IN SYSTEM PROCESS' extract/bugreport/bugreport*.txt)
  if [[ -n "$system_server_je" ]] ; then
    echo "=============="
    echo "Found Java Crash"
    echo "=============="
    echo "$system_server_je"
  fi
}

function find_deep_sleep_records() {
  echo "==============="
  echo " Deep sleep in LAST_KMSG"
  echo "==============="

  local last_kmsg="$(grep -rh -B 150 'was the duration of .LAST KMSG.' extract/bugreport/bugreport*.txt)"
  # echo "$last_kmsg"
  echo "$last_kmsg" | egrep "(PM: suspend entry|Freezing user space| was the duration of .LAST KMSG.)"
}

function try_parse_issue_241225() {
  local jira_id log_url

  jira_id="$1"
  log_url="$2"

  if [[ -z "$jira_id" ]] ; then
    echo "Invalid jira id."
    parser_help
    return
  fi

  if [ -z "$log_url" -a ! -f "$jira_id/output.zip" ] ; then
    echo "Invalid log url" 
    parser_help
    return
  fi

  local report_result="$OTOP/${jira_id}_report.txt"
  echo > $report_result

  if [[ -n "$log_url" ]] ; then
    download_feedback_log_and_extract "$jira_id" "$log_url"
  fi
  cd "$OTOP"
  cd "$jira_id"

  ls extract/bugreport/FS/data/miuilog/stability/scout/watchdog/pre_watchdog_pid* | xargs -I "{}" echo parse_rhythmic_hang "{}" > run_find_rhythmic_hang.sh
  . run_find_rhythmic_hang.sh >> "$report_result"

  ## parse_rhythmic_hang > "$report_result"

  echo "========================" >> "$report_result"
  echo " DPU E or dequeueBuffer " >> "$report_result"
  echo "========================" >> "$report_result"
  ls extract/bugreport/bugreport*.txt | xargs -I "{}" echo find_dpue_msg "{}" ">>$report_result" > run_dpue_msg.sh
  find -name 'bugreport*.txt' -o -name 'logd' | xargs -I "{}" echo find_dpue_msg "{}" ">>$report_result" >> run_dpue_msg.sh

  . run_dpue_msg.sh

  echo "========================" >> "$report_result"
  echo " Sensor hang risk "       >> "$report_result"
  echo "========================" >> "$report_result"

  echo "system ANRs:"  >> "$report_result"
  ls extract/bugreport/FS/data/miuilog/stability/scout/app/*system_server*_ANR/*info* | while read -r file ; do
    echo "$file" >> "$report_result"
    cat "$file" >> "$report_result"
  done

  find -name 'bugreport*.txt' -o -name 'logd' -o -name 'system_server*trace' -o -wholename '*extract/bugreport/FS/data/anr/anr_*' | xargs -I "{}" echo find_sensor_hang_risk "{}" > run_find_sensor_hang_risk.sh
  . run_find_sensor_hang_risk.sh >> "$report_result"

  find_reboot_risk >> "$report_result"
  find_deep_sleep_records >> "$report_result"
}

try_parse_issue_241225 $@
