--Get the list of all existing roles and their attributes
SELECT * 
FROM pg_roles;

--Get the roles with their access to specific tables
SELECT * 
FROM information_schema.role_table_grants
WHERE table_schema = 'public';

--Check the RLS status on tables
SELECT relname AS table_name, relrowsecurity AS rls_enabled, relforcerowsecurity AS rls_forced
FROM pg_class;

--Get the list of priviliges for routines(functions and procedures)
SELECT grantee, routine_name, privilege_type 
FROM information_schema.role_routine_grants
WHERE specific_schema= 'public';





