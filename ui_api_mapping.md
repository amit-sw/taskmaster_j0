# UI Actions to API Endpoint Mapping for Note Management

This document maps UI actions and components described in `note_management_ui_design.md` to the backend API endpoints defined in `notes_api_endpoints.md`.

---

## 1. Viewing a List of Notes (Dashboard / Notes Page)

*   **UI Action:** User navigates to the notes dashboard/page.
*   **Mapping:**
    *   The frontend makes a `GET` request to `/api/notes`.
    *   **Filtering:** If the user applies filters (e.g., by status, team, tags), these are translated into query parameters for the `GET` request. For example:
        *   Filter by status "Completed" (assuming status ID 3): `GET /api/notes?status_id=3`
        *   Filter by team "Marketing" (assuming team ID 1): `GET /api/notes?team_id=1`
        *   Filter by tag "urgent" (assuming tag ID 5): `GET /api/notes?tag_id=5` (Note: API for tag filtering might need specific design if not covered by a generic query param).
    *   **Sorting:** If the user applies sorting (e.g., by due date), this is translated into query parameters. For example:
        *   Sort by due date ascending: `GET /api/notes?sort_by=due_date&order=asc`
    *   The response data (an array of note objects) is used to render the individual note summary cards/list items.
    *   Fields like `title`, `due_date`, `status_id` (which would be mapped to a display name like "Open", "In Progress"), and `team_id` (mapped to team name) from the API response are used to populate the UI elements on each note card.

---

## 2. Viewing a Single Note (Detailed View)

*   **UI Action:** User taps/clicks on a note card from the list view.
*   **Mapping:**
    *   The frontend retrieves the unique ID of the selected note (`note_id`).
    *   It then makes a `GET` request to `/api/notes/{note_id}` (e.g., `/api/notes/123`).
    *   The response data (a single note object with full details like `title`, `content`, `due_date`, `status_id`, `team_id`, etc.) is used to populate the detailed note view.
    *   Checklist items within the `content` would be parsed and rendered appropriately by the frontend.

---

## 3. Creating a New Note

*   **UI Action:** User taps the "Quick Add" FAB, fills out the "New Note" form (title, content, due date, priority, tags, team, status), and taps "Save" / "Create".
*   **Mapping:**
    *   The frontend gathers the data from the form fields.
        *   `title`: from the title input.
        *   `content`: from the content editor (including any checklist formatting).
        *   `due_date`: from the date picker (formatted as ISO 8601 string).
        *   `status_id`: from the status selector (maps to a status ID).
        *   `team_id`: (optional) from the team selector.
        *   (Note: `priority` and `tags` are mentioned in UI but not explicitly in the `POST /api/notes` example request body in `notes_api_endpoints.md`. Assuming the API can accept these or they are handled differently, e.g. tags could be a separate API call after note creation or part of an extended POST request). For this mapping, we'll assume `status_id` and `team_id` are covered.
    *   The frontend makes a `POST` request to `/api/notes`.
    *   The request body will contain the collected data, for example:
        ```json
        {
          "title": "User's New Note Title",
          "content": "User's note content here...",
          "due_date": "2024-11-15T10:00:00Z",
          "status_id": 1, // e.g., 'Open'
          "team_id": 2 // Optional
        }
        ```
    *   Upon successful creation (e.g., 201 Created response), the UI might navigate to the detailed view of the new note or refresh the notes list. The response body from the API (`id`, `created_at`, etc.) will be used to update the frontend's state.

---

## 4. Editing an Existing Note

*   **UI Action (Trigger):**
    *   User taps "Edit" from the note list actions for a specific note.
    *   User taps "Edit" from the detailed note view of a specific note.
*   **UI Action (Form Interaction):** The user modifies the pre-filled form fields (title, content, due date, priority, status, tags, team) and taps "Save Changes".
*   **Mapping:**
    *   The frontend first fetches the full note details using `GET /api/notes/{note_id}` if it doesn't already have them, to populate the edit form.
    *   When the user clicks "Save Changes", the frontend gathers all the (potentially modified) data from the form fields, similar to the "Create Note" process.
    *   It then makes a `PUT` request (or `PATCH` for partial updates) to `/api/notes/{note_id}` (e.g., `/api/notes/123`).
    *   The request body will contain the complete updated representation of the note (for PUT) or the changed fields (for PATCH). Example for PUT:
        ```json
        {
          "title": "Updated Note Title",
          "content": "Updated note content.",
          "due_date": "2024-12-01T10:00:00Z",
          "status_id": 2, // e.g., 'In Progress'
          "team_id": 2
        }
        ```
    *   Upon successful update (e.g., 200 OK response), the UI might navigate back to the detailed view (which should reflect the updates) or refresh the note in the list. The API response with the updated note object is used to update the frontend state.

*   **UI Action (Changing Status directly):**
    *   User changes status from a dropdown in the detailed view or uses "Mark as Complete" / "Reopen" from the list view.
    *   **Mapping:** This is a specific case of editing a note.
        *   The frontend would determine the `note_id` and the new `status_id`.
        *   It would then make a `PUT` or `PATCH` request to `/api/notes/{note_id}` with at least the `status_id` field. If other fields are required by the `PUT` endpoint, they must be included, potentially fetching the note's current state first. For `PATCH`:
            ```json
            // PATCH /api/notes/123
            {
              "status_id": 3 // e.g., 'Completed'
            }
            ```
        *   The UI updates to reflect the new status.

---

## 5. Deleting a Note

*   **UI Action:**
    *   User taps "Delete" from the note list actions (via "More Options" menu) for a specific note and confirms in a dialog.
    *   User taps "Delete" from the detailed note view (often in a "More Options" menu) and confirms.
*   **Mapping:**
    *   The frontend retrieves the unique ID of the note to be deleted (`note_id`).
    *   It then makes a `DELETE` request to `/api/notes/{note_id}` (e.g., `/api/notes/123`).
    *   Upon successful deletion (e.g., 204 No Content or 200 OK response), the frontend removes the note from the list view or navigates away from the detailed view.

---

**Notes on Fields Not Explicitly in Notes API CRUD Examples:**

*   **Priority & Tags (UI Design):** The UI design includes `Priority` and `Tags` as part of note creation/editing. The provided `notes_api_endpoints.md` for `POST /api/notes` and `PUT /api/notes/{note_id}` does not explicitly list `priority` or `tags` in the example request bodies.
    *   **Possible Handling for API:**
        1.  These fields might be accepted by the API even if not in examples (e.g., `priority_id INT`, `tag_ids INT[]`).
        2.  Tags might be managed via separate endpoints (e.g., `POST /api/notes/{note_id}/tags`, `DELETE /api/notes/{note_id}/tags/{tag_id}`).
    *   **Mapping Assumption:** For this document, we assume the `POST` and `PUT` requests to `/api/notes` can include `priority_id` and an array of `tag_ids` if the backend supports it. Otherwise, separate API calls would be needed, and this mapping would need to be updated.
*   **Attachments:** Attachment management (`Add Attachment` button, listing attachments) is part of the UI design but not covered by the basic CRUD API in `notes_api_endpoints.md`. This would require separate API endpoints (e.g., `POST /api/notes/{note_id}/attachments`, `GET /api/notes/{note_id}/attachments`, `DELETE /api/attachments/{attachment_id}`) and a corresponding UI-API mapping section. This document focuses on the core note data.

This mapping covers the primary CRUD operations for notes based on the provided UI and API designs.
