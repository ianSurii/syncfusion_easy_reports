# Cross-Platform Saving & Download Guide

## Zero-UI Generation Architecture
The core reporting engine (`ReportEngine`) produces pure `ReportArtifact` bytes in memory without touching platform UI, file pickers, or permissions.

```dart
final prepared = await engine.prepare(definition: definition, records: data);
final artifact = await engine.exportExcel(prepared);

// Standalone byte access:
final Uint8List bytes = artifact.bytes;
final String filename = artifact.filename;
final String mimeType = artifact.mimeType;
```

## Platform-Specific Saving Behavior (`ReportSaver`)

| Platform | Behavior | Fallback Strategy |
| :--- | :--- | :--- |
| **Web** | Browser blob download via `package:web` anchor element | N/A (Standard web download) |
| **macOS / Desktop** | Native `FilePicker.saveFile` dialog | Automatic save to user's `Downloads` directory and reveal |
| **Android** | Public Downloads / Scoped App Storage | Application Documents directory |
| **iOS** | Temporary storage + Native Share Sheet | Application Documents directory |
