# Pujo Pookie

A responsive TypeScript / Next.js app based on the Pujo Pookie v1.1 PRD. Cream, vermilion, sage, a custom CSS Kolkata illustration, and mobile layouts. Deploy the repository directly on Vercel using its Next.js preset.

## Run locally

```sh
npm install
npm run dev
```

Open http://localhost:3000. Without environment variables the app runs in clearly labeled demo mode. Fictional profiles are for exploring discovery; demo plans, requests, squads, bookmarks and safety reminders persist only in this browser. Demo people never accept requests or send messages.

## Enable the real backend

1. Create a fresh Supabase project. Run `supabase/schema.sql` in its SQL editor.
2. Copy `.env.example` to `.env.local`. Fill in the Supabase project URL and publishable key. Never expose the service-role key.
3. Enable email/password authentication, email confirmations and a production SMTP provider in Supabase. Set the Auth Site URL to your deployed Vercel URL. Configure signup/auth rate limits and CAPTCHA for public launch.
4. Restart Next.js. Register two adult accounts, confirm emails, and create plans on both. Send a connection request, accept from the second account, then test private messages. Incoming messages refresh every five seconds.
5. Add a moderator through the SQL editor: `insert into public.admins(user_id) values ('YOUR_AUTH_USER_UUID');`. Moderator access is reachable from Safety. The browser cannot grant admin privileges.

## Deploy to Vercel

Push this project to your Git repository, import it in Vercel, choose Next.js, and add both environment variables from `.env.example`. Build command: `npm run build`. The managed Postgres backend persists independently of Vercel's ephemeral filesystem. Set Supabase Auth Site URL to the final domain before inviting users.

## Included

- Email/password auth with adult and community consent; database enforces age >=18 for public plans.
- Profile and plan editing, revocable discovery visibility, age/area/intent filters, day/time/pandal/interest matching and the PRD's weighted compatibility heuristic. Date intent requires mutual Date plans.
- Mutual requests and chat; database rejects messages before acceptance and after blocks/restrictions.
- Squads, join requests, organizer approval and capacity enforcement.
- Pandal route draft selection and external map links. Venue descriptions are illustrative, with no live crowd claims.
- Private reports, blocks, moderator review/restriction and an audit trail.
- Private trusted-contact settings, native plan sharing and in-page check-in reminders.
- Row-level security on every table, constrained inserts, limited column/table privileges, and database message/request throttles.

## Verification

`npm run build`, `npm run typecheck`, `npm test`, `npm run test:db`, and `npm run test:browser` (run `npx playwright install chromium` first). Browser smoke tests cover discovery filtering, plan persistence, requests, squads, safety and mobile overflow. Local PostgreSQL authorization tests use PGlite with a minimal Supabase Auth shim. They execute the schema and `supabase/security-checks.sql`, including mutual consent, private chat, blocks and moderator access. The same SQL checks can run against a disposable Supabase project. No remote backend has been provisioned; hosted email delivery and Auth integration still require testing with your project credentials.

## Before a public beta

This is an implemented MVP foundation, not a fully operated trust service. Adult confirmation is self-attestation, not identity verification. No verified badge is fabricated. Add a specialist liveness provider if desired, first-party photo uploads and media moderation, an actual staffed report-review process, and server-delivered check-ins if the product promises background reminders. Current check-ins work only while the page is open and never send emergency alerts automatically.

The UI accepts an HTTPS profile image URL; use an approved media host before public rollout to avoid third-party tracking images. Sample photos use Unsplash and fonts use Google Fonts. Configure approved media, retention/deletion workflows, encrypted backup/restore procedures, monitoring and legal/privacy review for public-scale use. Auth/account deletion currently requires the operator's Supabase workflow. Bookmarks persist in demo mode and are session-only in live mode. Discovery is authenticated and zone-level, without precise GPS, and members can pause visibility. Membership UI uses account identifiers; expand it with consented member profiles for beta.

The build follows the [Next.js documentation](https://nextjs.org/docs/app/getting-started/installation) and [Supabase row-level security model](https://supabase.com/docs/guides/database/postgres/row-level-security).
