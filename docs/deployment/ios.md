# iOS Deployment Guide

## Prerequisites
- macOS with Xcode installed
- Apple Developer account
- iOS device for testing
- CocoaPods installed

## Build Configuration

### 1. Configure Signing

Open `ios/Runner.xcworkspace` in Xcode:
- Select Runner target
- Navigate to Signing & Capabilities
- Enable "Automatically manage signing"
- Select your development team

For manual signing:
- Disable automatic signing
- Select your provisioning profile
- Select your signing certificate

### 2. Update Bundle Identifier

In Xcode:
- Select Runner target
- General tab
- Bundle Identifier: `com.yourcompany.parkinsonmonitor`

### 3. Configure Info.plist

Update `ios/Runner/Info.plist` with required permissions:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to connect to wearable devices for monitoring Parkinson's symptoms.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app uses Bluetooth to connect to wearable devices for monitoring Parkinson's symptoms.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app uses location services to record walking paths during outdoor monitoring sessions.</string>
<key>NSMotionUsageDescription</key>
<string>This app uses motion sensors to detect movement patterns and symptoms.</string>
```

## Building

### Debug Build
```bash
flutter build ios --debug
```

### Release Build
```bash
flutter build ios --release
```

### Using Makefile
```bash
make build-ios
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

### Run on Simulator
```bash
flutter run -d iPhone
```

## Deployment to App Store

### 1. Create Archive

Using Xcode:
```bash
open ios/Runner.xcworkspace
```

In Xcode:
- Product > Archive
- Wait for archive to complete
- Window > Organizer

### 2. Upload to App Store Connect

In Organizer:
- Select your archive
- Click "Distribute App"
- Select "App Store Connect"
- Follow the wizard

### 3. Configure in App Store Connect

- Create new app or select existing
- Upload screenshots
- Set app information
- Configure pricing and availability
- Submit for review

## Environment Configuration

### Production
```bash
cp .env.production .env
# Edit .env with production values
flutter build ios --release
```

### Development
```bash
cp .env.development .env
# Edit .env with development values
flutter build ios --debug
```

## Version Management

### Update Version
Edit `pubspec.yaml`:
```yaml
version: 1.0.0+1
```

Edit `ios/Runner/Info.plist`:
```xml
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
<key>CFBundleVersion</key>
<string>1</string>
```

### Automatic Versioning
Use the release workflow:
```bash
make release
```

## Troubleshooting

### Build Fails with Signing Errors
- Verify Apple Developer account is active
- Check provisioning profiles
- Ensure bundle identifier is unique
- Try automatic signing first

### CocoaPods Issues
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

### Permission Errors
- Ensure Info.plist has all required permissions
- Test on physical device (simulator has limited permissions)
- Check entitlements in Xcode

### Build Size Too Large
- Analyze with Xcode's size report
- Remove unused assets
- Enable bitcode (if required)
- Optimize images and resources

## Performance Optimization

### Build Speed
- Use Xcode build cache
- Enable parallel builds
- Use `flutter build ios --release` instead of debug

### App Size
- Analyze with Xcode's size report
- Remove unused assets
- Enable app thinning
- Use asset catalogs

## Security

### Code Signing
- Never commit provisioning profiles
- Use different certificates for dev/prod
- Backup certificates securely
- Use automatic signing when possible

### Data Protection
- Enable Data Protection capability
- Use Keychain for sensitive data
- Encrypt local storage
- Use App Transport Security (ATS)

## App Store Review Guidelines

### Required
- All features must work as described
- No placeholder content
- Proper error handling
- Privacy policy link
- Clear app description

### Common Rejection Reasons
- Missing permissions descriptions
- Broken functionality
- Inappropriate content
- Violation of App Store guidelines
- Missing metadata

### Tips for Approval
- Test thoroughly on physical devices
- Provide detailed review notes
- Include demo account if applicable
- Respond to review questions promptly
