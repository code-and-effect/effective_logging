# Effective Logging

A Rails3 / Rails4 engine to completely handle logging of events.

Logs are stored in a single database table. A Log (one logged event) can have many children Logs, nested to any depth.

Provides a ruby one-liner to log a message, status, user, associated object and any number of additional details.

Works great for single fire-and-forget events and long running tasks.

Provides a simple Javascript API for logging front-end events.

Automatically logs any email sent by the application, any successful user login via Devise, and all page views.

Has an effective_datatables driven admin interface to display and search/sort/filter all logs.


## Getting Started

Add to your Gemfile:

```ruby
gem 'effective_logging', :git => 'https://github.com/code-and-effect/effective_logging.git'
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


### Automatic Logging of E-mails

Any email sent by the application will be automatically logged.

This behaviour can be disabled in the config/initializers/effective_logging.rb initializer.

If the TO email address match a User, the :user will be set appropriately.


### Automatic Logging of User Logins

Any successful User logins via Devise will be automatically logged.

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

log_page_views accepts any options that an after_filter would accept.

skip_log_page_views accepts any options that a before_filter would accept.


### Logging From JavaScript

First, require the javascript in your application.js:

```ruby
//= require effective_logging
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

To use the Admin screen, please also install the effective_datatables gem:

```ruby
gem 'effective_datatables', :git => 'https://github.com/code-and-effect/effective_datatables.git'
```

Then you should be able to visit:

```ruby
link_to 'Logs', effective_logging.admin_logs_path   # /admin/logs
```


## License

MIT License.  Copyright Code and Effect Inc. http://www.codeandeffect.com

You are not granted rights or licenses to the trademarks of Code and Effect


### Testing

The test suite for this gem is unfortunately not yet complete.

Run tests by:

```ruby
rake spec
```
