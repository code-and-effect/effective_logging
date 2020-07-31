# Effective Logging

Automatically log all sent emails, user logins, and page views. This also will log custom events from Ruby and JavaScript.

Logs are stored in a single database table. A Log (one logged event) can have many children Logs, nested to any depth.

Provides a ruby one-liner to log a message, status, user, associated object and any number of additional details.

Works great for single fire-and-forget events and long running tasks.

Provides a simple Javascript API for logging front-end events.

Automatically logs any email sent by the application, any successful user login via Devise, and all page views.

Has an effective_datatables driven admin interface to display and search/sort/filter all logs.

## Getting Started

Add to your Gemfile:

```ruby
gem 'effective_logging'
```

Run the bundle command to install it:

```console
bundle install
```

Then run the generator:

```ruby
rails generate effective_logging:install
```

The generator will install an initializer which describes all configuration options and creates a database migration.

If you want to tweak the table name (to use something other than the default 'logs'), manually adjust both the configuration file and the migration now.

Then migrate the database:

```ruby
rake db:migrate
```

## Usage

### Basic

Log an event from anywhere in the application:

```ruby
EffectiveLogger.info 'something happened'
```

Each status, as per the config/initializers/effective_logging.rb initializer, will be created as a class level method:

```ruby
EffectiveLogger.info 'something happened'
EffectiveLogger.success 'it worked!'
EffectiveLogger.error 'now we are in trouble'
```

The :user and :associated options may be passed to indicate the user and associated (ActiveRecord) object which belong to this event:

```ruby
EffectiveLogger.info 'product purchased', :user => current_user, :associated => @product
```

Any other passed options will be serialized and stored as additional details:

```ruby
EffectiveLogger.info 'feedback given', :user => current_user, :feedback => 'your app is great!', :rating => 'good'
```

### Sub Logs

Any log can have children logs.  This is perfect for long-running tasks where there are multiple sub events:

```ruby
log = EffectiveLogger.info('importing important records')

log.success('record 1 imported', :associated => @record1)
log.error('record 2 failed to import', :associated => @record2)
log.success('record 3 imported', :associated => @record3)
```

### Model

(optional) Sometimes you'd like to work with the `Effective::Log` relationship directly.  Add to your model:

```ruby
has_many :logs, class_name: Effective::Log, as: :associated
```

### Automatic Logging of E-mails

Any email sent by the application will be automatically logged.

This behaviour can be disabled in the config/initializers/effective_logging.rb initializer.

If the TO email address match a User, the :associated will be set to this user.

You can specify additional fields to be logged via your mailer:

```ruby
def notify_admin_of_new_post(post)
  mail(
    to: 'admin@example.com',
    subject: 'A new post was created',
    log: { :post => post, :title => post.title }
  )
end
```

### Automatic Logging of User Login and Logout

Any successful User logins and logouts via Devise will be automatically logged.

This behaviour can be disabled in the config/initializers/effective_logging.rb initializer.

The User's IP address will also be logged.


### Logging Page Views

All page views, whether initiated by a logged in user or not, may be logged.

To enable application wide logging for every request, add the following to your ApplicationController:

```ruby
class ApplicationController < ActionController::Base
  log_page_views
end
```

The above command sets an after_filter to log every request. This is probably too much.  Try instead:

```ruby
class ApplicationController < ActionController::Base
  log_page_views :except => [:new, :create, :edit, :update, :destroy], :skip_namespace => [Admin, Devise], :details => false
end
```

The above command will log all requests to index, show and non-RESTful controller actions which are not from controllers in the Admin or Devise namespaces.

Page views always log the current_user when present.

By default, the request.params, request.format, request.referrer and request.user_agent information is also logged, unless :details => false is set.


Instead of logging all requests as per the ApplicationController, it may be easier to selectively log page views on just one or more controllers:

```ruby
class ProductsController < ApplicationController
  log_page_views
end
```

However, if log_page_views is set by the ApplicationController, you can still opt out of logging specific actions in two different ways:

```ruby
class ApplicationController < ActionController::Base
  log_page_views
end

class ProductsController < ApplicationController
  skip_log_page_views :only => [:show]   # Skip logging with a before_filter

  def index
    @products = Product.all

    skip_log_page_view if current_user.admin?    # Skip logging with a method
  end
end
```

The above command will skip logging of the :show action and will skip logging of the :index action if the current_user is an admin.

log_page_views accepts any options that an after_filter would accept and has access to the request object

```ruby
class ProductsController < ApplicationController
  log_page_views :if => Proc.new { request.get? }  # Only log GET requests
end
```

