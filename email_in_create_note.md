# Email-in to Create Note: Backend System Design

This document outlines the backend system design for the "Email-in to Create Note" functionality in Team Task Notes, allowing users to create notes by sending an email to a dedicated address.

---

## 1. Email Receiving Mechanism

*   **Proposed Approach:** Utilize a third-party transactional email service with an inbound email processing feature (often called Inbound Parse Webhook, Routes, or similar).
    *   **Examples:** SendGrid Inbound Parse, Mailgun Routes, Amazon SES with Lambda and SNS.
    *   **Reasoning:** These services are specialized in handling the complexities of email (SPF/DKIM/DMARC checks, spam filtering, parsing MIME types, etc.) and can reliably convert incoming emails into a structured format (typically JSON) posted to a webhook URL we define. This offloads significant development and maintenance effort.

*   **Information Provided to Backend (Typical JSON Payload):**
    When an email is received by such a service and forwarded to our backend webhook, the JSON payload typically includes:
    *   `from`: Sender's email address (e.g., `"John Doe <john.doe@example.com>"`) and sometimes a parsed version (name and email separate).
    *   `to`: Recipient email address(es) (e.g., `["create@notes.yourdomain.com"]`).
    *   `cc`: CC'd email address(es).
    *   `bcc`: BCC'd email address(es) (less common for privacy reasons, but possible).
    *   `subject`: Email subject line.
    *   `text`: Plain text content of the email body.
    *   `html`: HTML content of the email body (if present).
    *   `headers`: Full email headers (often as a string or key-value map).
    *   `attachments`: An array of attachment objects. Each attachment object might include:
        *   `filename`: Original filename (e.g., `"document.pdf"`).
        *   `content_type`: MIME type (e.g., `"application/pdf"`).
        *   `size`: File size in bytes.
        *   `content`: The actual file content, usually Base64 encoded, or a URL from which the attachment can be downloaded from the email service provider temporarily.
    *   `dkim`: Result of DKIM validation (e.g., `pass`, `fail`, `neutral`).
    *   `spf`: Result of SPF validation.
    *   `spam_score` / `spam_report`: Spam filtering results.
    *   `message_id`: Unique ID of the email message.

---

## 2. Dedicated Email Address

*   **Suggested Format:** A single, global email address for all users.
    *   Example: `create@notes.yourdomain.com` or `new@notes.yourdomain.com`
*   **Alternative (More Complex):** User-specific or team-specific addresses (e.g., `username.create@notes.yourdomain.com` or `teamname.notes@yourdomain.com`).
    *   **Consideration:** This adds complexity in routing and configuration within the email receiving service and our backend. For MVP, a single global address is simpler. The user is identified by their `From` address.

---

## 3. Backend Processing Endpoint (Webhook)

*   **API Endpoint Definition:**
    *   **HTTP Method:** `POST`
    *   **URL Path:** `/api/email/inbound/createnote` (or similar, e.g., `/webhooks/email/notes`)
    *   **Brief Description:** Receives incoming email data (as a JSON payload) from the configured third-party email service. It processes this data to create a new note.

*   **Expected Request Body:**
    *   The endpoint expects a `JSON` payload. The structure will depend on the chosen email service provider, but it will generally align with the fields listed in section 1 (e.g., `from`, `to`, `subject`, `text`, `html`, `attachments`).
    *   The Team Task Notes application will need to adapt its processing logic to the specific JSON structure provided by the selected email service (e.g., SendGrid's format will differ slightly from Mailgun's).

    **Example Conceptual JSON Structure (generic):**
    ```json
    {
      "sender": { // Often 'from' is a string, parsing might be needed
        "email": "john.doe@example.com",
        "name": "John Doe"
      },
      "recipient": "create@notes.yourdomain.com",
      "subject": "My New Note Title",
      "body_plain": "This is the content of my note.\n\nSent from my email.",
      "body_html": "<html><body><p>This is the content of my note.</p><p>Sent from my email.</p></body></html>",
      "attachments": [
        {
          "filename": "report.pdf",
          "contentType": "application/pdf",
          "size": 102400, // bytes
          "data_base64": "JVBERi0xLjQKJe..." // Base64 encoded content or a download URL
        }
      ],
      "spam_detected": false, // Example field from service
      "dkim_valid": true     // Example field from service
    }
    ```

---

## 4. Parsing Logic (Mapping Email to Note)

