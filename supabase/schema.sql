-- Run once in a fresh Supabase project's SQL editor.
create table public.accounts (id uuid primary key references auth.users on delete cascade, restricted boolean not null default false, created_at timestamptz not null default now());
create table public.admins (user_id uuid primary key references public.accounts);
create function public.register_account() returns trigger language plpgsql security definer set search_path=public as $$ begin
 if coalesce(new.raw_user_meta_data->>'adult_confirmed','false')<>'true' or coalesce(new.raw_user_meta_data->>'community_accepted','false')<>'true' then raise exception 'Adult eligibility and community consent required'; end if;
 insert into public.accounts(id) values(new.id); return new; end $$;
create trigger register_account after insert on auth.users for each row execute function public.register_account();
create function public.is_active() returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from accounts where id=auth.uid() and not restricted) $$;
create function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$ select public.is_active() and exists(select 1 from admins where user_id=auth.uid()) $$;
create table public.plans (
 id uuid primary key default gen_random_uuid(),user_id uuid not null unique references accounts on delete cascade,
 name text not null check(char_length(name) between 1 and 40),age int not null check(age between 18 and 100),bio text not null check(char_length(bio) between 1 and 300),avatar text not null check(avatar ~ '^https://'),
 day text not null check(day in ('Sashthi','Saptami','Ashtami','Navami','Dashami')),start int not null check(start between 0 and 23),"end" int not null check("end" between 1 and 24 and "end">start),
 area text not null check(area in ('South Kolkata','North Kolkata','Central Kolkata','Salt Lake')),intent text not null check(intent in ('Friend','Date','Squad','Pandal Partner','Food Partner','Photography Partner')),
 interests text[] not null check(cardinality(interests) between 1 and 6 and interests <@ array['Pandal hopping','Street food','Photography','Music','Art','Adda']),
 pandals text[] not null check(cardinality(pandals) between 1 and 5 and pandals <@ array['1','2','3','4','5']),budget text not null check(budget in ('Under ₹500','₹500–1,000','₹1,000–2,000','Flexible')),visible boolean not null default true, created_at timestamptz not null default now()
);
create table public.blocks(owner uuid not null references accounts,target uuid not null references accounts,created_at timestamptz default now(),primary key(owner,target),check(owner<>target));
create function public.can_interact(other uuid) returns boolean language sql stable security definer set search_path=public as $$
 select public.is_active() and exists(select 1 from accounts where id=other and not restricted) and not exists(select 1 from blocks where (owner=auth.uid() and target=other) or (owner=other and target=auth.uid())) $$;
create table public.connections(id uuid primary key default gen_random_uuid(),sender uuid not null references accounts,recipient uuid not null references accounts,status text not null default 'pending' check(status in ('pending','accepted','declined')),created_at timestamptz not null default now(),check(sender<>recipient));
create unique index connection_pair on connections(least(sender,recipient),greatest(sender,recipient));
create function public.connection_guard() returns trigger language plpgsql security definer set search_path=public as $$ begin
 perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,0));new.created_at=now();
 if not exists(select 1 from plans a join plans b on b.user_id=new.recipient where a.user_id=new.sender and a.visible and b.visible and ((a.intent='Date')=(b.intent='Date'))) then raise exception 'Both members need visible plans with compatible intent'; end if;
 if (select count(*) from connections where sender=auth.uid() and created_at>now()-interval '1 hour')>=30 then raise exception 'Too many requests. Try again later.'; end if; return new; end $$;
create trigger connection_guard before insert on connections for each row execute function connection_guard();
create function public.respond_connection(request_id uuid,accept boolean) returns void language plpgsql security definer set search_path=public as $$ declare c connections;begin
 select * into c from connections where id=request_id for update;
 if c.recipient is distinct from auth.uid() or c.status<>'pending' or not public.can_interact(c.sender) then raise exception 'Not authorized';end if;
 update connections set status=case when accept then 'accepted' else 'declined' end where id=request_id;end $$;
create table public.messages(id uuid primary key default gen_random_uuid(),connection_id uuid not null references connections,sender uuid not null references accounts,body text not null check(char_length(trim(body)) between 1 and 2000),created_at timestamptz not null default now());
create function public.can_chat(cid uuid) returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from connections where id=cid and status='accepted' and auth.uid() in (sender,recipient) and public.can_interact(case when sender=auth.uid() then recipient else sender end)) $$;
create function public.message_guard() returns trigger language plpgsql security definer set search_path=public as $$ begin
 perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,0));
 if (select count(*) from messages where sender=auth.uid() and created_at>now()-interval '1 minute')>=20 then raise exception 'Too many messages. Wait a minute.';end if;new.created_at=now();return new;end $$;
