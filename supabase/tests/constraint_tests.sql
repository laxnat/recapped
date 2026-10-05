-- Hobbies
insert into public.hobbies (id, user_id, name) values
  ('00000000-0000-0000-0000-000000000001', 'USER_ID', 'Reading'),
  ('00000000-0000-0000-0000-000000000002', 'USER_ID', 'Guitar');

-- Goals: one active Reading goal, one completed Reading goal, one Guitar goal
insert into public.goals (id, user_id, hobby_id, type, target_value, reward_cents, status, completed_at) values
  ('00000000-0000-0000-0000-000000000011', 'USER_ID', '00000000-0000-0000-0000-000000000001', 'pages',   100, 500, 'active',    null),
  ('00000000-0000-0000-0000-000000000012', 'USER_ID', '00000000-0000-0000-0000-000000000001', 'pages',    50, 300, 'completed', now()),
  ('00000000-0000-0000-0000-000000000021', 'USER_ID', '00000000-0000-0000-0000-000000000002', 'minutes', 120, 400, 'active',    null);

-- The earn for the completed goal
insert into public.transactions (user_id, hobby_id, goal_id, kind, amount_cents) values
  ('USER_ID', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000012', 'earn', 300);

-- Expect: FAIL, check constraint violation
insert into public.transactions (user_id, hobby_id, goal_id, kind, amount_cents) values
  ('4c6cc990-1757-4f3e-bf54-734db4a101a8', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000012', 'spend', 1800);

-- Expect: FAIL, check constraint violation for the negative amount
insert into public.transactions (user_id, hobby_id, goal_id, kind, amount_cents) values
	('4c6cc990-1757-4f3e-bf54-734db4a101a8', '00000000-0000-0000-0000-000000000001', null, 'spend', -500);
	
-- Expect: FAIL, check unique transaction per goal
insert into public.transactions (user_id, hobby_id, goal_id, kind, amount_cents) values
	('4c6cc990-1757-4f3e-bf54-734db4a101a8', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000012', 'earn', 300);
	
-- Expect: FAIL, foreign key mismatch between hobby and goal
insert into public.activity_logs (user_id, hobby_id, goal_id, date_log, amount) values
	('4c6cc990-1757-4f3e-bf54-734db4a101a8', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000012', '2026-10-05', 30);
	
-- Expect FAIL, check constraint failure
insert into public.goals (id, user_id, hobby_id, type, target_value, reward_cents, status, completed_at) values
	('00000000-0000-0000-0000-000000000013', '4c6cc990-1757-4f3e-bf54-734db4a101a8', '00000000-0000-0000-0000-000000000001', 'pages', 50, 300, 'completed', null);
	
-- Expect SUCCESS, valid spend
insert into public.transactions (user_id, hobby_id, goal_id, kind, amount_cents) values
	('4c6cc990-1757-4f3e-bf54-734db4a101a8', '00000000-0000-0000-0000-000000000001', null, 'spend', 200);
	
-- Expect SUCCESS, deleting the hobby
delete from public.hobbies where id = '00000000-0000-0000-0000-000000000001';

-- Expect: 0 (Reading goals were cascade-deleted)
select count(*) from public.goals
where hobby_id = '00000000-0000-0000-0000-000000000001';

-- Expect: 0 (Reading transactions were cascade-deleted, both the earn and the spend from Test 6)
select count(*) from public.transactions
where hobby_id = '00000000-0000-0000-0000-000000000001';

-- Expect: 1 row, the Guitar hobby (unaffected)
select id, name from public.hobbies
where user_id = '4c6cc990-1757-4f3e-bf54-734db4a101a8';

-- Expect: 1 row, the Guitar goal (...0021) (unaffected)
select id, hobby_id, status from public.goals
where user_id = '4c6cc990-1757-4f3e-bf54-734db4a101a8';