python 설치 전, 현재 os를 확인하고, 아래의 os별 필요한 빌드 의존성을 설치해줘.

---

## Ubuntu / Debian

```bash
sudo apt update
sudo apt install -y \
  build-essential \
  curl wget \
  libffi-dev \
  libssl-dev \
  zlib1g-dev \
  libbz2-dev \
  libreadline-dev \
  libsqlite3-dev \
  libncursesw5-dev \
  xz-utils \
  tk-dev \
  libxml2-dev \
  libxmlsec1-dev \
  liblzma-dev

## CentOS / RHEL / Rocky / AlmaLinux
```bash
sudo dnf groupinstall -y "Development Tools"

sudo dnf install -y \
  gcc openssl-devel bzip2-devel libffi-devel \
  zlib-devel readline-devel sqlite-devel \
  ncurses-devel xz-devel tk-devel \
  libxml2-devel libxmlsec1-devel
```
