# Auth spec (Saturday Oct 31)

## Goal
Sign up, log in, log out. Logged-out users get redirected to /login.
A logged-in query on hobbies returns [] (not an error).

## Packages
- [ ] install the @supabase/supabase-js and @supabase/ssr helper packages

## Env vars (.env.local + .env.example, names only in the example)
- [ ] NEXT_PUBLIC_SUPABASE_URL=supabase_project_url
- [ ] NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=supabase_publishable_key

## Files to create
- [ ] browser client — path: lib/supabase/client.ts  used by: to access Supabase from CLient Components, which run in the browser
- [ ] server client — path: lib/supabase/server.ts  used by: to access supabase from server components, server actions, route handlers, which run only on the server
- [ ] middleware/proxy — path: proxy.ts and lib/supabase/proxy.ts  where: proxy.ts lives at the project root, or in src/. what it does: refreshing the Auth token, passing the refreshed Auth token to Server Components, passing the refreshed Auth token to the browser
- [ ] /login page
- [ ] /signup page
- [ ] logout action

## How I'll check the user on the server
Method: supabase.auth.getClaims()  (not getSession — why: never trust getSession inside server code such as Proxy. It reads the session out of the cookie wihout revalidating it.) getClaims() verifies the token's signature on every call. Claims come from a token the server has verified rather than from whatever the cookie says. getUser() calls the Auth server, so it catches revocation but costs a network round trip.

## Done when
- [ ] Can sign up, log in, log out
- [ ] Logged-out visit to /hobbies redirects to /login
- [ ] Logged-in hobbies query returns []
- [ ] Refreshing the page keeps you logged in, which proves the cookie works
- [ ] Log in as a second user and confirm they can't see the first user's hobbies, which proves RLS works through the app.

## Questions for Saturday
- Email confirmation on or off for dev?
- Redirect in proxy or in layout?
- Should logout be a "server action: signOut(), then redirect to /login?"