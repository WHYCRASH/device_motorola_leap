#!/bin/bash
# Stage leap vendor decrypt blobs into the OrangeFox device tree.
# Sources: ROM dump (vendor/) + stock recovery ramdisk (/tmp/recnew).
# Recovery-adapted .rc files are written inline (peridot pattern: run as
# root under u:r:recovery:s0 with an explicit LD_LIBRARY_PATH).
#
# Usage: ./stage-vendor-blobs.sh [dump_dir] [tree_dir]
# Defaults assume this script lives in device/motorola/leap/.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
DUMP_DIR="${1:-/home/dautist/Projects/leaptwrp/razrultra2025-recovery-dev/Moto-Razr-60-Ultra-5G-XT2551-1-RETUS-16-ROM-DUMP}"
TREE_DIR="${2:-$SCRIPT_DIR}"
RROOT="${RROOT:-/tmp/recnew}"

V="$TREE_DIR/recovery/root/vendor"
mkdir -p "$V/bin/hw" "$V/lib64/hw" "$V/etc/init" "$V/etc/vintf/manifest" "$V/firmware_mnt/image"

copy_bin() { # src_rel dest_name
  cp -f "$DUMP_DIR/$1" "$V/$2"
  chmod 755 "$V/$2"
}
copy_lib() { # libname [subdir]
  local lib="$1" sub="${2:-}"
  local src="$DUMP_DIR/vendor/lib64/${sub:+$sub/}$lib"
  if [ -f "$src" ]; then
    cp -f "$src" "$V/lib64/${sub:+$sub/}$lib"
    echo "staged lib: ${sub:+$sub/}$lib"
  else
    echo "MISSING lib: ${sub:+$sub/}$lib" >&2
  fi
}

echo "== binaries =="
copy_bin vendor/bin/qseecomd bin/qseecomd
copy_bin vendor/bin/ssgtzd bin/ssgtzd
copy_bin vendor/bin/hw/android.hardware.security.keymint-service-spu-qti bin/hw/android.hardware.security.keymint-service-spu-qti
copy_bin vendor/bin/hw/android.hardware.gatekeeper-service-spu-qti bin/hw/android.hardware.gatekeeper-service-spu-qti
copy_bin vendor/bin/hw/android.hardware.weaver-service-spu-qti bin/hw/android.hardware.weaver-service-spu-qti
copy_bin vendor/bin/hw/vendor.qti.hardware.qseecom@1.0-service bin/hw/vendor.qti.hardware.qseecom@1.0-service
# non-SPU fallback pair (present in dump; let the stronger one win on-device)
copy_bin vendor/bin/hw/android.hardware.security.keymint-service-qti bin/hw/android.hardware.security.keymint-service-qti
copy_bin vendor/bin/hw/android.hardware.gatekeeper-service-qti bin/hw/android.hardware.gatekeeper-service-qti
copy_bin vendor/bin/hw/android.hardware.keymaster@4.0-service-qti bin/hw/android.hardware.keymaster@4.0-service-qti

echo "== libs: SPU keymint/weaver chain =="
for l in libspukeymint.so libspukeymintutils.so libspukeymintdeviceutils.so \
         libspukeymintprovision.so libspuclient.so vendor.qti.hardware.spu-V2-ndk.so \
         libqti-utils.so libspcom.so libqcbor.so libcrypto.so \
         libkeymaster_messages.so libkeymasterdeviceutils.so libgatekeeper.so \
         android.hardware.security.keymint-V3-ndk.so android.hardware.security.keymint-V2-ndk.so \
         android.hardware.security.rkp-V3-ndk.so \
         android.hardware.security.secureclock-V1-ndk.so android.hardware.security.sharedsecret-V2-ndk.so \
         android.hardware.common-V2-ndk.so android.system.suspend-V1-ndk.so \
         android.hardware.weaver-V2-ndk.so android.hardware.gatekeeper-V1-ndk.so; do
  copy_lib "$l"
done

