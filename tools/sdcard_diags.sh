#!/system/bin/sh
# sdcard_diags.sh - Comprehensive sdcard0 diagnostic
# Version: 1.0.0
# Purpose: Diagnose internal storage (sdcard0) issues on CM11 S6500D
# Created by: RTheGeek with ChatGPT & ClaudeAI assistance
# Date: 2026-02-20

OUT="/data/local/tmp/sdcard_diag.out"
echo "====== SDCARD0 DIAGNOSTIC REPORT v1.0.0 ======" > "$OUT"
echo "Generated: $(date)" >> "$OUT"
echo "" >> "$OUT"

#==============================================================================
# SECTION 1: SERVICE STATUS
#==============================================================================
# PURPOSE: Check if critical storage services are running
# EXPECTED: 
#   - init.svc.fuse_sdcard0 = "running" (FUSE daemon serving /storage/sdcard0)
#   - init.svc.mount_sdcard0 = "stopped" (oneshot service - runs once then stops)
#   - init.svc.vold = "running" (volume daemon for sdcard1/external storage)
# PROBLEM INDICATORS:
#   - fuse_sdcard0 = "stopped" → FUSE daemon not started, storage inaccessible
#   - mount_sdcard0 = "running" → Service stuck, bind mount may have failed
#   - vold = "stopped" → External SD (sdcard1) won't work
echo "=== 1. SERVICE STATUS ===" >> "$OUT"
echo "[Checks: fuse_sdcard0, mount_sdcard0, vold services]" >> "$OUT"
echo "[Expected: fuse_sdcard0=running, mount_sdcard0=stopped, vold=running]" >> "$OUT"
getprop | grep -E "init.svc.fuse_sdcard0|init.svc.vold|init.svc.mount_sdcard0" >> "$OUT"
echo "" >> "$OUT"

#==============================================================================
# SECTION 2: STORAGE PROPERTIES
#==============================================================================
# PURPOSE: Check system properties related to storage initialization
# EXPECTED:
#   - vold.post_fs_data_done = "1" (vold finished post-fs-data initialization)
#   - sys.sdcard0.mounted = "1" (our bind mount script succeeded)
#   - Multiple init.svc.fuse_* = "running" (FUSE daemons for each storage)
# PROBLEM INDICATORS:
#   - sys.sdcard0.mounted = "0" or missing → bind mount failed
#   - vold.post_fs_data_done = "0" → system not fully initialized
echo "=== 2. STORAGE PROPERTIES ===" >> "$OUT"
echo "[Checks: System properties for storage, vold, FUSE, mount status]" >> "$OUT"
echo "[Expected: vold.post_fs_data_done=1, sys.sdcard0.mounted=1]" >> "$OUT"
getprop | grep -E "vold|storage|external|sdcard|mount" >> "$OUT"
echo "" >> "$OUT"
getprop | grep -iE "fuse|emulat|persist" >> "$OUT"
echo "" >> "$OUT"

#==============================================================================
# SECTION 3: MOUNT STATUS
#==============================================================================
# PURPOSE: Verify bind mount and FUSE mounts exist
# EXPECTED:
#   1. /dev/block/mmcblk0p18 /mnt/media_rw/sdcard0 ext4
#      → This is the BIND MOUNT created by mount_sdcard0.sh
#      → Maps /data partition to backing directory for FUSE
#   2. /dev/fuse /storage/sdcard0 fuse ... user_id=1023,group_id=1023
#      → This is the FUSE mount that apps actually access
#      → Serves content from /mnt/media_rw/sdcard0 with proper permissions
#   3. Exit code: 0 for mountpoint test
#      → Confirms /storage/sdcard0 is an active mount point
# PROBLEM INDICATORS:
#   - Missing mmcblk0p18 mount → bind mount failed (core issue!)
#   - Missing /dev/fuse mount → FUSE daemon not serving storage
#   - Exit code: 1 → /storage/sdcard0 not mounted
echo "=== 3. MOUNT STATUS ===" >> "$OUT"
echo "[Checks: Bind mount (mmcblk0p18→sdcard0) and FUSE mounts]" >> "$OUT"
echo "[Expected: mmcblk0p18 at /mnt/media_rw/sdcard0, /dev/fuse at /storage/sdcard0]" >> "$OUT"
echo "" >> "$OUT"
echo "[All storage-related mounts:]" >> "$OUT"
mount | grep -E "sdcard|fuse|media_rw|emulated|storage" >> "$OUT" 2>&1
echo "" >> "$OUT"

