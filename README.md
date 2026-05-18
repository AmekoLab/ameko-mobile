# Ameko - Custom Keyboard Marketplace

![Flutter Version](https://img.shields.io/badge/Flutter-%5E3.9.0-blue.svg)
![Dart Version](https://img.shields.io/badge/Dart-3.x-blue.svg)

> **Academic Project Notice:** This repository is developed as a course project for the academic year 2026. 

## Overview

**Ameko** is a comprehensive mobile application built with Flutter, serving as a specialized e-commerce platform and marketplace for custom keyboards. The application provides a robust ecosystem for buyers, sellers (shop owners), and administrators, featuring a wide range of functionalities from secure payments to real-time communication.

## Key Features

- **E-commerce & Order Management:** Complete shopping experience from browsing products to advanced order processing and fulfillment.
- **Secure Wallet System:** Built-in mobile wallet protected by a custom PIN, featuring Stripe integration for deposits, withdrawal requests, and a detailed transaction history.
- **Real-Time Communication:** Integrated live chat module powered by SignalR, allowing seamless communication between customers and shop owners.
- **Warranty & Dispute Workflow:** Comprehensive system for handling warranty claims and return disputes, complete with automated real-time notifications for all stakeholders.
- **Community Hub:** Dedicated community section with role-based posting permissions.
- **Authentication & Security:** Robust user authentication, OTP verification, and role-based access control.

## Technology Stack

- **Framework:** Flutter (Dart)
- **State Management:** BLoC (`flutter_bloc`)
- **Network & API:** Dio
- **Dependency Injection:** GetIt
- **Real-Time WebSockets:** SignalR (`signalr_netcore`)
- **Routing:** GoRouter
- **Local Storage:** Shared Preferences & Flutter Secure Storage
- **UI/UX:** Google Fonts, Cached Network Image, SVG support, and custom responsive layouts.

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (^3.9.0)
- Dart SDK
- Android Studio / Xcode (for emulation/building)

### Installation & Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ameko_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Environment Configuration**
   Ensure you have a `.env` file at the root of the project with the necessary API Base URLs and configurations.

4. **Run the Application**
   ```bash
   flutter run
   ```

## Disclaimer

This software was created for educational purposes as part of a university course project in 2026. It demonstrates the integration of complex mobile architectures, real-time networking, and secure payment processing within a Flutter environment.

---
*Developed for the 2026 Academic Year Course Project.*
