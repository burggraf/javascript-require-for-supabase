# javascript-require-for-supabase
Import node js modules into plv8 postgresql

## Quick Syntax and Sample:
```
const module_name = require(<url-or-module-name>, <autoload>);
```
where

* url-or-module-name: either the public url of the node js module or a module name you've put into the plv8_js_modules table manually.

* autoload: (optional) boolean:  true if you want this module to be loaded automatically when the plv8 extension starts up, otherwise false

Sample function:
```
create or replace function test_underscore()
returns json as $$
    const _ = require('https://cdn.jsdelivr.net/npm/underscore@1.12.1/underscore-min.js');
    const retval = _.map([1, 2, 3], function(num){ return num * 3; });
    return retval;
$$ language plv8;
```
## Make writing Postgreqsql modules fun again
Can you write JavaScript in your sleep?  Me too.
Can you write PlpgSql queries to save your life?  Me either.

Enter our masked hero from heaven:  [PLV8](https://plv8.github.io)

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

Now, you've got all that JavaScript goodness flowing, and it hits you -- What?  I can't access the huge world of Node JS libraries?  What do you expect me to do -- write JavaScript from scratch like an animal?  Forget it!

Enter **javascript-require-for-supabase**.

Run the SQL contained in javascript-require-for-supabase.sql, and now you can use 'require()'.  Since you don't have access to a file system, though, you can't use npm install.  So we need to have a way to load those neato node_modules.  How do we do it?

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
This isn't the ideal method, but you can do this on your own if you want.  Basically you load the source code for the module into the table.  But you need to deal with escaping the single-quotes and all that fun stuff.  Try Method 1 first, there's really no downside as long as you choose a compatible library and you can access it from the internet the first time you use it.  See below for details on how all this works.

## How it works
The first time you call require(url) the following stuff happens:

1.  If your requested module is cached, we return it from the cache.  Super fast!  Woohoo!  Otherwise...
2.  We check to see if the url (or module name if you loaded it manually) exists in the plv8_js_modules table.  If it does, we load the source for the module from the database and then eval() it.  Yes, we're using eval(), and that's how this is all possible.  We know about the security vulnerabilities with eval() but in this case, it's a necessary evil.  If you've got a better way, hit me up on GitHub.
3.  If the module isn't in our plv8_js_modules table, we use the http_get() function from [pgsql-http](https://github.com/pramsey/pgsql-http) to load the source into a variable, then we store it in the plv8_js_modules for later.  Later when we need it, we can get it from the database, then cache it.

So it goes: 
1.  Are you in the cache?  Load you now!
2.  Are you in the database?  Load you from the database and cache you for next time!
3.  First time being called, ever?  We'll load you over http, write you to the database, and you're all set and loaded for next time!

If you call require(url, true) that "true" parameter means "autoload this module" so that it gets loaded into the cache when PLV8 starts up. Only do this with modules you need to have ready to go immediately.  False essentially lazy-loads this module the first time it's called after startup.

## Requirements:
1.  Supabase database (or any Postgresql database, probably, as long as it's a current-enough version).
2.  The [PLV8](https://plv8.github.io) extension loaded.  (If you're on Supabase, this is easy as described above.  If you're not, you can read up on how to do that with your Postgresql databse on the PLV8 site.)
3.  The [pgsql-http](https://github.com/pramsey/pgsql-http) extension loaded.  (Same issues as #2 above.)
4.  ```alter database postgres set plv8.start_proc to plv8_require;```  (This needs to be run once and it's in the javascript-require-for-supabase.sql script.)
5.  **plv8_js_modules** table (Again, this is in the javascript-require-for-supabase.sql script.)

## Troubleshooting
If you need to reload a module for some reason, just remove the module's entry from your **plv8_js_modules** table.  Or just wipe it out:  **delete from plv8_js_modules;**

Sometimes a module won't work.  If you're using the minified version, try the non-minified version of the library.  Or vice-versa.  Not every library is going to work, especailly anything that requires a DOM, or access to hardware, or things like socket.io.  This is just basic JavsScript stuff -- it's not going dispense Pepsi and shoot out rainbows.  But it's still very cool and will save you eons of programming time.

## Credits
This is based on the great work of Ryan McGrath here:  [Deep Dive Into PLV8](https://rymc.io/blog/2016/a-deep-dive-into-plv8)