echo "[Mountpoint test for /storage/sdcard0:]" >> "$OUT"
mountpoint -q /storage/sdcard0
echo "Exit code: $?" >> "$OUT"
echo "[Exit code 0 = mounted, 1 = not mounted]" >> "$OUT"
echo "" >> "$OUT"

#==============================================================================
# SECTION 4: DIRECTORY CONTENTS
#==============================================================================
# PURPOSE: Verify directory structure and permissions throughout storage stack
# EXPECTED PERMISSIONS (with -Z flag showing SELinux contexts):
#   /storage/sdcard0/: drwxrwx--x root sdcard_r u:object_r:fuse:s0
#   /data/media/0/: drwxrwxr-x media_rw media_rw u:object_r:system_data_file:s0
#   /mnt/media_rw/sdcard0/: drwxrwx--- media_rw media_rw
#
# EXPECTED STANDARD FOLDERS (auto-created by framework):
#   Alarms, Android, DCIM, Download, Movies, Music, Notifications, 
#   Pictures, Podcasts, Ringtones
#
# PROBLEM INDICATORS:
#   - /storage/sdcard0/ empty → FUSE not serving content or bind mount failed
#   - Wrong ownership (not media_rw) → permission issues, apps can't access
#   - Wrong SELinux context → access denied by security policy
#   - Missing standard folders → framework didn't initialize storage
echo "=== 4. DIRECTORY CONTENTS ===" >> "$OUT"
echo "[Checks: Directory structure, permissions, SELinux contexts, standard folders]" >> "$OUT"
echo "[Expected: Standard folders present, media_rw ownership, proper SELinux contexts]" >> "$OUT"
echo "" >> "$OUT"

echo "[/storage/] - User-facing mount points:" >> "$OUT"
ls -laZ /storage 2>/dev/null >> "$OUT" 2>&1
echo "" >> "$OUT"

echo "[/storage/sdcard0/] - What users/apps see (via FUSE):" >> "$OUT"
echo "[Expected: Alarms, Android, DCIM, Download, Music, etc.]" >> "$OUT"
ls -laZ /storage/sdcard0 2>/dev/null >> "$OUT" 2>&1
echo "" >> "$OUT"

echo "[/data/media/] - Actual storage location:" >> "$OUT"
echo "[Expected: '0' directory (user 0) and 'obb' directory]" >> "$OUT"
ls -laZ /data/media/ 2>/dev/null >> "$OUT" 2>&1
echo "" >> "$OUT"

echo "[/data/media/0/] - Real files location (what bind mount sources from):" >> "$OUT"
echo "[Expected: Same folders as /storage/sdcard0/]" >> "$OUT"
ls -laZ /data/media/0/ 2>/dev/null >> "$OUT" 2>&1
echo "" >> "$OUT"

echo "[/mnt/media_rw/sdcard0/] - Bind mount target (what FUSE daemon reads):" >> "$OUT"
echo "[Expected: Identical to /data/media/0/ - this IS /data/media/0/ via bind mount]" >> "$OUT"
ls -laZ /mnt/media_rw/sdcard0/ 2>/dev/null >> "$OUT" 2>&1
echo "" >> "$OUT"

echo "[/mnt/shell/emulated/] - Legacy emulated storage location:" >> "$OUT"
echo "[Expected: Does not exist on this ROM (not using emulated storage model)]" >> "$OUT"
ls -laZ /mnt/shell/emulated/ 2>/dev/null >> "$OUT" 2>&1
echo "" >> "$OUT"

echo "[/storage/emulated/] - Legacy emulated storage symlink:" >> "$OUT"
echo "[Expected: Does not exist (we use direct /storage/sdcard0)]" >> "$OUT"
ls -laZ /storage/emulated/ 2>/dev/null >> "$OUT" 2>&1
echo "" >> "$OUT"

