# Slack Notifications: Backend Logic and Process

This document outlines the backend logic and process for sending notifications from Team Task Notes to Slack, based on `slack_integration_backend.md` and the PRD.

---

## 1. Triggering Events for Slack Notifications

Based on the current scope, the following events in Team Task Notes will trigger Slack notifications:

1.  **Direct Share with a User:**
    *   **Trigger:** A note is shared with a specific Team Task Notes user via an entry being created in the `SharedWith` table.
    *   **Notification Goal:** Inform the recipient user in Slack that a note has been shared with them directly, specifying the note and the permission level granted.

2.  **Note Made Public to Team:**
    *   **Trigger:** A note's `is_public_to_team` flag is set to `TRUE`.
    *   **Notification Goal:** Inform all members of the note's associated team (who have a Slack connection) that a new note is now available for team viewing/collaboration.

---

## 2. Identifying Notification Recipients

### 2.1. For Direct Shares (`SharedWith` table creation)

*   **Step 1: Identify TTN User:** The `user_id` in the newly created `SharedWith` record is the Team Task Notes (TTN) user who should be notified.
*   **Step 2: Find Slack Connection:**
    *   Query the `SlackConnections` table using this TTN `user_id`.
    *   `SELECT slack_user_id, access_token_encrypted FROM SlackConnections WHERE app_user_id = :ttn_user_id;`
*   **Step 3: Determine Slack Recipient ID:**
    *   The `slack_user_id` retrieved from `SlackConnections` is the target for the direct message (DM) on Slack.
    *   The associated `access_token_encrypted` (after decryption) will be used to send the message.

### 2.2. For Notes Made `is_public_to_team`

*   **Step 1: Identify TTN Team:** The `team_id` on the `Notes` record whose `is_public_to_team` flag was just set to `TRUE` is the relevant TTN team.
*   **Step 2: Identify TTN Users in that Team:**
    *   Query the `Users` table for all users belonging to this `team_id`.
    *   `SELECT id FROM Users WHERE team_id = :note_team_id;`
*   **Step 3: Find Slack Connections for Each Team Member:**
    *   For each TTN user ID obtained in Step 2:
        *   Query `SlackConnections`: `SELECT slack_user_id, access_token_encrypted FROM SlackConnections WHERE app_user_id = :team_member_ttn_user_id;`
*   **Step 4: Determine Slack Recipient IDs:**
    *   For each team member who has an active Slack connection, their `slack_user_id` is a target for a DM.
    *   The respective `access_token_encrypted` will be used for each message.
    *   **Channel consideration (Future Enhancement):**
        *   Currently, the design defaults to DMing all connected team members.
        *   For a future enhancement, a `TeamSlackSettings` table could be introduced:
            ```sql
            CREATE TABLE TeamSlackSettings (
                ttn_team_id INT PRIMARY KEY,
                default_notification_channel_id VARCHAR(50), -- Slack Channel ID (e.g., C012345)
                FOREIGN KEY (ttn_team_id) REFERENCES Teams(id) ON DELETE CASCADE
            );
            ```
        *   If such a setting exists and a `default_notification_channel_id` is configured for the `ttn_team_id`, the notification could be sent to this channel instead of DMs. This would typically use the bot token associated with the workspace (`slack_team_id`). The Slack API `chat.postMessage` can send to a `channel_id` or a `user_id` (for DMs).

---

## 3. Crafting Notification Messages (Using Slack Block Kit)

Slack messages will be crafted using Block Kit for better formatting and interactivity.

### 3.1. Notification: Note Shared Directly

*   **Content Idea:** "[User X] shared a note with you: '[Note Title]' with [Permission Level] permission. [Link to Note]"
*   **Block Kit JSON Example:**
    ```json
    {
      "channel": "SLACK_USER_ID_TO_DM", // Target Slack User ID
      "blocks": [
        {
          "type": "section",
          "text": {
            "type": "mrkdwn",
            "text": ":page_facing_up: *A new note has been shared with you!*"
          }
        },
        {
          "type": "section",
          "fields": [
            {
              "type": "mrkdwn",
              "text": "*Shared by:*\n<@SLACK_ID_OF_SHARER> (or TTN User Name if Slack ID not available)"
            },
            {
              "type": "mrkdwn",
              "text": "*Note Title:*\n<https://your.teamtasknotes.app/notes/NOTE_ID_HERE|NOTE_TITLE_HERE>"
            },
            {
              "type": "mrkdwn",
              "text": "*Permission:*\nPERMISSION_LEVEL_HERE (e.g., View, Edit)"
            }
          ]
        },
        {
          "type": "actions",
          "elements": [
            {
              "type": "button",
              "text": {
                "type": "plain_text",
                "text": "Open Note",
                "emoji": true
              },
              "value": "open_note_NOTE_ID_HERE",
              "url": "https://your.teamtasknotes.app/notes/NOTE_ID_HERE",
              "action_id": "button_open_note"
            }
          ]
        }
      ]
    }
    ```
    *   `SLACK_USER_ID_TO_DM`: Recipient's Slack User ID.
    *   `SLACK_ID_OF_SHARER`: Slack User ID of the person who shared the note (if available, otherwise use TTN name).
    *   `NOTE_ID_HERE`, `NOTE_TITLE_HERE`, `PERMISSION_LEVEL_HERE`: Dynamic data.

