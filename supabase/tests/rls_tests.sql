-- =============================================================================
-- RLS policy tests
-- =============================================================================
--
-- How to run:
--   1. Create two users in Supabase (Authentication -> Users).
--   2. Replace every USER_A and USER_B below with their UIDs.
--   3. Run the SETUP section once, as the database owner (no role switching).
--   4. Run each test block (begin ... rollback) BY ITSELF.
--      Tests that are expected to error would stop the rest of the script.
--   5. Compare each result with its "Expect" comment.
--   6. Run the CLEANUP section when done (or delete both test users).
--
-- How RLS rejections show up:
--   - Blocked by `using` (select/update/delete): 0 rows, NO error.
--     Confirm with a follow-up select that the data didn't change.
--   - Blocked by `with check`, or no policy for an insert: error 42501.
--
-- Each test runs inside begin ... rollback, so nothing a test does persists,
-- and every test starts from the same setup data.
-- =============================================================================


-- =============================================================================
-- SETUP (run once, as the owner)
-- =============================================================================
--
-- ID reference:
--   a1  A's Reading hobby
--   a2  A's active goal
--   a3  A's completed goal (has an earn)
--   a4  A's log on the active goal (30 pages)
--   a5  A's log on the completed goal (25 pages)
--   b1  B's Guitar hobby
--   b2  B's active goal

-- User A
insert into public.hobbies (id, user_id, name) values
  ('00000000-0000-0000-0000-0000000000a1', 'USER_A', 'Reading');

insert into public.goals (id, user_id, hobby_id, type, target_value, reward_cents, status, completed_at) values
  ('00000000-0000-0000-0000-0000000000a2', 'USER_A', '00000000-0000-0000-0000-0000000000a1', 'pages', 100, 500, 'active',    null),
  ('00000000-0000-0000-0000-0000000000a3', 'USER_A', '00000000-0000-0000-0000-0000000000a1', 'pages',  25, 300, 'completed', now());

insert into public.transactions (user_id, hobby_id, goal_id, kind, amount_cents) values
  ('USER_A', '00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000a3', 'earn', 300);

insert into public.activity_logs (id, user_id, hobby_id, goal_id, date_log, amount) values
  ('00000000-0000-0000-0000-0000000000a4', 'USER_A', '00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000a2', '2026-10-05', 30),
  ('00000000-0000-0000-0000-0000000000a5', 'USER_A', '00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000a3', '2026-10-04', 25);

-- User B
insert into public.hobbies (id, user_id, name) values
  ('00000000-0000-0000-0000-0000000000b1', 'USER_B', 'Guitar');

insert into public.goals (id, user_id, hobby_id, type, target_value, reward_cents) values
  ('00000000-0000-0000-0000-0000000000b2', 'USER_B', '00000000-0000-0000-0000-0000000000b1', 'minutes', 120, 400);


-- =============================================================================
-- Test 1: A selects all hobbies
-- Expect: 1 row (a1, Reading). B's hobby is invisible, no error.
-- Why:    hobbies select policy only allows auth.uid() = user_id.
-- =============================================================================
begin;
  set local role authenticated;
  set local request.jwt.claims = '{"sub": "USER_A", "role": "authenticated"}';

  select id, name from public.hobbies;
rollback;


-- =============================================================================
-- Test 2: A inserts an earn directly, for their active goal
-- Expect: error 42501
-- Why:    transactions has no insert policy, and RLS denies by default.
--         Earns can only come from the completion function.
-- =============================================================================
begin;
  set local role authenticated;
  set local request.jwt.claims = '{"sub": "USER_A", "role": "authenticated"}';

  insert into public.transactions (user_id, hobby_id, goal_id, kind, amount_cents) values
    ('USER_A', '00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000a2', 'earn', 500);
rollback;


