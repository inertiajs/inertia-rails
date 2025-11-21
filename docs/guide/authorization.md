# Authorization

When using Inertia, authorization is best handled server-side in your application's authorization policies. However, you may be wondering how to perform checks against your authorization policies from within your Inertia page components since you won't have access to your framework's server-side helpers.

The simplest approach to solving this problem is to pass the results of your authorization checks as props to your page components.

Here's an example of how you might do this in a Rails controller using the [Action Policy](https://github.com/palkan/action_policy) gem:

```ruby
class UsersController < ApplicationController
  def index
    render inertia: {
      can: {
        create_user: allowed_to?(:create, User)
      },
      users: User.all.map do |user|
        user.as_json(
          only: [:id, :first_name, :last_name, :email]
        ).merge(
          can: {
            edit_user: allowed_to?(:edit, user)
          }
        )
      end
    }
  end
end
```
