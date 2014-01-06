# You can use your system's CA bundle or provide a private bundle.
# Since this app is often deployed on OS X, which uses Keychain to store certs,
# a local copy of Curl's public CA bundle is included.
GoogleAppsAuth.certificate_authority_file = "config/curl-ca-bundle.crt"

# Set this to your company's domain to restrict logins
# GoogleAppsAuth.default_domain = "example.com"
