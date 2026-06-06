# Privacy Policy — Parkinson Monitor

**Last Updated:** June 5, 2026

## 1. Data We Collect

### Required for Core Functionality
- **Motion Sensor Data** — Accelerometer and gyroscope readings collected during active monitoring sessions only
- **GPS Location** — Only when outdoor monitoring mode is active and user has granted permission
- **Bluetooth Device Info** — Device name and signal strength of paired BLE wearables

### Optional (Cloud Sync)
- **Supabase Account** — Anonymous authentication token when cloud sync is enabled
- **Monitoring Sessions** — Detection events, severity scores, and timestamps

### We Do NOT Collect
- Personal identification information (name, email, phone)
- Health records or medical history
- Contacts, photos, or other personal files

## 2. How We Use Data

- **Local Processing** — All motion detection and analysis happens on-device. Raw sensor data never leaves your phone.
- **Cloud Sync (Optional)** — When enabled, de-identified session summaries are uploaded to Supabase for multi-device access. You can disable this anytime.
- **Analytics (Optional)** — Firebase Analytics collects anonymous usage patterns (e.g., feature usage frequency). No health data is included.

## 3. Data Storage

- **Local Storage** — Session data stored in encrypted Hive database on your device
- **Cloud Storage** — Supabase (AWS/GCP infrastructure), encrypted at rest and in transit (TLS 1.3)

## 4. Data Sharing

- **We do not sell, rent, or share your data with third parties.**
- Data is accessible only to you through your authenticated session.
- Row-Level Security (RLS) policies on Supabase ensure strict data isolation.

## 5. Your Rights

- **Delete Data** — Clear all local data via Settings → Clear Data. Cloud data is deleted when you disable sync.
- **Export Data** — Generate PDF reports containing your session history.
- **Opt Out** — Cloud sync, analytics, and crash reporting are opt-in and can be toggled in Settings.

## 6. Medical Disclaimer

**Parkinson Monitor is an assistive tool, NOT a medical device.** It does not diagnose, treat, or prevent any disease. Detection results are for informational purposes only. Always consult a qualified healthcare professional for medical advice.

## 7. Contact

For privacy-related inquiries, contact us at privacy@parkinson-monitor.app.

## 8. Changes to This Policy

We will notify users of material changes via in-app notice. Continued use after changes constitutes acceptance.
