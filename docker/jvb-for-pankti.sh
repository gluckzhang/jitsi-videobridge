#!/bin/bash

JAVA_SYS_PROPS="-Dnet.java.sip.communicator.SC_HOME_DIR_LOCATION=/ -Dnet.java.sip.communicator.SC_HOME_DIR_NAME=config -Djava.util.logging.config.file=/config/logging.properties"

if [[ ! -z "$DOCKER_HOST_ADDRESS" ]]; then
    LOCAL_ADDRESS=$(hostname -I | cut -d " " -f1)
    JAVA_SYS_PROPS="$JAVA_SYS_PROPS -Dorg.ice4j.ice.harvest.NAT_HARVESTER_LOCAL_ADDRESS=$LOCAL_ADDRESS -Dorg.ice4j.ice.harvest.NAT_HARVESTER_PUBLIC_ADDRESS=$DOCKER_HOST_ADDRESS"
fi

DEFAULT_API_OPTS="none"
API_OPTS=${JVB_ENABLE_APIS:=$DEFAULT_API_OPTS}

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

mainClass="org.jitsi.videobridge.Main"
cp=$SCRIPT_DIR/jitsi-videobridge.jar:$SCRIPT_DIR/lib/*
logging_config="$SCRIPT_DIR/lib/logging.properties"
videobridge_rc="$SCRIPT_DIR/lib/videobridge.rc"

# if there is a logging config file in lib folder use it (running from source)
if [ -f $logging_config ]; then
    LOGGING_CONFIG_PARAM="-Djava.util.logging.config.file=$logging_config"
fi

if [ -f $videobridge_rc  ]; then
        source $videobridge_rc
fi

if [ -z "$VIDEOBRIDGE_MAX_MEMORY" ]; then VIDEOBRIDGE_MAX_MEMORY=3072m; fi
if [ -z "$VIDEOBRIDGE_GC_TYPE" ]; then VIDEOBRIDGE_GC_TYPE=ConcMarkSweepGC; fi

JAVA_SYS_PROPS=$JAVA_SYS_PROPS java -javaagent:/home/jitsi-videobridge/glowroot/glowroot.jar -Xmx$VIDEOBRIDGE_MAX_MEMORY $VIDEOBRIDGE_DEBUG_OPTIONS -XX:+Use$VIDEOBRIDGE_GC_TYPE -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/tmp -Djdk.tls.ephemeralDHKeySize=2048 $LOGGING_CONFIG_PARAM $JAVA_SYS_PROPS -cp $cp $mainClass --apis=$API_OPTS