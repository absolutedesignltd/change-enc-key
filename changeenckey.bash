#!/bin/bash
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

echo "Re-encrypting content"
FIND="config:store:set"
REPLACEMENT="config:store:set --encrypt"
for d in "${DECRYPTS[@]}"; do
        CMD="$(echo "$d" | sed "s/$FIND/$REPLACEMENT/")"
        php n98-magerun2.phar $CMD || true
done
