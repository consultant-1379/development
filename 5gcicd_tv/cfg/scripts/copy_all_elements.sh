#!/usr/bin/env bash

cd development
cp -r 5gcicd_tv/assets/* /assets/
chmod -R 775 /assets/*
cp -r 5gcicd_tv/config/* /config/
chmod -R 775 /config/*
cp -r 5gcicd_tv/dashboards/* /dashboards/
chmod -R 775 /dashboards/*
cp -r 5gcicd_tv/jobs/* /jobs/
chmod -R 775 /jobs/*
cp -r 5gcicd_tv/public/* /public/
chmod -R 775 /public/*
cp -r 5gcicd_tv/widgets/* /widgets/
chmod -R 775 /widgets/*
cd -
