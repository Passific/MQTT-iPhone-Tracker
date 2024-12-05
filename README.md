[![Docker-build-n-push](https://github.com/Passific/MQTT-iPhone-Tracker/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/Passific/MQTT-iPhone-Tracker/actions/workflows/docker-publish.yml)
![GitHub release](https://img.shields.io/github/release/Passific/MQTT-iPhone-Tracker.svg)

# MQTT iPhone-Tracker for HA
Track iPhones, or any device using [Bonjour](https://en.wikipedia.org/wiki/Bonjour_(software)) protocol, on the local network for Home Assistant.

This tracking method also works if the device is in deep sleep.

Based on [iPhone Detect](https://github.com/mudape/iphonedetect), but not limited to HA's subnet.

## Supported Architectures
Uses docker manifest for multi-platform awareness.

List of supported architectures:
| Architecture | Available |
| :---: | :---: |
| 386 | :white_check_mark: |
| amd64 | :white_check_mark: |
| arm/v6 | :white_check_mark: |
| arm/v7 | :white_check_mark: |
| arm64/v8 | :white_check_mark: |

## Usage

Some configuration parameters can be passed either by environment variables or command parameters.

If both are specified, command parameters will be used.

### Environment variables
| Variables | Default | Description |
| --- | --- | --- |
| `MQTT_USER` | _Empty_ | MQTT's user |
| `MQTT_PASSWORD` | _Empty_ | MQTT's password |
| `MQTT_IP` | 127.0.0.1 | MQTT's server IP address |
| `MQTT_PORT` | 1883 | MQTT's server port |
| `MQTT_HA_TOPIC_PREFIX` | homeassistant | Home Assistant's topic prefix on MQTT |
| `MQTT_LWT_TOPIC` | `MQTT_HA_TOPIC_PREFIX`/status | Home Assistant's topic for MQTT Birth and Last Will and Testament (LWT) |
| `CONSIDER_HOME` | 60 | Seconds to wait till marking someone as not home after not being seen. |
| `SCAN_INTERVAL` | 12 | Scan time. Must be shorter than ARP cache persistence, or the device will be marked not_home. |

### Command parameters
| Command | Description | Example |
| --- | --- | --- |
| `-u`<br>`--mqtt-user` | MQTT's user | `-u mqttuser` |
| `-p`<br>`--mqtt-password` | MQTT's password | `-p mqttpwd` |
| `-i`<br>`--mqtt-ip` | MQTT's server IP address | `-i 127.0.0.1` |
| `-o`<br>`--mqtt-port` | MQTT's server port | `-o 1883` |
| `-c`<br>`--mqtt-ha-topic` | Home Assistant's topic prefix on MQTT | `-c homeassistant` |
| `-b`<br>`--mqtt-lwt-topic` | Home Assistant's topic for MQTT Birth and Last Will and Testament (LWT) | `-b homeassistant/status` |
| `-h`<br>`--home` | Seconds to wait till marking someone as not home after not being seen. | `-h 60` |
| `-s`<br>`--scan-interval` | Scan time. Must be shorter than ARP cache persistence, or the device will be marked not_home. | `-s 12` |
| `-t`<br>`--target` | Device name of the device followed by it's IP. __MUST be the last parameter!__ | `-t "192.168.1.104" "iPhone 1"` |

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
      - CONSIDER_HOME=120
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
