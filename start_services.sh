#!/bin/bash
service ssh start
exec postgres -c config_file=/etc/postgresql.conf
