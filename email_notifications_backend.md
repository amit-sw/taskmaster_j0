# Email Notifications: Backend System Design

This document outlines the backend system design for sending email notifications from Team Task Notes to its users, triggered by specific in-app events.

---

## 1. Triggering Events for Email Notifications

The system will initially focus on a core set of events, with the possibility of expansion.

*   **Primary Events for Current Scope:**
    1.  **Direct Share with a User:**
        *   **Trigger:** A new entry is created in the `SharedWith` table, granting a specific user access to a note.
        *   **Goal:** Inform the recipient user that a note has been shared with them.
    2.  **Note Made Public to Team:**
        *   **Trigger:** A note's `is_public_to_team` flag is set to `TRUE`.
        *   **Goal:** Inform all members of the note's associated team that a new note is now available for team viewing/collaboration.

*   **Potential Future Triggers (for consideration):**
    *   **New Comment:** A new comment is added to a note that the user owns, is shared on, or is following.
    *   **Due Date Reminder:** A note's due date is approaching or has passed.
    *   **Task Assignment/Update:** If tasks are explicitly assigned within notes.
    *   **Mention in a Note/Comment:** If a user is @mentioned.

---

## 2. Identifying Email Recipients

The system needs to identify the correct email addresses for the intended recipients based on the triggering event.

*   **For Direct Shares (`SharedWith` table creation):**
    1.  The `user_id` in the newly created `SharedWith` record identifies the Team Task Notes (TTN) recipient.
    2.  Fetch the recipient's details from the `Users` table:
        `SELECT email, name FROM Users WHERE id = :shared_with_user_id;`
    3.  The `email` field obtained is the target for the notification.

*   **For Notes Made `is_public_to_team`:**
    1.  The `team_id` on the `Notes` record (whose `is_public_to_team` flag was set to `TRUE`) identifies the relevant TTN team.
    2.  Fetch details for all users belonging to this `team_id`:
        `SELECT id, email, name FROM Users WHERE team_id = :note_team_id;`
    3.  The `email` field for each user in the result set is a target for the notification.
    4.  **Exclusion:** The user who made the note public to the team should ideally be excluded from this specific notification (as they performed the action).

---

## 3. Email Templates (Conceptual)

Emails should be clear, informative, and provide direct calls to action. Using multipart (HTML and plain text) emails is best practice for compatibility across various email clients.

### 3.1. Notification: Note Shared Directly

*   **Suggested Subject Line:**
    *   `[Sharer's Name] shared the note "[Note Title]" with you in Team Task Notes`
    *   `You've been invited to collaborate on "[Note Title]" in Team Task Notes`

*   **Key Content Elements (HTML Body):**
    *   **Header/Logo:** Team Task Notes logo.
    *   **Salutation:** "Hi [Recipient's Name],"
    *   **Core Message:** "[Sharer's Name/Email] has shared a note titled **'[Note Title]'** with you and granted you '[Permission Level]' permission."
    *   **(Optional) Snippet of Note Content:** A brief preview of the note's content (first few lines, plain text).
    *   **Call to Action (Button):**
        *   Text: "View Note" or "Open in Team Task Notes"
        *   Link: A direct deep link to the specific note within the Team Task Notes application (e.g., `https://your.teamtasknotes.app/notes/NOTE_ID_HERE`).
    *   **Footer:** Basic app information, link to settings, unsubscribe link.

*   **Plain Text Version:** A simplified text-only version of the above for email clients that don't render HTML.

### 3.2. Notification: Note Made Public to Team

*   **Suggested Subject Line:**
    *   `New team note available: "[Note Title]" in [Team Name]`
    *   `"[Note Title]" is now visible to the [Team Name] team`

*   **Key Content Elements (HTML Body):**
    *   **Header/Logo:** Team Task Notes logo.
    *   **Salutation:** "Hi [Recipient's Name]," or "Hello [Team Name] Team," (if a generic team notification).
    *   **Core Message:** "[Actor's Name/Email] has made the note **'[Note Title]'** visible to everyone in the '[Team Name]' team."
    *   **(Optional) Snippet of Note Content:** A brief preview.
    *   **Call to Action (Button):**
        *   Text: "View Team Note" or "Open Note"
        *   Link: Direct deep link to the note.
    *   **Footer:** Basic app information, link to settings, unsubscribe link.

