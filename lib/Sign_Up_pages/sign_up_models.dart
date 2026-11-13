enum SignUpSubmissionResult {
  created,
  emailAlreadyRegistered,
  serviceUnavailable,
}

class SignUpRequest {
  const SignUpRequest({
    required this.email,
    required this.password,
    required this.fullName,
    required this.workspaceName,
  });

  final String email;
  final String password;
  final String fullName;
  final String workspaceName;
}

typedef SignUpSubmitter = Future<SignUpSubmissionResult> Function(
  SignUpRequest request,
);
