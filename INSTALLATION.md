# Installation Guide

Complete step-by-step installation instructions for CM11 with storage fix.

## Prerequisites

### Required
- Samsung Galaxy Mini 2 (**S6500D** - note the "D"!)
- TWRP 3.0.2.0 recovery installed
- External SD card (recommended for file transfer)
- Backup of all your data

### Downloads
1. **Patched ROM**: [Download Link]
2. **GApps** (optional): [Download Link]
3. **TWRP Recovery**: [Download Link]

## Installation Steps

### 1. Preparation

**Backup your data** - this is a full wipe:
```
- Contacts (export to Google or VCF file)
- Photos/Videos (copy to PC)
- App data (use Titanium Backup if available)
- SMS/Call logs
```

Copy ROM ZIP to external SD card.

### 2. Boot to Recovery

**Method 1**: Via ADB
```bash
adb reboot recovery
```

**Method 2**: Hardware buttons
- Power off device
- Hold Volume Up + Home + Power
- Release when you see Samsung logo

### 3. Wipe Everything

**Important**: Full wipe is required for clean installation!

#### Step 3a: Format Data
```
Wipe → Format Data → Type "yes" → Confirm
```

#### Step 3b: Advanced Wipe
```
Wipe → Advanced Wipe → Select:
☑ Dalvik / ART Cache
☑ Cache  
☑ System
☑ Data
☑ Internal Storage

Swipe to Wipe →
```

#### Step 3c: Unmount Partitions
```
Mount → UNCHECK:
☐ System
☐ Data
☐ Cache

(Leave external SD mounted)
```

### 4. Install ROM
```
Install → Navigate to external SD → Select ROM ZIP →
Swipe to confirm flash →
Wait for installation... →
```

**⚠️ CRITICAL: Do NOT wipe Dalvik/Cache after flashing!**

### 5. Install GApps (Optional)
```
Install → Select GApps ZIP →
Swipe to confirm flash →
```

### 6. Reboot
```
Reboot System →
```

**First boot takes 5-10 minutes - be patient!**

## Verification

After system boots:

### Method 1: Visual Check
1. Open **Settings → Storage**
2. You should see "Internal storage" with available space
3. Connect to PC via USB
4. Both storages should appear in Windows/Mac

### Method 2: App Test
1. Open **Camera** app
2. Take a photo
3. Photo should save successfully
4. Open **Gallery** to confirm photo is there

### Method 3: Diagnostic Script
```bash
adb shell
sdcard_diags.sh
```

Look for:
- Section 7: `mState=mounted` ✅
- Section 11: `File creation SUCCESS` ✅

## Troubleshooting

### Issue: Bootloop

**Cause**: Dalvik/Cache wiped after flashing ROM

**Solution**:
1. Reboot to TWRP
2. Repeat installation from Step 3
3. **Remember**: Don't wipe after flashing!

### Issue: Storage Still Empty

**Cause**: Patch didn't apply correctly

**Check**:
```bash
adb shell
ls -la /system/bin/mount_sdcard0.sh
```

**Expected**: File should exist

**If missing**: Re-flash ROM

### Issue: Apps Say "No SD Card"

**Check MountService state**:
```bash
adb shell
dumpsys mount | grep -A5 "sdcard0"
```

**Expected**: `mState=mounted`

**If shows "removed"**: Framework patch failed, re-flash

### Issue: MTP Not Working

**Solution**:
1. Go to Settings → Developer Options
2. Toggle "USB debugging" off and on
3. Disconnect and reconnect USB cable
4. Select "Media device (MTP)" on phone

## Post-Installation

### Recommended Apps
- **File Manager**: Use built-in or install Solid Explorer
- **Camera**: Built-in Camera works perfectly now
- **Backup**: Titanium Backup (requires root)

### Performance Tips
- Disable animations: Developer Options → Animation scale → 0.5x
- Limit background processes: Developer Options → Background process limit → 3
- Enable ART runtime: Already enabled (CM11 default)

## Need Help?

- **Diagnostic script**: Run `sdcard_diags.sh` and share output
- **XDA Thread**: [Link to thread]
- **GitHub Issues**: Report bugs here

---

**Enjoy your fully functional CM11 on S6500D!** 🎉