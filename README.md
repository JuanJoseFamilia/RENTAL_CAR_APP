 # rental_car_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

## Firestore Security Note 🔒

To enforce the policy that users cannot edit or delete reviews from the client app, a Firestore rules file has been added at `firebase/firestore.rules`.

Basic rules:
- `read`: allowed for everyone
- `create`: allowed for authenticated users
- `update` / `delete`: **prohibited** from the client (only server/admin SDKs can modify documents)

Deploy with:

```bash
firebase deploy --only firestore:rules --project your-project-id
```

This complements the client-side checks implemented in `ReviewService` which disallow editing reviews from the app.
