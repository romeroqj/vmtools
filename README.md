Download ISO files to `iso/` directory.

Build.

```
$ packer build template.pkr.hcl
```

```
$ doit build
$ doit install
$ doit clone --name node01
$ doit clean
$ 
```

## todo

- [ ] Install alpine with packer
  - [ ] install tailscaled and cloudflared
  - [ ] enable firewall using nft
    - https://tailscale.com/kb/1077/secure-server-ubuntu-18-04/
    - https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/do-more-with-tunnels/ports-and-ips/
  - [ ] disable sshd