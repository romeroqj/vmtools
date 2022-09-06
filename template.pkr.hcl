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
  accelerator    = "kvm"
  disk_interface = "virtio"
  net_device     = "virtio-net"

  vm_name   = "${var.vm_name}.${var.format}"
  format    = "${var.format}"
  cpus      = "${var.vcpus}"
  memory    = "${var.memory}"
  disk_size = "${var.disk_size}"
  boot_command = [
    "<esc><wait><wait>",
    "install ",
    "auto=true ",
    "priority=critical ",
    "interface=auto ",
    "url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg",
    "<enter><wait>"
  ]
  shutdown_command = "echo '/sbin/halt -h -p' > shutdown.sh; echo 'owner' | sudo -S bash 'shutdown.sh'"
  http_directory   = "http"
  headless         = true
  iso_url          = "${var.iso_url}"
  iso_checksum     = "${var.iso_checksum}"
  ssh_username     = "${var.ssh_username}"
  ssh_password     = "${var.ssh_password}"
  ssh_timeout      = "15m"
}


source "qemu" "bullseye-secure" {
  accelerator    = "kvm"
  disk_interface = "virtio"
  net_device     = "virtio-net"

  vm_name   = "${var.vm_name}-secure.${var.format}"
  format    = "${var.format}"
  cpus      = "${var.vcpus}"
  memory    = "${var.memory}"
  disk_size = "${var.disk_size}"

  headless     = true
  disk_image   = true
  iso_url      = "./output-bullseye/bullseye.qcow2"
  iso_checksum = "file:./output-bullseye/bullseye.md5sum"
  ssh_username = "${var.ssh_username}"
  ssh_password = "${var.ssh_password}"
  ssh_timeout  = "15m"
}


build {
  # TODO: Override fields with different values inside `build` block
  sources = [
    "source.qemu.bullseye",
    "source.qemu.bullseye-secure"
  ]

  # ESSENTIAL PACKAGES & SYSTEM HARDENING
  # 
  # This provisioner runs on base/golden imgages only. Base/golden images are
  # those which are not intended to run as-is.
  #
  # Install the bare-minimum packages...
  provisioner "shell" {
    only = ["source.qemu.bullseye"]
    script = [
      "scripts/base.sh",
      "scripts/sshd.sh"
    ]
  }


  # NETWORKING
  #
  # Set up 1x ethernet interface, configured via DHCP.
  #
  # The configuration files are moved to their respective locations by the shell provider.
  #
  # The interface is renamed to 'eth0' by systemd-udev according to the *.link file.
  # https://man.archlinux.org/man/systemd.link.5
  # 
  provisioner "file" {
    sources     = ["./conf/interfaces", "./conf/10-if-eth0.link"]
    destination = "/tmp/"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /tmp/interfaces /etc/network/interfaces",
      "sudo mv /tmp/10-if-eth0.link /etc/systemd/network/10-if-eth0.link"
    ]
  }


  # CLEAN UP
  #
  # Remove leftovers (e.g. cache, logs, temp files) and zero out the free image space.
  # 
  provisioner "shell" {
    scripts = [
      "scripts/cleanup.sh",
      "scripts/zerodisk.sh"
    ]
  }

  post-processor "manifest" {
    output     = "manifest.json"
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
