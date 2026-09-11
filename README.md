# ConnectCall 📱

**ConnectCall** is a Flutter-based real-time communication application that allows users to connect with each other through **audio and video calls**.

The project was developed as a Flutter internship assignment to demonstrate practical knowledge of Flutter development, Firebase integration, state management, and real-time WebRTC communication.

## ✨ Features

* 🔐 User registration and login
* 👤 User profile management
* 👥 Add and manage contacts
* 🟢 Online / offline user status
* 📹 Real-time video calling
* 📞 Real-time audio calling
* 📋 Call history
* 🔔 Incoming call handling
* 🎥 Local and remote video streams
* 🔄 Real-time call status management
* 🔥 Firebase Authentication and Firestore integration
* ⚡ Provider-based state management

## 🛠️ Technologies Used

| Technology              | Purpose                                 |
| ----------------------- | --------------------------------------- |
| Flutter                 | Cross-platform application development  |
| Dart                    | Programming language                    |
| Firebase Authentication | User registration and login             |
| Cloud Firestore         | User, contact, and call data            |
| WebRTC                  | Real-time audio and video communication |
| Provider                | State management                        |
| Android Studio          | Development and testing                 |
| Git & GitHub            | Version control                         |

## 📂 Project Structure

```text
lib/
├── core/
│   ├── constants/
│   └── theme/
│
├── models/
│   ├── call_model.dart
│   ├── contact_model.dart
│   └── user_model.dart
│
├── providers/
│   ├── auth_provider.dart
│   └── contact_provider.dart
│
├── screens/
│   ├── add_contact_screen.dart
│   ├── call_screen.dart
│   ├── contact_screen.dart
│   ├── history_screen.dart
│   ├── home_screen.dart
│   ├── login_screen.dart
│   ├── profile_screen.dart
│   ├── register_screen.dart
│   └── splash.dart
│
├── services/
│   ├── auth_service.dart
│   ├── call_service.dart
│   ├── calling_service.dart
│   ├── user_service.dart
│   └── webrtc_service.dart
│
├── widgets/
│   ├── call_button.dart
│   ├── common_button.dart
│   └── user_title.dart
│
├── firebase_options.dart
└── main.dart
```

## 🔐 Authentication

ConnectCall uses **Firebase Authentication** to provide secure user registration and login.

Users can:

* Create an account
* Log in using their credentials
* Access their profile
* Sign out of the application

## 📹 Audio & Video Calling

The application uses **WebRTC** for real-time peer-to-peer audio and video communication.

The calling functionality includes:

* Starting a call
* Receiving an incoming call
* Accepting a call
* Rejecting or ending a call
* Displaying the local video
* Displaying the remote video
* Switching between audio and video call functionality

Firebase Firestore is used for the signaling and call-related data required to establish communication between users.

## 🟢 Online Status

ConnectCall displays the user's current availability as:

* **Online** — when the user is active
* **Offline** — when the user is not available

This helps users identify whether a contact is currently available.

## 📋 Call History

The application maintains call-related information so users can view their previous calls through the **Call History** section.

## 🧠 State Management

The application uses the **Provider** package for state management.

Provider is used to manage application data such as:

* Authentication state
* Contact information
* User-related data
* UI updates based on changing application state

This helps keep the application code organized and separates UI logic from application data.

## 🔥 Firebase

The project uses Firebase services for backend functionality.

### Firebase Authentication

Used for:

* User registration
* User login
* User authentication state

### Cloud Firestore

Used for storing and synchronizing application data such as:

* User information
* Contacts
* Call information
* Call status

## 🚀 Getting Started

### Prerequisites

Before running the project, make sure you have:

* Flutter SDK installed
* Dart SDK
* Android Studio or Visual Studio Code
* Android emulator or physical Android device
* A Firebase project

### 1. Clone the repository

```bash
git clone https://github.com/YOUR_USERNAME/connect-call.git
```

### 2. Open the project

```bash
cd connect-call
```

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Configure Firebase

Connect the Flutter application to your Firebase project and make sure the required Firebase configuration files are available.

### 5. Run the application

```bash
flutter run
```

## 📱 Building the APK

To generate a release APK:

```bash
flutter build apk --release
```

The generated APK can be found at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## 🧪 Testing

The application was developed and tested using:

* Android Emulator
* Physical Android device
* Flutter debug mode
* Flutter release build

## 🎯 Project Objective

The main objective of ConnectCall is to demonstrate practical implementation of:

* Flutter UI development
* Firebase integration
* Authentication
* Cloud Firestore
* Provider state management
* WebRTC
* Real-time communication
* Android application development
* Git and GitHub version control

## 👩‍💻 Developer

**Shana K A**

Flutter Developer | BSc Computer Science

This project was developed as part of a **Flutter Development Internship Assignment**.

## 📄 License

This project was created for educational and internship evaluation purposes.
