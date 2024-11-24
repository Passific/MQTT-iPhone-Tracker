#!/bin/sh
# This script track iPhones (or Apple devices) on the local network,
# and report the status to MQTT for Home assistant to use

#TODO: configure LWT topic and expected message
#TODO: configure MQTT server IP
#TODO: configure MQTT server port

CONSIDER_HOME=${CONSIDER_HOME:-10}

send_discovery()
{
  NAME="$1"
  PRETTYNAME="$2"
  mosquitto_pub -h 127.0.0.1 -p 1883 -u "$MQTT_USER" -P "$MQTT_PASSWORD" \
   -t "homeassistant/device_tracker/${NAME}/config" \
   -m '{"state_topic": "homeassistant/device_tracker/'"${NAME}"'/state", "name": "'"${PRETTYNAME}"'", "payload_home": "home", "payload_not_home": "not_home", "source_type": "router"}'
}

MQTT_LWT_config()
{
  NAME="$1"
  PRETTYNAME="$2"
  # Send config on startup
  send_discovery "$NAME" "$PRETTYNAME"

  # Then re-send on HA status set to "online"
  while true; do
    mosquitto_sub -h 127.0.0.1 -p 1883 -u "$MQTT_USER" -P "$MQTT_PASSWORD" \
     -t "homeassistant/status" | while read -r payload; do
      # DEBUG
      echo "$(date): homeassistant/status sent $payload"
      if [ "online" = "$payload" ]; then
        send_discovery "$NAME" "$PRETTYNAME"
      fi
    done
    sleep 1
  done
}

track_iphone()
{
  IP="$1"
  PRETTYNAME="$2"
  NAME="$(echo "$PRETTYNAME" | tr -d ' ' | tr '[:upper:]' '[:lower:]')"

  echo "Tracking '$PRETTYNAME' iPhone ($IP)"

  guest_status='not_home'
  guest_lastseen=0

  # Send config message on Birth and Last Will and Testaments in the background
  MQTT_LWT_config "$NAME" "$PRETTYNAME" &

  while true; do sleep 12
    # IP
    hping3 -2 -c 3 -p 5353 "$IP" -q >/dev/null 2>&1
    if ip neigh show | grep REACHABLE | grep -q "$IP "; then
        guest_status='home'
        guest_lastseen=0
    else
        if [ $guest_lastseen -ge "$CONSIDER_HOME" ]; then
            guest_status='not_home'
        else
            guest_lastseen=$((guest_lastseen+1))
        fi
    fi
    mosquitto_pub -h 127.0.0.1 -p 1883 -u "$MQTT_USER" -P "$MQTT_PASSWORD" \
     -t "homeassistant/device_tracker/${NAME}/state" \
     -m "$guest_status"
  done
  exit 1
}

while [ $# -gt 1 ]; do
  case $1 in
    -t|--target)
      IP="$2"
      NAME="$3"
      track_iphone "$IP" "$NAME" &
      shift # past argument
      shift
      shift
      ;;
    -u|--mqtt-user)
      MQTT_USER="$2"
      shift # past argument
      shift
      ;;
    -p|--mqtt-password)
      MQTT_PASSWORD="$2"
      shift # past argument
      shift
      ;;
    -h|--home)
      CONSIDER_HOME="$2"
      shift # past argument
      shift
      ;;
    -*)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

wait

exit 1