1.  **Identify User:**
    *   Extract the sender's email address from the `from` field of the payload.
    *   Clean the email address (e.g., if it's in the format `"John Doe <john.doe@example.com>"`, extract `john.doe@example.com`).

2.  **Map to Note Fields:**
    *   **Note Title:**
        *   Use the email's `subject` field.
        *   If the subject is empty, a default title like "Note from [Sender's Name/Email] on [Date]" could be used, or the first few words of the body.
    *   **Note Content:**
        *   Prioritize the `text` (plain text) part of the email body for simplicity and to avoid complex HTML sanitization issues initially.
        *   If `text` is empty but `html` is present, the `html` body could be converted to Markdown or plain text (requires a library and careful sanitization to prevent XSS if rendered later as HTML). For MVP, sticking to `text` is safer.
        *   Email signatures: It's common for email bodies to contain signatures. Ideally, a signature stripping library/heuristic could be applied to clean the content (e.g., looking for common patterns like "--" or "Regards,"). This can be an iterative improvement.
    *   **`created_by`:** Set to the Team Task Notes `user_id` identified in step 1 (see section 5).
    *   **Default Fields for New Note:**
        *   `status_id`: Default to 'open' (or the system's default new note status).
        *   `priority`: Default to 'Medium'.
        *   `team_id`: Could be `NULL` by default, or set to the user's primary team if that logic exists.
        *   `due_date`: Not typically set from email unless a specific format in subject/body is implemented (adds complexity).

3.  **Handle Attachments:**
    *   Iterate through the `attachments` array in the payload.
    *   For each attachment:
        *   **Download/Decode:** If the content is Base64 encoded, decode it. If it's a URL, download the file from the email service provider (ensure this is done securely and promptly as such URLs are often temporary).
        *   **Storage:** Save the file to the application's standard attachment storage location (e.g., cloud storage like S3, local filesystem).
        *   **Database Record:** Create a new record in the `Attachments` table, associating it with the `note_id` of the newly created note. Store `file_name`, `file_path` (or storage key), and `content_type`.
    *   **Limits:** Consider imposing limits on attachment size and number per email to prevent abuse.

---

## 5. User Association & Security

*   **User Association:**
    *   The primary method for associating the email with a Team Task Notes user is by matching the sender's email address (from the `From` field) with the `email` column in the `Users` table.
    *   `SELECT id, team_id FROM Users WHERE email = :sender_email LIMIT 1;`

*   **Sender Email Not Found:**
    *   **MVP Approach:** If the sender's email address does not match any registered user in the `Users` table, the email should be rejected or silently ignored. This is the simplest and most secure initial approach.
    *   **Optional Future Enhancements:**
        *   **Send Bounce-back/Error Email:** Inform the sender that their email could not be processed because their address is not associated with an account. This requires an outbound email capability.
        *   **Invite User/Temporary Note:** Create a new "invited" user account or a temporary note that can be claimed. This adds significant complexity around user onboarding and security. (Not recommended for MVP).

*   **Security Considerations:**
    *   **SPF/DKIM/DMARC Verification:** Rely on the chosen third-party email receiving service to perform these checks. The payload from the service should indicate the results (e.g., `dkim: pass`, `spf: pass`). Emails failing these checks could be given a lower trust score or rejected outright by our webhook processing logic.
    *   **Webhook Security:**
        *   The webhook endpoint should use HTTPS.
        *   Some email services allow configuring a secret token that they include in webhook requests. Our endpoint should verify this token to ensure requests are genuinely from the configured service.
    *   **Rate Limiting:** Implement rate limiting on the `/api/email/inbound/createnote` endpoint (e.g., by sender IP, or by identified user if possible after initial parsing) to prevent abuse.
    *   **Content Sanitization:** If HTML email content is ever used for the note body, it MUST be rigorously sanitized to prevent XSS attacks. Using plain text only for MVP avoids this.
    *   **Attachment Scanning:** For enhanced security, consider integrating a virus/malware scanner for attachments before making them accessible. This can be a complex addition.
    *   **Preventing Loops:** Ensure that any automated replies (like success/failure confirmations) do not create email loops (e.g., by checking if the recipient is our own `create@` address or by using specific headers like `X-Auto-Response-Suppress`).

---

## 6. Reply/Feedback Mechanism (Optional)

*   **Consideration:** Should the user receive an email confirmation after their emailed note is processed?
*   **Success Confirmation:**
    *   **Pro:** Provides assurance to the user that their note was created. Can include a link to the new note.
    *   **Con:** Adds complexity (requires outbound email sending capability) and could contribute to inbox clutter for frequent users.
    *   **Implementation:** If done, send an email from a `no-reply@notes.yourdomain.com` address back to the original sender.
        *   Subject: "Note '[Note Title]' created successfully"
        *   Body: "Your note '[Note Title]' has been successfully created in Team Task Notes. You can view it here: [Link to Note]"

*   **Failure Confirmation (e.g., sender not found, processing error):**
    *   **Pro:** Informs the user why their email didn't result in a note.
    *   **Con:** Similar to success confirmations; also, if rejecting emails from unknown senders, a bounce-back might not be desired as it confirms the email address is monitored.
    *   **Implementation:** If the sender is a registered user but an error occurred (e.g., attachment too large, internal server error), a failure email can be useful.

*   **MVP Approach:** For MVP, no email feedback might be the simplest. The user can verify note creation by checking the app. Feedback can be added as a V2 feature based on user demand.

This design provides a comprehensive backend system for the "Email-in to Create Note" feature, balancing functionality with security and implementation complexity.
---
