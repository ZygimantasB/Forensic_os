# ForensicOS - Project Plan

## Overview

ForensicOS is a bootable USB-based Linux distribution purpose-built for digital forensics investigators. Based on Ubuntu/Debian, it provides a complete forensic workstation that boots from USB, automatically write-blocks evidence drives, and provides tools for disk imaging, file recovery, memory analysis, timeline analysis, and chain-of-custody reporting.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                   ForensicOS                         │
├─────────────┬───────────────┬───────────────────────┤
│  GUI Launch │   CLI Tools   │   Reporting Engine    │
│   (Zenity/  │  (forensic-*) │   (HTML/PDF/JSON)     │
│    YAD)     │               │                       │
├─────────────┴───────────────┴───────────────────────┤
│              Core Forensic Library                   │
│  (write-block, hashing, imaging, evidence mgmt)     │
├─────────────────────────────────────────────────────┤
│           System Services & udev Rules               │
│  (auto write-block, audit logging, case tracking)   │
├─────────────────────────────────────────────────────┤
│        Ubuntu/Debian Base (live-build)               │
│  (kernel, filesystem, bootloader, base packages)    │
└─────────────────────────────────────────────────────┘
```

---

## Development Phases

### Phase 1: Foundation (Build System & Base OS)
- **live-build configuration** for creating bootable ISO/USB
- Base package list (forensic tools from repos)
- Custom kernel parameters (no swap, no automount)
- Boot splash and branding
- UEFI + Legacy BIOS boot support

### Phase 2: Write-Blocking & Evidence Integrity
- **udev rules** to auto-mount all non-boot drives as read-only
- Software write-blocker service
- Audit logging of all device events
- SHA256 hash logging for all evidence operations

### Phase 3: Core Forensic Tools
- **forensic-imager**: Disk imaging (dd, dcfldd, ewfacquire for E01)
- **forensic-hasher**: Hash verification (MD5, SHA1, SHA256, SHA512)
- **forensic-mount**: Safe evidence mounting (read-only, loop, various FS)
- **forensic-carver**: File carving wrapper (foremost, scalpel, photorec)
- **forensic-timeline**: Timeline generation (log2timeline/plaso)
- **forensic-memory**: Memory acquisition (LiME, AVML) and analysis (Volatility3)
- **forensic-network**: Network capture and analysis (tcpdump, tshark, NetworkMiner)
- **forensic-loganalysis**: Log parsing and correlation

### Phase 4: Case Management & Reporting
- Case initialization (case number, examiner, date, description)
- Evidence tracking with chain-of-custody logs
- Automated report generation (HTML + PDF)
- Evidence integrity verification reports
- Examiner notes and annotations

### Phase 5: User Interface
- **forensic-launcher**: CLI menu-driven interface
- **forensic-gui**: Simple GUI launcher (YAD/Zenity-based)
- Desktop shortcuts and system tray integration
- Quick-action toolbar for common operations

### Phase 6: Build, Test & Release
- Makefile for building ISO
- CI/CD pipeline (GitHub Actions)
- Automated testing of forensic tools
- Documentation and user guide

---

## Key Features for Forensic Investigators

| Feature | Tool | Description |
|---------|------|-------------|
| **Disk Imaging** | forensic-imager | Create bit-for-bit copies in raw (dd) or E01 format with hash verification |
| **Write Blocking** | udev + systemd service | Automatically prevents writes to evidence drives |
| **Hash Verification** | forensic-hasher | Compute and verify MD5/SHA1/SHA256 hashes for evidence integrity |
| **File Carving** | forensic-carver | Recover deleted files using signature-based carving |
| **Timeline Analysis** | forensic-timeline | Generate filesystem/event timelines from evidence |
| **Memory Forensics** | forensic-memory | Acquire and analyze RAM dumps |
| **Network Forensics** | forensic-network | Capture and analyze network traffic |
| **Log Analysis** | forensic-loganalysis | Parse Windows/Linux/application logs |
| **Case Management** | forensic-case | Track cases, evidence, and chain of custody |
| **Reporting** | forensic-report | Generate professional forensic reports |
| **Safe Mounting** | forensic-mount | Mount evidence with read-only guarantees |

---

## Included Third-Party Tools

### Pre-installed from repositories:
- `sleuthkit` - File system forensic analysis
- `autopsy` - Digital forensics GUI
- `foremost` / `scalpel` - File carving
- `dcfldd` - Enhanced dd with hashing
- `ewf-tools` (libewf) - E01/EWF image support
- `hashdeep` / `md5deep` - Recursive hashing
- `volatility3` - Memory forensics
- `plaso` / `log2timeline` - Timeline analysis
- `bulk_extractor` - Extract features from disk images
- `binwalk` - Firmware analysis
- `wireshark` / `tshark` - Network protocol analysis
- `tcpdump` - Network packet capture
- `testdisk` / `photorec` - Data recovery
- `guymager` - GUI forensic imager
- `regripper` - Windows registry analysis
- `yara` - Malware pattern matching
- `clamav` - Antivirus scanning
- `exiftool` - Metadata extraction
- `strings` - Extract text from binaries
- `xxd` / `hexdump` - Hex viewers

---

## Repository Structure

```
Forensic_os/
├── PLAN.md                          # This plan
├── Makefile                         # Build orchestration
├── config/
│   ├── live-build/                  # live-build configuration
│   │   ├── auto/
│   │   │   ├── config              # lb config options
│   │   │   ├── build               # lb build options
│   │   │   └── clean               # lb clean options
│   │   ├── config/
│   │   │   ├── package-lists/
│   │   │   │   ├── forensic-tools.list.chroot
│   │   │   │   └── system-base.list.chroot
│   │   │   ├── includes.chroot/    # Files to include in live filesystem
│   │   │   ├── hooks/              # Build hooks
│   │   │   └── bootloaders/        # Custom bootloader config
│   │   └── README.md
│   ├── udev/                       # udev rules for write-blocking
│   │   └── 99-forensic-writeblock.rules
│   └── systemd/                    # systemd services
│       ├── forensic-writeblock.service
│       └── forensic-audit.service
├── tools/
│   ├── forensic-imager              # Disk imaging tool
│   ├── forensic-hasher              # Hash verification
│   ├── forensic-mount               # Safe evidence mounting
│   ├── forensic-carver              # File carving wrapper
│   ├── forensic-timeline            # Timeline analysis
│   ├── forensic-memory              # Memory acquisition/analysis
│   ├── forensic-network             # Network forensics
│   ├── forensic-loganalysis         # Log analysis
│   ├── forensic-case                # Case management
│   └── forensic-report              # Report generation
├── lib/
│   └── forensic-common.sh           # Shared library functions
├── ui/
│   ├── forensic-launcher            # CLI menu launcher
│   ├── forensic-gui                 # GUI launcher (YAD/Zenity)
│   └── desktop/
│       ├── forensic-os.desktop      # Desktop shortcut
│       └── icons/                   # Application icons
├── templates/
│   ├── report-template.html         # HTML report template
│   ├── chain-of-custody.html        # Chain of custody form
│   └── case-notes.html              # Case notes template
├── tests/
│   ├── test-imager.sh
│   ├── test-hasher.sh
│   ├── test-writeblock.sh
│   └── test-common.sh
├── scripts/
│   ├── build-iso.sh                 # Build the ISO image
│   ├── write-usb.sh                 # Write ISO to USB drive
│   └── setup-dev.sh                 # Set up development environment
└── .github/
    └── workflows/
        └── build.yml                # CI/CD build pipeline
