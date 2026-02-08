const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();

/**
 * Cloud Function để xóa user khỏi Firebase Auth
 * Chỉ user có custom claim 'admin' mới có quyền gọi function này
 *
 * @param {string} data.uid - ID của user cần xóa
 * @returns {Object} { success: true, message: "User deleted successfully" }
 */
exports.deleteUserByUid = functions.https.onCall(async (data, context) => {
  // Kiểm tra authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated to call this function',
    );
  }

  // Kiểm tra quyền admin thông qua custom claims
  if (!context.auth.token.admin) {
    throw new functions.https.HttpsError(
        'permission-denied',
        'Only admin can delete users',
    );
  }

  // Kiểm tra uid được cung cấp
  const uid = data.uid;
  if (!uid || typeof uid !== 'string') {
    throw new functions.https.HttpsError(
        'invalid-argument',
        'uid must be provided as a string',
    );
  }

  try {
    // Kiểm tra user có tồn tại không
    try {
      await admin.auth().getUser(uid);
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        // User không tồn tại trong Auth, nhưng vẫn trả về success
        // vì có thể đã được xóa trước đó
        return {
          success: true,
          message: 'User does not exist in Auth (may have been deleted already)',
        };
      }
      throw error;
    }

    // Xóa user khỏi Firebase Auth
    await admin.auth().deleteUser(uid);

    return {
      success: true,
      message: 'User deleted successfully from Firebase Auth',
    };
  } catch (error) {
    console.error('Error deleting user:', error);
    throw new functions.https.HttpsError(
        'internal',
        `Failed to delete user: ${error.message}`,
    );
  }
});

/**
 * Cloud Function để set admin custom claim cho user
 * Chỉ user có email adminchi@gmail.com mới có quyền gọi function này
 *
 * @param {string} data.uid - ID của user cần set admin
 * @returns {Object} { success: true, message: "Admin claim set successfully" }
 */
exports.setAdminClaim = functions.https.onCall(async (data, context) => {
  // Kiểm tra authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated to call this function',
    );
  }

  // Chỉ cho phép adminchi@gmail.com set admin claim
  const callerEmail = context.auth.token.email;
  if (!callerEmail || callerEmail.toLowerCase() !== 'adminchi@gmail.com') {
    throw new functions.https.HttpsError(
        'permission-denied',
        'Only super admin can set admin claims',
    );
  }

  const uid = data.uid;
  if (!uid || typeof uid !== 'string') {
    throw new functions.https.HttpsError(
        'invalid-argument',
        'uid must be provided as a string',
    );
  }

  try {
    // Set custom claim admin = true
    await admin.auth().setCustomUserClaims(uid, {admin: true});

    return {
      success: true,
      message: 'Admin claim set successfully',
    };
  } catch (error) {
    console.error('Error setting admin claim:', error);
    throw new functions.https.HttpsError(
        'internal',
        `Failed to set admin claim: ${error.message}`,
    );
  }
});
