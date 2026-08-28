#!/bin/bash
scp -i /home/devops/.ssh/sync_key -o StrictHostKeyChecking=no /home/devops/.ssh/authorized_keys devops@192.168.2.102:/home/devops/.ssh/authorized_keys
