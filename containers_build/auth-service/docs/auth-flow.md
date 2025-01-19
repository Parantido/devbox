sequenceDiagram
    participant User
    participant Traefik
    participant AuthService
    participant Keycloak
    participant ProtectedResource

    User->>Traefik: 1. Request Protected Resource
    Note over Traefik: Forward Auth Middleware
    Traefik->>AuthService: 2. Forward Auth Request<br/>with X-Original-Url
    
    alt Has Valid Token
        AuthService->>AuthService: 3a. Validate Token<br/>using JWK
        AuthService->>Traefik: 4a. Return 200 OK
        Traefik->>ProtectedResource: 5a. Forward Original Request
        ProtectedResource->>User: 6a. Return Protected Content
    else No Token or Invalid Token
        AuthService->>Keycloak: 3b. Redirect to Login<br/>with state param
        Keycloak->>User: 4b. Display Login Form
        User->>Keycloak: 5b. Submit Credentials
        Keycloak->>AuthService: 6b. Callback with Auth Code
        AuthService->>Keycloak: 7b. Exchange Code for Token
        Keycloak->>AuthService: 8b. Return Access Token
        AuthService->>User: 9b. Set auth_token Cookie<br/>& Redirect to Original URL
        User->>Traefik: 10b. Request Original Resource<br/>with auth_token Cookie
        Traefik->>AuthService: 11b. Forward Auth Request
        AuthService->>AuthService: 12b. Validate Token
        AuthService->>Traefik: 13b. Return 200 OK
        Traefik->>ProtectedResource: 14b. Forward Request
        ProtectedResource->>User: 15b. Return Protected Content
    end
