-- =====================================================================
-- STEP 4: Teach Snowflake to trust Entra-issued tokens
-- Run AFTER creating the Entra resource app (see ../entra/README.md),
-- because you need the resource app's client ID and your tenant ID.
-- =====================================================================

USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE SECURITY INTEGRATION external_oauth_entra
  TYPE = EXTERNAL_OAUTH
  ENABLED = TRUE
  EXTERNAL_OAUTH_TYPE = AZURE
  EXTERNAL_OAUTH_ISSUER = 'https://sts.windows.net/<TENANT_ID>/'
  EXTERNAL_OAUTH_JWS_KEYS_URL = 'https://login.microsoftonline.com/<TENANT_ID>/discovery/v2.0/keys'
  EXTERNAL_OAUTH_AUDIENCE_LIST = ('api://<RESOURCE_APP_CLIENT_ID>')
  EXTERNAL_OAUTH_TOKEN_USER_MAPPING_CLAIM = 'upn'
  EXTERNAL_OAUTH_SNOWFLAKE_USER_MAPPING_ATTRIBUTE = 'LOGIN_NAME'
  EXTERNAL_OAUTH_ANY_ROLE_MODE = ENABLE;   -- required for the session:role-any scope

DESCRIBE INTEGRATION external_oauth_entra;

-- What to confirm in the output:
--   ENABLED                                  = true
--   EXTERNAL_OAUTH_AUDIENCE_LIST             = api://<RESOURCE_APP_CLIENT_ID>
--   EXTERNAL_OAUTH_TOKEN_USER_MAPPING_CLAIM  = ['upn']
--   EXTERNAL_OAUTH_SNOWFLAKE_USER_MAPPING_ATTRIBUTE = LOGIN_NAME
--   EXTERNAL_OAUTH_ANY_ROLE_MODE             = ENABLE
--
-- Note: ACCOUNTADMIN, ORGADMIN, SECURITYADMIN are blocked by default
-- for external OAuth logins — a good safety default.
