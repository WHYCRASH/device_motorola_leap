#!/bin/bash
# Sanity check: every NEEDED entry of every shipped vendor binary must resolve
# either to a shipped lib or to a lib the TWRP 14.1 build system provides.
# Throwaway for pre-flash verification; not part of the build.
set -uo pipefail

TREE_DIR="${1:-/home/dautist/fox_14.1/device/motorola/leap}"
V="$TREE_DIR/recovery/root/vendor"
S="$TREE_DIR/recovery/root/system"

# Sonames known to come from the TWRP/AOSP build (libc/binder/ndk/base family).
# Kept as a fixed list so misses fail loudly instead of being hand-waved away.
BUILD_PROVIDED="libc.so libm.so libdl.so libc++.so liblog.so libcutils.so libutils.so \
  libbase.so libbinder_ndk.so libhidlbase.so libhardware.so libcrypto.so libqcbor.so \
  libgatekeeper.so android.hardware.boot-V1-ndk.so android.hardware.boot@1.0.so \
  android.hardware.boot@1.1.so android.hardware.boot@1.2.so android.hardware.fastboot-V1-ndk.so \
  android.hardware.fastboot@1.0.so android.hardware.fastboot@1.1.so \
  android.hardware.health-V3-ndk.so android.hardware.health@1.0.so android.hardware.health@2.0.so \
  android.hardware.security.keymint-V3-ndk.so android.hardware.security.rkp-V3-ndk.so \
  android.hardware.security.secureclock-V1-ndk.so android.hardware.security.sharedsecret-V1-ndk.so \
  android.hardware.security.sharedsecret-V2-ndk.so android.hardware.weaver-V2-ndk.so \
  android.hardware.gatekeeper-V1-ndk.so android.hardware.keymaster@4.0.so \
  vendor.qti.hardware.spu-V2-ndk.so"

fail=0
checked=0
for bin in "$V"/bin/qseecomd "$V"/bin/ssgtzd "$V"/bin/hw/* "$S"/bin/hw/*; do
  [ -f "$bin" ] || continue
  while read -r lib; do
    [ -n "$lib" ] || continue
    checked=$((checked + 1))
    if [ -f "$V/lib64/$lib" ] || [ -f "$V/lib64/hw/$lib" ] || [ -f "$S/lib64/$lib" ]; then
      : # shipped
    elif echo " $BUILD_PROVIDED " | grep -q " $lib "; then
      : # build-provided
    else
      echo "UNRESOLVED: $(basename "$bin") needs $lib"
      fail=1
    fi
  done < <(readelf -d "$bin" 2>/dev/null | grep NEEDED | sed 's/.*\[\(.*\)\]/\1/')
done

# Also check shipped .so link closure one level deep
for lib in "$V"/lib64/*.so "$V"/lib64/hw/*.so; do
  [ -f "$lib" ] || continue
  while read -r need; do
    [ -n "$need" ] || continue
    checked=$((checked + 1))
    if [ -f "$V/lib64/$need" ] || [ -f "$V/lib64/hw/$need" ] || [ -f "$S/lib64/$need" ]; then
      :
    elif echo " $BUILD_PROVIDED " | grep -q " $need "; then
      :
    else
      echo "UNRESOLVED: $(basename "$lib") needs $need"
      fail=1
    fi
  done < <(readelf -d "$lib" 2>/dev/null | grep NEEDED | sed 's/.*\[\(.*\)\]/\1/')
done

echo "checked $checked NEEDED edges"
if [ "$fail" = 0 ]; then echo "PASS: full lib closure resolves"; else echo "FAIL: missing libs above"; exit 1; fi
