--Get the list of all existing roles and their attributes
SELECT * 
FROM pg_roles; 
--we see FROM the RESULT that the super role (creator of the database) belongs to postgres (only postgres can create role or db)
--also postgres has all the privivliges - as being super role
--all roles inherit the priviliges of the role they are member of

--Get the roles with their access to specific tables
SELECT * 
FROM information_schema.role_table_grants
WHERE table_schema = 'public';
--we see that the only grantor is postgres, as only postgres has such privilige
--and we can see which user what type of priviliges has and for which schema, for which table, who granted them, 
--whether the grantee role has the privilige to grant that privilige to some other user

--Check the RLS status on tables
SELECT relname AS table_name, relrowsecurity AS rls_enabled, relforcerowsecurity AS rls_forced
FROM pg_class;
--via this query we see whether row level security is enabled on tables and whether it is enforced for all users or no

--Get the list of priviliges for routines(functions and procedures)
SELECT grantee, routine_name, privilege_type 
FROM information_schema.role_routine_grants
WHERE specific_schema= 'public';
--this query allows us to see which user granted priviliges to which user for which routine(function)




