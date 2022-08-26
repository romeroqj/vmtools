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

To build and install to AWS instead use the `--aws` flag.

```
$ doit install --aws
$ doit clone --aws --name ec2-node01
```