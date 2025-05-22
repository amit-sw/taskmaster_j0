# Search and Saved Filters: UI Design & User Flow

This document outlines the UI components and user flow for search functionality and the conceptual management of saved custom filters within the Team Task Notes application. This design is based on the PRD, `notes_api_enhancements.md`, and `note_management_ui_design.md`.

---

## 1. Search Functionality

The search functionality allows users to quickly find notes based on keywords in their title or content, integrated with existing filtering options.

### 1.1. Search Bar Location

*   **Primary Location:** A prominent **Search Bar** will be located in the main application header, making it globally accessible from most views.
*   **Alternative/Contextual Location:** When viewing the "List of Notes" (Dashboard / Notes Page), if the global header search is not the primary interaction point for this page, a search bar could also be placed directly above the note list, integrated with the existing filter controls (as described in `note_management_ui_design.md`). For consistency and immediate visibility, a global header search is often preferred.

    **Chosen Approach for this Design:** A global search bar in the main application header.

### 1.2. Initiating a Search

*   **User Action:**
    1.  The user types their search query (e.g., "meeting agenda", "urgent report") into the global Search Bar.
    2.  The search can be initiated in a few ways:
        *   **On-the-fly (Debounced):** As the user types, after a short delay (e.g., 300-500ms), the search automatically executes. This provides immediate feedback.
        *   **Explicit Submission:** User types their query and presses "Enter" or clicks a "Search" icon/button associated with the search bar.
    **Chosen Approach:** On-the-fly (debounced) for a more dynamic feel, with "Enter" key also triggering an immediate search.

*   **API Call:**
    *   When a search is initiated, the frontend makes a `GET` request to `/api/notes` including the search query in the `q` parameter (e.g., `GET /api/notes?q=meeting+agenda`).
    *   Any currently active filters (status, tags, priority, etc., from the filter bar on the notes list page) should ideally be combined with the search query. This means the search acts as an additional filter on the current view or a default view.

### 1.3. Displaying Search Results

*   **Integration with Existing Note List:**
    *   Search results will be displayed within the main "List of Notes" view (Dashboard / Notes Page).
    *   The existing note list component will be re-used, populating it with the notes returned from the `/api/notes?q=...&[other_filters]` API call.
    *   The notes will be displayed as cards or list items, consistent with the standard note list view.
    *   Pagination, sorting, and existing filter controls (status, tags, priority, etc.) will continue to function in conjunction with the search results. For example, a user can search for "report" and then further filter by "Status: Completed".

*   **Highlighting Search Terms (Optional Enhancement):**
    *   Within the displayed search results (note title and content snippet), the search terms entered by the user could be highlighted (e.g., bolded or with a background color) to help users quickly identify relevance. This is a frontend implementation detail.

### 1.4. Indicating Search Mode / Active Search Query

It's important for users to understand that the current list of notes is filtered by a search query.

*   **Search Bar State:** The global Search Bar will retain the active search query text.
*   **Clearable Search Query:** An "X" (clear) icon within the Search Bar will allow the user to easily clear the current search query, which would then refresh the note list to show results based on other active filters or the default view.
*   **Visual Cue Above Note List:**
    *   When a search query is active, a message or a "tag-like" indicator can be displayed above the note list.
    *   Example: "Search results for: **'meeting agenda'**" or "Filtering by keyword: **'meeting agenda'** [Clear Search]"
    *   Clicking "Clear Search" here would also remove the `q` parameter and refresh the list.
*   **Filter Bar Integration:** If a search query is active, it can also be visually represented as an active filter within the filter bar area, similar to how other filters like status or tags are shown.

---

## 2. Saved Custom Filters (Conceptual UI)

This section describes the conceptual UI for allowing users to save and reuse complex filter combinations, including search queries. The backend APIs for saving, listing, and managing these saved filters are considered a separate subtask.

### 2.1. Saving Current Filters

