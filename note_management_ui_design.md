# Note Management UI Design & User Flow

This document outlines the UI components and user flow for core note management features, keeping in mind mobile responsiveness and key UX highlights from the PRD.

---

## General UI/UX Principles:

*   **Clean, Mobile-First Layout:** Components are designed to be responsive and work well on small screens first, then adapt to larger screens.
*   **Prominent "Quick Add" Note Button:** A Floating Action Button (FAB) for easily creating new notes.
*   **Clear Status Indicators:** Visual cues for note status (e.g., open, in progress, completed).
*   **Intuitive Navigation:** Easy to move between list views, detail views, and creation/editing forms.

---

## 1. Viewing a List of Notes (Dashboard / Notes Page)

*   **Layout:**
    *   A scrollable list of note summaries.
    *   **Mobile:** Single column of stacked note cards.
    *   **Desktop:** Single wide column or potentially a multi-column grid if space permits.
    *   **"Quick Add" Button:** A circular Floating Action Button (FAB) with a `+` icon, fixed to the bottom-right of the screen (common mobile pattern, adaptable for desktop).
    *   **Filtering/Sorting Controls:**
        *   Located at the top of the list.
        *   **Filter by:** Dropdowns or segmented controls for `Status`, `Team`, `Tags`.
        *   **Sort by:** Dropdown for `Due Date`, `Creation Date`, `Priority`, `Title`.

*   **Individual Note Summary (Displayed as a Card or List Item):**
    *   **Title:** Bold, primary text, prominently displayed.
    *   **Snippet/Content Preview:** 1-2 lines of the note's text content.
    *   **Due Date:** If set, displayed clearly (e.g., "Due: Oct 26" or "Overdue"). Color-coded (e.g., red for overdue, orange for due today/soon).
    *   **Priority Indicator:** A small icon or colored tag (e.g., `!!!` for High, `!!` for Medium, `!` for Low).
    *   **Tags:** Displayed as small, rounded chips/lozenges with tag names.
    *   **Status Indicator:** A visual cue like a colored dot next to the title or a small text badge (e.g., "Open", "In Progress", "Completed").
    *   **Team Name:** If the note is associated with a team, the team name is displayed.

*   **Actions Available Directly from List View (per note):**
    *   **Primary Action (Tap/Click on Card):** Navigates to the "Viewing a Single Note (Detailed View)".
    *   **Secondary Actions (via "More Options" `...` icon on each note card):** Opens a small context menu/dropdown:
        *   `Edit`: Navigates to the "Editing an Existing Note" view.
        *   `Delete`: Shows a confirmation dialog (modal) before deleting the note.
        *   `Mark as Complete` / `Reopen`: Toggles the note's status between a default open state and 'Completed'. The label changes based on the current status.
        *   `(Optional) Quick View`: Opens a modal dialog showing the note's full content and details without leaving the list view.
        *   `(Optional) Share`: Opens the sharing dialog for that note.

---

## 2. Viewing a Single Note (Detailed View)

*   **Layout:**
    *   **Header Bar:**
        *   `Back Arrow` Icon: Returns to the note list view.
        *   `Note Title`: Displayed centrally or prominently.
        *   `Edit` Button/Icon: Allows editing the current note.
        *   `More Options (...)` Icon: Contains less frequent actions like `Delete`, `Share`.
    *   **Main Content Area (Scrollable):**
        *   **Title:** Large, clear text.
        *   **Content:**
            *   Formatted text content.
            *   If checklist items exist, they are rendered as interactive checkboxes (user can check/uncheck them).
        *   **Metadata Section:**
            *   **Due Date:** Clearly displayed.
            *   **Status:** Current status shown (e.g., "Status: In Progress"). Can be a dropdown to change status.
            *   **Priority:** Current priority shown (e.g., "Priority: High"). Can be a dropdown to change priority.
            *   **Tags:** Displayed as chips. An "Add/Edit Tags" button/icon might be present.
        *   **Attachments Section:**
            *   Header: "Attachments".
            *   List of attached files: Each with a file type icon, file name, and file size.
            *   Clicking an attachment downloads it or opens it in a new tab/viewer.
            *   `Add Attachment` Button: Opens a file picker.

*   **Actions Available:**
    *   `Edit` Button (in header or as a FAB): Navigates to the "Editing an Existing Note" view.
    *   `Delete` Button (often in "More Options" menu): Shows confirmation dialog, then deletes.
    *   `Share` Button (often in "More Options" menu): Opens a sharing modal/dialog to manage users/teams and permissions for this note.
    *   `Add Attachment` Button: Allows uploading files.
    *   `Change Status` Dropdown/Segmented Control: Allows updating the note's progress.
    *   Interactive Checklist Items: Tapping a checkbox toggles its state.

---

## 3. Creating a New Note

*   **Trigger:**
    *   Tapping the global "Quick Add" FAB.
    *   Tapping a "New Note" button if present on a specific page.
*   **UI (Full Page or Large Modal):**
    *   **Header Bar:**
        *   `Cancel` or `X` Icon/Button: Discards the new note and closes the create view.
        *   View Title: "New Note".
        *   `Save` or `Create` Button: Saves the note.
    *   **Form Fields:**
        *   **Title:** Single-line text input field. Required. Autofocused.
        *   **Content:**
            *   Multi-line text area for plain text by default.
            *   Option to use a simple Rich Text Editor (RTE) with controls for bold, italics, bullet points, numbered lists, and checklist creation (`[ ]`).
        *   **Due Date:** Input field that opens a calendar/date picker dialog.
        *   **Priority:** Dropdown menu or segmented control (e.g., Low, Medium, High). Default to Medium.
        *   **Tags:** Text input field that allows typing multiple tags. Suggestions for existing tags appear as user types. Tags are displayed as chips below the input.
        *   **Team Assignment (Optional):** Dropdown to select a team if applicable.
        *   **Status (Optional):** Dropdown to set an initial status (defaults to 'Open').
        *   **Add Attachment (Optional):** Button to add attachments during creation.
*   **"Quick Add" FAB Behavior:**
    *   **Option 1 (Simple Modal):** FAB opens a small modal with only `Title` and basic `Content` fields, and a "Save" button. An "Add More Details" button in this modal would transition to the full "Create Note" form.
    *   **Option 2 (Direct Full Form):** FAB directly opens the full "Create Note" form described above. (Chosen for simplicity in this design).

---

## 4. Editing an Existing Note

*   **Trigger:**
    *   Tapping "Edit" from the note list actions.
    *   Tapping "Edit" from the detailed note view.
*   **UI:**
    *   Essentially identical to the "Creating a New Note" form/view.
    *   **Header Bar:**
        *   `Cancel` or `X` Icon/Button: Discards changes and returns to the previous view (detailed view or list).
        *   View Title: "Edit Note".
        *   `Save Changes` Button.
    *   **Pre-filled Data:** All form fields (Title, Content, Due Date, Priority, Tags, Status, Team) are pre-populated with the existing note's data.
    *   **Content Editor:** The note's current content is loaded into the editor, ready for modification. Checklist items are also editable.
    *   **Attachments Management in Edit Mode:**
        *   Existing attachments are listed below the content editor or in a dedicated section.
        *   Each listed attachment has a `Remove` (X) button/icon.
        *   An `Add Attachment` button is still present to upload new files.

---

This structure aims to provide a comprehensive yet clear user flow for note management, aligning with the PRD's focus on usability and key features.