echo "[/mnt/media_rw/] - Parent directory for all media_rw mounts:" >> "$OUT"
echo "[Expected: sdcard0 and sdcard1 directories present]" >> "$OUT"
ls -laZ /mnt/media_rw/ 2>/dev/null >> "$OUT" 2>&1
echo "" >> "$OUT"

#==============================================================================
# SECTION 5: FUSE DAEMON PROCESSES
#==============================================================================
# PURPOSE: Check if FUSE daemons are running and with correct parameters
# EXPECTED:
#   Two /system/bin/sdcard processes:
#   1. PID xxx: /system/bin/sdcard -u 1023 -g 1023 -d /mnt/media_rw/sdcard0 /storage/sdcard0
#   2. PID xxx: /system/bin/sdcard -u 1023 -g 1023 -d /mnt/media_rw/sdcard1 /storage/sdcard1
#
# PARAMETERS EXPLAINED:
#   -u 1023 = user ID (media_rw)
#   -g 1023 = group ID (media_rw) 
#   -d = source directory (backing storage)
#   Last param = destination (what apps access)
#
# PROBLEM INDICATORS:
#   - Only one sdcard process → sdcard0 daemon didn't start
#   - Wrong source directory → serving wrong location
#   - Process missing entirely → service didn't start
echo "=== 5. FUSE DAEMON PROCESSES ===" >> "$OUT"
echo "[Checks: FUSE daemon processes serving storage to apps]" >> "$OUT"
echo "[Expected: Two /system/bin/sdcard processes (one for sdcard0, one for sdcard1)]" >> "$OUT"
echo "" >> "$OUT"
ps | grep sdcard >> "$OUT"
echo "" >> "$OUT"

echo "[Daemon command lines - shows what each daemon is serving:]" >> "$OUT"
for PID in $(ps | grep sdcard | grep -v grep | awk '{print $2}'); do
  if [ -f /proc/$PID/cmdline ]; then
    echo -n "PID $PID: " >> "$OUT"
    cat /proc/$PID/cmdline | tr '\0' ' ' >> "$OUT"
    echo "" >> "$OUT"
  fi
done
echo "" >> "$OUT"

#==============================================================================
# SECTION 6: VDC VOLUME STATUS
#==============================================================================
# PURPOSE: Check what vold (volume daemon) knows about storage volumes
# EXPECTED (with our fix):
#   - sdcard1 present in list (external SD managed by vold)
#   - sdcard0 NOT present in list (we bypass vold entirely)
#   - "vdc volume mount /storage/sdcard0" fails with error 406
#     (this is CORRECT - vold doesn't know about sdcard0)
#
# VOLUME STATE CODES:
#   0 = No-Media
#   1 = Idle-Unmounted  
#   2 = Pending
#   3 = Checking
#   4 = Mounted
#
# PROBLEM INDICATORS (if unfixed ROM):
#   - sdcard0 present with state 2 (Pending) → stuck, can't mount
#   - sdcard0 present with state 0 (No-Media) → vold can't find device
echo "=== 6. VDC VOLUME STATUS ===" >> "$OUT"
echo "[Checks: What vold (volume daemon) knows about storage]" >> "$OUT"
echo "[Expected: sdcard1 listed (state 4=Mounted), sdcard0 NOT listed (we bypass vold)]" >> "$OUT"
echo "[Volume states: 0=No-Media, 1=Idle, 2=Pending, 3=Checking, 4=Mounted]" >> "$OUT"
echo "" >> "$OUT"

echo "[vdc volume list:]" >> "$OUT"
vdc volume list >> "$OUT" 2>&1
echo "" >> "$OUT"

echo "[vdc volume mount /storage/sdcard0 attempt:]" >> "$OUT"
echo "[Expected: Error 406 'No such file or directory' - vold doesn't manage sdcard0]" >> "$OUT"
vdc volume mount /storage/sdcard0 >> "$OUT" 2>&1
echo "" >> "$OUT"

