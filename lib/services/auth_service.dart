import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as app_models;

class AuthService extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  app_models.User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  app_models.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;

  AuthService() {
    print('Initializing Auth');
    
    // Listen to auth state changes
    _firebaseAuth.authStateChanges().listen((user) {
      print('Auth state changed: ${user?.uid}');
      _onAuthStateChanged(user);
    });
  }

  Future<void> _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
    // If no user, clear current user and return
    if (firebaseUser == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }

    // If we already have a current user with the same ID, don't reload from Firestore
    if (_currentUser != null && _currentUser!.id == firebaseUser.uid) {
      return;
    }

    // If we're in the signup process, don't try to load from Firestore yet
    if (_isSigningUp) {
      print('In signup process, skipping auth state change handling');
      return;
    }

    // Get a valid username from Firebase Auth or use a default
    String username = firebaseUser.displayName ?? '';
    if (username.isEmpty) {
      username = 'User';
    }
    
    // Create a basic user object as a fallback
    final basicUser = app_models.User(
      id: firebaseUser.uid,
      username: username,
      email: firebaseUser.email!,
      createdAt: DateTime.now(),
    );

    // Try to load user data from Firestore
    try {
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      
      if (userDoc.exists && userDoc.data() != null) {
        // User document exists in Firestore
        final userData = userDoc.data()!;
        userData['id'] = firebaseUser.uid; // Ensure ID is set correctly
        
        try {
          // Try to create user from Firestore data
          String firestoreUsername = userData['username'] as String? ?? '';
          if (firestoreUsername.isEmpty) {
            firestoreUsername = username.isNotEmpty ? username : 'User';
            // Update the username in Firestore
            await _firestore.collection('users').doc(firebaseUser.uid).update({'username': firestoreUsername});
          }
          
          _currentUser = app_models.User(
            id: userData['id'] as String,
            username: firestoreUsername,
            email: userData['email'] as String? ?? firebaseUser.email!,
            photoUrl: userData['photoUrl'] as String?,
            createdAt: userData['createdAt'] is Timestamp 
              ? (userData['createdAt'] as Timestamp).toDate()
              : (userData['createdAt'] is String 
                ? DateTime.parse(userData['createdAt'] as String)
                : DateTime.now()),
          );
          print('Loaded user from Firestore: ${_currentUser!.username}');
          
          // Update display name in Firebase Auth if it doesn't match
          if (firebaseUser.displayName != _currentUser!.username) {
            try {
              await firebaseUser.updateDisplayName(_currentUser!.username);
              print('Updated Firebase Auth display name to: ${_currentUser!.username}');
            } catch (e) {
              print('Error updating display name: $e');
            }
          }
        } catch (e) {
          print('Error creating user from Firestore data: $e');
          print('User data: $userData');
          // Use the basic user as fallback
          _currentUser = basicUser;
          
          // Try to update the Firestore document with correct data
          try {
            await _firestore.collection('users').doc(firebaseUser.uid).set(_currentUser!.toJson());
            print('Updated user document with correct data');
          } catch (updateError) {
            print('Error updating user document: $updateError');
          }
        }
      } else {
        // No user document in Firestore, create one
        print('User document not found in Firestore, creating new one');
        _currentUser = basicUser;
        
        try {
          await _firestore.collection('users').doc(firebaseUser.uid).set(_currentUser!.toJson());
          print('Created new user document in Firestore');
        } catch (saveError) {
          print('Error saving new user document: $saveError');
        }
      }
    } catch (e) {
      // Error accessing Firestore
      print('Error loading user data from Firestore: $e');
      _currentUser = basicUser;
    }
    
    // Notify listeners of the change
    notifyListeners();
  }

  // Helper method to create a User object from Firestore data
  app_models.User _createUserFromData(Map<String, dynamic> userData) {
    try {
      // Extract ID with fallback
      final id = userData['id'] as String? ?? '';
      if (id.isEmpty) {
        throw Exception('User ID is missing or empty');
      }
      
      // Extract username with fallback - ensure it's never empty
      String username = userData['username'] as String? ?? 'User';
      if (username.isEmpty) {
        username = 'User';
      }
      
      // Extract email with fallback
      final email = userData['email'] as String? ?? '';
      if (email.isEmpty) {
        throw Exception('User email is missing or empty');
      }
      
      // Extract photo URL (optional)
      final photoUrl = userData['photoUrl'] as String?;
      
      // Extract created date with fallback
      DateTime createdAt;
      final createdAtData = userData['createdAt'];
      if (createdAtData is Timestamp) {
        createdAt = createdAtData.toDate();
      } else if (createdAtData is String) {
        try {
          createdAt = DateTime.parse(createdAtData);
        } catch (_) {
          createdAt = DateTime.now();
        }
      } else {
        createdAt = DateTime.now();
      }
      
      return app_models.User(
        id: id,
        username: username,
        email: email,
        photoUrl: photoUrl,
        createdAt: createdAt,
      );
    } catch (e) {
      print('Error creating user from data: $e');
      print('User data: $userData');
      // Create a basic user object with the available data
      String username = userData['username']?.toString() ?? 'User';
      if (username.isEmpty) {
        username = 'User';
      }
      
      return app_models.User(
        id: userData['id'] as String? ?? '',
        username: username,
        email: userData['email']?.toString() ?? '',
        createdAt: DateTime.now(),
      );
    }
  }

  Future<void> _saveUserToFirestore(app_models.User user) async {
    try {
      final userData = user.toJson();
      await _firestore.collection('users').doc(user.id).set(userData);
      print('User data saved to Firestore: $userData');
    } catch (e) {
      print('Error saving user data to Firestore: $e');
      throw e;
    }
  }

  // Flag to track if we're in the signup process to prevent duplicate user creation
  bool _isSigningUp = false;

  Future<bool> signUp(String username, String email, String password) async {
    if (_isSigningUp) {
      print('Already in signup process, ignoring duplicate call');
      return false;
    }
    
    try {
      _isSigningUp = true;
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      // Ensure username is not empty
      if (username.trim().isEmpty) {
        username = 'User';
      }
      
      // Create user with email and password first
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user document in Firestore
      final newUser = app_models.User(
        id: userCredential.user!.uid,
        username: username,
        email: email,
        createdAt: DateTime.now(),
      );
      
      // Set the current user directly
      _currentUser = newUser;
      
      // Try to update display name - wrap in try/catch to handle potential errors
      try {
        await userCredential.user?.updateDisplayName(username);
        print('Updated display name to: $username');
      } catch (displayNameError) {
        print('Error updating display name: $displayNameError');
        // Continue even if display name update fails
      }
      
      // Try to save to Firestore - wrap in try/catch to handle potential errors
      try {
        final userData = newUser.toJson();
        print('Saving user data to Firestore: $userData');
        await _firestore.collection('users').doc(newUser.id).set(userData);
        print('User data saved to Firestore successfully');
      } catch (firestoreError) {
        print('Error saving user to Firestore: $firestoreError');
        // Continue even if Firestore save fails
      }
      
      _isLoading = false;
      _isSigningUp = false;
      notifyListeners();
      
      // Return true even if there were non-critical errors
      return true;
    } catch (e) {
      _isLoading = false;
      _isSigningUp = false;
      if (e is firebase_auth.FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            _errorMessage = 'This email is already registered';
            break;
          case 'weak-password':
            _errorMessage = 'The password is too weak';
            break;
          default:
            _errorMessage = 'Registration failed: ${e.message}';
        }
      } else {
        _errorMessage = 'Registration failed: $e';
      }
      print('Sign up error: $_errorMessage');
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      // Sign in with email and password
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // If we have a user, consider it a success even if there are other issues
      final success = userCredential.user != null;
      
      // Try to load user data from Firestore
      if (success) {
        try {
          final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
          if (userDoc.exists && userDoc.data() != null) {
            final userData = userDoc.data()!;
            userData['id'] = userCredential.user!.uid;
            
            try {
              // Ensure username is not empty
              String username = userData['username'] as String? ?? '';
              if (username.isEmpty) {
                username = userCredential.user!.displayName ?? 'User';
                if (username.isEmpty) {
                  username = 'User';
                }
                // Update the username in Firestore
                await _firestore.collection('users').doc(userCredential.user!.uid).update({'username': username});
              }
              
              _currentUser = _createUserFromData(userData);
              print('Loaded user from Firestore during login: ${_currentUser!.username}');
              
              // Ensure Firebase Auth display name is set
              if (userCredential.user!.displayName != _currentUser!.username) {
                await userCredential.user!.updateDisplayName(_currentUser!.username);
                print('Updated Firebase Auth display name to: ${_currentUser!.username}');
              }
            } catch (parseError) {
              print('Error parsing user data during login: $parseError');
              // Create a basic user if parsing fails
              String username = userCredential.user!.displayName ?? 'User';
              if (username.isEmpty) {
                username = 'User';
              }
              
              _currentUser = app_models.User(
                id: userCredential.user!.uid,
                username: username,
                email: userCredential.user!.email!,
                createdAt: DateTime.now(),
              );
              
              // Update Firestore with the corrected user data
              await _firestore.collection('users').doc(_currentUser!.id).set(_currentUser!.toJson());
            }
          } else {
            // Create a basic user if no Firestore document exists
            String username = userCredential.user!.displayName ?? 'User';
            if (username.isEmpty) {
              username = 'User';
            }
            
            _currentUser = app_models.User(
              id: userCredential.user!.uid,
              username: username,
              email: userCredential.user!.email!,
              createdAt: DateTime.now(),
            );
            
            // Try to save the user to Firestore
            try {
              await _firestore.collection('users').doc(_currentUser!.id).set(_currentUser!.toJson());
              print('Created new user document in Firestore during login');
            } catch (saveError) {
              print('Error saving user during login: $saveError');
              // Continue even if save fails
            }
          }
        } catch (firestoreError) {
          print('Error loading user data from Firestore during login: $firestoreError');
          // Create a basic user if Firestore access fails
          String username = userCredential.user!.displayName ?? 'User';
          if (username.isEmpty) {
            username = 'User';
          }
          
          _currentUser = app_models.User(
            id: userCredential.user!.uid,
            username: username,
            email: userCredential.user!.email!,
            createdAt: DateTime.now(),
          );
          
          // Try to save the user to Firestore
          try {
            await _firestore.collection('users').doc(_currentUser!.id).set(_currentUser!.toJson());
          } catch (saveError) {
            print('Error saving user during login after Firestore error: $saveError');
          }
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      if (e is firebase_auth.FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            _errorMessage = 'No user found with this email';
            break;
          case 'wrong-password':
            _errorMessage = 'Wrong password';
            break;
          case 'user-disabled':
            _errorMessage = 'This account has been disabled';
            break;
          default:
            _errorMessage = 'Login failed: ${e.message}';
        }
      } else {
        _errorMessage = 'Login failed: $e';
      }
      print('Sign in error: $_errorMessage');
      
      // Check if the user is actually authenticated despite the error
      if (_firebaseAuth.currentUser != null) {
        // If the user is authenticated, we'll consider this a success
        String username = _firebaseAuth.currentUser!.displayName ?? 'User';
        if (username.isEmpty) {
          username = 'User';
        }
        
        _currentUser = app_models.User(
          id: _firebaseAuth.currentUser!.uid,
          username: username,
          email: _firebaseAuth.currentUser!.email!,
          createdAt: DateTime.now(),
        );
        
        // Try to save the user to Firestore
        try {
          await _firestore.collection('users').doc(_currentUser!.id).set(_currentUser!.toJson());
        } catch (saveError) {
          print('Error saving user during login after auth error: $saveError');
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firebaseAuth.signOut();
      
      // The auth state listener will handle setting _currentUser to null
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to sign out: $e';
      notifyListeners();
      print('Sign out error: $_errorMessage');
    }
  }

  Future<bool> updateProfile(String username, String? photoUrl) async {
    if (_currentUser == null) return false;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      // Ensure username is not empty
      if (username.trim().isEmpty) {
        username = 'User';
      }
      
      // Update display name in Firebase Auth
      await _firebaseAuth.currentUser?.updateDisplayName(username);
      
      // Create updated user object
      final updatedUser = app_models.User(
        id: _currentUser!.id,
        username: username,
        email: _currentUser!.email,
        photoUrl: photoUrl,
        createdAt: _currentUser!.createdAt,
      );
      
      // Update user in Firestore
      await _saveUserToFirestore(updatedUser);
      
      // Update local user object
      _currentUser = updatedUser;
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update profile: $e';
      notifyListeners();
      return false;
    }
  }
  
  // Add this method to check for and clean up duplicate user documents
  Future<void> checkAndCleanupDuplicateUsers() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return;
    
    try {
      print('Checking for duplicate users with email: ${firebaseUser.email}');
      
      // Query all documents with the same email
      final querySnapshot = await _firestore.collection('users')
          .where('email', isEqualTo: firebaseUser.email)
          .get();
      
      print('Found ${querySnapshot.docs.length} user documents with email ${firebaseUser.email}');
      
      if (querySnapshot.docs.length > 1) {
        print('Found ${querySnapshot.docs.length} user documents with the same email');
        
        // Find the document with the correct user ID
        final correctDoc = querySnapshot.docs.firstWhere(
          (doc) => doc.id == firebaseUser.uid,
          orElse: () => querySnapshot.docs.first,
        );
        
        // Get the username from the correct document
        final correctUsername = correctDoc.data()['username'] as String? ?? firebaseUser.displayName ?? 'User';
        print('Using username "$correctUsername" from document ${correctDoc.id}');
        
        // Update the Firebase Auth display name if needed
        if (firebaseUser.displayName != correctUsername) {
          print('Updating Firebase Auth display name from "${firebaseUser.displayName}" to "$correctUsername"');
          await firebaseUser.updateDisplayName(correctUsername);
        }
        
        // Delete all other documents
        for (final doc in querySnapshot.docs) {
          if (doc.id != firebaseUser.uid) {
            print('Deleting duplicate user document: ${doc.id} with username ${doc.data()['username']}');
            await _firestore.collection('users').doc(doc.id).delete();
          }
        }
        
        // Ensure the correct document has the right data
        final updatedUser = app_models.User(
          id: firebaseUser.uid,
          username: correctUsername,
          email: firebaseUser.email!,
          photoUrl: _currentUser?.photoUrl,
          createdAt: _currentUser?.createdAt ?? DateTime.now(),
        );
        
        // Use a transaction to update the user document
        final userRef = _firestore.collection('users').doc(firebaseUser.uid);
        await _firestore.runTransaction((transaction) async {
          transaction.set(userRef, updatedUser.toJson());
        });
        
        _currentUser = updatedUser;
        notifyListeners();
        print('User cleanup completed successfully');
      } else if (querySnapshot.docs.isEmpty) {
        // No user document found, create one
        print('No user document found for email ${firebaseUser.email}, creating one');
        final newUser = app_models.User(
          id: firebaseUser.uid,
          username: firebaseUser.displayName ?? 'User',
          email: firebaseUser.email!,
          createdAt: DateTime.now(),
        );
        
        await _saveUserToFirestore(newUser);
        _currentUser = newUser;
        notifyListeners();
      } else if (querySnapshot.docs.length == 1 && querySnapshot.docs.first.id != firebaseUser.uid) {
        // One document found but with wrong ID, fix it
        print('Found user document with correct email but wrong ID, fixing');
        final existingDoc = querySnapshot.docs.first;
        final existingData = existingDoc.data();
        
        // Create a new document with the correct ID
        final newUser = app_models.User(
          id: firebaseUser.uid,
          username: existingData['username'] as String? ?? firebaseUser.displayName ?? 'User',
          email: firebaseUser.email!,
          photoUrl: existingData['photoUrl'] as String?,
          createdAt: existingData['createdAt'] is String 
            ? DateTime.parse(existingData['createdAt']) 
            : (existingData['createdAt'] is Timestamp 
                ? (existingData['createdAt'] as Timestamp).toDate()
                : DateTime.now()),
        );
        
        // Save the new document and delete the old one
        await _saveUserToFirestore(newUser);
        await _firestore.collection('users').doc(existingDoc.id).delete();
        
        _currentUser = newUser;
        notifyListeners();
      }
    } catch (e) {
      print('Error checking for duplicate users: $e');
    }
  }
}