echo "== libs: qseecom/ssgtzd chain =="
for l in libQSEEComAPI.so libdrmfs.so libminkdescriptor.so libdmabufheap.so \
         libqrtr.so libminksocket_vendor.so libqmi_common_so.so libqmi_csi.so libqmi_cci.so \
         libdsi_netctrl.so libjsoncpp.so vendor.qti.hardware.qseecom-V1-ndk.so \
         vendor.qti.hardware.qseecom@1.0.so libxml.so libxml2.so libseclog.so libqdi.so \
         libqmi.so libqmi_encdec.so libqmi_client_qmux.so libqmi_client_helper.so libqmiservices.so \
         libdiag.so libdsutils.so libidl.so libnicm.so libnicm_dsi.so libnicm_utils.so \
         libconfigdb.so libmdmdetect.so libnetutils.so libssl.so \
         libion.so libvmmem.so; do
  copy_lib "$l"
done

echo "== libs: non-SPU fallback chain =="
for l in libqtikeymint.so libqtikeymaster4.so libkeymasterutils.so \
         android.hardware.keymaster@4.0.so android.hardware.keymaster@4.1.so \
         android.hardware.keymaster@3.0.so libhardware_legacy.so; do
  copy_lib "$l"
done

echo "== libs: hw-subdir gatekeeper impls =="
copy_lib libqtigatekeeper.so hw
copy_lib libspuqtigatekeeper.so hw
copy_lib libEseUtils.so hw
copy_lib vendor.qti.hardware.qseecom@1.0-impl.so hw

echo "== rc files (stock, verbatim) =="
cp -f "$DUMP_DIR/vendor/etc/init/ssgtzd.rc" "$V/etc/init/ssgtzd.rc"
cp -f "$DUMP_DIR/vendor/etc/init/vendor.qti.hardware.qseecom@1.0-service.rc" "$V/etc/init/qseecom-service.rc"

echo "== rc files (recovery-adapted, peridot pattern) =="
cat > "$V/etc/init/qseecomd.rc" <<'EOF'
# Adapted for recovery from vendor/etc/init/qseecomd.rc (stock leap dump).
service vendor.qseecomd /vendor/bin/qseecomd
    socket notify-topology stream 660 system drmrpc
    class core
    user root
    group root drmrpc
    setenv LD_LIBRARY_PATH /vendor/lib64:/vendor/lib64/hw:/system/lib64:/sbin
    disabled
    seclabel u:r:recovery:s0
EOF

mk_service() { # filename binary extra_groups
  cat > "$V/etc/init/$1" <<EOF
# Adapted for recovery from the stock leap dump (peridot pattern:
# root + recovery secontext + explicit vendor LD_LIBRARY_PATH).
service $2 /vendor/bin/hw/$3
    class early_hal
    user root
    group root $4
    setenv LD_LIBRARY_PATH /vendor/lib64:/vendor/lib64/hw:/system/lib64:/sbin
    disabled
    seclabel u:r:recovery:s0
EOF
}
mk_service android.hardware.security.keymint-service-spu-qti.rc vendor.keymint-spu-qti android.hardware.security.keymint-service-spu-qti drmrpc
mk_service android.hardware.gatekeeper-service-spu-qti.rc vendor.gatekeeper_spu android.hardware.gatekeeper-service-spu-qti ""
mk_service android.hardware.security.keymint-service-qti.rc vendor.keymint-qti android.hardware.security.keymint-service-qti drmrpc
mk_service android.hardware.gatekeeper-service-qti.rc vendor.gatekeeper_default android.hardware.gatekeeper-service-qti ""

cat > "$V/etc/init/android.hardware.weaver-service-spu-qti.rc" <<'EOF'
# Adapted for recovery from vendor/etc/init/android.hardware.weaver-service-spu-qti.rc.
# Stock gates on ro.boot.product.vendor.sku={pineapple,sun}; recovery forces
# the start after vendor modules load (see init.recovery.leap.rc).
service vendor.spu_weaver /vendor/bin/hw/android.hardware.weaver-service-spu-qti
    disabled
    class hal
    user root
    group root drmrpc
    setenv LD_LIBRARY_PATH /vendor/lib64:/vendor/lib64/hw:/system/lib64:/sbin
    capabilities WAKE_ALARM
    seclabel u:r:recovery:s0
EOF

