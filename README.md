# Daily Work 2026 Manager

A professional Flutter task-management application for Android, iOS, web, Windows, Linux, and macOS. The interface is built around the `DAILY WORK 2026` work register and uses a solid navy/royal-blue/slate visual system with Font Awesome icons.

## Run

```bash
flutter pub get
flutter run -d chrome
```

The same project can be built for any enabled Flutter target, for example:

```bash
flutter build web --release
flutter build apk --release
```

## Project structure

- `lib/models/`: `TaskModel`, `SubTaskModel`, status, and priority enums.
- `lib/providers/`: `TaskProvider` for filtering, statistics, view mode, CRUD, and persistence orchestration.
- `lib/services/`: Shared Preferences storage and JSON/CSV file operations.
- `lib/screens/`: responsive dashboard screen.
- `lib/widgets/`: table, Kanban, forms, filters, progress, chips, and statistics widgets.

## Included capabilities

- Table view with horizontal scrolling and Kanban view with four status columns.
- Add/edit task form with date, PIC, notes, priority, status, and editable sub-tasks.
- Sub-task check-off, progress bar, and completion percentage.
- Live statistics, search, status/PIC/priority filters, and clear filters.
- Local persistence through `shared_preferences`.
- JSON backup/restore and CSV export through `file_picker` and `csv`.
- Sample data and full reset controls.
