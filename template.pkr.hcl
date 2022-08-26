variable "vm_name" {
  type    = string
  default = "bullseye"
}

variable "format" {
  type    = string
  default = "qcow2"
}

variable "vcpus" {
  type    = string
  default = "1"
}

variable "memory" {
  type    = string
  default = "1024"
}

variable "disk_size" {
  type    = string
  default = "32768"
}

variable "iso_checksum" {
  type    = string
  default = "file:./iso/debian-11.4.0-amd64-netinst.iso.sha512sum"
}

variable "iso_url" {
  type    = string
  default = "./iso/debian-11.4.0-amd64-netinst.iso"
}

variable "ssh_username" {
  type    = string
  default = "owner"
}

variable "ssh_password" {
  type    = string
  default = "own3r"
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "qemu" "bullseye" {
  accelerator       = "kvm"
  disk_interface    = "virtio"
  net_device        = "virtio-net"

  vm_name           = "${var.vm_name}.${var.format}"
  format            = "${var.format}"
  cpus              = "${var.vcpus}"
  memory            = "${var.memory}"
  disk_size         = "${var.disk_size}"
  boot_command      = [
    "<esc><wait><wait>",
    "install ",
    "auto=true ",
    "priority=critical ",
    "interface=auto ",
    "url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg",
    "<enter><wait>"
  ]
  shutdown_command  = "echo '/sbin/halt -h -p' > shutdown.sh; echo 'owner' | sudo -S bash 'shutdown.sh'"
  http_directory    = "http"
  headless          = true
  iso_url           = "${var.iso_url}"
  iso_checksum      = "${var.iso_checksum}"
  ssh_username      = "${var.ssh_username}"
  ssh_password      = "${var.ssh_password}"
  ssh_timeout       = "15m"
}

build {
  sources = ["source.qemu.bullseye"]

  # CONFIGURATION FILES
  # They will be moved to their respective location by the shell provider.
  provisioner "file" {
    sources = [
      "./conf/interfaces",
      "./conf/10-if-eth0.link"
    ]
    destination = "/tmp/"
  }

  provisioner "shell" {
    scripts = [
      "scripts/base.sh",
      "scripts/sshd.sh",
      "scripts/cleanup.sh",
      "scripts/zerodisk.sh"
    ]
  }

  post-processor "manifest" {
    output = "manifest.json"
    strip_path = true
    custom_data = {
      timestamp = "${local.timestamp}"
    }
  }

  // post-processor "shell-local" {
  //   inline = [
  //       "jq \".builds[].files[].name\" manifest.json | xargs tar cfz artifacts.tgz"
  //   ]
  // }
}
