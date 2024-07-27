#!/bin/sh

rm -r addons/rivet/resources/template_2d/*
mkdir addons/rivet/resources/template_2d/assets
cp *.{tscn,gd} addons/rivet/resources/template_2d/
cp assets/*.png addons/rivet/resources/template_2d/assets/