Similarly, skip_log_page_views also accepts any options that a before_filter would accept.


### Logging ActiveRecord changes

All changes made to an ActiveRecord object can be logged.

This logging includes the resource's base attributes, all autosaved associations (any accepts_nested_attributes has_manys) and the string representation of all belongs_tos.

It will recurse through all accepts_nested_attributes has_many's and handle any number of child objects.

Add to your model:

```ruby
class Post < ActiveRecord::Base
  log_changes
end
```

and to your controller:

```ruby
class ApplicationController < ActionController::Base
  before_action :set_effective_logging_current_user
end
```

Then to see the log for this resource, on any view:

```erb
<%= render_datatable(@post.log_changes_datatable) %>
```

The `log_changes` mixin sets up `before_save`, `before_destroy` and `after_commit` hooks to record both an activity log, and an audit log of all changes.

Each changed attribute will have its before and after values logged to form an activity log.

And on each create / destroy / update, a full dump of all current attributes is saved, forming an audit log.

If this ends up hammering your database, you can skip logging the associations by using `except` or `include_associated: false`

```ruby
class Post < ActiveRecord::Base
  log_changes include_associated: false
end
```

There is some initial support for passing `only`, and `except`, to the mixin to customize what attributes are saved.

Apply your own formatting to the logged title of each attribute by creating an instance method on the resource:

```ruby
# Format the title of this attribute. Return nil to use the default attribute.titleize
def log_changes_formatted_attribute(attribute)
  attribute.downcase
end
```

Apply your own formatting to the logged before and after values of each attribute by creating an instance method on the resource:

```ruby
# Format the value of this attribute. Return nil to use the default to_s
def log_changes_formatted_value(attribute, value)
  if ['cost'].include?(attribute)
    ApplicationController.helpers.number_to_currency(value)
  elsif ['percentage'].include?(attribute)
    ApplicationController.helpers.number_to_percentage(value)
  end
end
```

Fully customize your log by creating a public instance method on the resource:
```ruby
# Format the log 
def log_changes_formatted_log(default_message, details)
  {
    associated_to_s: "My #{self.class} label",
    message: "Changed from #{details[:changes].first} to #{details[:changes].last}"
  }
end
```

### Logging From JavaScript

First, require the javascript in your application.js:

```ruby
//= require effective_logging
```

and add the user permission:

```ruby
can :create, Effective::Log
```

then logging an event from JavaScript is almost the same one-liner as from ruby:

```javascript
EffectiveLogger.success('clicked start on a video');
```

the above command sends an AJAX request that creates the Log.  If the current_user is present :user will be automatically set.

The syntax to attach (any number of) additional information fields is very forgiving:

```javascript
EffectiveLogger.info('clicked start on a video', {video_title: 'cool video', video_time: '5:00'});
```

and

```javascript
EffectiveLogger.success('some other event', 'additional', 'information', {subject: 'my subject', from: 'someone'}, 'and more');
```

The same statuses available to ruby will be available to JavaScript.

Creating child logs via JavaScript is not yet supported.


## Admin Screen

Visit:

```ruby
link_to 'Logs', effective_logging.admin_logs_path   # /admin/logs
```

But you may need to add the permission (using CanCan):

```ruby
can :manage, Effective::Log
can :admin, :effective_logging
```


### Build an All Logs Screen

If you don't want to use the builtin Admin screen, and would rather render the effective_datatable of logs elsewhere

In your controller:

```ruby
@datatable = EffectiveLogsDatatable.new
```

And then in your view:

```ruby
render_datatable(@datatable)
```

### Build a User Specific Logs Screen

We can also use a similar method to create a datatable of logs for just one user.

When initialized with :for, the logs are scoped to any log where this id matches the User or Associated column.

```ruby
EffectiveLogsDatatable.new(for: @user.id)
EffectiveLogsDatatable.new(for: [1, 2, 3])  # Users with ID 1, 2 and 3
```

### Upgrade from 2.0

The database has changed slightly in 3.x

```ruby
rails generate migration upgrade_effective_logging
```

and then:

```ruby
change_column :logs, :message, :text # Was string

add_column :logs, :changes_to_type, :string
add_column :logs, :changes_to_id, :integer

ActiveRecord::Base.connection.execute('UPDATE logs SET changes_to_type = associated_type;')
ActiveRecord::Base.connection.execute('UPDATE logs SET changes_to_id = associated_id;')
```

## License

MIT License.  Copyright [Code and Effect Inc.](http://www.codeandeffect.com/)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Bonus points for test coverage
6. Create new Pull Request

