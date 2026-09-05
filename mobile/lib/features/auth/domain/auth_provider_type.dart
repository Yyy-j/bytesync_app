/// Identity providers supported by the auth layer.
///
/// Only [google] is wired up to a real sign-in flow in this MVP. [apple]
/// exists so the rest of the auth stack (repository interface, state,
/// controller) never has to change shape when Sign in with Apple is added
/// later — only a new provider implementation needs to be plugged in.
enum AuthProviderType { google, apple }
