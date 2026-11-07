import { signup } from "./actions";

export default async function SignupPage({
    searchParams,
}: {
    searchParams: Promise<{ error?: string }>;
}) {
    const { error } = await searchParams;

    return (
        <main>
            <h1>Sign Up</h1>
            <form action={signup}>
                <label htmlFor="email">Email</label>
                <input id="email" name="email" type="email" required />

                <label htmlFor="password">Password</label>
                <input id="password" name="password" type="password" required/>

                {error && <p>{error}</p>}

                <button type="submit">Sign up</button>
            </form>
        </main>
    )
}