# TenantScore

TenantScore is an iOS + Node.js/PostgreSQL MVP for landlord tenant screening.

## Backend

```bash
cd backend
npm install
npm run db:init
npm run seed:users
PORT=5050 npm run dev
```

## Demo Logins

```text
landlord@tenantscore.test / Password123!
admin@tenantscore.test / Password123!
```

## iOS

Open:

```text
ios-app/TenantScore/TenantScore.xcodeproj
```

Run on the iPhone simulator. The app expects the backend at:

```text
http://localhost:5050/api
```

## MVP Features

- Signup/login with JWT and bcrypt
- Keychain token storage on iOS
- Tenant create, read, update, delete
- Risk score calculation
- Risk level and recommendation
- Score factor explanations
- Dashboard search and risk filtering
