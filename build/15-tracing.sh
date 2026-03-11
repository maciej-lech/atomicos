#!/usr/bin/bash

set -eoux pipefail

dnf5 install -y \
  bcc \
  bcc-tools \
  bpftop \
  bpftrace \
  iotop-c \
  nicstat \
  numactl \
  powerstat \
  powertop \
  sysprof \
  sysstat \
  systemtap-client \
  systemtap-devel \
  systemtap-runtime \
  tiptop \
  trace-cmd
