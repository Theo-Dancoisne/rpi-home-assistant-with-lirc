FROM ghcr.io/home-assistant/home-assistant:stable
# Image based on Alpine

RUN apk update

### start LIRC build ###

# Tools I need, git can be removed at the end
RUN apk add openrc --no-cache && \
    mkdir -p /run/openrc/exclusive && \
    touch /run/openrc/softlevel && \
    apk add git

# Lastest version of LIRC doesn't works on Alpine because of some plugins, so I took them from the master branch where patches have been made
RUN cd /root && \
    wget https://sourceforge.net/projects/lirc/files/LIRC/0.10.2/lirc-0.10.2.tar.gz && \
    tar -xvf lirc-0.10.2.tar.gz && \
    git clone https://git.code.sf.net/p/lirc/git lirc-git && \
    cp lirc-git/plugins/* lirc-0.10.2/plugins/

# Custom configuration with driver=default and device=/dev/lirc0
COPY ./config_lirc/lirc_options.conf /root/lirc-0.10.2/lirc_options.conf

# LIRC dependencies
# On Alpine: there is no python3-yaml so use py3-yaml ; needs xsltproc but only find it in libxslt
RUN apk add build-base && \
    apk add pkgconfig && \
    apk add libxslt && \
    apk add python3 && \
    apk add py3-yaml

# Configure the LIRC Makefile according to Alpine's architecture
RUN cd /root/lirc-0.10.2 && \
    CFLAGS="-DHAVE_LINUX_HIDDEV_FLAG_UREF" ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --with-driver=all --with-x=no

# LIRC Makefile dependencies
RUN apk add bash && \
    apk add linux-headers && \
    apk add --repository https://dl-cdn.alpinelinux.org/alpine/v3.20/main/ "automake<1.17" && \
    apk add autoconf

# Build LIRC
RUN cd /root/lirc-0.10.2 && \
    make && \
    make install

### end LIRC build ###


# Add a simple OpenRC service script
COPY ./config_lirc/lircd /etc/init.d/lircd
RUN chmod 755 /etc/init.d/lircd


# Add the devinput.lircd.conf you usually have when installing LIRC on other Linux distrib
RUN /root/lirc-0.10.2/tools/lirc-make-devinput > /etc/lirc/lircd.conf.d/devinput.lircd.conf
# Copy our lircd remote controls conf files
# You can find some in the remotes database https://lirc-remotes.sourceforge.net/remotes-table.html or make your own thanks to irrecord or mode2
COPY ./config_lirc/models/*.lircd.conf /etc/lirc/lircd.conf.d/



#  Part of the LIRC Home Assistant integration steps https://lirc.org/html/configure.html#lircrc_format
#  not used, not tested!
# RUN mkdir /etc/lirc/lircrc
# COPY ./config_lirc/.lircrc  /etc/lirc/lircrc/.lircrc
