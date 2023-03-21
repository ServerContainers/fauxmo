# fauxmo - (ghcr.io/servercontainers/fauxmo) [x86 + arm]

fauxmo - fauxmo `pip` releases on `alpine`

This is a container running the `pip` release of https://github.com/n8henrie/fauxmo.
It also has a cloned repo of https://github.com/n8henrie/fauxmo-plugins beneath `/fauxmo-plugins` included.

you can take a look at this `docker-compose.yml` to see it in action.

__IMPORTANT: Dockers `network_mode: host` should be used to make it visible inside your network__

_TODO: currently there are only 2 Plugins configurable using Environment Variables - if you like to seem more, take a look at my `scripts/entrypoint.sh` file and implement others - I'm happy to merge pull requests_

## Build & Variants

You can specify `DOCKER_REGISTRY` environment variable (for example `my.registry.tld`)
and use the build script to build the main container and it's variants for _x86_64, arm64 and arm_

You'll find all images tagged like `a3.15.0-f0.6.0` which means `a<alpine version>-f<fauxmo version>`.
This way you can pin your installation/configuration to a certian version. or easily roll back if you experience any problems
(don't forget to open a issue in that case ;D).

To build a `latest` tag run `./build.sh release`.

## Changelogs

* 2023-03-20
    * github action to build container
    * implemented ghcr.io as new registry
* 2023-03-19
    * switched from docker hub to a build-yourself container
    * new multistage build
* 2021-07-29
    * initial release
    * raw `/etc/fauxmo/config.json` support
    * `CommandLinePlugin` support
    * `HomeAssistantPlugin` support
    * multiarch build

## Usage (Environment variables and defaults)

You have two options using this container:

1. mount/pass a valid `/etc/fauxmo/config.json` file inside the container
2. use environment variables to configure your plugins/devices

### config.json `/etc/fauxmo/config.json`

just use a existing fauxmo config.json which fits your needs and mount/pass it into the container to the location: `/etc/fauxmo/config.json`

### environment variables

you can take a look at my `docker-compose.yml` to see it in action.
multiple plugins can be used together.

__Note: you need to take care of `,` after multiple `DEVICE` envs!__

#### CommandLinePlugin

_this one just needs one or more devices, no general config needed_

* __FAUXMO_PLUGIN_COMMANDLINE_DEVICE_1mydevicename__
    * adds a new DEVICE of `CommandLinePlugin`
    * needs to be vaild json and exept the last one it must end with a `,`!
    * I recommend using a sort number as start of `mydevicename`
    * examples
        * `      FAUXMO_PLUGIN_COMMANDLINE_DEVICE_1_stuff_to_file: '                { "name": "output stuff to a file", "port": 49915, "on_cmd": "touch testfile.txt", "off_cmd": "rm testfile.txt", "state_cmd": "ls testfile.txt" }'`

#### HomeAssistantPlugin

* __FAUXMO_PLUGIN_HOMEASSISTANT_CONFIG__
    * general config of the `HomeAssistantPlugin`
    * needs to be vaild json and end with a `,`!
    * use long-lived access token for the `ha_token` parameter, which you can generate in the web interface at the `/profile` homeassistant endpoint.
    * examples
        * `'"ha_host": "192.168.0.50", "ha_port": 8123, "ha_protocol": "http", "ha_token": "abc123",'`

* __FAUXMO_PLUGIN_HOMEASSISTANT_DEVICE_1mydevicename__
    * adds a new DEVICE of `HomeAssistantPlugin`
    * needs to be vaild json and end with a `,`!
    * I recommend using a sort number as start of `mydevicename`
    * examples
        * `      FAUXMO_PLUGIN_HOMEASSISTANT_DEVICE_1_my_fake_switch: '                { "name": "example Home Assistant device 1", "port": 12345, "entity_id": "switch.my_fake_switch" },'`
        * `      FAUXMO_PLUGIN_HOMEASSISTANT_DEVICE_2_my_fake_cover: '                { "name": "example Home Assistant device 2", "port": 12346, "entity_id": "switch.my_fake_cover" }'`

# Links

* https://github.com/n8henrie/fauxmo
* https://github.com/n8henrie/fauxmo-plugins
