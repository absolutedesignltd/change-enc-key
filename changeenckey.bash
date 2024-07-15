#!/bin/bash
echo "Checking prerequisites"

if ! command -v pwgen &> /dev/null
then
    echo "Please install pwgen"
    exit 1
fi

if ! [ -e n98-magerun2.phar ]
then
    echo "N98 missing"
    exit 1
fi

read -p "!!! Have you backed up the database (y/n)? " answer
case ${answer:0:1} in
    y|Y )
        echo "OK, continuing"
    ;;
    * )
        exit 1
    ;;
esac

echo "!!! Make a note of the current crypt key:"
php n98-magerun2.phar config:env:show crypt.key

echo "Finding paths which are encrypted and need updating"
PATHS=$(php n98-magerun2.phar db:query "select distinct(path) from core_config_data where value like '0:3:%';")
echo "${PATHS}"
mapfile -t PATHS <<< "${PATHS}"
echo "Number of paths: ${#PATHS[@]} (actual is one less as this contains mysql column headers)"
DECRYPTS=()
echo "Generating decrypted content"
for i in "${PATHS[@]}"; do
        if [[ "$i" == "path" ]]; then
                continue
        fi
        DECRYPTVAL=$(php n98-magerun2.phar config:store:get --decrypt --magerun-script "$i")
        #Split by newline again in case of multistore
        mapfile -t DECRYPTVAL <<< "${DECRYPTVAL}"
        for z in "${DECRYPTVAL[@]}"; do
                DECRYPTS+=("${z}")
        done
done
echo "Generated ${#DECRYPTS[@]} re-encrypt commands for n98"

echo "Disabling config cache to prevent conflict when key is replaced"
php n98-magerun2.phar cache:disable config

echo "Generating and setting new crypt key"
NEWKEY=$(pwgen 32 1)
echo $NEWKEY
php n98-magerun2.phar config:env:set crypt.key ${NEWKEY}

echo "Re-enabling config cache"
php n98-magerun2.phar cache:enable config

echo "Re-encrypting content"
FIND="config:store:set"
REPLACEMENT="config:store:set --encrypt"
for d in "${DECRYPTS[@]}"; do
        CMD="$(echo "$d" | sed "s/$FIND/$REPLACEMENT/")"
        #For some reason the output command has single quotes which go into the db so remove those
        CMD=${CMD//\'/}
        php n98-magerun2.phar $CMD || true
done
