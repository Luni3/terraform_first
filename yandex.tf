                                                                                                                                                                     yandex_2.tf
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}


provider "yandex" {
  token     = "y0_AgAAAAAFqYUaAATuwQAAAADTEatdRHhlYEmHS2GVFEFwveZOZoRUd1Q"
  cloud_id  = "b1g0mplmmd0907is97hb"
  folder_id = "b1g67g31ptfnf3km1906"
  zone      = "ru-central1-a"
}

resource "yandex_compute_image" "ubuntu_2004" {
  source_family = "ubuntu-2004-lts"
}

resource "yandex_compute_instance" "vm-1" {
  name = "terraform1"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = yandex_compute_image.ubuntu_2004.id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}


data "template_file" "inventory" {
  template = file("./terraform/_templates/inventory.tpl")

  vars = {
    user = "ubuntu"
    host = join("", [yandex_compute_instance.vm-1.name, " ansible_host=", yandex_compute_instance.vm-1.network_interface.0.nat_ip_address])
  }
}

resource "local_file" "save_inventory" {
  content  = data.template_file.inventory.rendered
  filename = "./inventory"
}


output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}

