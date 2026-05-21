-- Allow authenticated users to insert their own profile row.
-- Useful when writes are done through anon key + JWT instead of service role.

do $$
begin
	if to_regclass('public.users') is not null then
		drop policy if exists users_insert_own on public.users;
		create policy users_insert_own on public.users
		for insert with check (auth.uid() = id);
	end if;
end $$;
