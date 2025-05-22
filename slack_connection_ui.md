# Slack Connection Management: UI Design & User Flow

This document outlines the UI components and user flow for managing the connection between a user's Team Task Notes (TTN) account and their Slack account. This functionality is typically found within the user's settings or profile area in the TTN application.

This design is based on the PRD and the backend specifications in `slack_integration_backend.md` and `slack_notifications_backend.md`.

---

## 1. Location of Slack Connection Management

*   **Navigation:** User Settings / Profile > Integrations > Slack.
*   **Page Title:** "Slack Integration" or "Connect to Slack".

---

## 2. UI Components and User Flow

### 2.1. Initial State: Not Connected

*   **Display:**
    *   A section clearly labeled "Slack".
    *   Status text: "Status: Not Connected".
    *   A brief explanation of the benefits of connecting to Slack (e.g., "Connect your Slack account to create notes using slash commands and receive notifications directly in Slack.").
    *   A prominent **"Connect to Slack"** or **"Add to Slack" button**.
        *   This button should visually resemble Slack's standard "Add to Slack" buttons if possible (e.g., using Slack's brand colors and logo).

*   **"Connect to Slack" Button Action:**
    *   **User Click:** When the user clicks this button.
    *   **Action:** The frontend initiates a redirect to the Team Task Notes backend endpoint that starts the OAuth 2.0 flow.
    *   **API Call:** `GET /api/slack/oauth/initiate` (as defined in `slack_integration_backend.md`).
    *   **User Experience:** The user's browser is redirected to Slack's authorization page, where they will be prompted to authorize the TTN application for their selected Slack workspace. After authorization (or cancellation) on Slack, they are redirected back to the TTN application (via `/api/slack/oauth/callback`, which then redirects to a success/failure page within the TTN UI).

### 2.2. Post-Connection Attempt: Success

*   **Redirection:** After successful OAuth callback processing, the user is redirected to a dedicated success page or back to the Slack Integration settings page.
*   **Display (on Slack Integration settings page):**
    *   Status text: "Status: Connected!"
    *   **Connected Account Information:**
        *   "Connected to Slack Workspace: **[Slack Workspace Name]**" (e.g., `team_domain` or `team.name` from the OAuth response stored in `SlackConnections.raw_slack_response`).
        *   "As Slack User: **@[Slack User Name]** (`slack_user_id`)" (e.g., `user_name` or `authed_user.id` from OAuth).
        *   "Authorized Scopes: `[List of granted scopes]`" (e.g., `commands, chat:write`). This can be helpful for transparency.
    *   A **"Disconnect from Slack" button**.

### 2.3. Post-Connection Attempt: Failure

*   **Redirection:** If the OAuth flow fails (e.g., user denies access, CSRF token mismatch, Slack API error during token exchange), the user is redirected to a failure page or back to the Slack Integration settings page.
*   **Display (on Slack Integration settings page or failure page):**
    *   Status text: "Status: Connection Failed".
    *   A brief error message: "Could not connect to Slack. Please try again. Reason: [Optional: Simplified error message, e.g., 'Authorization denied' or 'An unexpected error occurred']."
    *   The "Connect to Slack" button remains visible for another attempt.

### 2.4. Connected State: Managing the Connection

*   **Display (on Slack Integration settings page when already connected):**
    *   Status text: "Status: Connected".
    *   Connected Account Information (as detailed in section 2.2).
    *   Information about features enabled by the connection (e.g., "You can now use `/createnote` in Slack.").
    *   A **"Disconnect from Slack" button**.

*   **"Disconnect from Slack" Button Action:**
    *   **User Click:** When the user clicks this button.
    *   **Confirmation Dialog:** A modal dialog appears:
        *   **Title:** "Disconnect from Slack?"
        *   **Message:** "Are you sure you want to disconnect your Team Task Notes account from Slack? This will disable Slack commands for note creation and stop Slack notifications for your account. You can reconnect at any time."
        *   **Buttons:**
            *   "Cancel" (closes the dialog, no action taken).
            *   "Disconnect" (proceeds with disconnection).
    *   **If "Disconnect" is Confirmed:**
        *   **API Call:** The frontend calls a new backend API endpoint to handle the disconnection.
            *   **Endpoint:** `DELETE /api/slack/connection` (or `/api/slack/oauth/revoke`)
            *   **Backend Action:**
                1.  The backend identifies the current TTN user.
                2.  It looks up their entry in the `SlackConnections` table.
                3.  It securely calls Slack's `auth.revoke` method using the stored access token to invalidate it on Slack's side.
                4.  It deletes the corresponding row from the `SlackConnections` table.
        *   **UI Update:** The page refreshes or updates to show the "Not Connected" state (as described in section 2.1). A success message like "Successfully disconnected from Slack." can be briefly displayed.

---

## 3. User Flow Summary

1.  **Access Settings:** User navigates to User Settings > Integrations > Slack.
2.  **Check Status:**
    *   **If Not Connected:** User sees "Connect to Slack" button.
        *   Clicks button -> Redirected to `/api/slack/oauth/initiate` -> Slack authorization -> Redirected to `/api/slack/oauth/callback` -> Redirected to TTN UI (success/failure page or settings page).
    *   **If Connected:** User sees "Connected to [Workspace Name]" and "Disconnect from Slack" button.
3.  **Disconnect (if connected):**
    *   User clicks "Disconnect from Slack".
    *   Confirmation dialog appears.
    *   User confirms -> Frontend calls `DELETE /api/slack/connection`.
    *   Backend revokes token with Slack and deletes local record.
    *   UI updates to "Not Connected" state.

This flow provides clear steps for users to manage their Slack integration within the Team Task Notes application, leveraging the backend OAuth and data storage mechanisms.
---
