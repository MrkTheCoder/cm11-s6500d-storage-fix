# Diagnostic Tools

## sdcard_diags.sh

**Comprehensive diagnostic script for analyzing internal storage (sdcard0) issues on Android devices.**

### Purpose

This script collects detailed information about:
- Storage mount status
- Service states (vold, FUSE daemons)
- Framework state (MountService)
- File permissions and SELinux contexts
- Configuration files
- System logs

### Usage

#### On Device (via ADB):
```bash
adb shell
sdcard_diags.sh
```

#### Or run directly:
```bash
adb push sdcard_diags.sh /data/local/tmp/
adb shell "chmod 755 /data/local/tmp/sdcard_diags.sh"
adb shell "/data/local/tmp/sdcard_diags.sh"
```

#### Save output to file:
```bash
adb shell "sdcard_diags.sh" > diagnostic-output.txt
```

### Output Sections

| Section | Purpose | Key Indicators |
|---------|---------|----------------|
| 1. Service Status | Check if storage services running | `fuse_sdcard0=running` |
| 2. Storage Properties | System properties for storage | `sys.sdcard0.mounted=1` |
| 3. Mount Status | Verify bind mount exists | `/dev/block/mmcblk0p18` mounted |
| 4. Directory Contents | File structure and permissions | Standard folders present |
| 5. FUSE Daemons | Check FUSE processes | Two sdcard daemons running |
| 6. VDC Status | Vold's view of volumes | sdcard0 NOT in vold list |
| 7. MountService | **CRITICAL**: Framework state | `mState=mounted` |
| 8. Configuration | Boot config files | voldmanaged line commented |
| 9. Vold Logs | Boot initialization logs | No sdcard0 errors |
| 10. Framework Logs | App-level storage handling | MountService recognizes sdcard0 |
| 11. Write Test | Functional test | File creation SUCCESS |

### Interpreting Results

#### ✅ Storage Working:
```
Section 7: mState=mounted
Section 3: Bind mount present
Section 11: File creation SUCCESS
```

#### ❌ Storage Broken:

**Symptom**: Section 7 shows `mState=removed`
- **Cause**: Framework patch missing or failed
- **Fix**: Re-flash patched services.jar

**Symptom**: Section 3 missing bind mount
- **Cause**: mount_sdcard0.sh not executing
- **Fix**: Check init.qcom.rc service definition

**Symptom**: Section 1 shows `fuse_sdcard0=stopped`
- **Cause**: FUSE daemon didn't start
- **Fix**: Check init.qcom.rc fuse service

**Symptom**: Section 11 file creation FAILED
- **Cause**: Permissions or mount issue
- **Fix**: Check SELinux contexts and ownership

### Example Outputs

**Before Fix**: [`before-fix-output.txt`](before-fix-output.txt)
- Shows `mState=removed`
- Missing bind mount
- Storage appears empty

**After Fix**: [`after-fix-output.txt`](after-fix-output.txt)
- Shows `mState=mounted`
- Bind mount present
- Full functionality restored

### AI Analysis

This script is designed to provide comprehensive output for AI analysis:

1. Copy the entire diagnostic output
2. Paste into ChatGPT or ClaudeAI
3. Ask: "Analyze this Android storage diagnostic. What's broken?"
4. AI will identify specific issues and suggest fixes

### Requirements

- Root access (via `adb root` or su)
- Android 4.4+ (tested on CM11)
- Basic shell commands: `getprop`, `mount`, `ls`, `dumpsys`

### Script Details

- **Version**: 1.0.0
- **Size**: ~17KB
- **Lines of code**: ~500
- **Output format**: Plain text
- **Output location**: `/data/local/tmp/sdcard_diag.out`

### Development

This script was created by RTheGeek with assistance from ChatGPT and ClaudeAI as part of the CM11 S6500D storage fix project.

### License

GPL-2.0 (matching CyanogenMod)