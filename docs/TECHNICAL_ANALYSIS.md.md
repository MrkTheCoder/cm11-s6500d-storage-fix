# Summary of Internal Storage Issues in CM11 for Samsung S6500D

## Developer: Jenad (XDA: cm-11-20180711-UNOFFICIAL-jenad.zip)

---

## Original Issues Found

### 1. **No Internal Storage Mount at Boot**
- **Problem**: `/storage/sdcard0` appeared empty despite files existing in `/data/media/0/`
- **Root Cause**: The FUSE daemon service `fuse_sdcard0` was defined but never started at boot
- **Evidence**: `init.qcom.rc` had service defined but no trigger to start it

### 2. **Missing Backing Storage**
- **Problem**: Even when manually starting `fuse_sdcard0`, storage remained empty
- **Root Cause**: The backing directory `/mnt/media_rw/sdcard0` had no bind mount from `/data/media/0`
- **Evidence**: FUSE daemon was serving an empty directory

### 3. **Incorrect voldmanaged Configuration**
- **Problem**: `fstab.qcom` pointed to non-existent hardware path
- **Original Line**: `/devices/platform/msm_sdcc.3/mmc_host auto auto defaults voldmanaged=sdcard0:23,noemulatedsd,nonremovable`
- **Issue**: 
  - Partition `:23` doesn't exist (actual data is on partition 18: `mmcblk0p18`)
  - Path `/msm_sdcc.3/mmc_host` exists but has no card without full path
  - Vold reported volume as "removed" to MountService

### 4. **Architectural Mismatch**
- **Problem**: CM11 framework expects vold to manage sdcard0, but device has no separate internal SD partition
- **Reality**: Internal storage should be emulated from `/data/media/0` (standard Android 4.4 KitKat approach)
- **Framework Issue**: This ROM's MountService was compiled without full emulated storage support

---

## Fixes Implemented

### Fix 1: Create Bind Mount Service
**File**: `/system/bin/mount_sdcard0.sh` (new file)
```bash
#!/system/bin/sh
sleep 2
mkdir -p /data/media/0
mount -o bind /data/media/0 /mnt/media_rw/sdcard0
if mountpoint -q /mnt/media_rw/sdcard0; then
    setprop sys.sdcard0.mounted 1
fi
```

**File**: `init.qcom.rc`
```
service mount_sdcard0 /system/bin/sh /system/bin/mount_sdcard0.sh
    class core
    user root
    group root
    oneshot
    seclabel u:r:init:s0
```

**Why**: Init's built-in `mount` command doesn't support bind mounts. Using an external service with proper shell mount works reliably.

### Fix 2: Enable FUSE Daemon
**File**: `init.qcom.rc`
```
service fuse_sdcard0 /system/bin/sdcard -u 1023 -g 1023 -d /mnt/media_rw/sdcard0 /storage/sdcard0
    class late_start
```

**Why**: Serves the bind-mounted storage through FUSE with proper permissions.

### Fix 3: Remove Broken voldmanaged Line
**File**: `fstab.qcom`
```
# vold managed volumes  
# REMOVED: /devices/platform/msm_sdcc.3/mmc_host   auto auto defaults voldmanaged=sdcard0:auto,nonremovable
/devices/platform/msm_sdcc.1/mmc_host   auto     auto     defaults         voldmanaged=sdcard1:auto,noemulatedsd
/devices/platform/msm_hsusb_host.0      auto     auto     defaults         voldmanaged=usbdisk:auto
```

**Why**: Vold can't mount what doesn't exist. Our bind mount bypasses vold entirely.

### Fix 4: Create Standard Folders
**Result**: Framework auto-creates standard folders (DCIM, Download, Music, etc.) when storage is properly mounted.

---

## Current State

### ✅ **What Works:**
1. Internal storage accessible at `/storage/sdcard0`
2. Files persist across reboots in `/data/media/0/`
3. File Manager can create/read/write files
4. All standard Android folders auto-created
5. Proper permissions through FUSE (media_rw → sdcard_r mapping)

### ❌ **What Doesn't Work:**
1. **Apps don't detect storage**: Camera, Sound Recorder, Tasker, etc. report "no SD present"
2. **MTP doesn't show internal storage**: When connected to PC, only external SD card visible
3. **MountService reports "removed"**: `dumpsys mount` shows `mState=removed` for sdcard0

### 🔍 **Root Cause of Remaining Issues:**
- **MountService depends on vold**: Framework checks vold's volume state before allowing apps to use storage
- **Vold can't cooperate**: Vold expects removable vfat media it can mount/unmount, not an ext4 bind mount
- **Catch-22**: 
  - WITH voldmanaged line → vold reports "removed" (can't find media)
  - WITHOUT voldmanaged line → MountService never initializes sdcard0
  - EITHER WAY → Apps see storage as unavailable

---

## Technical Details for Reference

**Device**: Samsung Galaxy Mini 2 (S6500D)  
**Chipset**: MSM7x27A  
**Partition Layout**:
- `/dev/block/mmcblk0p16` = /system
- `/dev/block/mmcblk0p17` = /cache  
- `/dev/block/mmcblk0p18` = /data (956MB total)
- No separate internal SD partition

**Actual Device Path**:
```
/sys/devices/platform/msm_sdcc.3/mmc_host/mmc0/mmc0:0001/block/mmcblk0
```

---

## What Would Be Needed for Full Fix

To make apps work, one of these approaches is required:

### Option A: Framework Patching (Recommended)
Modify `services.jar` or `framework.jar` to make MountService accept sdcard0 as mounted without vold verification. This requires smali patching.

### Option B: Custom Vold Binary
Compile custom vold that can handle ext4 bind mounts and report them as mounted to MountService.

### Option C: Switch to Emulated Storage Model
Fully implement Android 4.4's emulated storage architecture with proper framework support (requires significant ROM changes).

---

## Files Modified (Summary)

**Boot Image (ramdisk)**:
- `init.qcom.rc` - Added bind mount service, enabled FUSE daemon
- `fstab.qcom` - Removed broken voldmanaged line

**System Partition**:
- `/system/bin/mount_sdcard0.sh` (new) - Performs bind mount at boot
- `/system/xbin/sdcard_diags.sh` (optional) - Diagnostic script

---

This fix makes internal storage functional for direct file access but doesn't solve the framework-level integration needed for full app compatibility.