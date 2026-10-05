create table public.hobbies (
    id          uuid primary key default gen_random_uuid(),
    user_id     uuid not null references auth.users(id) on delete cascade,
    name        text not null check (char_length(name) between 1 and 50),
    created_at  timestamptz not null default now(),

    unique (user_id, name),
    unique (id, user_id)
);

alter table public.hobbies enable row level security;

create table public.goals (
	id        uuid primary key default gen_random_uuid(),
	user_id   uuid not null references auth.users(id) on delete cascade,
	hobby_id  uuid not null,
	type      text not null check (type in ('pages','minutes', 'sessions')),
	target_value integer not null check (target_value > 0),
	reward_cents integer not null check (reward_cents > 0),
	interval_set  text not null default 'one_time' check (interval_set in ('one_time')),
	status    text not null check (status in ('active', 'completed', 'abandoned')) default 'active',
	created_at timestamptz not null default now(),
	completed_at timestamptz,
	
	unique (id, hobby_id, user_id),
	foreign key (hobby_id, user_id) references public.hobbies (id, user_id) on delete cascade,
	check (completed_at >= created_at),
	check ((status = 'completed' and completed_at is not null) or (status != 'completed' and completed_at is null))
);

alter table public.goals enable row level security;

create index goals_user_id_hobby_id_idx on public.goals (user_id, hobby_id);

create table public.activity_logs (
	id        uuid primary key default gen_random_uuid(),
	user_id   uuid not null references auth.users(id) on delete cascade,
	hobby_id  uuid not null,
	goal_id   uuid,
	date_log  date not null,
	amount    integer not null check (amount > 0),
	created_at timestamptz not null default now(),
	
	foreign key (hobby_id, user_id) references public.hobbies (id, user_id) on delete cascade,
	foreign key (goal_id, hobby_id, user_id) references public.goals (id, hobby_id, user_id) on delete set null (goal_id)
);

alter table public.activity_logs enable row level security;

create index activity_logs_user_id_hobby_id_idx on public.activity_logs (user_id, hobby_id);
create index activity_logs_goal_id_idx on public.activity_logs (goal_id);

create table public.transactions (
	id         uuid primary key default gen_random_uuid(),
	user_id    uuid not null references auth.users(id) on delete cascade,
	hobby_id   uuid not null,
	goal_id    uuid,
	kind       text not null check (kind in ('earn', 'spend')),
	amount_cents integer not null check (amount_cents > 0),
	created_at timestamptz not null default now(),
	
	foreign key (hobby_id, user_id) references public.hobbies (id, user_id) on delete cascade,
	foreign key (goal_id, hobby_id, user_id) references public.goals (id, hobby_id, user_id),
	check ((kind = 'earn' and goal_id is not null) or (kind ='spend' and goal_id is null))
);

alter table public.transactions enable row level security;

create unique index transactions_one_earn_per_goal on public.transactions (goal_id) where kind = 'earn';
create index transactions_user_id_hobby_id_idx on public.transactions (user_id, hobby_id);