# Subscription Saver Copilot

Mobile-first Flutter MVP for tracking subscriptions and getting reminded before renewal.

## Implemented MVP
- Manual subscription add/edit with partial records allowed
- Dashboard with normalized monthly and annual spend
- Upcoming renewals, incomplete-record review queue, and weekly digest summary surface
- Decision tracking for keep, cancel, downgraded, snooze, and undecided
- Savings tracker for avoided next charge and normalized monthly savings
- Curated cancellation-link field with verification timestamp storage
- Gmail beta consent toggle and inbox-candidate trust messaging
- Local persistence with `shared_preferences`

## Run
```bash
flutter pub get
flutter run
```

## Test
```bash
flutter analyze
flutter test
```

## Notes
This MVP is local-first and demonstrates the manual-first product shape from the final spec. Notification delivery, auth, inbox scanning, and admin tooling are represented in the UX but not backed by live services yet.
