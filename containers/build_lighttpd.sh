#!/bin/bash -u 

sudo pkill lighttpd
sudo systemctl stop lighttpd

# User variables
ENV="lighttpd_container"
DIR_TO_IMPORT="to_import"
SHELL_TO_IMPORT=(/bin/bash /usr/bin/bash)
COMMANDS_TO_IMPORT=( id ls whoami hostname curl lighttpd )

import_cmd_and_libs() {
    libs=$(for cmd in $(which "$@"); do
        ! [ -x "$cmd" ] && echo "$cmd is not an executable file" >&2 && exit 1
        
        # Import the command
        mkdir -p "$ENV/$(dirname "$cmd")"
        cp "$cmd" "$ENV/$cmd"

        # Display libs used by command
        ldd -v "$cmd" \
            | grep '=>' \
            | sed 's/^.*=> \(.*\)$/\1/' \
            | sed 's/ ( *0x[0-9a-f][0-9a-f]*)$//' \
            | sort -u
    done | sort -u)

    # Import the shared libs
    for lib in $libs; do
        mkdir -p "$ENV/$(dirname "$lib")"
        cp "$lib" "$ENV/$lib"
    done
}


mkdir -p $ENV
(
    cd $ENV && mkdir -p \
        etc/default \
        proc \
        boot \
        sys \
        dev \
        run \
        var/tmp /var/log \
        root \
        lib lib64 \
        usr/bin usr/sbin usr/lib usr/lib64 \
        bin sbin \
        tmp \
        srv
)
chmod 1777 $ENV/tmp

## Import des fichiers de configuration de base
sed 's/systemd//g' /etc/nsswitch.conf > $ENV/etc/nsswitch.conf
grep -E "^root" /etc/passwd > $ENV/etc/passwd && sed -i 's|/usr/bin/zsh|/usr/bin/bash|g' $ENV/etc/passwd
grep -E "^root" /etc/group > $ENV/etc/group
grep -E "^root" /etc/shadow > $ENV/etc/shadow
grep -E "^$(which "${SHELL_TO_IMPORT[@]}")|#" /etc/shells > $ENV/etc/shells

## Import des binaires et de leur librairies
import_cmd_and_libs "${SHELL_TO_IMPORT[@]}" # required
import_cmd_and_libs "${COMMANDS_TO_IMPORT[@]}"
echo -e "🚀 Commands & Shared Libs successfully added!\n"


### SPÉCIFIQUE
mkdir -p $ENV/etc/lighttpd $ENV/var/www/html
cp $DIR_TO_IMPORT/lighttpd/lighttpd.conf $ENV/etc/lighttpd
cp $DIR_TO_IMPORT/lighttpd/index.html $ENV/var/www/html
mknod $ENV/dev/null c 1 3 2>/dev/null && chmod go+w $ENV/dev/null