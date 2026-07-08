# Security & Access Control Document
**Project:** DocuMind AI

## 1. API Key Security (Highest Priority)
Since this is a BYOK app, the API key is the most sensitive asset.
*   **Storage:** API keys will NOT be stored in SharedPreferences. They will be encrypted and stored using `flutter_secure_storage`, which utilizes Android's Keystore.
*   **Network Transmission:** API keys are only sent directly to the respective LLM provider (e.g., `api.openai.com`) over HTTPS. They never touch our servers (because we don't have any).

## 2. Data Privacy
*   **Local Documents:** All uploaded PDFs and extracted text remain on the user's local device storage. They are not uploaded to any cloud server.
*   **No Telemetry:** The app will not collect personal data, tracking IDs, or analytics by default. (Optional: Firebase Crashlytics can be added anonymously for bug tracking).

## 3. In-App Purchase (IAP) Security
*   **Validation:** Google Play Billing Library will be used. 
*   **Entitlements:** Pro features are unlocked based on local Play Store purchase receipts. Since there is no backend, we rely on Google Play's local cache for entitlement management (restoring purchases on new devices).

## 4. App Permissions
*   `READ_EXTERNAL_STORAGE` / `MANAGE_EXTERNAL_STORAGE` (Scoped Storage): Only required to access user-selected documents. Use the system file picker (`file_picker` package) to avoid requesting broad storage permissions.
*   Internet Access: Required to make API calls to OpenAI/Gemini.
```
