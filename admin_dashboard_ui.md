# Admin Dashboard: UI Design & User Flow

This document outlines the UI components and user flow for the Admin Dashboard in Team Task Notes. This design is based on the PRD and the backend API definitions in `admin_dashboard_api.md`.

**Assumptions:**
*   The user is authenticated as an administrator.
*   If the admin manages multiple teams, a team selector dropdown is available globally or at the top of the dashboard to switch context. The designs below assume a single team context is active.

---

## 1. Overall Layout

The Admin Dashboard will be structured with a clear navigation and distinct sections for different types of information.

*   **Navigation:**
    *   The Admin Dashboard will be accessible via a dedicated "Admin" or "Dashboard" link in the main application navigation (visible only to admin users).
    *   Within the dashboard, tabbed navigation or a sidebar could be used to switch between:
        *   **"Team Activity"** (for the detailed notes list)
        *   **"Participation Summary"** (for statistics and charts)

*   **Page Structure (Conceptual):**
    ```
    --------------------------------------------------
    | App Header (with Team Selector if applicable)  |
    --------------------------------------------------
    | Admin Dashboard Header: [Team Name] Dashboard  |
    --------------------------------------------------
    | Tabs: [Team Activity] [Participation Summary]  |
    --------------------------------------------------
    | Filter Bar (Contextual to the active tab)      |
    --------------------------------------------------
    | Main Content Area (Displays active tab's view) |
    --------------------------------------------------
    ```

*   **Filter Location:**
    *   A persistent **Filter Bar** will be located directly below the tab navigation.
    *   The filters displayed in this bar will be relevant to the active tab.
        *   For "Team Activity": Filters for user, status, tags, creation date, due date.
        *   For "Participation Summary": Filters for date range (to scope the summary period).
    *   A "Reset Filters" button will also be available.

---

## 2. Team Activity View (All Notes)

This view provides a detailed, filterable, and sortable list of all notes within the selected team.

*   **API Endpoint Used:** `GET /api/admin/notes`

*   **Layout:**
    *   **Filter Bar (as described above):**
        *   **User Selector:** Dropdown list of team members (populated from user data). Option for "All Users".
        *   **Status Selector:** Dropdown list of available note statuses (e.g., "Open", "In Progress", "Completed"). Option for "All Statuses".
        *   **Tag Selector:** Multi-select dropdown or text input with autocomplete for tags.
        *   **Created Date Range Picker:** Two date inputs (Start Date, End Date) for `created_at_start` and `created_at_end`.
        *   **Due Date Range Picker:** Two date inputs (Start Date, End Date) for `due_date_start` and `due_date_end`.
        *   **"Apply Filters" Button.**
        *   **"Reset Filters" Button.**
    *   **Notes List Display:** A table with sortable columns.
    *   **Pagination Controls:** Below the table.
    *   **Export Button:** Prominently displayed, e.g., top-right of the notes list section.

*   **Notes Table Columns (Sortable):**
    *   `Title`: Note title. Clicking could potentially open a read-only view of the note in a modal or new tab.
    *   `Created By`: Name of the user who created the note (from `created_by.name`).
    *   `Status`: Current status name (e.g., "In Progress").
    *   `Priority`: Priority level (e.g., "High", "Medium", "Low").
    *   `Due Date`: Formatted due date. Overdue notes could be visually highlighted (e.g., red text).
    *   `Created At`: Date of creation.
    *   `Updated At`: Date of last update.
    *   `Tags`: Comma-separated list of tag names or displayed as chips.
    *   `Team Public`: Yes/No or Icon indicating if `is_public_to_team` is true.
    *   (Optional) `Assigned To / Shared With`: Could show primary assignee or count of shared users.

*   **Interaction Flow for Filters:**
    1.  Admin selects desired filter values (e.g., specific user, status "Completed", date range).
    2.  Admin clicks the "Apply Filters" button.
    3.  The frontend makes a `GET` request to `/api/admin/notes` with the selected filter values as query parameters.
    4.  The notes table updates with the filtered and paginated results.
    5.  Sorting by clicking column headers triggers a new API call with `sort_by` and `order` parameters.

*   **Pagination Controls:**
    *   Displays "Page X of Y" and "Total Items: Z".
    *   "Previous" and "Next" buttons.
    *   (Optional) Direct page number input or selection.
    *   Changes trigger API calls with the `page` and `per_page` parameters.

---

## 3. Team Participation Summaries View

This view provides high-level statistics and visualizations of team activity and user contributions.

*   **API Endpoint Used:** `GET /api/admin/stats/summary`

*   **Layout:**
    *   **Filter Bar:**
        *   **Date Range Picker:** Two date inputs (Start Date, End Date) for `date_range_start` and `date_range_end` to define the summary period. Defaults to a reasonable period (e.g., "Last 30 days" or "All Time").
        *   **"Apply Filters" Button.**
    *   **Overall Statistics Section:**
        *   Displayed as prominent "Stat Cards" or a summary dashboard section.
        *   Cards for:
            *   "Total Notes Created" (from `overall_stats.total_notes_created`)
            *   "Total Notes Completed" (from `overall_stats.total_notes_completed`)
            *   "Total Notes Overdue" (from `overall_stats.total_notes_overdue`)
            *   "Active Users" (from `overall_stats.active_users_count`)
    *   **Status Breakdown Section:**
        *   **Visualization:** A bar chart or pie chart displaying the distribution of notes across different statuses (from `status_breakdown`). Each segment shows status name and count.
        *   Could also include a small table next to the chart listing statuses and their counts.
    *   **User Participation Section:**
        *   **Display:** A table listing team members and their individual statistics.
        *   **Table Columns (Sortable):**
            *   `User Name` (from `user_participation[].name`)
            *   `User Email` (from `user_participation[].email`)
            *   `Notes Created` (from `user_participation[].notes_created`)
            *   `Notes Completed` (from `user_participation[].notes_completed`)
            *   `Notes Overdue` (from `user_participation[].notes_overdue`)

*   **Interaction Flow for Filters:**
    1.  Admin selects a date range for the summary.
    2.  Admin clicks "Apply Filters".
    3.  The frontend makes a `GET` request to `/api/admin/stats/summary` with `date_range_start` and `date_range_end`.
    4.  All summary components (stat cards, charts, user participation table) update with the new data.

---

## 4. CSV Export

*   **Location of "Export to CSV" Button:**
    *   On the **"Team Activity"** tab/view.
    *   Positioned conveniently, e.g., near the top of the notes list table, perhaps next to the filter controls or as a primary action button for that view. Example: "Export View to CSV".

*   **Applying Filters to Export:**
    *   When the admin clicks the "Export to CSV" button, the frontend will use the **currently active filter parameters** from the "Team Activity" view (user, status, tags, date ranges for creation/due date).
    *   These filter parameters are passed to the `GET /api/admin/notes/export/csv` endpoint.
    *   **User Flow:**
        1.  Admin applies desired filters on the "Team Activity" notes list.
        2.  The list updates to show the filtered data.
        3.  Admin clicks "Export to CSV".
        4.  The browser initiates a download of the CSV file containing only the data that matches the currently applied filters.
    *   **Clear Indication:** The button text could dynamically update to reflect that filters are active (e.g., "Export Filtered View to CSV") or a small text note nearby could state "Current filters will be applied to the export."

---

This UI design aims to provide administrators with a powerful yet intuitive interface to monitor team progress, identify bottlenecks, understand workload distribution, and extract data for reporting purposes.
---
