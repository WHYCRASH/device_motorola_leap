#
# Copyright (C) 2026 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2026 The OrangeFox Recovery Project
#

DEVICE_PATH := device/motorola/leap

# Building with minimal manifest
ALLOW_MISSING_DEPENDENCIES := true

# Architecture (leap is 64-bit-only; no 2nd arch)
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := leap
TARGET_NO_BOOTLOADER := true
TARGET_USES_UEFI := true

# Platform
TARGET_BOARD_PLATFORM := sun
TARGET_BOARD_PLATFORM_GPU := qcom-adreno830

# Kernel (prebuilt GKI 6.6 Image from stock boot.img; recovery carries no kernel)
BOARD_KERNEL_PAGESIZE := 4096
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
BOARD_KERNEL_IMAGE_NAME := Image
BOARD_BOOT_HEADER_VERSION := 4
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --pagesize $(BOARD_KERNEL_PAGESIZE)
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/kernel
BOARD_USES_GENERIC_KERNEL_IMAGE := true

# Ramdisk use lz4 (stock recovery ramdisk is LZ4)
BOARD_RAMDISK_USE_LZ4 := true

# A/B (dedicated recovery partition; kernel excluded like stock)
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true

AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    boot \
    init_boot \
    vendor_boot \
    dtbo \
    vbmeta \
    vbmeta_system \
    recovery \
    system \
    system_ext \
    product \
    vendor \
    vendor_dlkm \
    system_dlkm

# Verified Boot
BOARD_AVB_ENABLE := true

# Partitions
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 134217728

# Dynamic partitions (super 9126805504, all erofs; no odm on this device)
BOARD_SUPER_PARTITION_SIZE := 9126805504
BOARD_SUPER_PARTITION_GROUPS := motorola_dynamic_partitions
BOARD_MOTOROLA_DYNAMIC_PARTITIONS_SIZE := 9122611200
BOARD_MOTOROLA_DYNAMIC_PARTITIONS_PARTITION_LIST := system system_ext product vendor vendor_dlkm system_dlkm

BOARD_PARTITION_LIST := $(call to-upper, $(BOARD_MOTOROLA_DYNAMIC_PARTITIONS_PARTITION_LIST))
$(foreach p, $(BOARD_PARTITION_LIST), $(eval BOARD_$(p)IMAGE_FILE_SYSTEM_TYPE := erofs))
$(foreach p, $(BOARD_PARTITION_LIST), $(eval TARGET_COPY_OUT_$(p) := $(call to-lower, $(p))))

BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs

# File systems
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
BOARD_USES_VENDOR_DLKMIMAGE := true

# Workaround for error copying vendor files to recovery ramdisk
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_COPY_OUT_VENDOR := vendor

# Recovery
BOARD_HAS_LARGE_FILESYSTEM := true
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888

# Crypto (FBEv2 + wrappedkey metadata; leap uses SPU keymint)
FIXED_DECRYPT := true
TW_INCLUDE_CRYPTO := $(FIXED_DECRYPT)
TW_INCLUDE_CRYPTO_FBE := $(FIXED_DECRYPT)
TW_INCLUDE_FBE_METADATA_DECRYPT := $(FIXED_DECRYPT)
BOARD_USES_QCOM_FBE_DECRYPTION := $(FIXED_DECRYPT)
TW_USE_FSCRYPT_POLICY := 2

BOARD_USES_METADATA_PARTITION := true
PLATFORM_VERSION := 99.87.36
PLATFORM_SECURITY_PATCH := 2127-12-31
PLATFORM_VERSION_LAST_STABLE := $(PLATFORM_VERSION)
VENDOR_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)
BOOT_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)

# Tool
TW_INCLUDE_REPACKTOOLS := true
TW_INCLUDE_RESETPROP := true
TW_INCLUDE_LIBRESETPROP := true
TW_INCLUDE_LPDUMP := true
TW_INCLUDE_LPTOOLS := true

# Debug
TARGET_USES_LOGD := true
TWRP_INCLUDE_LOGCAT := true

# Fastbootd
TW_INCLUDE_FASTBOOTD := true

# Other TWRP configurations
TW_THEME := portrait_hdpi
RECOVERY_SDCARD_ON_DATA := true
TARGET_RECOVERY_QCOM_RTC_FIX := true
TW_EXCLUDE_DEFAULT_USB_INIT := true
TW_USE_TOOLBOX := true
TARGET_USES_MKE2FS := true
TW_INPUT_BLACKLIST := "hbtp_vm"
# Standard QCOM brightness path - UNVERIFIED on leap, confirm on-device (Phase 6)
TW_BRIGHTNESS_PATH := "/sys/class/backlight/panel0-backlight/brightness"
TW_EXTRA_LANGUAGES := true
TW_DEFAULT_LANGUAGE := en
TW_NO_SCREEN_BLANK := true
TW_EXCLUDE_APEX := true
TW_USE_SERIALNO_PROPERTY_FOR_DEVICE_ID := true

# Touch + battery + SPU support modules, loaded at runtime from mounted vendor_dlkm
TW_LOAD_VENDOR_MODULES := "touchscreen_mmi.ko goodix_brl_mmi.ko focaltech_v3_5.ko panel_event_notifier.ko qti_battery_charger.ko spcom.ko spss_utils.ko qcom_spss.ko qsee_ipc_irq_bridge.ko qseecom_proxy.ko"
TW_LOAD_VENDOR_MODULES_EXCLUDE_GKI := true
TW_BATTERY_SYSFS_WAIT_SECONDS := 6