#==============================================================================
# SECTION 7: MOUNTSERVICE STATUS  
#==============================================================================
# PURPOSE: Check framework's view of storage state (THIS IS CRITICAL!)
# EXPECTED (with framework patch):
#   mPath=/storage/sdcard0
#   mPrimary=true
#   mEmulated=false
#   mState=mounted        ← THIS IS THE KEY FIX!
#   Current state: mounted
#
# PROBLEM INDICATORS (unfixed ROM):
#   - mState=removed → MountService doesn't recognize storage (MAIN ISSUE!)
#   - mState=unmounted → Framework initialized but not marked as ready
#   - Missing sdcard0 entry → MountService never initialized volume
#
# WHY THIS MATTERS:
#   Apps check MountService.getVolumeState() before accessing storage
#   If MountService reports "removed" or "unmounted", apps refuse to work
#   Our framework patch forces this to "mounted" regardless of vold
echo "=== 7. MOUNTSERVICE STATUS ===" >> "$OUT"
echo "[Checks: Framework's view of storage state - CRITICAL FOR APP COMPATIBILITY]" >> "$OUT"
echo "[Expected: mState=mounted for sdcard0 (this is what apps check!)]" >> "$OUT"
echo "" >> "$OUT"

echo "[Full MountService state:]" >> "$OUT"
dumpsys mount | head -60 >> "$OUT" 2>&1
echo "" >> "$OUT"

echo "[sdcard0 specific - LOOK FOR mState=mounted:]" >> "$OUT"
dumpsys mount | grep -A10 "mPath=/storage/sdcard0" >> "$OUT" 2>&1
echo "" >> "$OUT"

#==============================================================================
# SECTION 8: CONFIGURATION FILES
#==============================================================================
# PURPOSE: Verify boot configuration matches our fix
# EXPECTED:
#   /fstab.qcom:
#     - sdcard0 voldmanaged line COMMENTED OUT or REMOVED
#     - sdcard1 voldmanaged line present (for external SD)
#
#   /system/etc/vold.fstab:
#     - File should NOT exist (we removed experimental entries)
#
# PROBLEM INDICATORS:
#   - Uncommented sdcard0 voldmanaged line → vold will interfere
#   - vold.fstab exists with sdcard0 entry → conflicts with our approach
echo "=== 8. CONFIGURATION FILES ===" >> "$OUT"
echo "[Checks: Boot configuration files that control storage mounting]" >> "$OUT"
echo "[Expected: sdcard0 voldmanaged line removed/commented, vold.fstab absent]" >> "$OUT"
echo "" >> "$OUT"

echo "[/fstab.qcom - voldmanaged lines:]" >> "$OUT"
echo "[Expected: sdcard0 line commented out, sdcard1 line active]" >> "$OUT"
grep voldmanaged /fstab.qcom >> "$OUT" 2>&1
echo "" >> "$OUT"

echo "[/system/etc/vold.fstab (if exists):]" >> "$OUT"
echo "[Expected: File does not exist]" >> "$OUT"
if [ -f /system/etc/vold.fstab ]; then
  cat /system/etc/vold.fstab >> "$OUT" 2>&1
else
  echo "File does not exist (correct)" >> "$OUT"
fi
echo "" >> "$OUT"

#==============================================================================
# SECTION 9: VOLD LOGS
#==============================================================================
# PURPOSE: Check vold initialization logs for errors
# EXPECTED:
#   - vold starts successfully
#   - sdcard1 transitions: Initializing → No-Media → Pending → Idle → Mounted
#   - NO sdcard0 transitions (vold doesn't manage it)
#   - MountService logs: "got storage path: /storage/sdcard0" (framework knows about it)
#
# PROBLEM INDICATORS:
#   - Errors about sdcard0 → vold is trying to manage it (should be bypassed)
#   - sdcard0 stuck in "Pending" → vold can't find device
#   - "volume state changed for /storage/sdcard0 (unmounted -> removed)" 
#     → Framework marking as removed (unfixed ROM)
echo "=== 9. VOLD & SDCARD0 LOGS ===" >> "$OUT"
echo "[Checks: Boot logs from vold and MountService initialization]" >> "$OUT"
echo "[Expected: No errors, sdcard0 NOT mentioned in vold logs (bypassed)]" >> "$OUT"
echo "" >> "$OUT"

echo "[Recent vold and sdcard0 related log entries:]" >> "$OUT"
logcat -d -b main -b system 2>/dev/null | grep -iE "vold|sdcard0" | tail -60 >> "$OUT" 2>&1
echo "" >> "$OUT"

