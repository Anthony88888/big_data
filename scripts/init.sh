#!/bin/bash
# Description: script to init configuration to new server.
#---------------------------------------------------------------|
#   @Program     : System_init.sh                               |  
#   @Version     : 1.1                                          |
#   @Company     : QWKG                                         |
#   @Dep.        : IDC                                          |
#   @Writer      : Curry   <curry@gmail.com>                    |                
#   @Date        : 2017-11-07                                   |
#   @Origina     : wangshibo                                    |
#   @Author      : Curry                                        |
#---------------------------------------------------------------|

#临时dns设置，用于yum下载
#echo "nameserver 8.8.8.8" /etc/resolv.conf
#echo "nameserver 8.8.4.4" /etc/resolv.conf

#设置chrony时间服务
yum clean all &>/dev/null;yum -qy install chrony &>/dev/null
sed -i 's/^server/#server/g'  /etc/chrony.conf
cat >> /etc/chrony.conf <<-eof
    #  Start custom config
    # add time server address

    server time.pool.aliyun.com iburst
    bindcmdaddress 127.0.0.1
    # End custom config
eof

if [[ `rpm -q centos-release|cut -d- -f3` -eq "7" ]] ;then
    systemctl start chronyd.service
    systemctl enable chronyd.service
else
    service chronyd start
    chkconfig chronyd on
fi

#关闭防火墙
iptables -F
iptables -X
systemctl stop firewalld.service
systemctl disable firewalld.service 
sed -i 's/SELINUX=enforcing/SELINUX=disabled/'  /etc/selinux/config 

#设置DNS
#\cp -f /etc/resolv.conf /etc/resolv.conf.bak
#> /etc/resolv.conf
#echo "domain veredholdings.cn" >> /etc/resolv.conf
#echo "search veredholdings.cn" >> /etc/resolv.conf
#echo "nameserver 10.0.11.21" >> /etc/resolv.conf
#echo "nameserver 10.0.11.22" >> /etc/resolv.conf
#/usr/bin/chattr +ai /etc/resolv.conf


#内核参数优化
/bin/cat << EOF > /etc/sysctl.conf
kernel.sysrq = 1
kernel.core_uses_pid = 1
fs.aio-max-nr = 1048576                
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.ipv4.ip_forward = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.default.rp_filter = 2
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.all.arp_announce = 2
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.ip_local_port_range = 1024  65535
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_synack_retries = 2
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.rp_filter = 1
net.core.somaxconn = 65535
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 8192 87380 16777216
net.ipv4.tcp_wmem = 8192 65536 16777216
net.ipv4.tcp_max_syn_backlog = 16384
net.core.netdev_max_backlog = 10000
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_orphan_retries = 0
net.ipv4.tcp_max_orphans = 131072
#fs.file-max = 65536  #os can config
vm.min_free_kbytes = 1048576
vm.swappiness = 10
vm.dirty_ratio = 10
vm.vfs_cache_pressure=150
vm.drop_caches = 1
kernel.panic = 60
EOF
/sbin/sysctl -p >/dev/null 2>&1;


#ssh登陆优化
cp /etc/ssh/sshd_config{,.bak}  
#sed -e 's/\#PermitRootLogin yes/PermitRootLogin no/' -i /etc/ssh/sshd_config > /dev/null 2>&1
sed -e 's/GSSAPIAuthentication yes/GSSAPIAuthentication no/' -i /etc/ssh/sshd_config > /dev/null 2>&1
sed -e 's/#UseDNS yes/UseDNS no/' -i /etc/ssh/sshd_config > /dev/null 2>&1
systemctl restart sshd.service

#修改文件描述符数量
sed -i 's#4096#65535#g' /etc/security/limits.d/20-nproc.conf
/bin/cp /etc/security/limits.conf /etc/security/limits.conf.bak
echo '* soft nofile 65535'>>/etc/security/limits.conf
echo '* hard nofile 65535'>>/etc/security/limits.conf
echo '* soft nproc 102400'>>/etc/security/limits.conf
echo '* hard nproc 102400'>>/etc/security/limits.conf

# 安装常用软件
#/usr/bin/yum groupinstall "Development Tools"
yum install -y  vim iotop bc gcc gcc-c++ glibc glibc-devel pcre \
pcre-devel openssl  openssl-devel zip unzip zlib-devel  net-tools \
lrzsz tree ntpdate telnet lsof tcpdump wget libevent libevent-devel \
bc  systemd-devel bash-completion traceroute  

#设置linux系统时间为北京时间
rm -rf /etc/localtime  &&  ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime


#/bin/rm /root/init.sh
# 最后重启服务器
reboot

