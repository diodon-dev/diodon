#!/bin/sh
# -*- Mode: sh; indent-tabs-mode: nil; tab-width: 2; coding: utf-8 -*-

if [ -z "$DESTDIR" ]; then
  datadir="$1"

  echo "Updating icon cache..."
  gtk-update-icon-cache -f -t "$datadir/icons/hicolor"

  echo "Updating gsettings cache..."
  glib-compile-schemas "$datadir/glib-2.0/schemas"
fi