echo "[Sysfs block device paths - hardware detection:]" >> "$OUT"
echo "[Expected: mmcblk0 → msm_sdcc.3 (internal eMMC), mmcblk1 → msm_sdcc.1 (external SD)]" >> "$OUT"
ls -la /sys/block/ 2>/dev/null | grep mmc >> "$OUT" 2>&1
echo "" >> "$OUT"

#==============================================================================
# SECTION 10: FRAMEWORK STORAGE LOGS
#==============================================================================
# PURPOSE: Check framework services handling of storage
# EXPECTED:
#   - MountService initializes sdcard0 at boot
#   - ExternalStorage provider sees storage
#   - MtpService adds storage for USB file transfer
#   - No errors about "Missing UUID" (informational warning, not critical)
#
# PROBLEM INDICATORS:
#   - Errors about storage initialization failing
#   - MountService never mentions sdcard0
#   - Apps reporting storage unavailable in logs
echo "=== 10. FRAMEWORK STORAGE LOGS ===" >> "$OUT"
echo "[Checks: Framework services handling storage (MountService, MTP, etc.)]" >> "$OUT"
echo "[Expected: MountService and MtpService recognize sdcard0]" >> "$OUT"
echo "" >> "$OUT"

echo "[MountService/StorageManager/ExternalStorage:]" >> "$OUT"
logcat -d -b main 2>/dev/null | grep -iE "MountService|VolumeManager|sdcard0|ExternalStorage|StorageManager|MtpService" | tail -40 >> "$OUT" 2>&1
echo "" >> "$OUT"

#==============================================================================
# SECTION 11: FILE CREATION TEST
#==============================================================================
# PURPOSE: Functional test - can we actually write to storage?
# EXPECTED: 
#   "SUCCESS: File created at /storage/sdcard0/"
#
# PROBLEM INDICATORS:
#   - "FAILED: Cannot create file" → permissions issue or storage not writable
#   - "Permission denied" error → SELinux or ownership problem
#
# THIS IS THE ULTIMATE TEST:
#   If this succeeds, storage is functional at the filesystem level
#   If apps still don't work, it's a framework state issue (Section 7)
echo "=== 11. FILE CREATION TEST ===" >> "$OUT"
echo "[Checks: Can we actually write to storage? (Ultimate functionality test)]" >> "$OUT"
echo "[Expected: SUCCESS - file creation works]" >> "$OUT"
echo "" >> "$OUT"
touch /storage/sdcard0/diagnostic_test.txt 2>&1 >> "$OUT" && echo "SUCCESS: File created at /storage/sdcard0/" >> "$OUT" || echo "FAILED: Cannot create file at /storage/sdcard0/" >> "$OUT"
rm /storage/sdcard0/diagnostic_test.txt 2>/dev/null
echo "" >> "$OUT"

#==============================================================================
# REPORT FOOTER
#==============================================================================
echo "====== END DIAGNOSTIC REPORT ======" >> "$OUT"
echo "" >> "$OUT"
echo "=== QUICK DIAGNOSIS GUIDE ===" >> "$OUT"
echo "" >> "$OUT"
echo "IF STORAGE WORKS:" >> "$OUT"
echo "  • Section 7 shows: mState=mounted ✓" >> "$OUT"
echo "  • Section 3 shows: bind mount present ✓" >> "$OUT"
echo "  • Section 11 shows: File creation SUCCESS ✓" >> "$OUT"
echo "" >> "$OUT"
echo "IF STORAGE BROKEN:" >> "$OUT"
echo "  • Section 7 shows mState=removed → Framework patch missing/failed" >> "$OUT"
echo "  • Section 3 missing bind mount → mount_sdcard0.sh not running" >> "$OUT"
echo "  • Section 1 shows fuse_sdcard0=stopped → FUSE daemon didn't start" >> "$OUT"
echo "  • Section 11 shows FAILED → Permissions or mount issue" >> "$OUT"
echo "" >> "$OUT"
echo "SHARE THIS OUTPUT WITH AI (ChatGPT/ClaudeAI) FOR ANALYSIS" >> "$OUT"
echo "" >> "$OUT"

# Display to stdout
cat "$OUT"