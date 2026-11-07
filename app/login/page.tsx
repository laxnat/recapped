import { login } from "./actions";

export default async function LoginPage({
    searchParams,
}: {
    searchParams: Promise<{ error?: string }>;
}) {
    const { error } = await searchParams;

    return (
        <main>
            <h1>Log In</h1>
            <form>
                <label htmlFor="email">Email</label>
                <input id="email" name="email" required />

                <label htmlFor="password">Password</label>
                <input id="password" name="password" required />

                {error && <p>{error}</p>}

                <button formAction={login}>Log in</button>
            </form>
        </main>
    )
}