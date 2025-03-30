# REVO - Your Training Revolution

## Firebase Setup

Diese App verwendet Firebase für Authentifizierung und Datenspeicherung. Folgen Sie diesen Schritten, um Firebase für die App einzurichten:

### 1. Firebase-Projekt erstellen

1. Gehen Sie zu [Firebase Console](https://console.firebase.google.com/)
2. Klicken Sie auf "Projekt hinzufügen"
3. Geben Sie einen Projektnamen ein (z.B. "REVO-App")
4. Folgen Sie den Anweisungen, um das Projekt zu erstellen

### 2. Firebase zu Ihrer Flutter-App hinzufügen

1. Installieren Sie die Firebase CLI, falls noch nicht geschehen:
   ```
   npm install -g firebase-tools
   ```

2. Melden Sie sich bei Firebase an:
   ```
   firebase login
   ```

3. Installieren Sie das FlutterFire CLI:
   ```
   dart pub global activate flutterfire_cli
   ```

4. Konfigurieren Sie Firebase für Ihre Flutter-App:
   ```
   flutterfire configure --project=your-firebase-project-id
   ```
   Wählen Sie Ihre Plattformen (Android, iOS, Web) und folgen Sie den Anweisungen.

### 3. Firebase Authentication aktivieren

1. Gehen Sie in der Firebase Console zu Ihrem Projekt
2. Wählen Sie "Authentication" im linken Menü
3. Klicken Sie auf "Get started"
4. Aktivieren Sie die "Email/Password"-Methode

### 4. Firestore einrichten

1. Gehen Sie in der Firebase Console zu Ihrem Projekt
2. Wählen Sie "Firestore Database" im linken Menü
3. Klicken Sie auf "Create database"
4. Wählen Sie "Start in production mode" oder "Start in test mode" (für die Entwicklung)
5. Wählen Sie einen Standort für Ihre Datenbank

### 5. Sicherheitsregeln für Firestore

Setzen Sie die folgenden Sicherheitsregeln für Firestore:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Benutzer können nur ihre eigenen Daten lesen und schreiben
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Übungen können von allen authentifizierten Benutzern gelesen werden
    // Aber nur der Ersteller kann sie bearbeiten oder löschen
    match /exercises/{exerciseId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                            (resource.data.isCustom == false || 
                             resource.data.userId == request.auth.uid);
    }
  }
}
```

## App starten

Nachdem Sie Firebase eingerichtet haben, können Sie die App starten:

```
flutter run
```inzwischen sindsie auch nicht weit Die wollen ja mal den Händler formulieren Im Datum nennen 

## Funktionen

- Benutzerregistrierung und -anmeldung mit E-Mail und Passwort
- Benutzerprofil bearbeiten
- Übungen erstellen, bearbeiten und löschen
- Vordefinierte Übungen verwenden