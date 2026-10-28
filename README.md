# 🎓 EduMentor AI

[![Flutter](https://img.shields.io/badge/Flutter-v3.8+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-v3.8+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend%20%26%20Auth-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Groq](https://img.shields.io/badge/AI%20Powered-Groq%20Cloud-F55036?logo=groq&logoColor=white)](https://groq.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> **EduMentor AI** is a modern, bilingual (English & Tamil) educational learning and test-preparation platform built with Flutter and Supabase. Tailored for competitive exam aspirants (such as **NEET** and **JEE**) and high-school students, it provides an ultra-fast AI tutor, timed mock test simulations, personalized progress tracking, and curated study materials.

---

## 📑 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Application Architecture](#-application-architecture)
- [Tech Stack](#-tech-stack)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Environment Configuration](#environment-configuration)
  - [Database Setup (Supabase)](#database-setup-supabase)
  - [Running the App](#running-the-app)
- [Running Tests](#-running-tests)
- [Project Directory Structure](#-project-directory-structure)
- [Security & Access Control](#-security--access-control)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🌟 Overview

Preparing for high-stakes entrance exams like NEET and JEE requires high-frequency practice, instant doubt clearance, and strict discipline. Traditional tutoring often lacks real-time availability and personalized feedback. 

**EduMentor AI** bridges this gap by combining:
1. **Low-latency generative AI** (powered by Groq) to serve as an always-available personal tutor.
2. **Realistic timed mock assessments** with full answer key reviews and granular scoring.
3. **Bilingual pedagogical assistance** in English and fluent Tamil, breaking linguistic barriers in STEM learning.
4. **Role-Based Portals** enabling both students to learn and administrators to manage content, curate mock tests, and monitor learner analytics.

---

## ✨ Key Features

### 🤖 1. AI Teacher & Doubt Solver
* **Powered by Groq Cloud**: Utilizes high-throughput LLMs (default: `openai/gpt-oss-120b`, configurable to Qwen or LLaMA models).
* **Live Token Streaming**: Provides near-instant interactive responses with fluid streaming via Server-Sent Events (SSE).
* **Bilingual Intelligence**: Explains complex scientific principles in fluent Tamil or English based on the student's preference.
* **Plain Text Scientific Math**: Automatically formats mathematical formulas and equations using clean Unicode symbols (`x²`, `√x`, `θ`, `(a+b)/c`) rather than raw LaTeX syntax, ensuring high legibility on any mobile screen.
* **Context-Aware Memory**: Retains multi-turn conversational history with quick-reset options.
* **Sanitized Error Shield**: Masks sensitive technical stack traces and API keys from end users.

### 📝 2. Mock Test Simulation Engine
* **Subject & Topic Tests**: Full-length and chapter-wise mock tests across Physics, Chemistry, Biology, and Mathematics.
* **Live Exam Timer**: Countdown timer replicating real competitive test environments.
* **MCQ Navigation**: Question palette allowing students to jump between questions, flag questions for review, and submit tests.
* **Comprehensive Analytics**: Instant test scoring, percentage calculation, and side-by-side answer evaluation.

### 📈 3. Performance & Streak Analytics
* **Study Streak Tracker**: Gamified daily study streak counter to encourage continuous learning habits.
* **Performance Dashboard**: Graphical tracking of average scores, completion rates, and subject proficiency over time.
* **Percentile & Rank Estimation**: Dynamic benchmark indicators based on peer performance.

### 📚 4. Curated Learning Resources Hub
* **Multi-Format Materials**: Access revision notes, cheatsheets, formula books, and question banks.
* **Exam Filtering**: Targeted categorization for NEET, JEE, or combined syllabi.
* **Resource Viewer**: Built-in linking and file downloading for offline study.

### 👨‍💼 5. Admin Management Suite
* **Interactive Dashboard**: Real-time stats on registered students, published tests, questions, and average test scores.
* **Test Builder**: Complete CRUD interface to create, modify, publish, and delete mock tests and question sets.
* **Test Attempt Analytics**: Deep dive into test submission metrics and score distributions.
* **User & Content Moderation**: Manage enrolled students and study resource catalogs.

### 🔐 6. Authentication & Security
* **Multi-Provider Auth**: Email/Password authentication and Google Sign-In with OAuth token validation.
* **Strict Role-Based Routing**: Hardened navigation guards separating student interfaces from administrative control panels.
* **Row Level Security (RLS)**: Enforced directly on Supabase PostgreSQL tables to guarantee that student test attempts and profiles remain strictly confidential.

---

## 🏛️ Application Architecture

EduMentor AI is built using a clean, feature-first modular architecture:

```
lib/
├── core/                       # Shared utilities, global configs, and core theme
│   ├── services/               # Global services (AuthService, Supabase client)
│   └── theme/                  # Color schemes, typography, and Material theme data
├── features/                   # Independent feature modules
│   ├── admin/                  # Admin portal (dashboard, tests CRUD, user management)
│   ├── ai/                     # AI Teacher (chat screen, Groq API client, streaming)
│   ├── auth/                   # Authentication (Splash, Onboarding, Login, Register)
│   ├── dashboard/              # Student dashboard, streaks, and performance analytics
│   ├── mocktests/              # Mock test engine, question player, and score results
│   ├── profile/                # User profile management and preferences
│   └── resources/              # Learning resource hub and study materials
├── navigation/                 # GoRouter route declarations and bottom navigation tabs
└── main.dart                   # Application entry point & configuration verification
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Frontend Framework** | [Flutter](https://flutter.dev) (SDK `^3.8.1`) |
| **Language** | [Dart](https://dart.dev) |
| **State Management** | [`provider`](https://pub.dev/packages/provider) |
| **Routing & Navigation** | [`go_router`](https://pub.dev/packages/go_router) |
| **Backend & Database** | [Supabase](https://supabase.com) (PostgreSQL, Supabase Auth, Storage, RLS) |
| **AI Inference** | [Groq Cloud API](https://groq.com) (`openai/gpt-oss-120b`, `qwen/qwen3.8-27b`) |
| **Networking & HTTP** | [`http`](https://pub.dev/packages/http), [`dio`](https://pub.dev/packages/dio) |
| **UI & Styling** | [`google_fonts`](https://pub.dev/packages/google_fonts), [`lucide_icons`](https://pub.dev/packages/lucide_icons), [`lottie`](https://pub.dev/packages/lottie) |
| **Local Storage** | [`shared_preferences`](https://pub.dev/packages/shared_preferences) |
| **Configuration** | [`flutter_dotenv`](https://pub.dev/packages/flutter_dotenv) |

---

## 🚀 Getting Started

Follow these steps to set up and run EduMentor AI on your local machine.

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`v3.8.1` or newer)
- [Dart SDK](https://dart.dev/get-dart)
- [Git](https://git-scm.com/)
- An active [Supabase account](https://supabase.com)
- An active [Groq Cloud account & API Key](https://console.groq.com)
- (Optional for Google Sign-In) A [Google Cloud Console project](https://console.cloud.google.com) with an OAuth 2.0 Web Client ID

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/edumentor_ai.git
   cd edumentor_ai
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

### Environment Configuration

Create a `.env` file in the root directory by copying the sample template:

```bash
cp .env.example .env
```

Open `.env` and provide your API credentials:

```dotenv
# Groq AI Configuration
GROQ_API_KEY=gsk_your_actual_groq_api_key_here
GROQ_MODEL=openai/gpt-oss-120b

# Supabase Configuration
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_PUBLISHABLE_KEY=your_supabase_anon_publishable_key

# Google OAuth Configuration (Required for Google Sign-In)
GOOGLE_WEB_CLIENT_ID=your_google_web_client_id.apps.googleusercontent.com
```

> **Note**: The `.env` file is included in your `.gitignore` to prevent leaking credentials. Never commit your production keys to version control.

### Database Setup (Supabase)

EduMentor AI includes a production-ready, idempotent SQL migration script located at [`supabase/schema.sql`](supabase/schema.sql).

1. Log in to your [Supabase Dashboard](https://supabase.com/dashboard).
2. Open your project and navigate to the **SQL Editor** tab.
3. Paste the contents of `supabase/schema.sql` into the query window and click **Run**.
4. The script automatically sets up:
   - `profiles` (with automatic user sync triggers and role checks)
   - `mock_tests` and `mock_test_questions`
   - `test_attempts`
   - `learning_resources`
   - Row Level Security (RLS) policies protecting student records
   - Helper function `public.is_admin()` for role verification

#### Setting up an Admin User
To promote a user to an administrator:
1. Register an account via the app or through the Supabase Authentication dashboard.
2. Run the following query in the Supabase SQL editor:
   ```sql
   UPDATE public.profiles
   SET role = 'admin'
   WHERE id = 'PASTE_USER_UUID_HERE';
   ```

### Running the App

Run the application on your target device or emulator:

```bash
# Run on connected device / emulator
flutter run

# Run on Chrome (Web)
flutter run -d chrome

# Run on Windows Desktop
flutter run -d windows
```

---

## 🧪 Running Tests

EduMentor AI includes comprehensive unit tests verifying AI model resolution, response formatting, streaming, and error sanitization.

To run all unit tests:

```bash
flutter test
```

To run a specific test suite:

```bash
flutter test test/services/ai_service_test.dart
```

---

## 📁 Project Directory Structure

```text
edumentor_ai/
├── assets/
│   └── images/                       # App graphics and branding illustrations
├── lib/
│   ├── core/
│   │   ├── services/
│   │   │   └── auth_service.dart     # Supabase & Google sign-in handling
│   │   └── theme/
│   │       └── app_theme.dart        # Custom typography, colors, and styling
│   ├── features/
│   │   ├── admin/
│   │   │   ├── screens/              # Admin CRUD and management screens
│   │   │   └── services/             # Admin data and metrics service
│   │   ├── ai/
│   │   │   ├── screens/              # AI Teacher chat interface
│   │   │   └── services/             # Groq AI integration and stream parser
│   │   ├── auth/
│   │   │   └── screens/              # Splash, Onboarding, Login, Register
│   │   ├── dashboard/
│   │   │   ├── screens/              # Student home, streaks, performance
│   │   │   └── services/             # Dashboard and analytics service
│   │   ├── mocktests/
│   │   │   ├── models/               # Mock test and question models
│   │   │   ├── screens/              # Test taking and result screens
│   │   │   └── services/             # Test fetch, submit, and score service
│   │   ├── profile/
│   │   │   ├── screens/              # Profile settings and preferences
│   │   │   └── services/             # User profile service
│   │   └── resources/
│   │       ├── models/               # Learning resource data model
│   │       ├── screens/              # Resources catalog screen
│   │       └── services/             # Learning resources service
│   ├── navigation/
│   │   ├── app_router.dart           # GoRouter route declarations
│   │   └── student_tabs.dart         # Bottom navigation scaffold
│   └── main.dart                     # App bootstrap and env validator
├── supabase/
│   └── schema.sql                    # Full PostgreSQL schema, triggers, and RLS
├── test/
│   ├── models/                       # Model serialization tests
│   └── services/                     # AI service and mocking tests
├── .env.example                      # Sample configuration file
├── pubspec.yaml                      # Project dependencies and asset definitions
└── README.md                         # Documentation
```

---

## 🛡️ Security & Access Control

* **Safe Error Propagation**: Groq API key errors, quota limits, and network errors are sanitized by `AiService.formatErrorMessage` before display, guaranteeing that API tokens and raw stack traces are never exposed to students.
* **Row Level Security (RLS)**: Public tables (`mock_tests`, `learning_resources`) are read-accessible to authenticated students, while modifying them requires administrator privileges verified through `public.is_admin()`.
* **Zero Privilege Escalation**: User roles are validated through server-side PostgreSQL checks and cannot be escalated simply by modifying client-side user metadata.

---

## 🤝 Contributing

Contributions to EduMentor AI are welcome!

1. **Fork** the repository.
2. **Create a feature branch**:
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Commit your changes**:
   ```bash
   git commit -m "Add amazing feature"
   ```
4. **Push to the branch**:
   ```bash
   git push origin feature/amazing-feature
   ```
5. **Open a Pull Request**.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
