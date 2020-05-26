#!/bin/bash

NOW="$(date +%Y-%m-%dT%H:%M:%S)"

sshConfig="${HOME}/.ssh/config"
configD="${sshConfig}.d"
temp="${sshConfig}-temp"

if [ ! -d $configD ]; then
    mkdir $configD;
    if [ -f $sshConfig ]; then
        cp $sshConfig "$configD/01-base.config"
        echo <<END
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
+ Setting up your config file to be managed with ssh-configifyer.sh +
+ Your current configiuration has been moved to                     +
+    ~/.ssh/config.d/01-base.config                                 +
+ If you update ~/.ssh/config it will be overwritten the next time  +
+ you run ssh-configifyer.sh but you can it will be backed up with  +
+ a date stamp (e.g. ~/.ssh/config-2020-02-02T12:12:12)             +
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
END
    fi
fi

for config in "${configD}"/*.config; do
    echo >> $temp
    echo "# $config" >> $temp
    cat $config >> $temp
done

if [ ! -s "${temp}" ]; then
    echo "No configuration files set up in $configD!" 1>&2
    exit 1
fi

if [ "$(diff $sshConfig $temp > /dev/null 2>&1)" ]; then
    mv $sshConfig "${sshConfig}-${NOW}"
    mv $temp $sshConfig
    echo Updated ssh config
fi