cat > "$V/etc/init/vendor.qti.hardware.qseecom@1.0-service.rc" <<'EOF'
# Adapted for recovery from vendor/etc/init/vendor.qti.hardware.qseecom@1.0-service.rc.
service qseecom-service /vendor/bin/hw/vendor.qti.hardware.qseecom@1.0-service
    class hal
    user root
    group root drmrpc
    setenv LD_LIBRARY_PATH /vendor/lib64:/vendor/lib64/hw:/system/lib64:/sbin
    disabled
    seclabel u:r:recovery:s0
    interface aidl vendor.qti.hardware.qseecom
EOF

echo "== vintf fragments (stock, verbatim) =="
cp -f "$DUMP_DIR/vendor/etc/vintf/manifest/android.hardware.security.keymint-service-qti.xml" "$V/etc/vintf/manifest/"
cp -f "$DUMP_DIR/vendor/etc/vintf/manifest/android.hardware.weaver-service-spu-qti.xml" "$V/etc/vintf/manifest/"
cp -f "$DUMP_DIR/vendor/etc/vintf/manifest/vendor.qti.hardware.qseecom@1.0-service.xml" "$V/etc/vintf/manifest/"
cp -f "$RROOT/system/etc/vintf/manifest/boot-service.qti.xml" "$V/etc/vintf/manifest/"

echo "== trigger rc: start HALs once vendor modules are loaded =="
mkdir -p "$TREE_DIR/recovery/root"
cat > "$TREE_DIR/recovery/root/init.recovery.leap.rc" <<'EOF'
# leap: bring up the SPU decrypt stack after TWRP loads vendor_dlkm modules.
on property:twrp.modules.loaded=true
    mkdir /firmware
    mount vfat /dev/block/bootdevice/by-name/modem${ro.boot.slot_suffix} /firmware ro
    wait /sys/class/power_supply/battery
    start vendor.qseecomd
    start qseecom-service
    start vendor.keymint-spu-qti
    start vendor.gatekeeper_spu
    start vendor.spu_weaver
    umount /firmware
    start vendor.health-recovery
EOF

echo "== ssg TA config (offline-capable part) =="
if [ -f "$DUMP_DIR/vendor/etc/ssg/ta_config.json" ]; then
  mkdir -p "$V/etc/ssg"
  cp -f "$DUMP_DIR/vendor/etc/ssg/ta_config.json" "$V/etc/ssg/ta_config.json"
fi

echo "== vendor manifest.xml (keymint/gatekeeper/weaver/qseecom) =="
cat > "$V/etc/vintf/manifest.xml" <<'EOF'
<manifest version="4.0" type="device" target-level="8">
    <hal format="aidl">
        <name>android.hardware.security.keymint</name>
        <version>3</version>
        <fqname>IKeyMintDevice/default</fqname>
    </hal>
    <hal format="aidl">
        <name>android.hardware.security.keymint</name>
        <version>3</version>
        <fqname>IRemotelyProvisionedComponent/default</fqname>
    </hal>
    <hal format="aidl">
        <name>android.hardware.security.secureclock</name>
        <fqname>ISecureClock/default</fqname>
    </hal>
    <hal format="aidl">
        <name>android.hardware.security.sharedsecret</name>
        <fqname>ISharedSecret/default</fqname>
    </hal>
    <hal format="aidl">
        <name>android.hardware.gatekeeper</name>
        <fqname>IGatekeeper/default</fqname>
    </hal>
    <hal format="aidl">
        <name>android.hardware.weaver</name>
        <version>2</version>
        <interface>
            <name>IWeaver</name>
            <instance>default</instance>
        </interface>
    </hal>
    <hal format="aidl">
        <name>vendor.qti.hardware.qseecom</name>
        <fqname>IQSEECom/default</fqname>
    </hal>
    <hal format="aidl">
        <name>android.hardware.boot</name>
        <fqname>IBootControl/default</fqname>
    </hal>
    <sepolicy>
        <version>35.0</version>
    </sepolicy>
</manifest>
EOF

echo "== TA firmware placeholder (needs adb pull from device) =="
cat > "$V/firmware_mnt/image/README.txt" <<'EOF'
TA firmware lives in the modem partition (/vendor/firmware_mnt/image) and is
NOT in the ROM dump. Pull from the running phone and drop the files here:
  adb pull /vendor/firmware_mnt/image/ <tree>/recovery/root/vendor/firmware_mnt/image/
Remove this README once real TA blobs land. Until then /data decrypt is UNVERIFIED.
EOF

echo "staged OK -> $V"
