#!/bin/bash
# Create user devops with sudo
sudo adduser devops
sudo usermod -aG sudo devops

# Set up SSH key
sudo mkdir -p /home/devops/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAy3q6B623NbLObHqLLA9piA+nca3AWHDhtxuaMSDdtUjfebd0Fh/Kqu2qWMY+hSp6JtYNeQXeSCSyks4pk4Uo7U8PasbbiGg/hsrG60W5qYeLMzyHhAZALnvXO3eEcR44m9cuc7xKO8cw01K2qLQUPCXgNm+4Gtn2yhLFOuRB51dEiKA4w4tovF8bCzfa9DJTTB7B7lwVQorDY9ZEut8LwN0OhLhrfjntBuDDrJyr+PxB2XP1dkvwFunHh+da9Y23/IQdg/UNUJvdK/qJJ77rdYBfnqbzMA2lTcmONhce8MChFidJnGXspV2Wc4XP0bOMy6albMVy9+Ug299tXsJQ5Q==" | sudo tee /home/devops/.ssh/authorized_keys > /dev/null
sudo chown -R devops:devops /home/devops/.ssh
sudo chmod 700 /home/devops/.ssh
sudo chmod 600 /home/devops/.ssh/authorized_keys

# Harden SSH
sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd
