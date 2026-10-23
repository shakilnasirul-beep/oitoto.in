# 📱 Oi Toto! — Android Build & Release Guide

This guide details how to compile and package both the **Customer Android App** and **Driver Partner Android App** into release APKs and Google Play Store App Bundles (AAB).

---

## 1. Prerequisites

- **Flutter SDK:** 3.19.0 or higher
- **Dart SDK:** 3.3.0 or higher
- **Android Studio & SDK:** Android SDK Platform 34 (API Level 34)
- **Java Development Kit:** JDK 17 (recommended for Gradle 8+)

Verify your Flutter environment:
```bash
flutter doctor
```

---

## 2. Compiling the Customer App (`oi_toto_customer`)

### Step 1: Navigate to the Customer App directory
```bash
cd G:\oitoto\apps\customer_app
```

### Step 2: Fetch dependencies
```bash
flutter pub get
```

### Step 3: Configure Target API Base URL
In `lib/core/constants/api_constants.dart`:
- For **Android Emulator**: `http://10.0.2.2:8000/api/v1`
- For **Physical USB Device / Wi-Fi**: `http://<YOUR_LOCAL_IP>:8000/api/v1` (e.g. `http://192.168.1.100:8000/api/v1`)
- For **Production Server**: `https://api.oitoto.in/api/v1`

### Step 4: Run on Connected Device / Emulator
```bash
flutter run
```

### Step 5: Build Release APK
```bash
flutter build apk --release
```
Output location:
```text
build/app/outputs/flutter-apk/app-release.apk
```

### Step 6: Build Google Play Store App Bundle (AAB)
```bash
flutter build appbundle --release
```
Output location:
```text
build/app/outputs/bundle/release/app-release.aab
```

---

## 3. Compiling the Driver App (`oi_toto_driver`)

### Step 1: Navigate to the Driver App directory
```bash
cd G:\oitoto\apps\driver_app
```

### Step 2: Fetch dependencies
```bash
flutter pub get
```

### Step 3: Run on Connected Device / Emulator
```bash
flutter run
```

### Step 4: Build Release APK
```bash
flutter build apk --release
```
Output location:
```text
build/app/outputs/flutter-apk/app-release.apk
```

### Step 5: Build Google Play Store App Bundle (AAB)
```bash
flutter build appbundle --release
```

---

## 4. Keystore Generation for Production Signing

Generate a Java keystore for signing the production release:
```bash
keytool -genkey -v -keystore oitoto-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias oitoto
```

Create `android/key.properties`:
```properties
storePassword=YourKeystorePassword
keyPassword=YourKeyPassword
keyAlias=oitoto
storeFile=../oitoto-release-key.jks
```

Configure `android/app/build.gradle`:
```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```
