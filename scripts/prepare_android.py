#!/usr/bin/env python3
import sys
import os
import re

app_type = sys.argv[1] if len(sys.argv) > 1 else 'customer'
is_driver = (app_type == 'driver')

print(f"=== Preparing Android wrappers for {app_type} app ===")

# 1. Update AndroidManifest.xml
manifest_path = 'android/app/src/main/AndroidManifest.xml'
if os.path.exists(manifest_path):
    with open(manifest_path, 'r', encoding='utf-8') as f:
        manifest = f.read()

    perms = '''
        <uses-permission android:name="android.permission.INTERNET"/>
        <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
        <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
        <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
        <uses-permission android:name="android.permission.CALL_PHONE"/>
        <uses-permission android:name="android.permission.VIBRATE"/>
    '''
    if is_driver:
        perms += '''
        <uses-permission android:name="android.permission.WAKE_LOCK"/>
        <uses-permission android:name="android.permission.CAMERA"/>
        '''

    manifest = manifest.replace('<application', perms + '    <application android:usesCleartextTraffic="true"')
    if is_driver:
        manifest = manifest.replace('android:label="oi_toto_driver"', 'android:label="Oi Toto Partner"')
    else:
        manifest = manifest.replace('android:label="oi_toto_customer"', 'android:label="Oi Toto!"')

    with open(manifest_path, 'w', encoding='utf-8') as f:
        f.write(manifest)
    print(f"[{app_type}] Updated AndroidManifest.xml successfully.")

# 2. Update android/app/build.gradle
app_gradle = 'android/app/build.gradle'
if os.path.exists(app_gradle):
    with open(app_gradle, 'r', encoding='utf-8') as f:
        bg = f.read()

    bg = bg.replace('compileSdkVersion flutter.compileSdkVersion', 'compileSdkVersion 34')
    bg = bg.replace('compileSdk = flutter.compileSdk', 'compileSdk = 34')
    bg = bg.replace('minSdkVersion flutter.minSdkVersion', 'minSdkVersion 21')
    bg = bg.replace('minSdk = flutter.minSdk', 'minSdk = 21')
    bg = bg.replace('defaultConfig {', 'defaultConfig {\n        multiDexEnabled true')

    with open(app_gradle, 'w', encoding='utf-8') as f:
        f.write(bg)
    print(f"[{app_type}] Updated android/app/build.gradle successfully.")

# 3. Update android/build.gradle (root Kotlin version to 1.9.22)
root_gradle = 'android/build.gradle'
if os.path.exists(root_gradle):
    with open(root_gradle, 'r', encoding='utf-8') as f:
        rg = f.read()

    rg = re.sub(r"ext\.kotlin_version\s*=\s*['\"][^'\"]+['\"]", "ext.kotlin_version = '1.9.22'", rg)
    rg = re.sub(r'kotlin-gradle-plugin:[0-9.]+', 'kotlin-gradle-plugin:1.9.22', rg)

    with open(root_gradle, 'w', encoding='utf-8') as f:
        f.write(rg)
    print(f"[{app_type}] Updated android/build.gradle with Kotlin 1.9.22.")

# 4. Update android/settings.gradle if applicable
settings_gradle = 'android/settings.gradle'
if os.path.exists(settings_gradle):
    with open(settings_gradle, 'r', encoding='utf-8') as f:
        sg = f.read()

    sg = re.sub(r'org\.jetbrains\.kotlin\.android"\s+version\s+"[^"]+"', 'org.jetbrains.kotlin.android" version "1.9.22"', sg)

    with open(settings_gradle, 'w', encoding='utf-8') as f:
        f.write(sg)
    print(f"[{app_type}] Updated android/settings.gradle with Kotlin 1.9.22.")
