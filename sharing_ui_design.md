# Note Sharing and Permissions: UI Design & User Flow

This document outlines the UI components and user flow for managing note sharing and permissions, referencing the PRD, `sharing_permissions_api_endpoints.md`, and `note_management_ui_design.md`.

---

## General Principles:

*   **Clarity:** Users should easily understand who a note is shared with and their permission levels.
*   **Efficiency:** Sharing with users and teams, and modifying permissions should be quick and intuitive.
*   **Mobile-First:** The design should be responsive and work seamlessly on various screen sizes.

---

## 1. Accessing Sharing Settings

Users can access the sharing settings for a note from two primary locations:

*   **From the Note List View:**
    *   As defined in `note_management_ui_design.md`, each note card/list item has a "More Options" (`...`) icon.
    *   Tapping this icon reveals a context menu.
    *   A `Share` or `Manage Sharing` option will be added to this menu.
    *   **User Flow:** User taps `...` on a note -> Taps `Share` -> Sharing Interface (Modal Dialog) opens.

*   **From the Detailed Note View:**
    *   As defined in `note_management_ui_design.md`, the detailed note view has a header bar with actions.
    *   A `Share` button/icon will be prominently displayed in this header bar (or within a "More Options" menu if the header is crowded).
    *   **User Flow:** User opens a note to view details -> Taps `Share` button/icon -> Sharing Interface (Modal Dialog) opens.

---

## 2. Sharing Interface (Modal Dialog)

Upon initiating sharing, a modal dialog (or a full-screen view on smaller mobile devices) appears. This interface is the central hub for managing all sharing aspects of the selected note.

*   **Modal Header:**
    *   **Title:** "Share Note: [Note Title]" or "Manage Access: [Note Title]".
    *   **Close Button (`X`):** To dismiss the modal.

*   **Section 1: Share with Specific People**
    *   **Input Field (User Search):**
        *   **Placeholder Text:** "Enter name or email to share with..."
        *   **Functionality:** As the user types, an autocomplete dropdown appears suggesting matching users from the system (especially users within the same team, or recently collaborated with).
        *   Selecting a user from the dropdown adds them to a temporary "to be added" list below the input field before confirming the share.
    *   **Add User & Set Permissions:**
        *   Once a user is selected (e.g., from autocomplete), they appear in a staging area before final addition.
        *   Next to the selected user's name/email, a **Permission Dropdown** is displayed, defaulting to `'view'`.
        *   **Options:** `'View'`, `'Comment'`, `'Edit'` (as defined in `SharedWith.permission_level`).
        *   An **"Add" / "Share" Button** confirms adding this user with the selected permission level.
    *   **API Mapping:**
        *   Searching users might involve a `GET /api/users?search=<query>` endpoint (not yet defined, but implied).
        *   Clicking "Add" / "Share" for a user maps to `POST /api/notes/{note_id}/shares` with `user_id` and `permission_level`.

*   **Section 2: Currently Shared With**
    *   **Display:** A scrollable list of users who already have access to this note.
    *   **Each List Item Shows:**
        *   **User's Name and Email/Avatar.**
        *   **Current Permission Level:** Displayed as text (e.g., "Can view", "Can edit").
        *   **Permission Dropdown:** Allows changing the existing permission level for that user.
            *   **API Mapping:** Changing permission maps to `PUT /api/notes/{note_id}/shares/{user_id}`.
        *   **Remove Access Button (`X` or "Remove"):** Allows removing the user's access to the note.
            *   A confirmation prompt should appear before removal.
            *   **API Mapping:** Removing access maps to `DELETE /api/notes/{note_id}/shares/{user_id}`.
    *   **Empty State:** If not shared with anyone, a message like "This note is currently private." is displayed.
    *   **API Mapping (Initial Load):** This list is populated by `GET /api/notes/{note_id}/shares`.

*   **Section 3: Team Sharing (if applicable)**
    *   This section is visible if the note is associated with a team (`Notes.team_id` is not NULL).
    *   **Toggle Switch for `is_public_to_team`:**
        *   **Label:** "Make visible to everyone in [Team Name]" or "Team Access".
        *   **Functionality:** A toggle switch (On/Off).
            *   **Off (Default):** "Only explicitly shared team members can access."
            *   **On:** "Everyone in [Team Name] can view this note." (The default permission for team-wide access, e.g., 'view' or 'comment', should be clearly communicated or configurable at an application level).
        *   **API Mapping:** Toggling this switch updates the `is_public_to_team` flag via `PUT /api/notes/{note_id}` (as part of the note's general properties). The request would include `{"is_public_to_team": true/false}`.
    *   **Note:** If the note is *not* associated with any team (`team_id` is NULL), this section might be hidden or show a message like "This note is not part of a team. Assign it to a team to enable team-wide sharing."

*   **Modal Footer:**
    *   **"Done" or "Close" Button:** Saves any pending changes (though individual actions like adding/removing users or changing permissions might trigger API calls immediately for responsiveness) and closes the modal.

---

## 3. Visual Indicators of Sharing Status

Visual cues help users quickly understand a note's accessibility.

*   **In the Note List View (on each note card/item):**
    *   **Private Note (Default):** No specific icon, or a subtle "lock" icon.
    *   **Shared with Individuals:** A "people" / "users" icon. Hovering over this icon (on desktop) could show a tooltip like "Shared with X users".
    *   **Public to Team:** A "team" / "group" icon. If also shared with specific individuals outside the team or with specific permissions, both icons might be shown or combined.
    *   **Mixed Status:** If a note is public to the team AND shared with specific external users, a combination of icons or a generic "shared" icon could be used. The detailed view would provide clarity.

*   **In the Detailed Note View:**
    *   **Header Area:** Near the note title or share button, display icons similar to the list view (e.g., "people" icon, "team" icon).
    *   **Text Indicator:** A small text label like "Shared", "Private", or "Team Access" could also be displayed.
    *   **Tooltip/Popover:** Clicking or hovering on the sharing icons/status text could show a brief summary: "Shared with 3 people and public to Marketing Team."

---

## User Flow Summary:

1.  **Initiate Sharing:** User clicks "Share" (from list or detail view).
2.  **Sharing Modal Opens:**
    *   User sees who it's currently shared with (`GET /api/notes/{note_id}/shares`).
    *   User can search for new people to share with.
    *   For each new person, user selects permission level, clicks "Add" (`POST /api/notes/{note_id}/shares`).
    *   User can change permission for existing shared users (`PUT /api/notes/{note_id}/shares/{user_id}`).
    *   User can remove access for existing shared users (`DELETE /api/notes/{note_id}/shares/{user_id}`).
    *   User can toggle "Team Access" (`PUT /api/notes/{note_id}` with `is_public_to_team` flag).
3.  **Close Modal:** User clicks "Done" or "X".
4.  **Visual Update:** Icons/indicators in list and detail views update to reflect the new sharing status.

This design aims for a balance between providing comprehensive sharing controls and maintaining ease of use, aligning with the features defined in the API and overall application structure.
---
