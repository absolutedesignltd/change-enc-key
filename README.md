# Bash script to change the Magento 2 encryption key, and re-encrypt and re-save sys config values with the new key

Should work with differing website/store view values

Generates random new crypt key and replaces the existing one

NO WARRANTY! Always back up database first.

The script backs up the core_config_table and makes a note of the previous, removed encryption key

## Requirements
Requires N98-magerun2 in project root -make sure it's the most recent release for your M2/php version

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

Remember to clear down afterwards i.e remove the script and ensure the backup content is located outside webroot (hopefully your webroot is the pub folder anyway, right?)

## Notes and exclusions

Doesn't handle encrypted data outside core_config_data, so be aware some things might break (oauth keys?). Credit card data definitely not included because that shouldn't be in your database for the vast majority of people (and if it is, you probably don't want this rough and ready bash script!)

Redeploying static is excluded from the script as it's likely to be fairly environment specific

This is deliberately one-and-done, we don't anticpate needing to do this multiple times. If for some reason you might, see: https://github.com/genecommerce/module-encryption-key-manager
