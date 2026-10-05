-- Run after schema.sql in a disposable project. Everything rolls back.
begin;
insert into auth.users(id,raw_user_meta_data) values
('11111111-1111-4111-8111-111111111111','{"adult_confirmed":true,"community_accepted":true}'),
('22222222-2222-4222-8222-222222222222','{"adult_confirmed":true,"community_accepted":true}'),
('33333333-3333-4333-8333-333333333333','{"adult_confirmed":true,"community_accepted":true}');
insert into plans(user_id,name,age,bio,avatar,day,start,"end",area,intent,interests,pandals,budget)
select id,'Tester',22,'A shared Pujo plan','https://example.com/avatar.jpg','Ashtami',17,22,'South Kolkata','Friend',array['Art'],array['1'],'Flexible' from accounts where id in ('11111111-1111-4111-8111-111111111111','22222222-2222-4222-8222-222222222222','33333333-3333-4333-8333-333333333333');
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}',true);
insert into connections(id,sender,recipient) values('44444444-4444-4444-8444-444444444444','11111111-1111-4111-8111-111111111111','22222222-2222-4222-8222-222222222222');
do $$ begin
 begin insert into messages(connection_id,sender,body) values('44444444-4444-4444-8444-444444444444',auth.uid(),'Before consent');raise exception 'FAIL: pending chat allowed';exception when insufficient_privilege then null;end;
 begin perform respond_connection('44444444-4444-4444-8444-444444444444',true);raise exception 'FAIL: sender accepted own request';exception when raise_exception then if sqlerrm like 'FAIL:%' then raise;end if;end;
 begin perform moderate_report(gen_random_uuid(),true);raise exception 'FAIL: non-admin moderation';exception when raise_exception then if sqlerrm like 'FAIL:%' then raise;end if;end;
end $$;
select set_config('request.jwt.claims','{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated"}',true);
select respond_connection('44444444-4444-4444-8444-444444444444',true);
insert into messages(connection_id,sender,body) values('44444444-4444-4444-8444-444444444444',auth.uid(),'After consent');
select set_config('request.jwt.claims','{"sub":"33333333-3333-4333-8333-333333333333","role":"authenticated"}',true);
do $$ begin if exists(select 1 from messages) then raise exception 'FAIL: outsider can read chat';end if;end $$;
select set_config('request.jwt.claims','{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated"}',true);
update plans set visible=false where user_id=auth.uid();
do $$ begin
 if not exists(select 1 from plans where user_id=auth.uid()) then raise exception 'FAIL: owner cannot edit hidden plan';end if;
 begin update plans set age=17 where user_id=auth.uid();raise exception 'FAIL: underage public plan accepted';exception when check_violation then null;end;
end $$;
select set_config('request.jwt.claims','{"sub":"33333333-3333-4333-8333-333333333333","role":"authenticated"}',true);
do $$ begin if exists(select 1 from plans where user_id='22222222-2222-4222-8222-222222222222') then raise exception 'FAIL: hidden plan discoverable';end if;end $$;
select set_config('request.jwt.claims','{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated"}',true);
update plans set visible=true where user_id=auth.uid();
select set_config('request.jwt.claims','{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}',true);
insert into blocks(owner,target) values(auth.uid(),'22222222-2222-4222-8222-222222222222');
do $$ begin
 if exists(select 1 from messages) then raise exception 'FAIL: blocked chat visible';end if;
 if exists(select 1 from plans where user_id='22222222-2222-4222-8222-222222222222') then raise exception 'FAIL: blocked profile visible';end if;
 begin insert into messages(connection_id,sender,body) values('44444444-4444-4444-8444-444444444444',auth.uid(),'After block');raise exception 'FAIL: blocked chat allowed';exception when insufficient_privilege then null;end;
end $$;
insert into reports(id,reporter,target,reason) values('55555555-5555-4555-8555-555555555555',auth.uid(),'22222222-2222-4222-8222-222222222222','Harassment: Test report details');
reset role;
insert into admins(user_id) values('33333333-3333-4333-8333-333333333333');
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"33333333-3333-4333-8333-333333333333","role":"authenticated"}',true);
select moderate_report('55555555-5555-4555-8555-555555555555',true);
do $$ begin if not exists(select 1 from audit_log where report_id='55555555-5555-4555-8555-555555555555') then raise exception 'FAIL: moderation not audited';end if;end $$;
select set_config('request.jwt.claims','{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated"}',true);
do $$ begin if public.is_active() then raise exception 'FAIL: restricted account active';end if;if exists(select 1 from plans) then raise exception 'FAIL: restricted account discovers profiles';end if;end $$;
rollback;
