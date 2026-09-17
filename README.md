# MediPill Monitor 💊

> **Intelligent IoT-Based Medication Planning, Reminder & Monitoring System**  
> *Production-ready Flutter application designed for an ESP32-powered, 4-container smart medicine box.*

[![Flutter](https://img.shields.io/badge/Flutter-3.9.0+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Analysis](https://img.shields.io/badge/flutter%20analyze-0%20issues-brightgreen.svg)]()
[![Tests](https://img.shields.io/badge/flutter%20test-28%20passed-brightgreen.svg)]()

---

## 📋 Table of Contents

- [Overview](#overview)
- [Physical Hardware Architecture (4 Reusable Containers)](#physical-hardware-architecture-4-reusable-containers)
- [Medical Safety & Terminology Safeguards](#medical-safety--terminology-safeguards)
- [Zero Demo Data & Genuine Empty States](#zero-demo-data--genuine-empty-states)
- [Persistent Local Storage](#persistent-local-storage)
- [Hardware & Simulation Mode Isolation](#hardware--simulation-mode-isolation)
- [Cross-Platform Adaptability](#cross-platform-adaptability)
- [Key Features](#key-features)
- [Design System & Accessibility](#design-system--accessibility)
- [Project Directory Structure](#project-directory-structure)
- [Getting Started](#getting-started)
- [Testing & Quality Verification](#testing--quality-verification)
- [Future ESP32 Hardware Integration](#future-esp32-hardware-integration)
- [License](#license)

---

## 🌟 Overview

**MediPill Monitor** is a clinical-grade, elderly-friendly medication management system built in Flutter. Designed to pair with a future physical IoT medicine dispenser powered by an **ESP32 microcontroller**, the application coordinates medication schedules, issues timely audio-visual reminders, logs physical container interactions via reed switches and load cells, and alerts caretakers upon consecutive unconfirmed events.

---

## ⚙️ Physical Hardware Architecture (4 Reusable Containers)

Unlike obsolete 7-compartment models where one compartment was dedicated to each day of the week, MediPill Monitor operates on **EXACTLY 4 REUSABLE PHYSICAL CONTAINERS**:

| Container | Time Slot | Typical Schedule | Reusability |
| :--- | :--- | :--- | :--- |
| **Container 1** | **Morning** | 08:00 AM | Reused Monday through Sunday |
| **Container 2** | **Afternoon** | 01:00 PM | Reused Monday through Sunday |
| **Container 3** | **Evening** | 08:00 PM | Reused Monday through Sunday |
| **Container 4** | **Night** | 10:00 PM | Reused Monday through Sunday |

### 7-Day Planning Matrix $\times$ 4 Containers
The physical box contains 4 physical containers, but patient schedules repeat throughout the entire 7-day calendar week (**Monday to Sunday**). Containers are refilled daily or on scheduled intervals. The 7-day weekly planner models rows as the 4 container slots and columns as the 7 calendar days.

---

## 🛡️ Medical Safety & Terminology Safeguards

MediPill Monitor strictly maintains clinical safety boundaries by reporting **observable device and application events**, never making unsupported clinical ingestion claims:

1. **No Ingestion Assumptions:**
   - The application **never** claims *"medicine swallowed"*, *"pill consumed"*, or *"verified ingestion"*.
   - Events are recorded strictly as:
     - `Medication Event Recorded` (User or device interaction logged)
     - `Container Interaction Detected` (Reed switch door opened/closed)
     - `Weight Change Detected` (Load cell measured $\Delta g$)
     - `Unconfirmed Event` (Scheduled dose window passed without confirmation)
     - `Missed Event` (Manually or threshold-flagged unconfirmed dose)
2. **Observable Recording Metrics (Not Clinical Adherence):**
   - Ratios and percentages are labeled as **"Scheduled Medication Events Recorded"** (e.g. `18 / 21 recorded (86%)`).
   - The UI explicitly clarifies: *"Calculated from observable device & application events (not clinical adherence)."*
3. **Weight & Quantity Safety:**
   - Raw load cell weight is displayed in grams with two decimal places (e.g., `14.50 g`).
   - Medicine inventory levels are categorized qualitatively as `Normal`, `Low`, or `Empty` (`Estimated Remaining`). Raw grams are never fabricated into exact tablet counts without lab calibration.
4. **Human-in-the-Loop OCR:**
   - Scanned prescription or label text flows through: `OCR Scan` $\rightarrow$ `Editable Draft` $\rightarrow$ `User Review/Correction` $\rightarrow$ `Explicit Confirmation` $\rightarrow$ `Save`. No OCR action auto-saves medical data without patient verification.
5. **Role-Tailored Notifications:**
   - **Patients:** Receive scheduled reminders with Snooze capabilities (5, 10, 15 minutes).
   - **Caretakers:** Only receive escalation alerts when consecutive missed/unconfirmed thresholds are breached (e.g., 1, 2, or 3 missed events) or if the IoT device drops offline.
   - **Doctors:** Access analytics dashboards without receiving routine daily medication push alarms.

---

## 🧼 Zero Demo Data & Genuine Empty States

MediPill Monitor does not rely on fabricated or hardcoded demonstration data in normal application usage:
- **Clean Startup:** The application initializes with clean empty states across all screens (Home, Weekly Plan, Medicines, History, Caretakers, and Doctor Analytics).
- **No Fabricated Numbers:** Percentages, recording ratios, and load-cell weights reflect strictly genuine user activities. No hardcoded statistics (e.g. `18 / 21`, `86%`, `High Recording Rate`) are displayed.
- **Dynamic 7-Day Plan Generation:** When real medications are created by the user, the application dynamically schedules doses across the Monday–Sunday weekly matrix across the 4 physical container slots.
- **Isolated Test Fixtures:** Sample datasets are strictly confined to `TestFixtures` in `lib/data/repositories/repositories.dart` for automated testing.

---

## 💾 Persistent Local Storage

The application leverages **`shared_preferences`** through a modular service layer ([`LocalPersistenceService`](lib/services/storage/local_persistence_service.dart)):
- **User Profiles & Accounts:** Active session and registered user credentials persist across app restarts.
- **Medications & Schedules:** Created medicines and dosage instructions are preserved.
- **Medication Events & Audit History:** Recorded, missed, or unconfirmed dose events are stored in local JSON format.
- **Caretaker Configurations:** Notification threshold preferences and contact rosters persist.
- **Simulation Mode Flag:** Developer simulation preferences are remembered.

---

## 🔌 Hardware & Simulation Mode Isolation

To uphold medical safety and avoid misleading users:
- **Disconnected by Default:** The `MockDeviceService` initializes in a completely disconnected state (`isConnected = false`, `isSimulated = false`). Default telemetry displays `"Device not connected"` / `"No physical device connected"` with `0.0 g` container weights and `"Empty"` status.
- **Explicit Testing Toggle:** Developer simulation mode can only be enabled via an explicit switch in the ESP32 Device Settings screen.
- **Unambiguous Banner:** When simulation mode is activated, the application prominently banners **`"SIMULATED DEVICE — TESTING"`** across telemetry cards and never masquerades as a live physical IoT device.

---

## 📱 Cross-Platform Adaptability

MediPill Monitor is engineered for responsive execution across **Mobile**, **Tablet**, **Desktop**, and **Web**:
- **Mobile (< 768px):** Clean bottom navigation bar with 5 primary destinations (`Home`, `Plan`, `Medicines`, `History`, `Settings`).
- **Desktop & Web (>= 768px):** Responsive left-anchored `NavigationRail` with max-width content constraints (800px–1000px) preventing stretched cards on wide displays.
- **Camera Scanning Fallback:** On desktop and web environments where mobile camera hardware is unavailable, tapping scan triggers an informative fallback modal:
  > *"Camera scanning is unavailable on this platform. You can upload an image or enter the medicine manually."*

---

## 🚀 Key Features

### 1. Home Dashboard
- **Medication Events Recorded Card:** Live ratio of scheduled events recorded derived from actual logs, or clean "No medication events recorded yet" empty state.
- **Next Upcoming Medication:** Prominent highlight card indicating the next due medicine, time, and assigned container number (1–4).
- **4-Container Quick Grid:** Instant status of Containers 1 to 4 with assigned time slots, current weights, door open/closed status, and inventory level pills.
- **Hardware Connection Banner:** Clear indication of real ESP32 connectivity, simulation testing mode, or disconnected status.

### 2. Weekly Medication Plan (Mon–Sun)
- Interactive **7-Day $\times$ 4-Container** schedule matrix.
- Week navigation with Previous Week, Next Week, and Quick "Current Week" buttons.
- Filter toolbar supporting filtering by medicine name, time slot, and status (`All`, `Recorded`, `Due Soon`, `Missed`, `Unconfirmed`).
- Tap-to-inspect detail bottom sheet displaying scheduled day, time, container ID, measured weight delta ($\Delta g$), and quick "Mark Recorded" or "Mark Missed" actions.

### 3. Medicines Directory & OCR Scanning
- Directory displaying active medications with container assignment indicators or a clean empty state with an [Add Medicine] action.
- **Equal-Path Add Medicine Flow:** Choose between `Scan Medicine Image` (OCR) or `Enter Manually`.
- Multi-medicine container assignment warning if multiple medicines share the same physical container slot.

### 4. History & Audit Log
- Searchable, chronological audit trail of all medication events.
- Filter by date range: *This Week*, *Previous Week*, *This Month*, or *All*.
- Clear provenance tracking: `IoT Device`, `Mobile`, or `Manual`.
- Logs load-cell weight delta $\Delta g$ and door transition timestamps.

### 5. Doctor Analytics Dashboard
- Patient monitoring summary calculated dynamically from actual recorded, unconfirmed, and missed events.
- **Medication Event Recording Trend (Mon–Sun):** Dynamic day-by-day table showing scheduled vs recorded event counts across the week.
- **4-Container Hardware Telemetry Logs:** Reed switch cycle counts and load-cell weight readings when hardware/simulator is linked.

### 6. Caretaker Oversight & Alert Escalation
- Caretaker roster with contact info and relationship badges.
- Configurable notification preferences:
  - Unconfirmed / Missed Medication Alerts
  - Consecutive Missed Thresholds (notify after 1, 2, or 3 unconfirmed events)
  - Low Medicine Level Warnings
  - IoT Device Offline Alerts

### 7. ESP32 Device Screen & Interactive Simulator
- Live telemetry for Containers 1 to 4.
- **Developer Simulation Controls:**
  - Toggle developer simulation mode on/off.
  - Toggle door reed switches open/closed for Containers 1, 2, 3, or 4.
  - Simulate weight reduction / dispense events (-0.5 g).
  - Toggle mock ESP32 WiFi gateway connection.

### 8. Streamlined Settings Screen
- Completely clean settings experience with the legacy Appearance section removed (no dead buttons or broken cards).
- Provides User Profile overview, direct links to Caretaker & Alerts configuration, Doctor Analytics, ESP32 Device Settings, and Sign Out.

---

## 🎨 Design System & Accessibility

MediPill Monitor utilizes a bespoke, non-generic healthcare palette crafted specifically for high contrast and readability:

| Element | Color Code | Purpose |
| :--- | :--- | :--- |
| **Brand Primary Start** | `#0B4A3F` | Deep Emerald brand gradient start |
| **Brand Primary End** | `#143C52` | Midnight Teal brand gradient end |
| **Background** | `#FAF7F2` | Warm Ivory calming background |
| **Card Surface** | `#FFFFFF` | High-contrast card surface |
| **Text Primary** | `#2A2826` | Soft Charcoal typography |
| **Text Secondary** | `#5A5652` | Muted Charcoal secondary labels |
| **Status: Recorded** | `#3F6B4F` | Flat solid forest green |
| **Status: Due Soon** | `#B9793A` | Warm amber |
| **Status: Missed** | `#7A2B3A` | Rich burgundy red |
| **Accent Gold** | `#B8935A` | Subtle highlight & high-completion gradient |

---

## 📁 Project Directory Structure

```
CHITTI/
├── lib/
│   ├── core/
│   │   ├── app_state.dart                 # Central ChangeNotifier coordinating state, IoT, & schedule
│   │   └── theme/
│   │       └── app_theme.dart             # Bespoke theme, palette, card styling, typography
│   ├── data/
│   │   ├── models/
│   │   │   └── models.dart                # User, Medicine, Event, Caretaker, PhysicalContainer models
│   │   └── repositories/
│   │       └── repositories.dart          # In-memory repositories with persistence hooks & TestFixtures
│   ├── features/
│   │   ├── auth/
│   │   │   └── auth_screens.dart          # Animated Splash, Welcome, Login, and Registration
│   │   ├── caretaker/
│   │   │   └── caretaker_screen.dart      # Caretaker directory & threshold alert rules
│   │   ├── device/
│   │   │   └── device_screen.dart         # Live 4-container telemetry & developer simulation controls
│   │   ├── doctor/
│   │   │   └── doctor_screen.dart         # Clinical recorded event trends & load-cell telemetry
│   │   ├── history/
│   │   │   └── history_screen.dart        # Event audit log with date filters and sensor provenance
│   │   ├── home/
│   │   │   └── home_screen.dart           # Dashboard: Next dose, 4-container grid, recorded event ratio
│   │   ├── medicines/
│   │   │   └── medicines_screen.dart      # Directory, manual add, & OCR draft review/edit form
│   │   ├── settings/
│   │   │   └── settings_screen.dart       # User profile, links to Caretaker/Doctor/Device, Sign Out
│   │   └── weekly_plan/
│   │       └── weekly_plan_screen.dart    # 7-day Monday–Sunday matrix across 4 container slots
│   ├── services/
│   │   ├── auth/
│   │   │   └── auth_service.dart          # Authentication service with reactive authStateChanges
│   │   ├── device/
│   │   │   └── device_service.dart        # MockDeviceService (disconnected by default, simulation mode)
│   │   ├── medicine_image/
│   │   │   └── medicine_image_service.dart# OCR image parsing simulator returning MedicineDraft
│   │   ├── notifications/
│   │   │   └── notification_service.dart  # Notification interface with snoozing & threshold alerts
│   │   └── storage/
│   │       └── local_persistence_service.dart # SharedPreferences JSON local persistence engine
│   ├── widgets/
│   │   └── navigation_shell.dart          # Adaptive 5-tab shell (BottomBar on mobile, NavigationRail on wide screens)
│   └── main.dart                          # App bootstrap, AppStateProvider, MediPillApp root
├── test/
│   └── widget_test.dart                   # Full 28-test suite (Architecture, Safety, Persistence, Adaptability)
├── pubspec.yaml                           # Flutter dependencies & assets configuration
├── analysis_options.yaml                  # Flutter recommended lints configuration
└── README.md                              # This documentation
```

---

## 🛠️ Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.9.0 or higher)
- [Dart SDK](https://dart.dev/get-dart) (v3.0.0 or higher)
- Chrome browser (for web testing) or Windows build tools / Android emulator

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/khaleedshaik62/Medipill.git
   cd Medipill
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run static analysis:
   ```bash
   flutter analyze
   ```
   *(Expected result: `No issues found!`)*

4. Run the automated test suite:
   ```bash
   flutter test
   ```
   *(Expected result: `All tests passed!`)*

5. Run the application:
   ```bash
   # Run in Chrome
   flutter run -d chrome

   # Run on Windows desktop
   flutter run -d windows
   ```

---

## 🧪 Testing & Quality Verification

MediPill Monitor enforces a comprehensive automated test suite with **28 tests passing (100% success rate)** across 6 core testing categories in [`test/widget_test.dart`](test/widget_test.dart):

1. **Hardware & Container Constraints:**
   - Verifies device contains exactly 4 physical containers (1 to 4) and rejects invalid container IDs.
   - Confirms Containers 1–4 map to Morning, Afternoon, Evening, and Night time slots.
2. **Medical Safety & Observable Terminology:**
   - Verifies `MedicationStatus` adheres strictly to recorded/unconfirmed/missed event tracking without unsupported ingestion claims.
   - Asserts caretaker alert preferences use observable event language (`missed_medication`, `medication_recorded`).
3. **Weekly Schedule Matrix (Monday–Sunday):**
   - Validates weekly schedule coverage across all 7 calendar days.
   - Confirms container reusability: the same physical container (Container 1) is reused across multiple days of the week.
4. **Authentication & Session Flows:**
   - Validates credential verification, error handling, password masking toggle, account sign-up, and session teardown on logout.
5. **Clean Startup, Zero Demo Data & Disconnected Device:**
   - Asserts unseeded startup contains zero medicines, events, or caretakers.
   - Verifies device starts disconnected (`"Device not connected"`, `0.0 g` weights) by default.
   - Tests developer simulation isolation: activates `"SIMULATED DEVICE — TESTING"` label only when explicitly enabled.
   - Verifies Home screen renders genuine empty states without fabricated metrics (`18 / 21`, `86%`, `High Recording Rate`).
6. **Appearance Removal from Settings:**
   - Asserts Settings screen has no Appearance section, theme selector, dark/light toggle, or dead buttons.
   - Confirms valid system settings (Profile, Caretaker, Doctor, Device, Sign Out) remain fully accessible.
7. **Real Data Addition & Dynamic Schedule Calculation:**
   - Verifies adding a new medicine dynamically populates Monday–Sunday dosage events assigned to the corresponding container slot.
8. **Local Persistence Across Simulated Restarts:**
   - Verifies `LocalPersistenceService` persists and restores user profile, medicines, caretakers, and simulation mode using mock `SharedPreferences`.
9. **Platform Adaptability & UI Fallbacks:**
   - Tests `AdaptiveNavigationShell` responsive breakpoint: renders `BottomNavigationBar` on mobile (`< 768px`) and `NavigationRail` on desktop (`>= 768px`).
   - Verifies desktop/web camera scanning fallback dialog displays proper explanatory text with direct manual entry options.

---

## 🔌 Future ESP32 Hardware Integration

The application is structured to easily bind to real ESP32 hardware via MQTT / WebSocket or Bluetooth Low Energy (BLE):
- **Microcontroller:** ESP32 (dual-core 240 MHz with built-in Wi-Fi and Bluetooth)
- **Weight Sensing:** 4 $\times$ Mini load cells connected through 4 $\times$ HX711 24-bit ADC amplifiers
- **Lid/Door Sensing:** 4 $\times$ Magnetic reed switches (GPIO input with pull-ups)
- **Time Synchronization:** DS3231 I2C High-Precision RTC module
- **Alert Signaling:** Piezo buzzer and RGB status LEDs

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

