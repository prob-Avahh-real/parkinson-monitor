# Android Deployment Guide

## Prerequisites
- Android SDK installed
- Keystore file for signing
- Google Play Developer account

## Build Configuration

### 1. Configure Signing

Create or update `android/key.properties`:

```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=path/to/your/keystore.jks
```

Add `android/key.properties` to `.gitignore`:

```gitignore
android/key.properties
*.jks
```

### 2. Update build.gradle.kts

Ensure `android/app/build.gradle.kts` includes signing configuration:

```kotlin
android {
    signingConfigs {
        create("release") {
            val keyProperties = Properties()
            val keyPropertiesFile = rootProject.file("key.properties")
            if (keyPropertiesFile.exists()) {
                keyProperties.load(FileInputStream(keyPropertiesFile))
            }
            keyAlias = keyProperties["keyAlias"] as String
            keyPassword = keyProperties["keyPassword"] as String
            storeFile = file(keyProperties["storeFile"] as String)
            storePassword = keyProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

## Building

### Debug Build
```bash
flutter build apk --debug
```

### Release Build
```bash
flutter build apk --release
```

### App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

### Using Makefile
```bash
make build-android
```

## Testing

### Install on Device
```bash
flutter install
```

### Run on Connected Device
```bash
flutter run
```

## Deployment to Google Play Store

### 1. Create App Bundle
```bash
flutter build appbundle --release
```

### 2. Upload to Play Console
- Go to Google Play Console
- Select your app
- Navigate to Release > Production
- Upload the AAB file from `build/app/outputs/bundle/release/app-release.aab`

### 3. Configure Release
- Set release notes
- Target audience
- Rollout percentage (recommended: start with 1-5%)

## Environment Configuration

### Production
```bash
cp .env.production .env
# Edit .env with production values
flutter build appbundle --release
```

### Development
```bash
cp .env.development .env
# Edit .env with development values
flutter build apk --debug
```

## Version Management

### Update Version
Edit `pubspec.yaml`:
```yaml
version: 1.0.0+1
```

Format: `major.minor.patch+buildNumber`

### Automatic Versioning
Use the release workflow:
```bash
make release
```

## Troubleshooting

### Build Fails with Signing Errors
- Verify `key.properties` exists and is correct
- Check keystore file path
- Ensure passwords are correct

### ProGuard Issues
- Update `android/app/proguard-rules.pro`
- Add rules for third-party libraries
- Test with `isMinifyEnabled = false` first

### APK Size Too Large
- Enable code shrinking: `isMinifyEnabled = true`
- Enable resource shrinking
- Split APKs by ABI: `flutter build apk --split-per-abi`

## Performance Optimization

### Build Speed
- Use Flutter build cache
- Enable Gradle build cache
- Use `flutter build apk --release` instead of debug

### App Size
- Analyze with `flutter build apk --analyze-size`
- Remove unused assets
- Use code splitting
- Enable R8 full mode

## Security

### Keystore Management
- Never commit keystore files
- Use environment variables for passwords
- Backup keystore securely
- Use different keystores for dev/prod

### Code Obfuscation
- Enable ProGuard/R8 in release builds
- Keep mapping files for crash reporting
- Test obfuscated builds thoroughly
