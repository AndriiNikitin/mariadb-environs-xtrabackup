#!/bin/bash

set -e

./replant.sh m1-bb-10.1-xtrabackup
m1*/checkout.sh
m1*/cmake.sh
m1*/build.sh

./runsuite.sh m1 _plugin/xtrabackup/t/bug1227240.sh