*   **Plain Text Version:** A simplified text-only version.

---

## 4. Sending Mechanism

*   **Recommendation:** Utilize a third-party transactional email service.
    *   **Examples:** SendGrid, Mailgun, Amazon SES, Postmark, Mailchimp Transactional (formerly Mandrill).
    *   **Reasoning:** These services specialize in email deliverability (handling SPF, DKIM, DMARC, IP reputation, bounce processing, unsubscribe handling, analytics) which is complex to manage reliably in-house.

*   **Authentication with Email Service:**
    *   Typically, authentication is done via an **API Key**.
    *   The Team Task Notes backend would securely store this API key (e.g., in environment variables or a secrets management system).
    *   The API key is included in the HTTP headers of API requests made to the email service (e.g., `Authorization: Bearer YOUR_API_KEY`).

*   **Information Provided to Email Service API:**
    When sending an email, our backend would make an API call (usually a POST request to a specific endpoint like `/mail/send`) to the chosen service, providing a JSON payload with details like:
    *   `from`:
        *   `email`: The sender email address (e.g., `notifications@notes.yourdomain.com` or `no-reply@notes.yourdomain.com`).
        *   `name`: (Optional) The sender name (e.g., "Team Task Notes" or "[App Name] Notifications").
    *   `to`: An array of recipient objects, each containing:
        *   `email`: The recipient's email address.
        *   `name`: (Optional) The recipient's name.
    *   `subject`: The email subject line.
    *   `html`: The HTML version of the email body.
    *   `text`: The plain text version of the email body (for multipart emails).
    *   **(Optional) Tracking Settings:** Configuration for open tracking, click tracking, etc.
    *   **(Optional) Headers:** Custom headers if needed (e.g., for unsubscribe links or categorization).

---

## 5. User Preferences & Unsubscribes (Consideration)

While the full UI/UX for managing these preferences is a separate task, the backend needs to be designed with this in mind.

*   **Support for Preferences:**
    *   The system will eventually need a way for users to opt-out of:
        *   Specific types of email notifications (e.g., "don't email me for new team notes, only direct shares").
        *   All email notifications (a global unsubscribe).
    *   This typically involves adding columns to the `Users` table or a dedicated `UserNotificationPreferences` table (e.g., `user_id, notification_type_id, is_enabled_email`).

*   **Handling Unsubscribe Links:**
    1.  **Unique Link Generation:** Each notification email that allows unsubscription for that type (or globally) must contain an unsubscribe link. This link should be unique to the user and the notification type (if granular).
        *   Example: `https://your.teamtasknotes.app/api/email/unsubscribe?token=UNIQUE_UNSUBSCRIBE_TOKEN`
    2.  **Token:** The `UNIQUE_UNSUBSCRIBE_TOKEN` would be a securely generated token (e.g., JWT or a long random string) that encodes the `user_id` and potentially the `notification_type` to unsubscribe from. This token is stored temporarily or can be verified by its signature.
    3.  **API Endpoint for Unsubscribe:**
        *   **HTTP Method:** `GET` (for link clicking) or `POST` (if a form is involved).
        *   **URL Path:** `/api/email/unsubscribe`
        *   **Action:**
            *   The endpoint validates the `token`.
            *   If valid, it updates the user's notification preferences in the database (e.g., sets `email_direct_share_notifications_enabled = false` for that user).
            *   It then displays a confirmation page to the user (e.g., "You have been unsubscribed from these notifications.").
    4.  **Email Service Integration:** Many third-party email services also offer their own unsubscribe handling (global list-unsubscribe headers). We should integrate with these where possible, ensuring our internal user preference state is the source of truth or is synchronized.

*   **Checking Preferences Before Sending:**
    *   Before sending any email notification, the backend logic must first check the recipient user's preferences. If they have opted out of that specific notification type (or all notifications), the email should not be sent.

This design ensures that email notifications are relevant, well-formatted, and respect user preferences for communication.
---
