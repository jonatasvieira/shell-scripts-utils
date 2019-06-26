#!/bin/bash

#http://khmel.org/?p=945

echo "Disable firewall..."
systemctl disable firewalld
systemctl stop firewalld
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0

echo "Install epel repository."
yum -y install epel-release

echo "Install extra packages."
yum -y install createrepo
yum -y install yum-utils
yum -y install httpd

echo "Enable apache httpd"
systemctl enable httpd

echo "Create directory for repositories"
mkdir -p /data/repos201602

echo "Synchronize repositories."
reposync --gpgcheck -l --repoid=base       --download_path=/data/repos201602/ --downloadcomps --download-metadata
reposync --gpgcheck -l --repoid=centosplus --download_path=/data/repos201602/ --downloadcomps --download-metadata
reposync --gpgcheck -l --repoid=extras     --download_path=/data/repos201602/ --downloadcomps --download-metadata
reposync --gpgcheck -l --repoid=updates    --download_path=/data/repos201602/ --downloadcomps --download-metadata
reposync -l --repoid=epel       --download_path=/data/repos201602/ --downloadcomps --download-metadata

echo "Update definitions of repository."
createrepo /data/repos201602/base/ -g comps.xml
createrepo /data/repos201602/centosplus/
createrepo /data/repos201602/extras/
createrepo /data/repos201602/updates/
createrepo /data/repos201602/epel/ -g comps.xml

echo "Create disabled directory to store default repositorioes"
mkdir -p /etc/yum.repos.d/disabled/

echo "Move all repos to /etc/yum.repos.d/disabled"
mv /etc/yum.repos.d/* /etc/yum.repos.d/disabled/

echo "Create new file /etc/yum.repos.d/internal-repos.repo"
echo "[base]
name=CentOS Base
baseurl=http://localhost/repos/base/
gpgcheck=0                            
enabled=1
         
[updates]
name=CentOS Updates
baseurl=http://localhost/repos/updates/
gpgcheck=0                               
enabled=1
         
[extras]
name=CentOS Extras
baseurl=http://localhost/repos/extras/
gpgcheck=0                              
enabled=1
         
[centosplus]
name=CentOS CentOSPlus
baseurl=http://localhost/repos/centosplus/
gpgcheck=0                                  
enabled=1
         
[epel]
name=Extra Packages for Enterprise Linux 7
baseurl=http://localhost/repos/epel/
gpgcheck=0                            
enabled=1" >> /etc/yum.repos.d/internal-repos.repo

echo "Create new HTTPD configuration file"
echo "Alias /repos /data/repos201602
<Directory /data/repos201602>
    Options Indexes FollowSymLinks
    Require all granted
</Directory>" >> /etc/httpd/conf.d/repos.conf

echo "Start HTTPD service:"
systemctl start httpd
