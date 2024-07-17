#!/bin/bash
echo "Checking prerequisites"

if ! command -v pwgen &> /dev/null
then
    echo -n "Please install pwgen or enter a key of 32 chars (numbers and letters):"
    read NEWKEY
    if [ ${#NEWKEY} != 32 ];then
        echo "The key must be 32 chars"
	exit 1
    fi
    if ! [[ "$NEWKEY" =~ ^[-0-9a-zA-Z]*$ ]];then
	    echo "the key must be numbers and letters"
	    exit 1
    fi

fi

if ! [ -e n98-magerun2.phar ]
then
    echo "N98 missing"
    exit 1
fi
rm keyNew.txt keyOld.txt
read -p "!!! Have you disabled crons (y/n)? " answer
case ${answer:0:1} in
    y|Y )
        echo "OK, continuing"
    ;;
    * )
        exit 1
    ;;
esac

echo "Enabling maintenance mode"
php n98-magerun2.phar maint:enable

echo "Backing up core config data table"
php n98-magerun2.phar db:dump --include core_config_data -c gzip coreconf_cryptkey_backup.sql

if ! [ -e coreconf_cryptkey_backup.sql.gz ]
then
    echo "DB backup missing, exiting"
    exit 1
fi

echo "Making a note of the current crypt key in file cryptbak.txt"
php n98-magerun2.phar config:env:show crypt.key >> cryptbak.txt

if ! [ -e cryptbak.txt ]
then
    echo "Cryptkey backup missing, exiting"
    exit 1
fi

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
                echo "${z}" >> keyOld.txt
        done
done

echo "Generated ${#DECRYPTS[@]} re-encrypt commands for n98"

read -p "Last chance to pray to god(s)/science - continue (y/n)? " answer
case ${answer:0:1} in
    y|Y )
        echo "OK, continuing"
    ;;
    * )
        exit 1
    ;;
esac

echo "Disabling config cache to prevent conflict when key is replaced"
php n98-magerun2.phar cache:disable config

if command -v pwgen &> /dev/null
then
    echo "Generating and setting new crypt key"
    NEWKEY=$(pwgen 32 1)
    echo $NEWKEY
fi

php n98-magerun2.phar config:env:set crypt.key ${NEWKEY}

echo "Re-enabling config cache"
php n98-magerun2.phar cache:enable config

echo "Re-encrypting content"
FIND="config:store:set"
REPLACEMENT="config:store:set --encrypt"
for d in "${DECRYPTS[@]}"; do
        CMD="$(echo "$d" | sed "s/$FIND/$REPLACEMENT/")"
        eval "php n98-magerun2.phar ${CMD}"
done

PATHS=$(php n98-magerun2.phar db:query "select distinct(path) from core_config_data where value like '0:3:%';")
mapfile -t PATHS <<< "${PATHS}"
DECRYPTS=()
for i in "${PATHS[@]}"; do
        if [[ "$i" == "path" ]]; then
                continue
        fi
        DECRYPTVAL=$(php n98-magerun2.phar config:store:get --decrypt --magerun-script "$i")
        #Split by newline again in case of multistore
        mapfile -t DECRYPTVAL <<< "${DECRYPTVAL}"
        for z in "${DECRYPTVAL[@]}"; do
                DECRYPTS+=("${z}")
                echo "${z}" >> keyNew.txt
        done
done

if cmp -s keyNew.txt keyOld.txt; then
    printf 'Keys are the same /n'
else
    printf 'the keys doee not match please check keyNew.txt keyOld.txt and restore the old DB /n'
fi

echo "Running setup upgrade"
php -d memory_limit=1G bin/magento setup:upgrade

echo "Please re-enable crons, deploy static, disable maintenance mode, and test site"
