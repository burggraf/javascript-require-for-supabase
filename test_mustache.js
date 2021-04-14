create or replace function test_mustache()
returns text as $$
    const Mustache = require('https://cdnjs.cloudflare.com/ajax/libs/mustache.js/4.2.0/mustache.js', false);

    const template = 'Welcome to Mustache, {{ name }}!'

    var retval = Mustache.render(template, { name: 'Luke' });

    return retval; 
$$ language plv8;