*   **Trigger/Button Location:**
    *   When filters (including any text in the global search bar that's been applied, selected user, status, tags, priority, date ranges) are active on the "List of Notes" page, a **"Save Current Filter"** or **"Save View"** button will become visible/enabled.
    *   This button could be located near the existing filter controls (e.g., at the end of the filter bar) or within a "Filter Options" dropdown menu.

*   **User Flow for Saving:**
    1.  User applies various filters (e.g., search query `q="project X"`, `status_id=1`, `priority_id=3`).
    2.  User clicks the "Save Current Filter" button.
    3.  A small modal dialog or an inline input field appears, prompting the user:
        *   **"Save Filter As:"** [Text input field for the filter name]
        *   **Buttons:** "Save" and "Cancel".
    4.  User enters a descriptive name (e.g., "My Urgent Project X Tasks", "Monthly Reports - Open") and clicks "Save".
    5.  **Frontend Action:** The frontend captures the current filter state (all active query parameters: `q`, `status_id`, `priority_id`, `tag_id`, `created_by_user_id`, date ranges, sort options, etc.) and the chosen name.
    6.  **(Future Backend Interaction):** This named filter configuration would then be sent to a backend API (e.g., `POST /api/users/me/saved-filters`) to be stored.
    7.  A confirmation message (e.g., "Filter 'My Urgent Project X Tasks' saved!") is displayed.

### 2.2. Listing and Accessing Saved Filters

*   **Location:**
    *   A **"Saved Filters"** or **"My Views"** dropdown menu will be available, likely positioned near the filter bar or as a prominent option on the notes list page.
    *   Alternatively, a dedicated section or sidebar could list saved filters if they are a very central part of the workflow. A dropdown is often more space-efficient.

*   **Dropdown Content:**
    *   The dropdown lists all filters saved by the user.
    *   Each item in the dropdown displays the name of the saved filter (e.g., "My Urgent Project X Tasks").
    *   (Optional) A "Manage Saved Filters" option at the bottom of the dropdown.

### 2.3. Applying a Saved Filter

*   **User Flow:**
    1.  User clicks on the "Saved Filters" dropdown.
    2.  User selects a saved filter name from the list.
    3.  **Frontend Action:**
        *   The frontend retrieves the parameters associated with the selected saved filter (this would initially be from frontend state if backend for saved filters isn't built, or fetched from a (future) `GET /api/users/me/saved-filters/{filter_id}` endpoint).
        *   It then populates the filter controls (search bar, status dropdowns, tag selectors, etc.) with these saved parameters.
        *   It automatically triggers a refresh of the note list by making a `GET /api/notes` call with all the applied query parameters from the saved filter.
    4.  The note list updates to reflect the applied saved filter. The active filters (including the search query) are visibly set in their respective UI controls.

### 2.4. Managing Saved Filters (Conceptual)

*   **Accessing Management Interface:**
    *   Via the "Manage Saved Filters" option in the "Saved Filters" dropdown.
    *   This could lead to a dedicated settings page section or a modal dialog.

*   **Management Interface Features:**
    *   A list of all their saved filters.
    *   For each saved filter, options to:
        *   **Rename:** Allows editing the name of the saved filter.
            *   User clicks "Rename" -> Input field with current name appears -> User edits and saves.
            *   **(Future Backend Interaction):** `PUT /api/users/me/saved-filters/{filter_id}`
        *   **Delete:** Allows removing the saved filter.
            *   User clicks "Delete" -> Confirmation prompt -> User confirms.
            *   **(Future Backend Interaction):** `DELETE /api/users/me/saved-filters/{filter_id}`
        *   **(Optional) Update:** Allows modifying the filter criteria of an existing saved filter (e.g., apply new filters, then "Update Selected Saved Filter"). This is more complex than just re-saving with the same name.

---

This design integrates search seamlessly into the existing note list and provides a conceptual framework for a powerful saved filters feature, enhancing user productivity in managing and finding their notes.
---
