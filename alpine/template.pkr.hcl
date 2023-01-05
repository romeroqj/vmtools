variable "vm_name" {
  type    = string
  default = "alpine"
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
  default = "file:./alpine-standard-3.17.0-x86_64.iso.sha256"
}

variable "iso_url" {
  type    = string
  default = "./alpine-standard-3.17.0-x86_64.iso"
}

variable "ssh_username" {
  type    = string
  default = "root"
}

variable "root_password" {
  type    = string
  default = "AlpineLinux01"
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "qemu" "alpine" {
  accelerator    = "kvm"
  disk_interface = "virtio"
  net_device     = "virtio-net"

  vm_name   = "${var.vm_name}.${var.format}"
  format    = "${var.format}"
  cpus      = "${var.vcpus}"
  memory    = "${var.memory}"
  disk_size = "${var.disk_size}"
  boot_command = [
    "<wait>",
    "root<enter><wait>",
    "setup-interfaces -ar<enter><wait5>",
    "wget http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg -O preseed.cfg<enter><wait5>",
    "ERASE_DISKS=/dev/vda setup-alpine -f preseed.cfg<enter><wait5>",
    "${var.root_password }<enter><wait>",
    "${var.root_password }<enter><wait>",
    "<enter><wait30>",    # Setup a user? [no]
    "mount /dev/vda3 /mnt<enter><wait>",
    "echo 'PermitRootLogin yes' >> /mnt/etc/ssh/sshd_config<enter><wait>",
    "umount /mnt<enter><wait>",
    "reboot<enter>"
  ]
  shutdown_command = "/sbin/poweroff"
  http_directory   = "http"
  headless         = false
  iso_url          = "${var.iso_url}"
  iso_checksum     = "${var.iso_checksum}"
  ssh_username     = "root"
  ssh_password     = "${var.root_password}"
  ssh_timeout      = "15m"
}

build {
  # TODO: Override fields with different values inside `build` block
  sources = [
    "source.qemu.alpine",
  ]

  # ESSENTIAL PACKAGES & SYSTEM HARDENING
  # 
  # This provisioner runs on base/golden imgages only. Base/golden images are
  # those which are not intended to run as-is.
  #
  # Install the bare-minimum packages...
  provisioner "shell" {
    only = ["source.qemu.alpine"]
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
  # 
  // provisioner "file" {
  //   sources     = ["./conf/interfaces", "./conf/10-if-eth0.link"]
  //   destination = "/tmp/"
  // }

  // provisioner "shell" {
  //   inline = [
  //     "sudo mv /tmp/interfaces /etc/network/interfaces",
  //     "sudo mv /tmp/10-if-eth0.link /etc/systemd/network/10-if-eth0.link"
  //   ]
  // }


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
