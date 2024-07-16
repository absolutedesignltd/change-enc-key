# Bash script to change the Magento 2 encryption key, and re-encrypt and re-save sys config values with the new key

Should work with differing website/store view values

Generates random new crypt key and replaces the existing one

NO WARRANTY! Always back up database first.

## Requirements
Requires N98-magerun2 in project root

Requires pwgen installed on server

Requires mapfile installed on server


## Usage
Put the script in Magento project root

Run it


Be sure to note down the prior encryption key in case things go wrong

## Gotchas
After the key is changed, if there's a problem while re-saving the encrypted data, you're probably gonna need to restore from backup. Only the sys config table so not too bad

The script disables caching before making changes which should prevent problems, but in testing it was finicky and you may see errors saying bin/magento is unavailable

Forcibly clearing the caches (i.e. restart Redis) and restarting services seems to sort this. If I figure out how to make this reliable, I'll alter it.
