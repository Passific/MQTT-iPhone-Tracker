#!/bin/sh
# This script track iPhones (or Apple devices) on the local network,
# and report the status to MQTT for Home assistant to use

CONSIDER_HOME=${CONSIDER_HOME:-10}
MQTT_IP=${MQTT_IP:-127.0.0.1}
MQTT_PORT=${MQTT_PORT:-1883}
MQTT_HA_TOPIC_PREFIX=${MQTT_HA_TOPIC_PREFIX:-homeassistant}
MQTT_LWT_TOPIC=${MQTT_LWT_TOPIC:-${MQTT_HA_TOPIC_PREFIX}/status}

send_discovery()
{
  NAME="$1"
  PRETTYNAME="$2"
  # DEBUG
  echo "$(date): Sending discovery message"
  mosquitto_pub -h "$MQTT_IP" -p "$MQTT_PORT" -u "$MQTT_USER" -P "$MQTT_PASSWORD" \
   -t "${MQTT_HA_TOPIC_PREFIX}/device_tracker/${NAME}/config" \
   -m '{"state_topic": "${MQTT_HA_TOPIC_PREFIX}/device_tracker/'"${NAME}"'/state", "name": "'"${PRETTYNAME}"'", "payload_home": "home", "payload_not_home": "not_home", "source_type": "router"}'
}

MQTT_LWT_config()
{
  NAME="$1"
  PRETTYNAME="$2"
  # Send config on startup
  send_discovery "$NAME" "$PRETTYNAME"

  # Then re-send on HA status set to "online"
  while true; do
    mosquitto_sub -h "$MQTT_IP" -p "$MQTT_PORT" -u "$MQTT_USER" -P "$MQTT_PASSWORD" \
     -t "$MQTT_LWT_TOPIC" | while read -r payload; do
      # DEBUG
      echo "$(date): ${MQTT_LWT_TOPIC} sent ${payload}"
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
    mosquitto_pub -h "$MQTT_IP" -p "$MQTT_PORT" -u "$MQTT_USER" -P "$MQTT_PASSWORD" \
     -t "${MQTT_HA_TOPIC_PREFIX}/device_tracker/${NAME}/state" \
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
    -i|--mqtt-ip)
      MQTT_IP="$2"
      shift # past argument
      shift
      ;;
    -o|--mqtt-port)
      MQTT_PORT="$2"
      shift # past argument
      shift
      ;;
    -c|--mqtt-ha-topic)
      MQTT_HA_TOPIC_PREFIX="$2"
      shift # past argument
      shift
      ;;
    -b|--mqtt-lwt-topic)
      MQTT_LWT_TOPIC="$2"
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
