/* javascript-require-for-supabase.sql */

/* the alter database line below needs to be run ONCE on your database */
alter database postgres set plv8.start_proc to plv8_require;
create table if not exists plv8_js_modules (
    module text unique primary key,
    autoload bool default false,
    source text
);
create or replace function plv8_require()
returns void as $$
    moduleCache = {};

    load = function(key, source) {
        var module = {exports: {}};
        try {
            eval("(function(module, exports) {" + source + "; })")(module, module.exports);
        } catch (err) {
            plv8.elog(ERROR, `eval error in source: ${err} (SOURCE): ${source}`);
        }
            
        // store in cache
        moduleCache[key] = module.exports;
        return module.exports;
    };

    require = function(module, autoload) {
        if(moduleCache[module])
            return moduleCache[module];

        var rows = plv8.execute(
            "select source from plv8_js_modules where module = $1", 
            [module]
        );
        
        if (rows.length === 0 && module.substr(0,4) === 'http') {

            try {
                source = plv8.execute(`SELECT content FROM http_get('${module}');`)[0].content;       
            } catch (err) {
                plv8.elog(ERROR, `Could not load get module through http: ${module}`);
            }
            try {
                /* the line below is written purely for esthetic reasons, so as not to mess up the online source editor */
                /* when using standard regExp expressions, the single-quote char messes up the code highlighting */
                /* in the editor and everything looks funky */
                const quotedSource = source.replace(new RegExp(String.fromCharCode(39), 'g'), String.fromCharCode(39, 39));

                plv8.execute(`insert into plv8_js_modules (module, autoload, source) values ('${module}', ${autoload ? true : false}, '${quotedSource}')`);                
            } catch (err) {
                plv8.elog(ERROR, `Error inserting module into plv8_js_modules: ${err} ${module}, ${autoload ? true : false}, '${plv8.quote_literal(source)}'`);
            }
            return load(module, source);
        }
        
        else if(rows.length === 0) {
            plv8.elog(NOTICE, `Could not load module: ${module}`);
            return null;
        } else {
            return load(module, rows[0].source);
        }
        
    };
    
    // Grab modules worth auto-loading at context start and let them cache
    var query = `select module, source from plv8_js_modules where autoload = true`;
    plv8.execute(query).forEach(function(row) {
        load(row.module, row.source);
    });
$$ language plv8;
