# Frontend Specification Document
**Project:** DocuMind AI

## 1. Design Philosophy
*   **Theme:** Minimalist, Dark-first (AMOLED Black background), with a premium "Tech" feel.
*   **Accent Colors:** Electric Blue (#2979FF) for primary actions, Neon Purple (#D500F9) for AI elements.
*   **Typography:** Inter or SF Pro Display for clean readability.

## 2. Screen Flow & Architecture
*   **Onboarding Screen:** 3-page carousel explaining BYOK -> "Add API Key" CTA.
*   **Home Screen:** 
    *   Empty State: "Drop your first document here" with a glowing upload icon.
    *   Populated State: List of processed documents with thumbnails, names, and "Chat" buttons.
*   **Document View & Chat Screen (Core Screen):**
    *   Split view or overlay. 
    *   Top: Document viewer (PDF pages).
    *   Bottom: Chat interface.
    *   Floating Action Bar: "Summarize", "Key Takeaways".
*   **Settings Screen:** Manage API Key, Buy Pro, Restore Purchase, Theme toggle.

## 3. UI Components
*   **Typing Indicator:** Animated 3-dot pulse when AI is thinking.
*   **Citation Chips:** Small clickable chips below AI responses (e.g., `[Page 4]`). Clicking scrolls the PDF viewer to that page.
*   **Haptic Feedback:** Trigger subtle vibration on successful API key validation, document upload completion, and IAP success.
*   **Shimmer Effects:** Use shimmer loading states while a large PDF is being chunked and embedded.
```
