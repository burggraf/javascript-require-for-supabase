# javascript-require-for-supabase
Import node js modules into plv8 postgresql

## Make writing Postgreqsql modules fun again
Can you write JavaScript in your sleep?  Me too.
Can you write PlpgSql queries to save your life?  Me either.

Enter our masked hero from heaven:  plv8
https://plv8.github.io/

So how do I write nifty JavaScript modules for Supabase / Postgres?

1.  Turn on the plv8 extension for Supabase (Database / Extensions / PLV8 / ON)
2.  Write a function!

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

Where do I find the url?  Hunt around on the library documentation page to find a CDN version of the library or look for documentation that shows how to load the library in HTML with a <SCRIPT> command.

## Method 2:  manually load the library into your plv8_js_modules table
This isn't the ideal method, but you can do this on your own if you want.  Basically you load the source code for the module into the table.  But you need to deal with escaping the single-quotes and all that fun stuff.  Try Method 1 first, there's really no downside as long as you choose a compatibe library and you can access it from the internet the first time you use it.  See below for details on how all this works.

## How it works
The first time you call require(url) the following stuff happens: