import 'package:flutter/foundation.dart';

/// Optional callback and email passed through TV auth routes.
@immutable
class TvAuthRouteArgs {
  const TvAuthRouteArgs({this.onSessionEstablished, this.email});

  final VoidCallback? onSessionEstablished;
  final String? email;

  static TvAuthRouteArgs from(dynamic args) {
    if (args is VoidCallback) {
      return TvAuthRouteArgs(onSessionEstablished: args);
    }
    if (args is Map) {
      return TvAuthRouteArgs(
        onSessionEstablished: args['onSessionEstablished'] as VoidCallback?,
        email: args['email'] as String?,
      );
    }
    return const TvAuthRouteArgs();
  }

  Map<String, dynamic> withEmail(String email) => {
        if (onSessionEstablished != null)
          'onSessionEstablished': onSessionEstablished,
        'email': email,
      };
}
