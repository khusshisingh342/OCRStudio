# OCR Studio: Packaged Commodity Compliance Verification Engine

An iOS application built with SwiftUI and Apple Vision framework designed to perform automated optical character recognition (OCR) and rule-based verification for packaged commodities under Indian Legal Metrology Rules.

---

## 📌 Features

- **On-Device Vision OCR:** Instant scanning of product labels using Apple's high-accuracy `VNRecognizeTextRequest`.
- **Legal Metrology Validation Engine:** Real-time checking of mandatory declarations on pre-packaged commodities:
  - Manufacturer/Packer Details
  - Country of Origin
  - Net Quantity / Dimensions
  - Maximum Retail Price (MRP inclusive of all taxes)
  - Date of Manufacture / Packing
  - Consumer Care Details
- **Camera & Gallery Support:** Pick images directly from device storage or live camera capture with runtime permission management.
- **Copy & Export:** Fast interaction tools for copying recognized text payloads.

---

## 🔄 System Architecture Pipeline

```
+-----------------------------------------------------------------------------------+
|                                  USER INTERFACE                                   |
|                                (ContentView.swift)                                |
|                                                                                   |
|   +-----------------------+                    +------------------------------+   |
|   |   Authentication      |                    |    Image Selection Source    |
|   |  (Email / Password)   |                    |  (Photo Library / Camera)    |
|   +-----------+-----------+                    +--------------+---------------+   |
|               |                                               |                   |
+---------------|-----------------------------------------------|-------------------+
                |                                               |
                v                                               v
+-----------------------------------------------------------------------------------+
|                                   ENGINE LAYER                                    |
|                                                                                   |
|  +-----------------------------------------------------------------------------+  |
|  |                            Processing Pipeline                              |  |
|  |                                                                             |  |
|  |   [ 1. Image Capture ]                                                      |  |
|  |            |                                                                |  |
|  |            v                                                                |  |
|  |   [ 2. Apple Vision Engine ]                                                |  |
|  |            |---> VNRecognizeTextRequest (.accurate level)                   |
|  |            |---> CGImage Request Handler                                    |
|  |            v                                                                |
|  |   [ 3. OCR Text Output ]                                                    |
|  |            |                                                                |
|  |            v                                                                |
|  |   [ 4. Compliance Analysis Engine ] (ComplianceEngine.swift)               |
|  |            |---> Declaration Parser (Fields & Expressions)                  |
|  |            |---> Legal Metrology Rules Validator                            |
|  |            v                                                                |
|  |   [ 5. Compliance View Render ]                                             |
|  |            |---> Line Item Statistics & Verification Flags                  |
|  +-----------------------------------------------------------------------------+  |
+-----------------------------------------------------------------------------------+
```

---

## 📁 Project Structure

```text
OCRStudio/
├── OCRStudioApp.swift        # Application Entry Point
├── ContentView.swift         # Main UI View (Login & Scanner Dashboard)
├── ComplianceEngine.swift    # Business Logic & Legal Metrology Validation
├── ImagePicker.swift         # Camera / Photo Library Picker
├── Theme.swift               # Color & Typography Design System
└── Info.plist                # App Configuration & Permissions
```

---

## 🛠 Setup & Requirements

- **iOS Version:** iOS 16.0+
- **Development Tool:** Xcode 14.0+
- **Language:** Swift 5.7+
- **Frameworks:** SwiftUI, Vision, UIKit, AVFoundation
