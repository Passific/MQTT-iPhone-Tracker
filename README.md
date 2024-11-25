[![Docker-build-n-push](https://github.com/Passific/MQTT-iPhone-Tracker/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/Passific/MQTT-iPhone-Tracker/actions/workflows/docker-publish.yml)

# MQTT iPhone-Tracker for HA
Track iPhone, or any Apple device using [Bonjour](https://en.wikipedia.org/wiki/Bonjour_(software)) protocol, on the local network for Home Assistant.
This tracking method also works if the device is in deep sleep.


## Usage

### Environment variables
| Variables | Default | Description |
| --- | --- | --- |
| `MQTT_USER` | Empty | MQTT username |
| `MQTT_PASSWORD` | Empty | MQTT password |
| `CONSIDER_HOME` | 10 | Seconds to wait till marking someone as not home after not being seen. |

### Command parameters
| Command | Description | Example |
| --- | --- | --- |
| `-t` | Device to be tracked | `-t "192.168.1.104" "iPhone 1"` |

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
