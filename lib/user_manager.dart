class UserManager {
  // This is the Singleton pattern. It ensures we only ever have one
  // instance of this class in the entire app, so the user ID is
  // always consistent.
  static final UserManager _instance = UserManager._internal();

  factory UserManager() {
    return _instance;
  }

  UserManager._internal();

  // This is where we will store the current user's ID after login.
  String? currentUserId;
}