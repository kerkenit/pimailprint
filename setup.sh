#!/usr/bin/env bash

is_root () {
	return $(id -u)
}

has_sudo() {
	local prompt

	prompt=$(sudo -nv 2>&1)
	if [ $? -eq 0 ]; then
		echo "has_sudo__pass_set"
	elif echo $prompt | grep -q '^sudo:'; then
		echo "has_sudo__needs_pass"
	else
		echo "no_sudo"
	fi
}

elevate_cmd () {
	local cmd=$@

	HAS_SUDO=$(has_sudo)

	case "$HAS_SUDO" in
	has_sudo__pass_set)
		sudo $cmd
		;;
	has_sudo__needs_pass)
		echo "Please supply sudo password for the following command: sudo $cmd"
		sudo $cmd
		;;
	*)
		echo "Please supply root password for the following command: su -c \"$cmd\""
		su -c "$cmd"
		;;
	esac
}

if is_root; then
	echo "Error: need to call this script as a normal user, not as root!"
	exit 1
fi

elevate_cmd apt update
elevate_cmd apt upgrade -y
elevate_cmd apt install -y libreoffice hplip rubygems build-essential default-jre libreoffice-java-common fonts-crosextra-carlito fonts-crosextra-caladea ttf-mscorefonts-installer unoconv cups-filters cups-* procmail fetchmail
elevate_cmd apt autoremove -y

elevate_cmd mkdir -p /home/$(whoami)
elevate_cmd chown $(whoami):$(whoami) -R /home/$(whoami)
if [ ! -d /home/$(whoami)/pimailprint ]; then
    elevate_cmd git clone https://github.com/kerkenit/pimailprint.git /home/$(whoami)/pimailprint
else
	cd /home/$(whoami)/pimailprint
	git pull origin main
fi
elevate_cmd touch /var/log/printmail.log
elevate_cmd chown -R $(whoami):$(whoami) /home/$(whoami)/pimailprint /var/log/printmail.log
elevate_cmd chmod +x /home/$(whoami)/pimailprint/printmail.sh
elevate_cmd rm -rf /tmp/pimailprint
echo "Setup complete!"
if [ ! -f /home/$(whoami)/pimailprint/fetchmail.conf ]; then
	echo "Let's edit the configuration file /home/$(whoami)/pimailprint/fetchmail.conf"
	echo ""
	read -p "What is your email address? " email_address
	read -p "What is your email password? " email_password
	read -p "What is your IMAP server address? " imap_server
	read -p "What port does your IMAP server use? " imap_port

	echo "set no bouncemail" > /home/$(whoami)/pimailprint/fetchmail.conf
	echo "poll $imap_server" >> /home/$(whoami)/pimailprint/fetchmail.conf
	echo "service $imap_port" >> /home/$(whoami)/pimailprint/fetchmail.conf
	echo "protocol imap" >> /home/$(whoami)/pimailprint/fetchmail.conf
	echo "user \"$email_address\"" >> /home/$(whoami)/pimailprint/fetchmail.conf
	echo "password \"$email_password\"" >> /home/$(whoami)/pimailprint/fetchmail.conf
	echo "ssl" >> /home/$(whoami)/pimailprint/fetchmail.conf
	echo "sslcertck" >> /home/$(whoami)/pimailprint/fetchmail.conf
	echo "sslproto TLS1.2" >> /home/$(whoami)/pimailprint/fetchmail.conf
	echo "no keep" >> /home/$(whoami)/pimailprint/fetchmail.conf
	echo "mda \"/usr/bin/procmail -m './procmail.conf'\"" >> /home/$(whoami)/pimailprint/fetchmail.conf
	elevate_cmd chmod 700 /home/$(whoami)/pimailprint/fetchmail.conf
	elevate_cmd chmod 700 /home/$(whoami)/pimailprint/fetchmail.conf
else
	echo "Configuration file /home/$(whoami)/pimailprint/fetchmail.conf already exists."
	echo "If you want to change the configuration, please edit it manually."
fi
elevate_cmd cupsctl --remote-admin --remote-any --share-printers
elevate_cmd usermod -a -G lpadmin $(whoami)
elevate_cmd service cups restart
ip_address=$(hostname -I | awk '{print $1}')
echo "You can now configure your CUPS printer by visiting https://$ip_address:631"
echo "You can log in with user $(whoami) and your password."