### 3.2. Notification: Note Made Public to Team

*   **Content Idea:** "A note '[Note Title]' has been made public to the [Team Name] team by [User X]. [Link to Note]"
*   **Block Kit JSON Example (for DM to each team member):**
    ```json
    {
      "channel": "SLACK_USER_ID_OF_TEAM_MEMBER", // Target Slack User ID of team member
      "blocks": [
        {
          "type": "section",
          "text": {
            "type": "mrkdwn",
            "text": ":loudspeaker: *A note is now available for your team!*"
          }
        },
        {
          "type": "section",
          "fields": [
            {
              "type": "mrkdwn",
              "text": "*Team:*\nTEAM_NAME_HERE"
            },
            {
              "type": "mrkdwn",
              "text": "*Note Title:*\n<https://your.teamtasknotes.app/notes/NOTE_ID_HERE|NOTE_TITLE_HERE>"
            },
            {
              "type": "mrkdwn",
              "text": "*Made public by:*\n<@SLACK_ID_OF_USER_WHO_MADE_PUBLIC> (or TTN User Name)"
            }
          ]
        },
        {
          "type": "actions",
          "elements": [
            {
              "type": "button",
              "text": {
                "type": "plain_text",
                "text": "View Note",
                "emoji": true
              },
              "value": "view_note_NOTE_ID_HERE",
              "url": "https://your.teamtasknotes.app/notes/NOTE_ID_HERE",
              "action_id": "button_view_note"
            }
          ]
        }
      ]
    }
    ```
    *   If sending to a common team channel (future enhancement), the `channel` would be the `channel_id`.

---

## 4. Sending Mechanism

### 4.1. Slack API Endpoint

*   The primary Slack API method for sending these notifications will be `chat.postMessage`.
*   This method allows sending messages to a specific channel, a private channel, or directly to a user (DM) by providing the appropriate `channel` ID (which can be a user ID for DMs).

### 4.2. Authentication (Using Access Token)

1.  **Retrieve Token:** When a notification needs to be sent, the backend logic will identify the target TTN user(s). For each user, it will look up their `SlackConnections` record.
2.  **Decrypt Token:** The `access_token_encrypted` field from `SlackConnections` will be decrypted to get the plaintext Slack access token (e.g., `xoxb-...` for bot tokens, which are generally preferred for app-initiated notifications, or `xoxp-...` if user-specific actions are taken).
    *   **Bot Token Preference:** If the app was installed with bot token scopes (e.g., `chat:write` for the bot), this token is generally used for app-initiated notifications like these. The `SlackConnections` table might store the bot token associated with the `slack_team_id` or the specific `slack_user_id` if it's a user token with necessary permissions. For notifications, a bot token is usually more appropriate. The `access_token` stored could be the bot token obtained during the OAuth flow.
3.  **Make API Call:** The `chat.postMessage` API call will be made with this access token included in the `Authorization` header:
    ```
    POST https://slack.com/api/chat.postMessage
    Authorization: Bearer YOUR_DECRYPTED_ACCESS_TOKEN
    Content-type: application/json; charset=utf-8

    {
      "channel": "TARGET_SLACK_USER_ID_OR_CHANNEL_ID",
      "blocks": [ ... Block Kit JSON ... ],
      "text": "Fallback text for notifications that don't support blocks." // Important for accessibility
    }
    ```

### 4.3. Backend Process Flow (Example: Direct Share)

1.  **Event:** A new row is inserted into `SharedWith` (e.g., TTN User A shares Note N with TTN User B with 'edit' permission).
2.  **Notification Service Triggered:** A backend service (e.g., an asynchronous task queue worker, or a post-database-commit hook) is triggered by this event.
3.  **Identify Recipient:** The service identifies TTN User B as the recipient.
4.  **Fetch Slack Connection:** It queries `SlackConnections` for `app_user_id = TTN User B's ID`.
5.  **If Connection Exists:**
    *   Retrieve `slack_user_id` and decrypted `access_token`.
    *   Optionally, fetch sharer's (TTN User A) Slack ID if available to include in the message (`<@SLACK_ID_OF_SHARER>`).
    *   Construct the Block Kit JSON for the "Note Shared Directly" notification, filling in dynamic details (Note N's title, ID, link, 'edit' permission).
    *   Make a `POST` request to `https://slack.com/api/chat.postMessage` using the retrieved `access_token` and the constructed JSON payload, targeting User B's `slack_user_id` as the `channel`.
6.  **Logging:** Log the outcome (success/failure) of the notification attempt.

This process ensures that relevant users are notified in Slack about important events within Team Task Notes, enhancing collaboration and awareness.
---
