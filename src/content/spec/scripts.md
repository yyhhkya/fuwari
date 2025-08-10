## [换源](https://linuxmirrors.cn/)

```bash
bash <(curl -sSL https://linuxmirrors.cn/main.sh)
```

## [docker安装](https://linuxmirrors.cn/#docker)

```bash
bash <(curl -sSL https://linuxmirrors.cn/docker.sh)
```

## [一键DD](https://github.com/bin456789/reinstall)

```bash
curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh || wget -O reinstall.sh $_

---

bash reinstall.sh anolis      7|8|23
                  rocky       8|9|10
                  oracle      8|9
                  almalinux   8|9|10
                  opencloudos 8|9|23
                  centos      9|10
                  fedora      41|42
                  nixos       25.05
                  debian      9|10|11|12
                  opensuse    15.6|tumbleweed
                  alpine      3.19|3.20|3.21|3.22
                  openeuler   20.03|22.03|24.03|25.03
                  ubuntu      16.04|18.04|20.04|22.04|24.04|25.04 [--minimal]
                  kali
                  arch
                  gentoo
                  aosc
                  fnos
                  redhat      --img="http://access.cdn.redhat.com/xxx.qcow2"
```

## [VPS融合怪](https://github.com/spiritLHLS/ecs)

```bash
curl -L https://raw.githubusercontent.com/oneclickvirt/ecs/master/goecs.sh -o goecs.sh && chmod +x goecs.sh && bash goecs.sh env && bash goecs.sh install && goecs
```

## [SpeedTest一键测速](https://hub.docker.com/r/ilemonrain/html5-speedtest)

```bash
docker run -d -p 7070:80 --name speedtest ilemonrain/html5-speedtest:alpine
```

## [3x-ui](https://github.com/MHSanaei/3x-ui)

```bash
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
```