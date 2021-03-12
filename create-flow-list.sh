#!/bin/bash

grep -oP '(?<=wait_enter).*?(?= &&)' ubuntu-setup.sh | tr -d \'
