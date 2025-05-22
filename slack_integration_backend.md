# Slack Integration: Backend Components and API Endpoints

This document outlines the backend design for integrating Team Task Notes with Slack, focusing on the OAuth 2.0 flow for connecting workspaces and handling slash commands for note creation.

---

## 1. Slack Connection (OAuth 2.0 Flow)

### 1.1. Conceptual OAuth 2.0 Flow

The OAuth 2.0 flow allows users to authorize Team Task Notes to access their Slack workspace and perform actions on their behalf (like creating notes).

1.  **Initiation:**
    *   A user in Team Task Notes initiates the "Add to Slack" or "Connect to Slack" process (e.g., by clicking a button).
    *   Team Task Notes redirects the user to Slack's authorization URL (`https://slack.com/oauth/v2/authorize`). This request includes parameters like `client_id` (our app's Slack client ID), `scope` (permissions we're requesting, e.g., `commands` for slash commands, `chat:write` for sending messages), `redirect_uri` (our callback URL), and an optional `state` parameter for security.

2.  **User Authorization on Slack:**
    *   The user is presented with Slack's authorization screen, showing the permissions Team Task Notes is requesting.
    *   If the user approves, Slack redirects them back to the `redirect_uri` specified by Team Task Notes. This redirect includes a temporary `code` and the `state` parameter (if provided).

3.  **Code Exchange and Token Retrieval:**
    *   Team Task Notes' backend receives the request at the callback URL.
    *   It first verifies the `state` parameter to prevent CSRF attacks.
    *   Then, it makes a secure server-to-server POST request to Slack's `https://slack.com/api/oauth.v2.access` endpoint. This request includes the received `code`, our app's `client_id`, and `client_secret`.
    *   Slack validates the request and, if successful, responds with a JSON payload containing an `access_token` (typically a bot token `xoxb-` or a user token `xoxp-` depending on requested scopes), `team.id`, `authed_user.id` (if user scopes were requested), and other relevant information.

4.  **Storing Connection Information:**
    *   Team Task Notes securely stores the `access_token`, Slack `team_id`, Slack `user_id` (if applicable), and any other necessary details (like bot ID or incoming webhook URL if requested).
    *   The user is then informed of the successful connection.

### 1.2. Team Task Notes API Endpoints for OAuth

*   **Endpoint 1: Initiate OAuth Flow**
    *   **HTTP Method:** `GET`
    *   **URL Path:** `/api/slack/oauth/initiate` (or `/slack/install`)
    *   **Brief Description:** Redirects the user to Slack's authorization URL. This endpoint constructs the appropriate Slack URL with `client_id`, `scope`, `redirect_uri`, and `state`.
    *   **Example Request:** User clicks "Add to Slack" button in Team Task Notes UI.
    *   **Example Response:** HTTP 302 Redirect to `https://slack.com/oauth/v2/authorize?client_id=YOUR_SLACK_CLIENT_ID&scope=commands,chat:write&redirect_uri=YOUR_APP_REDIRECT_URI&state=CSRF_TOKEN`

*   **Endpoint 2: OAuth Callback**
    *   **HTTP Method:** `GET`
    *   **URL Path:** `/api/slack/oauth/callback`
    *   **Brief Description:** Receives the authorization `code` from Slack after user approval. Exchanges the code for an access token and stores the connection information.
    *   **Example Request (from Slack):** `GET /api/slack/oauth/callback?code=TEMPORARY_AUTH_CODE&state=CSRF_TOKEN_FROM_INITIATION`
    *   **Backend Actions:**
        1.  Verify `state` parameter.
        2.  Call `https://slack.com/api/oauth.v2.access` with `code`, `client_id`, `client_secret`.
        3.  Receive `access_token`, `team.id`, `authed_user.id`, etc. from Slack.
        4.  Store this information (see section 1.3).
        5.  Redirect user to a success/failure page in Team Task Notes.
    *   **Example Response (to user's browser):** HTTP 302 Redirect to `/slack-connection-success` or `/slack-connection-failed`.

### 1.3. Storing Slack Connection Information

Key information to store securely for each connection:

*   **`app_user_id`:** The ID of the user in Team Task Notes who initiated the connection (if the connection is user-specific).
*   **`slack_user_id`:** The Slack User ID (`authed_user.id` from OAuth response).
*   **`slack_team_id`:** The Slack Team ID (`team.id` from OAuth response).
*   **`slack_bot_user_id`:** (Optional, if a bot user is part of the installation, `bot_user_id` from OAuth response).
*   **`access_token`:** The Slack access token (e.g., `xoxb-...` or `xoxp-...`). This must be encrypted at rest.
*   **`scopes`:** Comma-separated list of granted scopes.
*   **`raw_slack_response`:** (Optional, for debugging/future use) The full JSON response from `oauth.v2.access`.

**Storage Suggestion:**

Create a new table named `SlackConnections`:

```sql
CREATE TABLE SlackConnections (
    id INT PRIMARY KEY AUTO_INCREMENT,
    app_user_id INT, -- Foreign key to your Users table
    slack_user_id VARCHAR(50) NOT NULL, -- Slack's user ID (e.g., U12345)
    slack_team_id VARCHAR(50) NOT NULL, -- Slack's team ID (e.g., T12345)
    slack_bot_user_id VARCHAR(50), -- Slack's bot user ID (if applicable)
    access_token_encrypted TEXT NOT NULL, -- Encrypted access token
    scopes TEXT, -- Comma-separated list of scopes
    raw_slack_response JSON, -- Store the full OAuth response
    connected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE (app_user_id, slack_team_id), -- Assuming one connection per user per team
    UNIQUE (slack_user_id, slack_team_id), -- Or one connection per Slack user per team
    FOREIGN KEY (app_user_id) REFERENCES Users(id) ON DELETE CASCADE
);
```
*(The unique constraint might need adjustment based on whether connections are primarily per-TTN-user or per-Slack-user, or if multiple TTN users can connect to the same Slack workspace under different Slack user IDs).*

---

## 2. Slash Command for Note Creation

### 2.1. Slash Command API Endpoint

*   **HTTP Method:** `POST`
*   **URL Path:** `/api/slack/commands/createnote`
*   **Brief Description:** Receives slash command executions from Slack (e.g., `/createnote`). Validates the request, parses the command text, creates a note in Team Task Notes, and sends a response back to Slack.
*   **Request Validation:** Crucially, this endpoint MUST [verify requests from Slack](https://api.slack.com/authentication/verifying-requests-from-slack) using the signing secret.

### 2.2. Expected Payload from Slack

When a user executes `/createnote <title>; <content>` in Slack, Slack will send a POST request to the endpoint above with `Content-Type: application/x-www-form-urlencoded` and a body similar to this (fields may vary slightly):

```
token=DEPRECATED_VERIFICATION_TOKEN_DO_NOT_USE_FOR_VERIFICATION
team_id=T12345ABC
team_domain=myworkspace
channel_id=C12345XYZ
channel_name=general
user_id=U67890DEF  // The Slack user ID who executed the command
user_name=john.doe
command=/createnote
text=My Note Title; This is the content of my note.
api_app_id=A0KRD7HC3
is_enterprise_install=false
response_url=https://hooks.slack.com/commands/T12345ABC/1234567890/XXXXXXXXXXXXXXXXXXXXXXXX
trigger_id=13345224609.738474920.8088930838d88f008e0
```

**Key fields for processing:**
*   `user_id`: To identify the Slack user and find their corresponding Team Task Notes account via the `SlackConnections` table.
*   `team_id`: To identify the Slack workspace.
*   `text`: The raw text entered by the user after the command (e.g., "My Note Title; This is the content of my note.").
*   `response_url`: A temporary URL provided by Slack to send deferred or out-of-band responses. Valid for 30 minutes, up to 5 messages.
*   `trigger_id`: Used for opening modals.

### 2.3. Parsing Slash Command Text

The `text` field needs to be parsed to extract the note's title and content. A simple convention like using a semicolon (`;`) as a delimiter can be used:

*   **Input `text`:** `My Note Title; This is the content of my note.`
*   **Parsing Logic:**
    1.  Split the `text` string by the first occurrence of `;`.
    2.  The part before the semicolon is the `title`. Trim whitespace.
    3.  The part after the semicolon is the `content`. Trim whitespace.
    4.  If no semicolon is present, the entire `text` could be treated as the `title`, and the `content` could be empty or a default value. Alternatively, an error message could be returned asking for the correct format.

**Example:**
*   `text = "Meeting Summary; Discuss project X, decisions on Y."`
    *   `title = "Meeting Summary"`
    *   `content = "Discuss project X, decisions on Y."`
*   `text = "Quick thought"`
    *   `title = "Quick thought"`
    *   `content = ""` (or prompt for content/error)

### 2.4. Slash Command Response

The response to Slack should generally be an ephemeral message visible only to the user who executed the command. This is sent as a JSON payload in the HTTP response body.

*   **Successful Note Creation:**
    ```json
    {
      "response_type": "ephemeral",
      "text": "✅ Note created successfully!",
      "attachments": [
        {
          "title": "My Note Title",
          "title_link": "https://your.teamtasknotes.app/notes/NOTE_ID_HERE", // Link to the created note
          "text": "This is the content of my note."
        }
      ]
    }
    ```
    *(Alternatively, a simpler text-only response: `{"response_type": "ephemeral", "text": "✅ Note 'My Note Title' created successfully!"}`)*

*   **Error (e.g., User not connected, parsing error, API error):**
    ```json
    {
      "response_type": "ephemeral",
      "text": "⚠️ Error creating note: Could not parse title and content. Please use the format: `/createnote <title>; <content>`"
    }
    ```
    or
    ```json
    {
      "response_type": "ephemeral",
      "text": "⚠️ Error creating note: Your Slack account is not connected to Team Task Notes. Please connect it first at [Link to Team Task Notes Slack settings]."
    }
    ```

**Deferred Responses:**
If note creation takes longer than 3 seconds, an initial acknowledgement should be sent immediately:
```json
{
  "response_type": "ephemeral", // Or "in_channel" if you want it visible to others
  "text": "⏳ Creating your note..."
}
```
And the actual success/failure message can be sent later to the `response_url`.

This design provides a foundation for Slack integration, covering both the initial connection and a core interaction via slash commands.
---
