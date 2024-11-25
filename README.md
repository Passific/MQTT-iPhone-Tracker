[![Docker-build-n-push](https://github.com/Passific/MQTT-iPhone-Tracker/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/Passific/MQTT-iPhone-Tracker/actions/workflows/docker-publish.yml)

# MQTT iPhone-Tracker for HA
Track iPhones, or any device using [Bonjour](https://en.wikipedia.org/wiki/Bonjour_(software)) protocol, on the local network for Home Assistant.

This tracking method also works if the device is in deep sleep.


## Usage

Some configuration parameters can be passed either by environment variables or command parameters.

If both are specified, command parameters will be used.

### Environment variables
| Variables | Default | Description |
| --- | --- | --- |
| `MQTT_USER` | Empty | MQTT's user |
| `MQTT_PASSWORD` | Empty | MQTT's password |
| `MQTT_IP` | 127.0.0.1 | MQTT's server IP address |
| `MQTT_PORT` | 1883 | MQTT's server port |
| `MQTT_HA_TOPIC_PREFIX` | homeassistant | Home Assistant's topic prefix on MQTT |
| `MQTT_LWT_TOPIC` | ${MQTT_HA_TOPIC_PREFIX}/status | Home Assistant's topic for MQTT Birth and Last Will and Testament (LWT) |
| `CONSIDER_HOME` | 10 | Seconds to wait till marking someone as not home after not being seen. |

### Command parameters
| Command | Description | Example |
| --- | --- | --- |
| `-t`<br>`--target` | Device name of the device followed by it's IP | `-t "192.168.1.104" "iPhone 1"` |
| `-u`<br>`--mqtt-user` | MQTT's user | `-q mqtt` |
| `-p`<br>`--mqtt-password` | MQTT's password | `-p mqtt` |
| `-i`<br>`--mqtt-ip` | MQTT's server IP address | `-p 127.0.0.1` |
| `-o`<br>`--mqtt-port` | MQTT's server port | `-o 1883` |
| `-c`<br>`--mqtt-ha-topic` | Home Assistant's topic prefix on MQTT | `-c homeassistant` |
| `-b`<br>`--mqtt-lwt-topic` | Home Assistant's topic for MQTT Birth and Last Will and Testament (LWT) | `-b homeassistant/status` |
| `-h`<br>`--home` | Seconds to wait till marking someone as not home after not being seen. | `-h 10` |

### Docker compose example:
```yaml
mqtt-iphone-tracker:
    container_name: mqtt-iphone-tracker
    image: ghcr.io/passific/mqtt-iphone-tracker:latest
    restart: unless-stopped
    depends_on:
      - mosquitto
    network_mode: host # Needed for mDNS
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
    environment:
      - MQTT_USER=mqttuser
      - MQTT_PASSWORD=mqttpwd
      - CONSIDER_HOME=10
    command: ["-t", "192.168.1.104", "iPhone 1", "-t", "192.168.1.105", "iPhone 2"]

################################################
# Example of configuration for eclipse-mosquitto
mosquitto:
    container_name: mosquitto
    image: eclipse-mosquitto:latest
    restart: unless-stopped
    ports:
      - "1883:1883" #default mqtt port
      - "9001:9001" #default mqtt port for websockets
    volumes:
      - ./config:/mosquitto/config:rw
      - ./data:/mosquitto/data:rw
      - ./log:/mosquitto/log:rw
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
# volumes for mapping eclipse-mosquitto's data,config and log
volumes:
  config:
  data:
  log:
```
