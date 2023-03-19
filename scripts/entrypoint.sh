#!/bin/sh

cat <<EOF
################################################################################

Welcome to the servercontainers/fauxmo

################################################################################

# IMPORTANT!

In March 2023 - Docker informed me that they are going to remove my 
organizations `servercontainers` and `desktopcontainers` unless 
I'm upgrading to a pro plan.

I'm not going to do that. It's more of a professionally done hobby then a
professional job I'm earning money with.

In order to avoid bad actors taking over my org. names and publishing potenial
backdoored containers, I'd recommend to switch over clone my github repos and
build the containers yourself.

You'll find this container sourcecode here:

    https://github.com/ServerContainers/fauxmo

The container repos will be updated regularly.
EOF

INITALIZED="/etc/fauxmo/config.json"

if [ ! -f "$INITALIZED" ]; then
  echo ">> CONTAINER: starting initialisation"

  cat /container/config/config.json.part > /etc/fauxmo/config.json


  ##
  # fauxmo Commandline Config ENVs
  ##

  if env | grep '^FAUXMO_PLUGIN_COMMANDLINE_DEVICE_' >/dev/null 2>/dev/null; then
    echo '        "CommandLinePlugin": {' >> /etc/fauxmo/config.json
    PLUGIN_PATH=$(find / | grep 'plugins/commandlineplugin.py$')
    echo '            "path": "'"$PLUGIN_PATH"'",' >> /etc/fauxmo/config.json

    echo '            "DEVICES": [' >> /etc/fauxmo/config.json
  fi

  for I_CONF in "$(env | grep '^FAUXMO_PLUGIN_COMMANDLINE_DEVICE_')"
  do
    CONF_CONF_VALUE=$(echo "$I_CONF" | sed 's/^[^=]*=//g')
    echo "$CONF_CONF_VALUE" >> /etc/fauxmo/config.json
  done

  if env | grep '^FAUXMO_PLUGIN_COMMANDLINE_DEVICE_' >/dev/null 2>/dev/null; then
    echo '            ]' >> /etc/fauxmo/config.json
    echo '        }' >> /etc/fauxmo/config.json # Commandline End
  fi


  ##
  # fauxmo HomeAssistant Config ENVs
  ##
  if env | grep '^FAUXMO_PLUGIN_HOMEASSISTANT_CONFIG=' >/dev/null 2>/dev/null; then
    tail -n1 /etc/fauxmo/config.json | grep '^        }' > /dev/null 2> /dev/null && echo '        ,' >> /etc/fauxmo/config.json # add comma

    echo '        "HomeAssistantPlugin": {' >> /etc/fauxmo/config.json
    PLUGIN_PATH=$(find / | grep 'plugins/homeassistantplugin.py$')
    echo '            "path": "'"$PLUGIN_PATH"'",' >> /etc/fauxmo/config.json

    env | grep '^FAUXMO_PLUGIN_HOMEASSISTANT_CONFIG=' | sed 's/^[^=]*=//g' >> /etc/fauxmo/config.json

    echo '            "DEVICES": [' >> /etc/fauxmo/config.json
  fi

  for I_CONF in "$(env | grep '^FAUXMO_PLUGIN_HOMEASSISTANT_DEVICE_')"
  do
    CONF_CONF_VALUE=$(echo "$I_CONF" | sed 's/^[^=]*=//g')
    echo "$CONF_CONF_VALUE" >> /etc/fauxmo/config.json
  done

  if env | grep '^FAUXMO_PLUGIN_HOMEASSISTANT_CONFIG=' >/dev/null 2>/dev/null; then
    echo '            ]' >> /etc/fauxmo/config.json
    echo '        }' >> /etc/fauxmo/config.json # HomeAssistant End
  fi


  echo '    }' >> /etc/fauxmo/config.json
  echo '}' >> /etc/fauxmo/config.json
else
  echo ">> CONTAINER: already initialized - direct start of fauxmo"
fi

##
# CMD
##
echo ">> CMD: exec docker CMD"
echo "$@"
exec "$@"
