# -*- mode: ruby -*-
# vi: set ft=ruby :

# This script to install common Kubernetes packages and is to be used
# in all VMS i.e both master and node VMs 
$script = <<-SCRIPT
# Install Docker CE
## Set up the repository:
### Update the apt package index
apt-get update

### Install packages to allow apt to use a repository over HTTPS
apt-get install -y apt-transport-https ca-certificates curl software-properties-common 

### Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

### Add docker apt repository.
add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"

## Install docker ce.
apt-get update && apt-get install -y docker-ce=18.06.2~ce~3-0~ubuntu
apt-mark hold docker-ce 

# Setup daemon.
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=cgroupfs"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
systemctl daemon-reload
systemctl restart docker

# Install CRI-O - Prerequisites
modprobe overlay
modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat > /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl --system

# Install prerequisites
apt-get install -y software-properties-common

add-apt-repository ppa:projectatomic/ppa
apt-get update

# Install CRI-O
apt-get install -y cri-o-1.11
sudo apt-mark hold cri-o-1.11

systemctl start crio

# Installing kubeadm, kubelet and kubectl
apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update && apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Kubelet requires swap off
swapoff -a

# Keep swap off after reboot
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

systemctl daemon-reload
systemctl restart kubelet

# Get the IP address that VirtualBox has given this VM
IPADDR=`ifconfig eth1 | grep -i mask | awk '{print $2}'| cut -f2 -d:`
LIPADDR=`ifconfig eth0 | grep -i mask | awk '{print $2}'| cut -f2 -d:`
echo This VM has IP address $IPADDR

# Set up Kubernetes
NODENAME=$(hostname -s)

kubeadm init --pod-network-cidr=${CIDR} \
             --node-name ${NODENAME} \
             --apiserver-advertise-address ${IPADDR} \
             --apiserver-cert-extra-sans="${LIPADDR},${IPADDR}" \
             --ignore-preflight-errors=SystemVerification \
             --skip-token-print 

# Set up admin creds for the vagrant user
echo Copying credentials to /home/vagrant...
mkdir -p {$HOME/.kube,/home/vagrant/.kube,/vagrant/.kube}                                                                    
echo /home/vagrant/.kube/config  $HOME/.kube/config /vagrant/.kube/config | xargs -n 1 \\cp -v /etc/kubernetes/admin.conf 
sudo chown $(id -u vagrant):$(id -g vagrant) /vagrant/.kube/config /home/vagrant/.kube/config $HOME/.kube/config

SCRIPT

##
#  Vagrant confiuration 
Vagrant.configure("2") do |config|
  
  config.vm.provider "virtualbox" do |v|
    v.cpus = 2
  end

  config.vm.hostname = "kube"
  config.vm.box = "bento/ubuntu-16.04"
  config.vm.network "private_network", type: "dhcp"
  config.vm.provision "shell", inline: $script
end