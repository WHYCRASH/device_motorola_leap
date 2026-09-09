#
# Copyright (C) 2026 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/motorola/leap

# Inherit from device.mk configuration
$(call inherit-product, $(DEVICE_PATH)/device.mk)

# Release name
PRODUCT_RELEASE_NAME := leap

## Device identifier
PRODUCT_DEVICE := leap
PRODUCT_NAME := twrp_leap
PRODUCT_BRAND := motorola
PRODUCT_MODEL := motorola razr 60 ultra
PRODUCT_MANUFACTURER := motorola

# Assert
TARGET_OTA_ASSERT_DEVICE := leap
