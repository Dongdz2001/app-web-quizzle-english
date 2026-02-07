const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();

/**
 * Cloud Function để xóa user khỏi Firebase Auth
 * Chỉ admin (adminchi@gmail.com) mới có quyền gọi function này
 * 
 * @param {string} data.userId - ID của user cần xóa
 * @returns {Object} { success: true, message: "User deleted successfully" }
 */
exports.deleteUser = functions.https.onCall(async (data, context) => {
  // Kiểm tra authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to call this function'
    );
  }

  // Kiểm tra quyền admin
  const callerEmail = context.auth.token.email;
  if (!callerEmail || callerEmail.toLowerCase() !== 'adminchi@gmail.com') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admin can delete users'
    );
  }

  // Kiểm tra userId được cung cấp
  const userId = data.userId;
  if (!userId || typeof userId !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'userId must be provided as a string'
    );
  }

  try {
    // Kiểm tra user có tồn tại không
    try {
      await admin.auth().getUser(userId);
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        // User không tồn tại trong Auth, nhưng vẫn trả về success
        // vì có thể đã được xóa trước đó
        return {
          success: true,
          message: 'User does not exist in Auth (may have been deleted already)'
        };
      }
      throw error;
    }

    // Xóa user khỏi Firebase Auth
    await admin.auth().deleteUser(userId);

    return {
      success: true,
      message: 'User deleted successfully from Firebase Auth'
    };
  } catch (error) {
    console.error('Error deleting user:', error);
    throw new functions.https.HttpsError(
      'internal',
      `Failed to delete user: ${error.message}`
    );
  }
});
