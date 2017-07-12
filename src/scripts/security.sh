#!/bin/sh
set -e

########################################################################
# Scripts to harden SSH as assessed by CIS-CAT
########################################################################
echo "Applying CIS-CAT security benchmark.."

# 5.2.1 Ensure permissions on /etc/ssh/sshd_config are configured
sudo mv -bf /tmp/sshd_config /etc/ssh/sshd_config
sudo chown root:root /etc/ssh/sshd_config
sudo chmod og-rwx /etc/ssh/sshd_config

sudo mv -bf /tmp/issue.net /etc/issue.net
sudo chown root:root /etc/issue.net
sudo chmod 644 /etc/issue.net

# 1.1.1.1 Ensure mounting of cramfs filesystems is disabled
sudo grep -q -F 'install cramfs /bin/true' /etc/modprobe.d/CIS.conf | echo 'install cramfs /bin/true' | sudo tee -a /etc/modprobe.d/CIS.conf
# 1.1.1.2 Ensure mounting of freevxfs filesystems is disabled
sudo grep -q -F 'install freevxfs /bin/true' /etc/modprobe.d/CIS.conf | echo 'install freevxfs /bin/true' | sudo tee -a /etc/modprobe.d/CIS.conf
# 1.1.1.3 Ensure mounting of jffs2 filesystems is disabled
sudo grep -q -F 'install jffs2 /bin/true' /etc/modprobe.d/CIS.conf | echo 'install jffs2 /bin/true' | sudo tee -a /etc/modprobe.d/CIS.conf
# 1.1.1.4 Ensure mounting of hfs filesystems is disabled
sudo grep -q -F 'install hfs /bin/true' /etc/modprobe.d/CIS.conf | echo 'install hfs /bin/true' | sudo tee -a /etc/modprobe.d/CIS.conf
# 1.1.1.5 Ensure mounting of hfsplus filesystems is disabled
sudo grep -q -F 'install hfsplus /bin/true' /etc/modprobe.d/CIS.conf | echo 'install hfsplus /bin/true' | sudo tee -a /etc/modprobe.d/CIS.conf
# 1.1.1.6 Ensure mounting of squashfs filesystems is disabled
sudo grep -q -F 'install squashfs /bin/true' /etc/modprobe.d/CIS.conf | echo 'install squashfs /bin/true' | sudo tee -a /etc/modprobe.d/CIS.conf
# 1.1.1.7 Ensure mounting of udf filesystems is disabled
sudo grep -q -F 'install udf /bin/true' /etc/modprobe.d/CIS.conf | echo 'install udf /bin/true' | sudo tee -a /etc/modprobe.d/CIS.conf
# 1.1.1.8 Ensure mounting of FAT filesystems is disabled
sudo grep -q -F 'install vfat /bin/true' /etc/modprobe.d/CIS.conf | echo 'install vfat /bin/true' | sudo tee -a /etc/modprobe.d/CIS.conf

echo "# CIS 1.6.1" >> sudo tee -a /etc/security/limits.conf
echo "* hard core 0" >> sudo tee -a /etc/security/limits.conf
echo "fs.suid_dumpable = 0" >> sudo tee -a /etc/security.limits.conf

sudo chmod 0600 /boot/grub/grub.conf

echo "# CIS 3.1" >> sudo tee -a /etc/sysconfig/init
echo "umask 027" >> sudo tee -a /etc/sysconfig/init

sudo tee -a /etc/sysctl.conf << EOF > /dev/null
# CIS 4.1.2
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0

# CIS 4.2.2
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0

# CIS 4.2.4
net.ipv4.conf.all.log_martians=1
net.ipv4.conf.default.log_martians=1
EOF

sudo chmod 0600 /var/log/boot.log

sudo chmod 0600 /etc/crontab
sudo chmod 0600 /etc/cron.hourly
sudo chmod 0600 /etc/cron.weekly
sudo chmod 0600 /etc/cron.daily
sudo chmod 0600 /etc/cron.monthly
sudo chmod 0700 /etc/cron.d

sudo touch /etc/at.allow
sudo chown root:root /etc/at.allow
sudo chmod 0600 /etc/at.allow
sudo restorecon /etc/at.allow

sudo touch /etc/cron.allow
sudo chown root:root /etc/cron.allow
sudo chmod 0600 /etc/cron.allow
sudo restorecon /etc/cron.allow

sudo rm -f /etc/cron.deny
sudo chmod 0600 /var/log/cron