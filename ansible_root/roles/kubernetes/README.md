Kubernetes
==========

This role is intended to configure the dependencies of a kubernetes master or
worker node.  It currently is specifically geared towards configuring master and
worker nodes that will be setup as a cluster by `kubeadm`.

It optionally can do some additional config, like pre-pulling kubernetes docker
images via kubeadm on master nodes.

This role can be used to pre-bake kubernetes VM images with something like
packer.

Set Kubelet Node IP
-------------------

This role includes a task to set the kubelet node IP, which can't be
done until a machine has been provisioned so it is left as a separate, optional
task.  This way you can use packer for all the tasks that can be done to build a
base image and then run the kubelet set node IP task after a machine is
provisioned.
