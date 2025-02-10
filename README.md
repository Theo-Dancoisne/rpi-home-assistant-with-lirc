# Send IR signals through Home Assistant

## Usage
Drop your .lircd.conf files in *`config_lirc/models`* and run the Docker compose `docker compose up -d`.  
See [config_lirc/models/README.me](config_lirc/models/README.me) for more details.
<br>

## Notes
<p>

**The purpose here is to send IR signals, not receive them**, but you can easly adapt the Dockerfile and make use of the
[LIRC Home Assistant integration](https://www.home-assistant.io/integrations/lirc).  
Here I use the Home Assistant docker image and install the LIRC package on it, you can expect
another version of this in the future as in the overall, it was a bad idea, details in the 
<a href="#problems">Problems encountered</a> section.  

**Default output port** for the Home Assistant image **is :8123**.  
Takes about 460 seconds to build the image, not including the image download.  
</p>

From [https://www.home-assistant.io/integrations/lirc](https://www.home-assistant.io/integrations/lirc):

> LIRC integration for Home Assistant allows you to RECEIVE signals from an infrared remote control and control actions 
> based on the buttons you press. You can use them to set scenes or trigger any other automation.
> 
> Sending IR commands is not supported in this integration (yet), but can be accomplished using the shell_command integration
> in conjunction with the irsend command.

<br>

___

<h2 id="problems">Problems encountered</h2>

- Home Assistant docker image is based on the Alpine Linux minimal one, so some important packages are not shipped with it
(ex: OpenRC, SysLog, ...).
- Current LIRC package for Alpine doesn't works, which is why I had to build it here.
- LIRC crashes at boot up, don't know why as there's no logs.
- Starting LIRC from dockerfile:ENTRYPOINT or dockerfile:CMD will either restart the container in an infinite loop, or won't let
the homeassistant service start.


## Docker/application main steps:
1. Retrieves the lastest tagged release to this day (2025-02-02 V0.10.2) of lirc from repo, merges its *`plugins`* directory with the one
on the main branch to fix some issues.
1. Imports a custom lirc configuration (which mostly sets **driver** to **default** and **device** to **/dev/lirc0**).
1. Downloads the strict minimum dependencies required to build and run lirc.
1. Starts the *`configure`* file with the appropriate parameters for the Alpine Linux architecture.
1. Builds.
1. Imports home-made OpenRC init service script for lirc (missing in the lirc Alpine package).
1. Imports your lircd remote controls conf files from *`config_lirc/models`*.
1. Starts lircd from the Home Assistant automation system thanks to this:  
    \> [config/automations.yaml#L1-L6](config/automations.yaml#L1-L6) 
    ```YAML
    - alias: "Start LIRC"
    trigger:
        - platform: homeassistant
        event: start
    action:
        - service: shell_command.restart_lircd
    ```

    \> [config/configuration.yaml#L15-L16](config/configuration.yaml#L15-L16)  
    ```YAML
    shell_command:
        restart_lircd: rc-service lircd restart
    ```