-- =============================================================================
-- Test 3: A marks their active goal as completed
-- Expect: error 42501
-- Why:    using passes (A's active goal), but the new row fails with check,
--         which only allows status 'active' or 'abandoned'.
--         Both status and completed_at are set so the CHECK constraint passes
--         and only the policy can reject it.
-- =============================================================================
begin;
  set local role authenticated;
  set local request.jwt.claims = '{"sub": "USER_A", "role": "authenticated"}';

  update public.goals
  set status = 'completed', completed_at = now()
  where id = '00000000-0000-0000-0000-0000000000a2'
  returning *;
rollback;


-- =============================================================================
-- Test 4: A fixes a typo on a log tied to an ACTIVE goal (30 -> 25)
-- Expect: 1 row returned with amount = 25, no error
-- Why:    activity_logs update policy allows logs whose goal is not completed,
--         checked both before (using) and after (with check).
-- =============================================================================
begin;
  set local role authenticated;
  set local request.jwt.claims = '{"sub": "USER_A", "role": "authenticated"}';

  update public.activity_logs
  set amount = 25
  where id = '00000000-0000-0000-0000-0000000000a4'
  returning *;
rollback;


-- =============================================================================
-- Test 5: A edits a log tied to a COMPLETED goal (25 -> 30)
-- Expect: update affects 0 rows, no error; the select shows amount still 25
-- Why:    the log's goal is completed, so the update's using is false and the
--         row is not targetable. Silent block, so the select confirms it.
-- =============================================================================
begin;
  set local role authenticated;
  set local request.jwt.claims = '{"sub": "USER_A", "role": "authenticated"}';

  update public.activity_logs
  set amount = 30
  where id = '00000000-0000-0000-0000-0000000000a5'
  returning *;

  select id, amount from public.activity_logs
  where id = '00000000-0000-0000-0000-0000000000a5';
rollback;


-- =============================================================================
-- Test 6: A abandons their active goal
-- Expect: 1 row returned with status = 'abandoned', no error
-- Why:    using requires the goal to be active before the update;
--         with check allows the new status 'abandoned'.
-- =============================================================================
begin;
  set local role authenticated;
  set local request.jwt.claims = '{"sub": "USER_A", "role": "authenticated"}';

  update public.goals
  set status = 'abandoned'
  where id = '00000000-0000-0000-0000-0000000000a2'
  returning *;
rollback;


-- =============================================================================
-- Test 7: A inserts a hobby with B's user_id
-- Expect: error 42501
-- Why:    hobbies insert policy's with check requires auth.uid() = user_id.
-- =============================================================================
begin;
  set local role authenticated;
  set local request.jwt.claims = '{"sub": "USER_A", "role": "authenticated"}';

  insert into public.hobbies (user_id, name)
  values ('USER_B', 'Planted Hobby');
rollback;


-- =============================================================================
-- Test 8: A reassigns their own hobby to B
-- Expect: error 42501
-- Why:    using passes (it's A's hobby), but the new row has B's user_id,
--         which fails with check.
--         Uses a fresh hobby with no goals or logs, so the composite foreign
--         keys can't be what rejects it. Only the policy can.
-- =============================================================================
begin;
  set local role authenticated;
  set local request.jwt.claims = '{"sub": "USER_A", "role": "authenticated"}';

  insert into public.hobbies (id, user_id, name)
  values ('00000000-0000-0000-0000-0000000000a6', 'USER_A', 'Test Hobby');

  update public.hobbies
  set user_id = 'USER_B'
  where id = '00000000-0000-0000-0000-0000000000a6'
  returning *;
rollback;


-- =============================================================================
-- CLEANUP (run as the owner)
-- Deleting the hobbies cascades to their goals, logs, and transactions.
-- Deleting both test users from Authentication -> Users also works.
-- =============================================================================
delete from public.hobbies
where id in (
  '00000000-0000-0000-0000-0000000000a1',
  '00000000-0000-0000-0000-0000000000b1'
);