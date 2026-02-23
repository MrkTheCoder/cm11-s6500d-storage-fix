# ROM Development Toolkit Guide

A comprehensive guide for modifying Android ROM files on Linux (Xubuntu).

---

## Contents

- [Package Requirements](#package-requirements)
- [Installation](#installation)
  - [1. Installing Xubuntu Minimal](#1-installing-xubuntu-minimal)
  - [2. Installing Required Packages](#2-installing-required-packages)
- [General Workflow](#general-workflow)
- [Working with boot.img](#working-with-bootimg)
  - [Unpacking boot.img](#unpacking-bootimg)
  - [Editing Files](#editing-files)
  - [Repacking boot.img](#repacking-bootimg)
- [Working with JAR Files](#working-with-jar-files)
  - [Decompiling JAR Files](#decompiling-jar-files)
  - [Editing Smali Code](#editing-smali-code)
  - [Recompiling JAR Files](#recompiling-jar-files)
- [Helpful Tips & Commands](#helpful-tips--commands)
- [Troubleshooting](#troubleshooting)

---

## Package Requirements

### Required Tools & Packages

| OS/App Name | Installation Command / URL | Description |
|-------------|---------------------------|-------------|
| **Xubuntu 24.04 LTS** | [xubuntu.org/download](https://xubuntu.org/download/) | Lightweight Ubuntu variant with Xfce desktop (Minimal ISO recommended) |
| **apktool** | `sudo apt install apktool` | Decompile/recompile APK and JAR files to/from smali bytecode |
| **Android Image Kitchen** | [GitHub: osm0sis/Android-Image-Kitchen](https://github.com/osm0sis/Android-Image-Kitchen) | Unpack/repack boot.img and recovery.img files |
| **android-tools-adb** | `sudo apt install android-tools-adb` | Android Debug Bridge - communicate with Android devices |
| **android-tools-fastboot** | `sudo apt install android-tools-fastboot` | Flash images to Android devices in bootloader mode |
| **git** | `sudo apt install git` | Version control system (required for cloning AIK) |
| **cpio** | `sudo apt install cpio` | Archive tool for ramdisk manipulation |
| **gzip** | `sudo apt install gzip` | Compression tool for ramdisk files |
| **lz4** | `sudo apt install liblz4-tool` | Fast compression (used by some boot.img formats) |
| **squashfs-tools** | `sudo apt install squashfs-tools` | Tools for squashfs filesystem (some ROM images) |
| **wget** | `sudo apt install wget` | Download files from command line |
| **curl** | `sudo apt install curl` | Transfer data with URLs (alternative to wget) |
| **p7zip-full** | `sudo apt install p7zip-full` | 7-Zip command-line archiver |
| **unzip** | `sudo apt install unzip` | Extract ZIP archives |
| **zip** | `sudo apt install zip` | Create ZIP archives (essential for ROM repacking) |
| **openjdk-8-jdk** | `sudo apt install openjdk-8-jdk` | Java Development Kit 8 (required for apktool) |
| **python3** | `sudo apt install python3 python3-pip` | Python runtime (some tools require it) |
| **perl** | `sudo apt install perl` | Perl interpreter (required by AIK scripts) |
| **file** | `sudo apt install file` | Identify file types |
| **Mousepad** | `sudo apt install mousepad` | Lightweight GUI text editor with syntax highlighting |
| **PeaZip** | `sudo apt install peazip` or [peazip.github.io](https://peazip.github.io/) | GUI archive manager for extracting/creating ROM ZIPs |
| **GtkHash** | `sudo apt install gtkhash` | GUI hash calculator (MD5, SHA-1, SHA-256, CRC32) |
| **rhash** | `sudo apt install rhash` | Command-line hash calculator with recursive folder support |
| **tree** | `sudo apt install tree` | Display directory structure in tree format |
| **nano** | `sudo apt install nano` | Simple terminal text editor (backup option) |
| **vim** | `sudo apt install vim` | Advanced terminal text editor |

### One-Line Installation Command

```bash
sudo apt update && sudo apt install -y apktool android-tools-adb android-tools-fastboot git cpio gzip liblz4-tool squashfs-tools wget curl p7zip-full unzip zip openjdk-8-jdk python3 python3-pip perl file mousepad peazip gtkhash rhash tree nano vim
```

### Manual Installation: Android Image Kitchen

```bash
cd ~
git clone https://github.com/osm0sis/Android-Image-Kitchen.git
cd Android-Image-Kitchen
chmod +x unpackimg.sh repackimg.sh cleanup.sh
```

---

## Installation

### 1. Installing Xubuntu Minimal

**Recommended Setup:**

For ROM development, we recommend installing Xubuntu in a virtual machine if your system has:
- ✅ 4GB+ RAM (8GB+ recommended)
- ✅ SSD storage (for faster compilation)
- ✅ 50GB+ free disk space

**Virtual Machine Options:**
- **VMware Workstation** (recommended for performance)
- **VirtualBox** (free and open source)

**Physical Installation:**
- Install directly on hardware for maximum performance
- Dual-boot with existing OS if desired

**Download Xubuntu:**
- Get Xubuntu Minimal ISO: [xubuntu.org/download](https://xubuntu.org/download/)
- Choose "Minimal Installation" during setup to keep system lightweight
- Select "Download updates while installing" and "Install third-party software"

### 2. Installing Required Packages

After Xubuntu is installed and running, open **Terminal** and run:

```bash
# Update package lists
sudo apt update

# Install all required packages
sudo apt install -y apktool android-tools-adb android-tools-fastboot git cpio gzip liblz4-tool squashfs-tools wget curl p7zip-full unzip zip openjdk-8-jdk python3 python3-pip perl file mousepad peazip gtkhash rhash tree nano vim

# Clone Android Image Kitchen
cd ~
git clone https://github.com/osm0sis/Android-Image-Kitchen.git
cd Android-Image-Kitchen
chmod +x *.sh

# Verify installations
apktool --version
adb version
java -version
```

---

## General Workflow

**Understanding the ROM Modification Process:**

When modifying ROM files, you'll follow this general pattern regardless of file type:

1. **Extract** - Get the file from the ROM ZIP
   - GUI method: Use **PeaZip** to open ZIP and drag-drop files
   - CLI method: Use `unzip` or `7z` commands

2. **Unpack/Decompile** - Access source code
   - For **boot.img**: Unpack to access ramdisk files (readable text)
   - For **JAR files**: Decompile to smali bytecode (editable)

3. **Edit** - Modify the unpacked/decompiled files
   - Use **Mousepad** text editor (GUI)
   - Or terminal editors: `nano`, `vim`
   - Edit configuration files, smali code, scripts, etc.

4. **Repack/Recompile** - Reverse the process
   - For **boot.img**: Repack ramdisk and boot image
   - For **JAR files**: Recompile smali back to DEX bytecode

5. **Replace** - Put modified file back in ROM ZIP
   - GUI method: Use **PeaZip** to add/replace files
   - CLI method: Use `zip` command to update archive

6. **Verify** - Calculate checksums
   - GUI method: Use **GtkHash** (right-click → Checksums)
   - CLI method: Use `md5sum`, `sha1sum`, or `rhash`

**Important Notes:**
- ⚠️ Always backup original files before modifying
- ⚠️ Keep ROM structure intact (folder hierarchy matters)
- ⚠️ Test modifications on device before sharing
- ⚠️ Document all changes you make

---

## Working with boot.img

The `boot.img` file contains the kernel and ramdisk. The ramdisk includes critical initialization scripts like `init.qcom.rc` and filesystem configuration in `fstab.qcom`.

### Unpacking boot.img

**Step 1: Extract boot.img from ROM ZIP**

Using **PeaZip** (GUI):
```
Right-click ROM ZIP → PeaZip → Open archive → 
Navigate to boot.img → Extract to folder
```

Using command line:
```bash
# Create working directory
mkdir -p ~/rom-work/boot
cd ~/rom-work/boot

# Extract boot.img from ROM
unzip ~/Downloads/rom.zip boot.img
```

**Step 2: Unpack boot.img with Android Image Kitchen**

```bash
# Copy boot.img to AIK directory
cp boot.img ~/Android-Image-Kitchen/

# Navigate to AIK
cd ~/Android-Image-Kitchen

# Unpack the boot image
./unpackimg.sh boot.img
```

**Output:**
```
Android Image Kitchen - UnpackImg Script
by osm0sis @ xda-developers

Splitting image...
Done!

Unpacked kernel: kernel
Unpacked ramdisk: ramdisk/
```

**Step 3: Navigate to unpacked ramdisk**

```bash
cd ~/Android-Image-Kitchen/ramdisk
ls -la
```

You'll see files like:
```
init
init.qcom.rc        ← Configuration script (example target)
init.rc
fstab.qcom         ← Filesystem table
default.prop
...
```

### Editing Files

**Using Mousepad (GUI):**

```bash
# Open file in Mousepad
mousepad init.qcom.rc &
```

The `&` symbol keeps the terminal free while Mousepad runs.

**Example edit** - Adding a service to `init.qcom.rc`:

```bash
# Find the appropriate section (e.g., after other services)
# Add your custom service definition:

service mount_sdcard0 /system/bin/sh /system/bin/mount_sdcard0.sh
    class core
    user root
    group root
    oneshot
    seclabel u:r:init:s0
```

**Save the file** in Mousepad (Ctrl+S) and close.

**Using terminal editors:**

```bash
# Using nano (simpler)
nano init.qcom.rc

# Using vim (advanced)
vim init.qcom.rc
```

### Repacking boot.img

**Step 1: Repack the modified ramdisk and boot image**

```bash
cd ~/Android-Image-Kitchen

# Repack boot.img
./repackimg.sh
```

**Output:**
```
Android Image Kitchen - RepackImg Script
by osm0sis @ xda-developers

Packing ramdisk...
Done!

Building image...
Done!

New image: image-new.img
```

**Step 2: Rename and verify**

```bash
# Rename to boot.img
mv image-new.img boot-modified.img

# Verify file size (should be similar to original)
ls -lh boot*.img

# Calculate hash
sha1sum boot-modified.img
```

**Step 3: Clean up for next modification**

```bash
# Clean up AIK workspace
./cleanup.sh
```

**Step 4: Replace boot.img in ROM ZIP**

Using **PeaZip**:
```
Open ROM ZIP → Navigate to boot.img → 
Delete old boot.img → 
Add your boot-modified.img → 
Rename to boot.img
```

Using command line:
```bash
# Update boot.img in ROM ZIP
cd ~/rom-work
zip -u rom.zip boot-modified.img
# Or replace directly
zip -d rom.zip boot.img
zip -u rom.zip boot-modified.img
# Rename inside zip if needed
```

---

## Working with JAR Files

JAR (Java Archive) files like `services.jar` contain Android framework code compiled to DEX bytecode. We decompile to **smali** (human-readable assembly) to edit.

### Decompiling JAR Files

**Step 1: Extract JAR file from ROM**

Using **PeaZip**:
```
Open ROM ZIP → system/framework/services.jar → 
Extract to folder
```

Using command line:
```bash
# Create working directory
mkdir -p ~/rom-work/framework
cd ~/rom-work/framework

# Extract from ROM
unzip ~/Downloads/rom.zip system/framework/services.jar
```

**Step 2: Decompile with apktool**

```bash
cd ~/rom-work/framework

# Decompile services.jar
apktool d system/framework/services.jar
```

**Output:**
```
I: Using Apktool 2.x.x
I: Loading resource table...
I: Baksmaling classes.dex...
I: Copying assets and libs...
I: Copying unknown files...
I: Copying original files...
```

**Result:**
- Creates folder: `services.jar.out/`
- Contains: `smali/` (decompiled code), `original/`, `apktool.yml`

**Step 3: Navigate to smali code**

```bash
cd services.jar.out/smali
```

The `smali/` directory mirrors Java package structure:
```
smali/
├── android/
├── com/
│   └── android/
│       └── server/
│           ├── MountService.smali      ← Example target
│           ├── PackageManagerService.smali
│           └── ...
└── ...
```

### Editing Smali Code

**Finding the target file:**

```bash
# Search for a specific smali file
find . -name "MountService.smali"

# Output:
# ./com/android/server/MountService.smali
```

**Open in Mousepad:**

```bash
mousepad ./com/android/server/MountService.smali &
```

**Example edit** - Adding code to force storage state:

Find the method (search for method name):
```smali
.method private updatePublicVolumeState(Landroid/os/storage/StorageVolume;Ljava/lang/String;)V
    .locals 11
    .param p1, "volume"
    .param p2, "state"
    
    # Add your patch here:
    const-string v6, "/storage/sdcard0"
    invoke-virtual {v4, v6}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v6
    if-eqz v6, :skip_sdcard0_fix
    
    const-string p2, "mounted"
    
    :skip_sdcard0_fix
    # Original code continues...
```

**Important smali editing tips:**
- Don't modify `.line` numbers
- Maintain proper indentation
- Match register counts (`.locals`)
- Test label names don't conflict (`:label_name`)
- Comments start with `#`

**Save changes** (Ctrl+S) and close Mousepad.

### Recompiling JAR Files

**Step 1: Recompile with apktool**

```bash
cd ~/rom-work/framework

# Recompile the modified smali back to DEX
apktool b services.jar.out
```

**Output:**
```
I: Using Apktool 2.x.x
I: Checking whether sources has changed...
I: Smaling smali folder into classes.dex...
I: Building apk file...
I: Copying unknown files...
I: Built apk into: services.jar.out/dist/services.jar
```

**Step 2: Verify compilation**

```bash
# Check if output was created
ls -lh services.jar.out/dist/services.jar

# Compare size with original (should be similar)
ls -lh system/framework/services.jar
ls -lh services.jar.out/dist/services.jar
```

**Step 3: Replace in ROM**

```bash
# Copy recompiled JAR over original
cp services.jar.out/dist/services.jar system/framework/services.jar

# Calculate hash for verification
sha1sum system/framework/services.jar
```

**Step 4: Update ROM ZIP**

Using **PeaZip**:
```
Open ROM ZIP → Navigate to system/framework/services.jar →
Delete old services.jar →
Add your modified services.jar
```

Using command line:
```bash
cd ~/rom-work
zip -u rom.zip system/framework/services.jar
```

---

## Helpful Tips & Commands

### Running GUI Apps in Background

**Command:** `command &`

The `&` symbol runs the command in the background, freeing up your terminal.

```bash
# Open Mousepad without blocking terminal
mousepad myfile.txt &

# Open file manager at current location
xdg-open . &

# Open multiple files in background
mousepad file1.txt &
mousepad file2.txt &
```

**Why it's useful:**
- Continue using terminal while editing files
- Launch multiple GUI applications from one terminal
- Keep scripts running while you work

---

### Opening File Manager at Current Location

**Command:** `sudo xdg-open . &`

Opens the GUI file manager in the current directory with elevated permissions.

```bash
# Open file manager here
xdg-open . &

# Open file manager with root privileges
sudo xdg-open . &

# Open specific directory
xdg-open ~/rom-work &
```

**Options explained:**
- `xdg-open` - Opens files/folders with default application
- `.` - Current directory
- `&` - Run in background
- `sudo` - Run as root (for accessing system directories)

**Alternative:**
```bash
# Using Thunar (Xfce file manager) directly
thunar . &
sudo thunar . &
```

---

### Making Scripts Executable

**Command:** `chmod +x script.sh`

Sets the executable permission bit, allowing the script to run.

```bash
# Make script executable
chmod +x myscript.sh

# Now you can run it
./myscript.sh

# Make multiple scripts executable
chmod +x *.sh
```

**Permission modes explained:**
- `chmod +x` - Add execute permission for all users
- `chmod 755` - rwxr-xr-x (owner: rwx, group: rx, others: rx)
- `chmod 644` - rw-r--r-- (owner: rw, group: r, others: r)
- `chmod u+x` - Add execute for user only
- `chmod go-w` - Remove write permission from group and others

**Verify permissions:**
```bash
ls -l myscript.sh
# Output: -rwxr-xr-x  1 user group  1234 date time myscript.sh
#         ↑ executable bit set
```

---

### Detailed File Listing with Permissions

**Command:** `ls -laZ`

Shows detailed file information including hidden files, permissions, ownership, and SELinux contexts.

```bash
# List all files with full details
ls -laZ

# List specific directory
ls -laZ /system/bin/

# List without SELinux context (if not supported)
ls -la
```

**Options explained:**
- `-l` - Long format (detailed information)
- `-a` - All files (including hidden files starting with `.`)
- `-h` - Human-readable sizes (KB, MB, GB)
- `-Z` - SELinux security context (important for Android)

**Output format:**
```
drwxr-xr-x  2 user group u:object_r:system_data_file:s0  4096 Feb 20 10:00 folder/
-rw-r--r--  1 user group u:object_r:system_data_file:s0  1234 Feb 20 10:00 file.txt
↑          ↑ ↑    ↑     ↑                              ↑    ↑              ↑
type       │ own  group SELinux context                size date            name
perms      links
```

**Permission types:**
- `d` - Directory
- `-` - Regular file
- `l` - Symbolic link
- `rwx` - Read, Write, Execute (for owner/group/others)

---

### Finding Files by Name

**Command:** `find /path -name "filename"`

Searches for files recursively in directory tree.

```bash
# Find a specific file in current directory
find . -name "MountService.smali"

# Find all smali files
find . -name "*.smali"

# Find in specific directory
find ~/rom-work -name "services.jar"

# Case-insensitive search
find . -iname "mountservice.smali"

# Find and show full path
find /path -name "file" -type f

# Find directories only
find . -name "smali" -type d
```

**Options explained:**
- `.` - Current directory (or specify path)
- `-name "pattern"` - Match filename pattern
- `-iname` - Case-insensitive name match
- `-type f` - Files only
- `-type d` - Directories only
- `-type l` - Symbolic links only

**Advanced examples:**
```bash
# Find and execute command on results
find . -name "*.smali" -exec grep -l "MountService" {} \;

# Find modified in last 7 days
find . -name "*.img" -mtime -7

# Find larger than 10MB
find . -name "*.jar" -size +10M

# Find and list details
find . -name "boot.img" -ls
```

**Useful for ROM development:**
```bash
# Find all init scripts
find ramdisk/ -name "init*.rc"

# Find specific smali class
find smali/ -name "*MountService*.smali"

# Find all JAR files in system
find system/ -name "*.jar"
```

---

### Calculating Checksums

**GUI Method - GtkHash:**

```bash
# Install GtkHash
sudo apt install gtkhash

# Launch
gtkhash &

# Or right-click file in file manager:
# Right-click → Checksums → Select hash types → Calculate
```

**Command Line - Single File:**

```bash
# MD5
md5sum boot.img

# SHA-1
sha1sum boot.img

# SHA-256
sha256sum boot.img

# CRC32 (requires rhash)
rhash --crc32 boot.img

# All hashes at once (rhash)
rhash --md5 --sha1 --crc32 boot.img
```

**Command Line - Multiple Files:**

```bash
# Generate checksums for all files in directory
md5sum * > checksums.md5

# Recursive (all files in folder tree)
find . -type f -exec md5sum {} \; > all-checksums.md5

# Using rhash for folder (creates .sfv file)
rhash -r --crc32 --sfv ./

# Verify checksums
md5sum -c checksums.md5
```

**Create checksum report:**

```bash
# Generate comprehensive hash report
cat > generate-hashes.sh << 'EOF'
#!/bin/bash
FILE="$1"
echo "=== Checksums for $FILE ==="
echo "CRC32:  $(rhash --crc32 $FILE | awk '{print $1}')"
echo "MD5:    $(md5sum $FILE | awk '{print $1}')"
echo "SHA-1:  $(sha1sum $FILE | awk '{print $1}')"
echo "SHA-256: $(sha256sum $FILE | awk '{print $1}')"
EOF

chmod +x generate-hashes.sh
./generate-hashes.sh rom.zip
```

---

### Text Searching in Files

**Command:** `grep -r "search term" directory/`

Search for text patterns in files.

```bash
# Search for text in all files
grep -r "mount_sdcard0" .

# Search in specific file type
grep -r "sdcard0" . --include="*.rc"

# Case-insensitive
grep -ri "mountservice" .

# Show line numbers
grep -rn "voldmanaged" .

# Show surrounding context
grep -C 3 "storage" init.qcom.rc
```

**Options explained:**
- `-r` - Recursive search in directories
- `-i` - Case-insensitive
- `-n` - Show line numbers
- `-l` - Show only filenames (not content)
- `-C 3` - Show 3 lines of context around match
- `--include="*.ext"` - Only search specific file types

---

## Troubleshooting

### Common Issues

**Issue: apktool fails with "Could not find resources"**
```bash
# Solution: Use empty framework
apktool empty-framework-dir --force
apktool d services.jar
```

**Issue: Boot image won't unpack**
```bash
# Check boot.img format
file boot.img

# Try AIK cleanup and retry
cd ~/Android-Image-Kitchen
./cleanup.sh
./unpackimg.sh boot.img
```

**Issue: Modified ROM bootloops**
```bash
# Check if you wiped Dalvik/Cache after flashing (don't!)
# Flash original ROM first, then re-flash your modified version
# Check logcat for errors: adb logcat > boot-log.txt
```

**Issue: "Permission denied" when running scripts**
```bash
# Make script executable
chmod +x script.sh

# Or run with bash explicitly
bash script.sh
```

**Issue: Can't edit files in /system**
```bash
# Use sudo for file manager
sudo xdg-open /system &

# Or sudo for text editor
sudo mousepad /system/file.txt &
```

---

## Additional Resources

- **Android Image Kitchen**: [GitHub](https://github.com/osm0sis/Android-Image-Kitchen)
- **apktool Documentation**: [ibotpeaches.github.io/Apktool](https://ibotpeaches.github.io/Apktool/)
- **XDA Developers**: [forum.xda-developers.com](https://forum.xda-developers.com)
- **Smali/Baksmali**: [GitHub](https://github.com/JesusFreke/smali)

---

**Good luck with your ROM development!** 🚀