import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Human {
  static User user;
  static String profilePhoto;
  static String username;
  static String uid;
  static String email;
  static String coverPhoto;
  static Set<String> following;
  static Set<String> hasDownloaded;
  static Set<String> hasBlocked;
  static Set<String> hasDeleted;
  static Set<String> hasBeenBlockedBy;
  static List<Map<String, dynamic>> myChannels;
  static List<DocumentSnapshot> recentUserSearches;
  static List<DocumentSnapshot> recentChannelSearches;
  static File fProfilePhoto;
  static File fCoverPhoto;
  static Map<String, int> userActions;
  static Map<String, int> reactionsToHave;
  static Map<String, int> peopleToFollow;
  static Map<String, int> actionsToTake;
  static Map<String, int> channelsToDownload;
  static dynamic numberOfIthReactions;
  static int followingCount;
  static int followerCount;
  static bool hasJustCreatedAccount;
  static int numberOfUnreadNotifications;
  static int numberOfChannels;
}
