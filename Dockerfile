# https://www.home-assistant.io/integrations/lirc
# LIRC integration for Home Assistant allows you to RECEIVE signals from an infrared remote control and control actions based on the buttons
# you press. You can use them to set scenes or trigger any other automation.

# Sending IR commands is not supported in this integration (yet), but can be accomplished using the shell_command integration in conjunction
# with the irsend command.

# Curent LIRC package for Alpine doesn't works, that's why I built it here

FROM ghcr.io/home-assistant/home-assistant:stable
# Image based on Alpine v3.21

RUN apk update

### start LIRC build ###

# Tools I need that can be removed at the end
RUN apk add openrc  --no-cache && \
    mkdir -p /run/openrc/exclusive && \
    touch /run/openrc/softlevel && \
    apk add git

# Last LIRC release don't work on Alpine because of some plugins, so I took them from the master branch where patches have been made
RUN cd /root && \
    wget https://sourceforge.net/projects/lirc/files/LIRC/0.10.2/lirc-0.10.2.tar.gz && \
    tar -xvf lirc-0.10.2.tar.gz && \
    git clone https://git.code.sf.net/p/lirc/git lirc-git && \
    cp lirc-git/plugins/* lirc-0.10.2/plugins/

# LIRC dependencies
# On Alpine: there is no python3-yaml so use py3-yaml ; needs xsltproc but only find it in libxslt
RUN apk add build-base && \
    apk add pkgconfig && \
    apk add libxslt && \
    apk add python3 && \
    apk add py3-yaml

# Configure LIRC Makefile according to Alpine architecture
RUN cd /root/lirc-0.10.2 && \
    CFLAGS="-DHAVE_LINUX_HIDDEV_FLAG_UREF" ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --with-driver=all --with-x=no

# LIRC Makefile dependencies
RUN apk add bash && \
    apk add linux-headers && \
    apk add --repository https://dl-cdn.alpinelinux.org/alpine/v3.20/main/ "automake<1.17" && \
    apk add autoconf

RUN cd /root/lirc-0.10.2 && \
    make && \
    make install

### end LIRC build ###


### start LIRC post installtion configuration ###

# Custom configuration with driver=default and device=/dev/lirc0
COPY ./config_lirc/lirc_options.conf /etc/lirc/lirc_options.conf
# Simple OpenRC service
COPY ./config_lirc/lircd /etc/init.d/lircd
RUN chmod 755 /etc/init.d/lircd && \
    rc-update add lircd default

### end LIRC post installtion configuration ###


# Copy my homemade lirc models
COPY ./config_lirc/models/lg_stereo.lircd.conf /etc/lirc/lircd.conf.d/lg_stereo.lircd.conf
COPY ./config_lirc/models/hdmi_switch.lircd.conf /etc/lirc/lircd.conf.d/hdmi_switch.lircd.conf

# Restart lirc to take into account new models
RUN rc-service lircd restart


# Not tested and not used since it's for receiving IR signals in Home Assistant
# Copy lircrc file that will be used by home-assistant as interface of my lirc models
# RUN mkdir /etc/lirc/lircrc
# COPY ./config_lirc/.lircrc  /etc/lirc/lircrc/.lircrc


