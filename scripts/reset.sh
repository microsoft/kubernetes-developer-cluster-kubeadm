#!/bin/bash

sudo kubeadm reset -f
sudo kubeadm config images pull
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address $PIP --cri-socket /run/containerd/containerd.sock

# copy config file
sudo rm ~/.kube/config
sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config
sudo chown -R ${USER}:${USER} ~/.kube

# add flannel network overlay
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml --namespace=kube-system

# add the taint to schedule normal pods on the control plane
#   this let you run a "one node" cluster for development
kubectl taint nodes --all node-role.kubernetes.io/master-
