#!/bin/bash

chown -R www-data:www-data $RELEASE/public
mkdir -p $SHARED/uploads
chown -R www-data:www-data $SHARED/uploads
ln -s wp/index.php $RELEASE/public/index.php
