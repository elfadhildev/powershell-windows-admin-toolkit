<div align="center">

# 🚀 PowerShell Windows Admin Toolkit

**The Ultimate All-in-One GUI Toolkit for Windows 10 & 11 Management.**

[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-0078D6?style=for-the-badge&logo=windows)](https://github.com/elfadhildev)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?style=for-the-badge&logo=powershell)](https://microsoft.com/powershell)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)
[![Release](https://img.shields.io/badge/Release-v3.5.2-blueviolet?style=for-the-badge)](https://github.com/elfadhildev/powershell-windows-admin-toolkit/releases)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=for-the-badge)](http://makeapullrequest.com)

*Stop typing dozens of commands. Manage, optimize, and secure your Windows with a single click.*

[Key Features](#-key-features) • [Quick Start](#-quick-start) • [Screenshots](#-screenshots) • [Troubleshooting](#-troubleshooting) • [Roadmap](#-roadmap)

</div>

---

## 📖 Introduction

**PowerShell Windows Admin Toolkit** is a modern, lightweight, and fully graphical (GUI) administration utility built entirely on PowerShell and WPF (Windows Presentation Foundation). 

Inspired by modern system administration suites, this toolkit was designed from the ground up to provide a safer, more categorized, and visually appealing Dark Mode interface. Whether you are an IT professional, a system administrator, or an everyday user, this tool puts enterprise-grade system maintenance right at your fingertips.

> ⚠️ **Disclaimer:** Always create a **System Restore Point** (available in Option 8) before applying system-level tweaks or debloating. Use at your own risk.

---

## 📸 Screenshots


<div align="center">
  <img width="985" height="683" alt="Cuplikan layar 2026-11-01 233240" src="https://github.com/user-attachments/assets/1160e926-1b88-4be4-b6fc-175911911c70" />
  <br>
  <i>Main Control Panel Interface</i>
</div>

---

## ✨ Key Features (v3.5.2)

The toolkit features **15 distinct modules** categorized into 4 main pillars. Here is a complete breakdown of what the toolkit can do:

### 🧹 1. System Maintenance & Debloating
- **Pure Clean**: Deep maintenance that clears Temp, Prefetch, and DNS Cache. Also runs DISM, SFC, and cleanmgr in the background without freezing the UI.
- **Windows Debloater**: Safely removes 35+ built-in bloatware apps (Cortana, Bing, Xbox) categorized into 6 sections.
- **Startup Manager**: Deep-scans startup items from the Registry, Startup Folders, and Task Scheduler. Features safe **Disable** and **Enable** (Revert) modes.
- **System Tweaks**: 38 tweaks divided into *Essential* and *Advanced*. Includes **Preset Recommendations** (Minimal, Standard, Advanced, Clear).

### 📦 2. Application Management
- **Install Apps**: A mega-list of **231 applications** across 10 categories (Browsers, Dev, Games, Utilities, etc.) installed via Winget.
- **App Backup**: Export your currently installed apps to a `.json` file, or import them to a new PC for instant mass installation.
- **Automation Presets**: 1-click setup profiles. Instantly install apps for *Standard*, *Gamer*, or *Developer* workflows.

### 🛡️ 3. Security, Backup & Recovery
- **Restore Point**: Create and **Revert** to system restore points natively without opening the legacy Windows UI.
- **User Profile Backup**: GUI-driven Robocopy backup for Documents, Pictures, Desktop, and AppData. Includes real-time logging.
- **Update Manager**: Pause Windows updates for 1 year or 50 years. Enforce *Security-Only* updates to prevent feature-breaking updates.
- **One-Click Fixes**: Emergency repairs for Reset Network Stack (Winsock), Reset Update Cache, and Repair System Files (SFC/DISM).

### 📊 4. Diagnostics & Networking
- **System Audit**: Instantly checks hardware (CPU, RAM, Disk Health), Windows activation status, and faulty drivers.
- **Network Diagnostics**: Displays active TCP connections, PIDs, DNS status, and performs real-time network tracing.
- **Event Log Analyzer**: Scans the Event Viewer for critical errors over the last 7 days and provides actionable solutions.
- **DNS Switcher**: Instantly switch to Cloudflare, Google, AdGuard (Ad-blocking), or Quad9 for faster, safer browsing.

---

## ⚡ Quick Start

### Prerequisites
- Windows 10 or Windows 11 (x64/ARM64).
- PowerShell 5.1 (Built-in) or PowerShell 7+.
- Administrative privileges.
- Active Internet Connection (for Winget installations).

### One-Liner Installation
Open **PowerShell as Administrator** and paste the following command:

```powershell
irm https://raw.githubusercontent.com/elfadhildev/powershell-windows-admin-toolkit/main/toolkit.ps1 | iex
