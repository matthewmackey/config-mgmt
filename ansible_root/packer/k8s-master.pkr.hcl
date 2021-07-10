source "vagrant" "k8s-master" {
  communicator = "ssh"
  provider = "virtualbox"
  source_path = "ubuntu/focal64"
  box_version = "20210624.0.0"
  add_force = true
}

build {
  sources = ["source.vagrant.k8s-master"]

  provisioner "ansible" {
    playbook_file = "../play-kubernetes.yml"
    keep_inventory_file = true
    extra_arguments = ["-vv"]
    groups = ["k8s_cluster", "k8s_masters"]
  }
}