create trigger message_guard before insert on messages for each row execute function message_guard();
create index messages_conversation_time on messages(connection_id,created_at);
create table public.squads(id uuid primary key default gen_random_uuid(),owner_id uuid not null references accounts,name text not null check(char_length(name) between 1 and 80),description text not null check(char_length(description) between 1 and 500),area text not null check(area in ('South Kolkata','North Kolkata','Central Kolkata','Salt Lake')),day text not null check(day in ('Sashthi','Saptami','Ashtami','Navami','Dashami')),capacity int not null check(capacity between 2 and 12),created_at timestamptz default now());
create table public.squad_requests(squad_id uuid not null references squads on delete cascade,user_id uuid not null references accounts,status text not null default 'pending' check(status in ('pending','accepted','declined')),created_at timestamptz default now(),primary key(squad_id,user_id));
create function public.owns_squad(sid uuid) returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from squads where id=sid and owner_id=auth.uid()) and public.is_active() $$;
create function public.respond_squad(sid uuid,member uuid,accept boolean) returns void language plpgsql security definer set search_path=public as $$ declare cap int;begin
 select capacity into cap from squads where id=sid and owner_id=auth.uid() for update;
 if cap is null or not public.can_interact(member) then raise exception 'Not authorized';end if;
 if accept and (select count(*) from squad_requests where squad_id=sid and status='accepted')>=cap-1 then raise exception 'Squad is full';end if;
 update squad_requests set status=case when accept then 'accepted' else 'declined' end where squad_id=sid and user_id=member and status='pending';end $$;
create table public.reports(id uuid primary key default gen_random_uuid(),reporter uuid not null references accounts,target uuid not null references accounts,reason text not null check(char_length(reason) between 10 and 2100),status text not null default 'pending' check(status in ('pending','reviewed','restricted')),created_at timestamptz not null default now(),check(reporter<>target));
create table public.audit_log(id bigint generated always as identity primary key,admin_id uuid not null references accounts,report_id uuid not null references reports,action text not null,created_at timestamptz default now());
create table public.safety_settings(user_id uuid primary key references accounts on delete cascade,trusted_contact text not null check(char_length(trusted_contact)<=150),check_in_at timestamptz);
create function public.moderate_report(report_id uuid,restrict_account boolean) returns void language plpgsql security definer set search_path=public as $$ declare target_id uuid;begin
 if not public.is_admin() then raise exception 'Not authorized';end if;
 select target into target_id from reports where id=report_id for update;if target_id is null then raise exception 'Report not found';end if;
 if restrict_account then update accounts set restricted=true where id=target_id;end if;
 update reports set status=case when restrict_account then 'restricted' else 'reviewed' end where id=report_id;
 insert into audit_log(admin_id,report_id,action) values(auth.uid(),report_id,case when restrict_account then 'restrict_account' else 'review' end);end $$;
-- Deny anonymous access. Only policies below allow authenticated access.
alter table accounts enable row level security;alter table admins enable row level security;alter table plans enable row level security;alter table blocks enable row level security;alter table connections enable row level security;alter table messages enable row level security;alter table squads enable row level security;alter table squad_requests enable row level security;alter table reports enable row level security;alter table audit_log enable row level security;alter table safety_settings enable row level security;
create policy own_account on accounts for select to authenticated using(id=auth.uid());
create policy read_plans on plans for select to authenticated using(public.can_interact(user_id) and (visible or user_id=auth.uid()));
create policy insert_plan on plans for insert to authenticated with check(user_id=auth.uid() and public.is_active());
create policy edit_plan on plans for update to authenticated using(user_id=auth.uid() and public.is_active()) with check(user_id=auth.uid() and public.is_active());
create policy own_blocks on blocks for select to authenticated using(owner=auth.uid());
create policy block_account on blocks for insert to authenticated with check(owner=auth.uid() and public.is_active());
create policy own_connections on connections for select to authenticated using(auth.uid() in (sender,recipient) and public.can_interact(case when sender=auth.uid() then recipient else sender end));
create policy request_connection on connections for insert to authenticated with check(sender=auth.uid() and status='pending' and public.can_interact(recipient));
create policy read_messages on messages for select to authenticated using(public.can_chat(connection_id));
create policy send_messages on messages for insert to authenticated with check(sender=auth.uid() and public.can_chat(connection_id));
create policy read_squads on squads for select to authenticated using(public.can_interact(owner_id));
create policy create_squad on squads for insert to authenticated with check(owner_id=auth.uid() and public.is_active());
create policy read_squad_requests on squad_requests for select to authenticated using((user_id=auth.uid() or public.owns_squad(squad_id)) and public.is_active());
create policy join_squad on squad_requests for insert to authenticated with check(user_id=auth.uid() and status='pending' and public.is_active() and exists(select 1 from squads where id=squad_id and owner_id<>auth.uid() and public.can_interact(owner_id)));
create policy submit_report on reports for insert to authenticated with check(reporter=auth.uid() and status='pending' and public.is_active());
create policy read_reports on reports for select to authenticated using(reporter=auth.uid() or public.is_admin());
create policy read_audit on audit_log for select to authenticated using(public.is_admin());
create policy own_safety on safety_settings for all to authenticated using(user_id=auth.uid() and public.is_active()) with check(user_id=auth.uid() and public.is_active());
revoke all on all tables in schema public from anon,authenticated;
grant select on accounts,plans,blocks,connections,messages,squads,squad_requests,reports,audit_log,safety_settings to authenticated;
grant insert on plans,blocks,connections,messages,squads,squad_requests,reports,safety_settings to authenticated;
grant update on plans,safety_settings to authenticated;
revoke execute on all functions in schema public from public,anon,authenticated;
grant execute on function public.is_active(),public.is_admin(),public.can_interact(uuid),public.can_chat(uuid),public.owns_squad(uuid),public.respond_connection(uuid,boolean),public.respond_squad(uuid,uuid,boolean),public.moderate_report(uuid,boolean) to authenticated;
