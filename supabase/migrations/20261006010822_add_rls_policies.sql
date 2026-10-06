-- hobbies
create policy "Users can view their own hobbies"
on public.hobbies
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "Users can create their own hobbies"
on public.hobbies
for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy "Users can update their own hobbies"
on public.hobbies
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "Users can delete their own hobbies"
on public.hobbies
for delete
to authenticated
using ((select auth.uid()) = user_id);

-- goals
create policy "Users can view their own goals"
on public.goals
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "Users can create a new goal that is active"
on public.goals
for insert
to authenticated
with check ((select auth.uid()) = user_id and status = 'active');

create policy "Users can update their own active goals"
on public.goals
for update
to authenticated
using ((select auth.uid()) = user_id and (status = 'active'))
with check ((select auth.uid()) = user_id and (status in ('active', 'abandoned')));

create policy "Users can delete their own goals"
on public.goals
for delete
to authenticated
using ((select auth.uid()) = user_id);

-- activity_logs
create policy "Users can view their own activity logs"
on public.activity_logs
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "Users can create their own activity logs"
on public.activity_logs
for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy "Users can update their own activity logs"
on public.activity_logs
for update
to authenticated
using ((select auth.uid()) = user_id and (goal_id is null or exists (
		select 1 from public.goals g
		where g.id = activity_logs.goal_id
			and g.status != 'completed'
	)))
with check ((select auth.uid()) = user_id 
	and (goal_id is null or exists (
		select 1 from public.goals g
		where g.id = activity_logs.goal_id
			and g.status != 'completed'
	)));

create policy "Users can delete their own activity logs"
on public.activity_logs
for delete
to authenticated
using ((select auth.uid()) = user_id and (goal_id is null or exists (
		select 1 from public.goals g
		where g.id = activity_logs.goal_id
			and g.status != 'completed'
	)));

-- transactions
create policy "Users can view their own transactions"
on public.transactions
for select
to authenticated
using ((select auth.uid()) = user_id);