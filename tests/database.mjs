import {PGlite} from '@electric-sql/pglite';
import {readFile} from 'node:fs/promises';
const db=new PGlite();
await db.exec(`create role anon;create role authenticated;create schema auth;create table auth.users(id uuid primary key,raw_user_meta_data jsonb);create function auth.uid() returns uuid language sql stable as $$select (current_setting('request.jwt.claims',true)::jsonb->>'sub')::uuid$$;grant usage on schema auth to authenticated;grant execute on function auth.uid() to authenticated;`);
await db.exec(await readFile(new URL('../supabase/schema.sql',import.meta.url),'utf8'));
await db.exec(await readFile(new URL('../supabase/security-checks.sql',import.meta.url),'utf8'));
console.log('PostgreSQL schema and authorization checks passed: mutual consent, private chat, blocks, moderator access.');
await db.close();