```

---

## Technology Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Base OS | Ubuntu 24.04 LTS | LTS stability, wide hardware support, large package repos |
| Build System | live-build | Standard Debian/Ubuntu live system builder |
| Shell | Bash | Universal, no extra dependencies |
| GUI Framework | YAD (Yet Another Dialog) | Lightweight, powerful GTK dialogs from shell scripts |
| Report Format | HTML → PDF (wkhtmltopdf) | Portable, professional, no heavy dependencies |
| Imaging Format | Raw (dd) + E01 (libewf) | Industry standard forensic formats |
| Hashing | sha256sum + hashdeep | Built-in + recursive/matching capabilities |
| Write Blocking | udev rules + kernel params | Kernel-level protection, no hardware needed |

---

## Development Agents & Skills

For ongoing development, these Claude Code capabilities will be used:

1. **General-purpose agents** - For implementing each forensic tool
2. **Explore agents** - For researching codebase patterns and dependencies
3. **Plan agents** - For designing complex subsystems
4. **simplify skill** - For code review and quality checks after implementation
5. **session-start-hook skill** - For CI/CD setup ensuring tests pass
6. **commit skill** - For clean git history management

---

## Getting Started (Development)

```bash
# Clone and enter the project
git clone <repo-url>
cd Forensic_os

# Set up development environment
./scripts/setup-dev.sh

# Build the ISO (requires root and live-build)
sudo make build

# Write to USB
sudo ./scripts/write-usb.sh /dev/sdX forensic-os.iso
```
