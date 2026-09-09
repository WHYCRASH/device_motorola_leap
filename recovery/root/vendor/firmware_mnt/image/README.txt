TA firmware lives in the modem partition (/vendor/firmware_mnt/image) and is
NOT in the ROM dump. Pull from the running phone and drop the files here:
  adb pull /vendor/firmware_mnt/image/ <tree>/recovery/root/vendor/firmware_mnt/image/
Remove this README once real TA blobs land. Until then /data decrypt is UNVERIFIED.
