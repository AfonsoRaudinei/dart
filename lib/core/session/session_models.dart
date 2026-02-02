sealed class SessionState {
  const SessionState();
}

class SessionUnknown extends SessionState {
  const SessionUnknown();
}

class SessionPublic extends SessionState {
  const SessionPublic();
}

class SessionAuthenticated extends SessionState {
  final String token;
  const SessionAuthenticated(this.token);
}
