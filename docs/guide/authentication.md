# Authentication

One of the benefits of using Inertia is that you don't need a special authentication system such as OAuth to connect to your data provider (API). Also, since your data is provided via your controllers, and housed on the same domain as your JavaScript components, you don't have to worry about setting up CORS.

Rather, when using Inertia, you can simply use whatever authentication system you like, such as solutions based on Rails' built-in `has_secure_password` method, or gems like [Devise](https://github.com/heartcombo/devise), [Sorcery](https://github.com/Sorcery/sorcery), [Authentication Zero](https://github.com/lazaronixon/authentication-zero), etc.

Rails 8 also ships a session-based authentication generator, which adds users, sessions, and password resets to your app:

```bash
bin/rails generate authentication
```

The generator creates ERB views for the sign-in and password reset forms. To use Inertia pages instead, render them from the generated `SessionsController` and `PasswordsController`.

> [!TIP]
> The [Inertia Rails starter kits](/guide/starter-kits) provide out-of-the-box scaffolding for new Inertia applications, including authentication.
