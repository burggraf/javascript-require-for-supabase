# javascript-require-for-supabase
Import node js modules into plv8 postgresql

## Quick Syntax:

const module_name = require(<url-or-module-name>, <autoload>);
where
*url-or-module-name* either the public url of the node js module or a module name you've put into the plv8_js_modules table manually.
*autoload* (optional) is a boolean:  true if you want this module to be loaded automatically when the plv8 extension starts up, otherwise false

## Make writing Postgreqsql modules fun again
Can you write JavaScript in your sleep?  Me too.
Can you write PlpgSql queries to save your life?  Me either.

Enter our masked hero from heaven:  plv8
https://plv8.github.io/

So how do I write nifty JavaScript modules for Supabase / Postgres?

1.  Turn on the plv8 extension for Supabase (Database / Extensions / PLV8 / ON)
2.  (Since you're already there, turn on the HTTP extension, which is a requirement for javascript-require-for-supabase.)
3.  Write a function!

```
create or replace function hello_javascript(name text)
returns json as $$
    const retval = { message: `Hello, my good friend ${name}!` };
    return retval; 
$$ language plv8;
```

So the syntax is a little weird, but you'll get used to it.  You need to add a data type after any function parameters.  You need to add the return type after the function name (and parameters).  You need to delimit the function with $$ pairs.  You have to add "language plv8" at the end.  Not so bad.  Cut and paste from a template if you can't remember all that (like I can't.)

Now, you've got all that JavaScript goodness flowing, and it hits you -- What?  I can't access all huge world of Node JS libraries?  What do you expect me to do -- write JavaScript from scratch like an animal?  Forget it!

Enter *javascript-require-for-supabase*.

Run the SQL contained in javascript-require-for-supabase.sql, and now you can use 'require()'.  Since you don't have access to a file system, though you can't use npm install.  So we need to have a way to load those neato node_modules.  How do we do it?

## Method 1:  load from the web automatically
This is the easiest (and preferred) method.

```
const module = require('https://url-to-public-function');
```
Here's how we'd use the popular Moment JS library:
```
create or replace function test_momentjs()
returns json as $$
    const moment = require('https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.29.1/moment.js', false);
    const retval = moment().add(7, 'days');
    
    return retval; 
$$ language plv8;
```
Then just call this function from SQL:
```
select test_momentjs();
```

Where do I find the url?  Hunt around on the library documentation page to find a CDN version of the library or look for documentation that shows how to load the library in HTML with a <SCRIPT> command.

## Method 2:  manually load the library into your plv8_js_modules table
This isn't the ideal method, but you can do this on your own if you want.  Basically you load the source code for the module into the table.  But you need to deal with escaping the single-quotes and all that fun stuff.  Try Method 1 first, there's really no downside as long as you choose a compatibe library and you can access it from the internet the first time you use it.  See below for details on how all this works.

## How it works
The first time you call require(url) the following stuff happens:

1.  If your requested module is cached, we return it from the cache.  Super fast!  Woohoo!  Otherwise...
2.  We check to see if the url (or module name if you loaded it manually) exists in the plv8_js_modules table.  If it does, we load the source for the module from the database and then eval() it.  Yes, we're using eval(), and that's how this is all possible.  We know about the security vulnerabilities with eval() but in this case, it's a necessary evil.  If you've got a better way, hit me up on GitHub.
3.  If the module isn't in our plv8_js_modules table, we use the http_get() function from pgsql-http (https://github.com/pramsey/pgsql-http) to load the source into a variable, then we store it in the plv8_js_modules for later.  Later when we need it, we can get it from the database, then cache it.


5.  
