# Python 설치 전 Linux 의존성 설치

Python 또는 `pyenv`로 Python을 설치하기 전에, 현재 Linux 배포판에 맞는 빌드 의존성을 설치해줘.

## 작업 지침

- 먼저 현재 OS가 어떤 배포판인지 확인해줘.
- 아래 목록에서 해당 배포판에 맞는 명령만 실행해줘.
- 설치가 끝나면 Python 빌드에 필요한 패키지가 정상 설치되었는지 간단히 확인해줘.

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
```

## CentOS / RHEL / Rocky / AlmaLinux

```bash
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y \
  gcc openssl-devel bzip2-devel libffi-devel \
  zlib-devel readline-devel sqlite-devel \
  ncurses-devel xz-devel tk-devel \
  libxml2-devel libxmlsec1-devel
```
