import * as functions from 'firebase-functions'
import * as admin from "firebase-admin"

admin.initializeApp()

export const getEmailFromUsername = functions.https.onCall(async (data: any) => {
    const username: string = data['username']
    const password: string = data['password']
    if (typeof username !== 'string' || typeof password !== 'string' || username.length < 3 || username.length > 32) {
        return null
    }
    const queryUsers: admin.firestore.QuerySnapshot | void = await
        admin.firestore().collection('users').where('username', '==', username).get().catch((error) => console.log(error))
    if (queryUsers === undefined || queryUsers.docs.length === 0) {
        return null
    }
    const userSnap: admin.firestore.DocumentSnapshot = queryUsers.docs[0]
    if (!userSnap.exists) {
        return null
    }
    const uid: string = userSnap.id
    const hiddenSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('privateInfo').doc(uid).get().catch((error) => console.log(error))
    if (hiddenSnap === undefined || !hiddenSnap.exists) {
        return null
    }
    const firebaseClient = require('firebase')
    const email: string = hiddenSnap.get('email')
    let thereIsAnError: boolean = false
    const firebaseConfig = {
        apiKey: 'AIzaSyAdwRS6oJ8x5W80HAzoexI7iGfdNwXHXq0',
        projectId: 'jasper-2ffc6',
        databaseURL: 'https://jasper-2ffc6.firebaseio.com',
        authDomain: 'jasper-2ffc6.firebaseapp.com',
        storageBucket: 'jasper-2ffc6.appspot.com',
        messagingSenderId: '24616032168'
    }
    if (!firebaseClient.apps.length) {
        firebaseClient.initializeApp(firebaseConfig)
    }
    await firebaseClient.auth().signInWithEmailAndPassword(email, password).catch((_: any) => thereIsAnError = true)
    if (!thereIsAnError) {
        return hiddenSnap.get('email')
    }
    return null
})

export const selectChannel = functions.https.onCall(async (data: any, context) => {
    const channelID: string = data['channelID']
    const uid: string = data['uid']
    if (typeof uid === 'string' && typeof channelID === 'string' && context.auth !== undefined && context.auth.uid === uid && channelID.trim().length >= 3) {
        const promises: any = []
        const _channelSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('users').doc(uid).collection('channels').doc(channelID).get().catch((error) => console.log(error))
        if (_channelSnap !== undefined && _channelSnap.exists) {
            const channelQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(uid).collection('channels').where('isUsing', '==', true).get().catch((error) => console.log(error))
            if (channelQuery !== undefined) {
                for (const channelSnap of channelQuery.docs) {
                    await channelSnap.ref.update({ isUsing: false }).catch((error) => console.log(error))
                }
            }
            promises.push(_channelSnap.ref.update({ isUsing: true, lastUsed: Date.now() }).catch((error) => console.log(error)))
            return Promise.all(promises)
        }
    }
    return null
})

export const selectTrending = functions.https.onCall(async (data: any, context) => {
    const channelID: string = data['channelID']
    const uid: string = data['uid']
    if (typeof uid === 'string' && typeof channelID === 'string' && context.auth !== undefined && context.auth.uid === uid) {
        return admin.firestore().collection('users').doc(uid).collection('trending').doc(channelID).update({ lastUsed: Date.now() }).catch((error) => console.log(error))
    }
    return null
})

export const updateUserToken = functions.https.onCall(async (data: any, context) => {
    const uid: string = data['uid']
    const token: string = data['token']
    if (typeof uid === 'string' && typeof token === 'string' && context.auth !== undefined && context.auth.uid === uid) {
        return admin.firestore().collection('privateInfo').doc(uid).update({ token: token }).catch((error) => console.log(error))
    }
    return null
})

export const pushNotificationToSeen = functions.https.onCall(async (data: any, context) => {
    const notificationID = data['notificationID']
    const uid = data['uid']
    if (typeof uid === 'string' && typeof notificationID === 'string' && context.auth !== undefined && context.auth.uid === uid) {
        return admin.firestore().collection('users').doc(uid).collection('notifications').doc(notificationID).update({ seen: true }).catch((error) => console.log(error))
    }
    return null
})

export const pushPostToSeen = functions.https.onCall(async (data: any, context) => {
    const uid = data['uid']
    const postID = data['postID']
    if (typeof uid === 'string' && typeof postID === 'string' && context.auth !== undefined && context.auth.uid === uid) {
        return admin.firestore().collection('users').doc(uid).collection('home').doc(postID).update({ seen: true }).catch((error) => console.log(error))
    }
    return null
})

export const blockUser = functions.https.onCall(async (data: any, context) => {
    const uid = data['uid']
    const userID = data['userID']
    if (typeof uid === 'string' && typeof userID === 'string' && context.auth !== undefined && context.auth.uid === uid && context.auth.uid !== userID) {
        const userSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('users').doc(userID).get().catch((error) => console.log(error))
        if (userSnap !== undefined && userSnap.exists) {
            return admin.firestore().collection('users').doc(uid).collection('hasBlocked').doc(userID).create({ beenBlockingSince: Date.now() }).catch((error) => console.log(error))
        }
    }
    return null
})

export const onUserBlocked = functions.firestore.document(`users/{user}/hasBlocked/{profile}`).onCreate(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const promises: any = []
    promises.push(admin.firestore().collection('users').doc(context.params.profile).collection('followers').doc(context.params.user).delete().catch((error) => console.log(error)))
    promises.push(admin.firestore().collection('users').doc(context.params.profile).collection('hasBeenBlockedBy').doc(context.params.user).create({}).catch((error) => console.log(error)))
    promises.push(admin.firestore().collection('users').doc(context.params.user).collection('followers').doc(context.params.profile).delete().catch((error) => console.log(error)))
    return Promise.all(promises)
})

export const onUserUnblocked = functions.firestore.document(`users/{user}/hasBlocked/{profile}`).onDelete(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    return admin.firestore().collection('users').doc(context.params.profile).collection('hasBeenBlockedBy').doc(context.params.user).delete().catch((error) => console.log(error))
})

export const unblockUser = functions.https.onCall(async (data: any, context) => {
    const uid = data['uid']
    const userID = data['userID']
    if (typeof uid === 'string' && typeof userID === 'string' && context.auth !== undefined && context.auth.uid === uid && context.auth.uid !== userID) {
        return admin.firestore().collection('users').doc(uid).collection('hasBlocked').doc(userID).delete().catch((error) => console.log(error))
    }
    return null
})

export const deletePost = functions.https.onCall(async (data: any, context) => {
    const postID = data['postID']
    if (typeof postID === 'string') {
        const postSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('posts').doc(postID).get().catch((error) => console.log(error))
        if (postSnap !== undefined && postSnap.exists) {
            if (context.auth !== undefined && context.auth.uid === postSnap.get('authorUID')) {
                return postSnap.ref.delete().catch((error) => console.log(error))
            }
        }
    }
    return null
})

export const updateProfile = functions.https.onCall(async (data: any, context) => {
    const username = data['username']
    const coverPhoto = data['coverPhoto']
    const profilePhoto = data['profilePhoto']
    const uid = data['uid']
    const coverPath = data['coverPath']
    const profilePath = data['profilePath']
    const deleteCover = data['deleteCover']
    const deleteProfile = data['deleteProfile']
    const regex = /^[a-zA-Z0-9_]*$/
    const updateData: any = {}
    if (typeof username !== 'string' || !regex.test(username) || username.length > 32 || username.length < 3 || typeof profilePath !== 'string' || typeof coverPath !== 'string' || typeof deleteCover !== 'boolean' || typeof deleteProfile !== 'boolean') {
        return null
    }
    if (typeof uid === 'string' && (coverPhoto === null || typeof coverPhoto === 'string') && (profilePhoto === null || typeof profilePhoto === 'string') && context.auth !== undefined && context.auth.uid === uid) {
        const usernameQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').where('displayName', '==', username.trim().toLowerCase()).get().catch((error) => console.log(error))
        if (usernameQuery === undefined || (usernameQuery.docs.length !== 0 && (usernameQuery.docs.length !== 1 || usernameQuery.docs[0].id !== uid))) {
            return null
        }
        updateData.username = username.trim()
        updateData.displayName = username.trim().toLowerCase()
        if (updateData.displayName === 'feedstack') {
            return null
        }
        if (deleteCover) {
            updateData.coverPhoto = null
        }
        else {
            if (coverPhoto !== null && typeof coverPhoto === 'string') {
                const bucket = admin.storage().bucket()
                const storageFile = bucket.file(coverPath)
                const exists: void | [boolean] = await storageFile.exists().catch((error) => console.log(error))
                if (exists === undefined || exists[0] === false) {
                    return null
                }
                updateData.coverPhoto = coverPhoto
            }
        }
        if (deleteProfile) {
            updateData.profilePhoto = null
        }
        else {
            if (profilePhoto !== null && typeof profilePhoto === 'string') {
                const bucket = admin.storage().bucket()
                const storageFile = bucket.file(profilePath)
                const exists: void | [boolean] = await storageFile.exists().catch((error) => console.log(error))
                if (exists === undefined || exists[0] === false) {
                    return null
                }
                updateData.profilePhoto = profilePhoto
            }
        }
        if (Object.keys(updateData).length > 0) {
            return admin.firestore().collection('users').doc(uid).update(updateData).catch((error) => console.log(error))
        }
    }
    return null
})

export const makeReaction = functions.https.onCall(async (data: any, context) => {
    const uid = data['uid']
    const reactionSelected = data['reactionSelected']
    const postID = data['postID']
    if (typeof postID === "string" && typeof reactionSelected === "number" && typeof uid === "string" && reactionSelected >= 0 && reactionSelected <= 2 && context.auth !== undefined && context.auth.uid === uid) {
        const userSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('users').doc(uid).get().catch((error) => console.log(error))
        const postSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('posts').doc(postID).get().catch((error) => console.log(error))
        if (postSnap === undefined) {
            return null
        }
        if (postSnap.exists) {
            const hasBeenBlockedBySnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('users').doc(uid).collection('hasBeenBlockedBy').doc(postSnap.get('authorUID')).get().catch((error) => console.log(error))
            if (hasBeenBlockedBySnap === undefined || hasBeenBlockedBySnap.exists) {
                return null
            }
        }
        if (userSnap !== undefined && userSnap.exists) {
            return admin.firestore()
                .collection('posts')
                .doc(postID)
                .collection('reactions')
                .doc(uid)
                .set({
                    'username': userSnap.get('username'),
                    'profilePhoto': userSnap.get('profilePhoto'),
                    'coverPhoto': userSnap.get('coverPhoto'),
                    'reactionTime': Date.now(),
                    'reactionSelected': reactionSelected,
                }, { merge: true })
                .catch((error) => console.log(error))
        }
    }
    return null
})

export const followUser = functions.https.onCall(async (data: any, context) => {
    const userUID = data['userUID']
    const uid = data['uid']
    if (typeof uid === "string" && typeof userUID === "string" && context.auth !== undefined && context.auth.uid === uid) {
        if (uid === userUID) {
            return null
        }
        const hasBeenBlockedBySnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('users').doc(uid).collection('hasBeenBlockedBy').doc(userUID).get().catch((error) => console.log(error))
        if (hasBeenBlockedBySnap === undefined || hasBeenBlockedBySnap.exists) {
            return null
        }
        const hasBlockedSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('users').doc(uid).collection('hasBlocked').doc(userUID).get().catch((error) => console.log(error))
        if (hasBlockedSnap === undefined || hasBlockedSnap.exists) {
            return null
        }
        const followingQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(uid).collection('following').get().catch((error) => console.log(error))
        if (followingQuery !== undefined) {
            if (followingQuery.docs.length < 10000) {
                const userSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('users').doc(uid).get().catch((error) => console.log(error))
                if (userSnap !== undefined && userSnap.exists) {
                    return admin.firestore().collection('users').doc(userUID).collection('followers').doc(uid).set({
                        'username': userSnap.get('username'),
                        'profilePhoto': userSnap.get('profilePhoto'),
                        'coverPhoto': userSnap.get('coverPhoto'),
                        'startedFollowing': Date.now()
                    }, { merge: true }).catch((error) => console.log(error))
                }
            }
        }
    }
    return null
})

export const reportPost = functions.https.onCall(async (data: any, context) => {
    const uid = data['uid']
    const postID = data['postID']
    if (typeof uid === 'string' && typeof postID === 'string' && context.auth !== undefined && context.auth.uid === uid) {
        const postSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('posts').doc(postID).get().catch((error) => console.log(error))
        if (postSnap !== undefined && postSnap.exists) {
            return admin.firestore().collection('reports').doc(postSnap.id).collection('reporters').doc(uid).create({ reported: Date.now() }).catch((error) => console.log(error))
        }
    }
    return null
})

export const onReportDeleted = functions.firestore.document(`reports/{report}`).onDelete(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const promises: any = []
    const reporterQuery: admin.firestore.QuerySnapshot | void = await snapshot.ref.collection('reporters').get().catch((error) => console.log(error))
    if (reporterQuery !== undefined) {
        for (const reporterSnap of reporterQuery.docs) {
            promises.push(reporterSnap.ref.delete().catch((error) => console.log(error)))
        }
    }
    return Promise.all(promises)
})

export const onReporterCreated = functions.firestore.document(`reports/{report}/reporters/{reporter}`).onCreate(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    return admin.firestore().collection('reports').doc(context.params.report).set({ numberOfReporters: admin.firestore.FieldValue.increment(1) }, { merge: true }).catch((error) => console.log(error))
})

export const makePost = functions.https.onCall(async (data: any, context) => {
    const uid = data['uid']
    const image = data['image']
    let caption = data['caption']
    const postID = data['postID']
    if (typeof caption !== 'string') {
        return 0
    }
    caption = caption.trim()
    if (typeof postID === 'string' && caption.length > 0 && caption.length <= 512 && (image === null || typeof image === 'string') && typeof uid === 'string' && context.auth !== undefined && context.auth.uid === uid) {
        if (image !== null) {
            const bucket = admin.storage().bucket()
            const storageFile = bucket.file(`users/${uid}/images/posts/${postID}`)
            const exists: void | [boolean] = await storageFile.exists().catch((error) => console.log(error))
            if (exists === undefined || exists[0] === false) {
                return 0
            }
        }
        const userSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('users').doc(uid).get().catch((error) => console.log(error))
        if (userSnap !== undefined && userSnap.exists) {
            const _Symbols = '·・ー_';

            const _Numbers = '0-9０-９';

            const _EnglishLetters = 'a-zA-Zａ-ｚＡ-Ｚ';

            const _JapaneseLetters = 'ぁ-んァ-ン一-龠';

            const _SpanishLetters = 'áàãâéêíóôõúüçÁÀÃÂÉÊÍÓÔÕÚÜÇ';

            const _ArabicLetters = '\u0621-\u064A';

            const _ThaiLetters = '\u0E00-\u0E7F';

            const _HashTagContentLetters = _Symbols +
                _Numbers +
                _EnglishLetters +
                _JapaneseLetters +
                _SpanishLetters +
                _ArabicLetters +
                _ThaiLetters;

            const hashTagRegExp = RegExp(
                `(?!\\n)(?:^|\\s)(#([${_HashTagContentLetters}]+))`,
                'gm'
            );

            const atSignRegExp = RegExp(
                `(?!\\n)(?:^|\\s)([#@]([${_HashTagContentLetters}]+))`,
                'gm'
            );
            const hashtags = caption.match(hashTagRegExp)
            const promises: any = []
            if (hashtags !== null) {
                for (const hashtag of hashtags) {
                    const hashtagStr = hashtag.trim().toLowerCase().substr(1)
                    promises.push(admin.firestore().collection('posts').doc(postID).collection('hashtags').doc(hashtagStr).create({}).catch((error) => console.log(error)))
                }
            }
            const mentions = caption.match(atSignRegExp)
            if (mentions !== null) {
                for (const mention of mentions) {
                    const mentionStr = mention.trim().toLowerCase().substr(1)
                    promises.push(admin.firestore().collection('posts').doc(postID).collection('mentions').doc(mentionStr).create({}).catch((error) => console.log(error)))
                }
            }
            const theData: any = {
                authorUID: uid,
                caption: caption,
                profilePhoto: userSnap.get('profilePhoto'),
                coverPhoto: userSnap.get('coverPhoto'),
                username: userSnap.get('username'),
                bookmark: Date.now(),
                numberOfComments: 0,
                numberOfIthReactions: {
                    '0': 0,
                    '1': 0,
                    '2': 0,
                    '3': 0,
                    '4': 0,
                    '5': 0,
                    '6': 0
                },
            }
            if (image !== null) {
                theData.image = image
            }
            promises.push(admin.firestore().collection('posts').doc(postID).create(theData).catch((error) => console.log(error)))
            await Promise.all(promises)
            return 1
        }
    }
    return 0
})

export const addUserToRecents = functions.https.onCall(async (data: any, context) => {
    const uid: string = data['uid']
    const userUID: string = data['userUID']
    if (typeof uid === 'string' && context.auth !== undefined && context.auth.uid === uid && typeof userUID === 'string') {
        const userSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('users').doc(userUID).get().catch((error) => console.log(error))
        if (userSnap !== undefined && userSnap.exists) {
            return admin.firestore().collection('users').doc(uid).collection('recentUserSearches').doc(userUID).set({
                username: userSnap.get('username'),
                profilePhoto: userSnap.get('profilePhoto'),
                coverPhoto: userSnap.get('coverPhoto'),
                lastSearched: Date.now(),
            }, { merge: true }).catch((error) => console.log(error))
        }
    }
    return null
})

export const addChannelToRecents = functions.https.onCall(async (data: any, context) => {
    const uid: string = data['uid']
    const channelID: string = data['channelID']
    if (typeof uid === 'string' && context.auth !== undefined && context.auth.uid === uid && typeof channelID === 'string') {
        const channelSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('channels').doc(channelID).get().catch((error) => console.log(error))
        if (channelSnap !== undefined) {
            return admin.firestore().collection('users').doc(uid).collection('recentChannelSearches').doc(channelID).set({
                name: channelSnap.get('name'),
                photo: channelSnap.get('photo'),
                description: channelSnap.get('description'),
                code: channelSnap.get('code'),
                bookmark: channelSnap.get('bookmark'),
                lastSearched: Date.now(),
            }, { merge: true }).catch((error) => console.log(error))
        }
    }
    return null
})

export const makeUserAndProfile = functions.https.onCall(async (data: any) => {
    let username: string = data['username']
    let email: string = data['email']
    let password: string = data['password']
    let token = data['token']
    let regex = /^[a-zA-Z0-9_]*$/
    if (typeof username !== 'string' || typeof email !== 'string' || typeof password !== 'string' || !regex.test(username)) {
        return 0
    }
    username = username.trim()
    const displayName = username.toLowerCase()
    email = email.trim()
    password = password.trim()
    if (password.length < 6) {
        return 0
    }
    if (username.length > 32 || username.length < 3) {
        return 0
    }
    regex = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
    if (regex.test(email) === false) {
        return 0
    }
    if (displayName === 'feedstack') {
        return 0
    }
    const usernameQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').where('displayName', '==', displayName).get().catch((error) => console.log(error))
    if (usernameQuery === undefined) {
        return 0
    }
    if (usernameQuery.docs.length !== 0) {
        return -2
    }
    const errorMsg: string = 'auth/email-already-exists'
    const createRequest: admin.auth.CreateRequest = { email: email, password: password }
    let isDuplicate: boolean = false
    const userRecord: admin.auth.UserRecord | void = await admin.auth().createUser(createRequest).catch((error) => {
        if (error.code === errorMsg) {
            isDuplicate = true
        }
    })
    if (isDuplicate) {
        return -1
    }
    if (userRecord === undefined) {
        return 0
    }
    const channels: string[] = ['Most liked', 'Home']
    const photos: string[] = ['https://firebasestorage.googleapis.com/v0/b/jasper-2ffc6.appspot.com/o/default%2Fimages%2Fegg.jpg?alt=media&token=434d9a49-ee2f-4e2d-bd05-90a547ae93c9', 'https://firebasestorage.googleapis.com/v0/b/jasper-2ffc6.appspot.com/o/default%2Fimages%2Fsponge.webp?alt=media&token=dfc69d95-7ed9-4897-b728-22a3adc2687d']
    const descriptions: string[] = ['This feed will show you posts that people like the most.', 'This feed will show you the most recent posts that you or people you follow have made.']
    const bookmarks: number[] = [1603081778195, 1603081778194]
    const codes: string[] = ['https://firebasestorage.googleapis.com/v0/b/jasper-2ffc6.appspot.com/o/default%2Fdocuments%2Fmost_liked.js?alt=media&token=3eaa0cd7-494b-4301-9e9f-79c0270ceb30', 'https://firebasestorage.googleapis.com/v0/b/jasper-2ffc6.appspot.com/o/default%2Fdocuments%2Fmy_home.js?alt=media&token=23a6156a-2fdf-42f3-bfc1-a3287fb99378']
    const currentTime: number = Date.now()
    const lastUsed: number[] = [currentTime, currentTime - 1]
    const promises: any = []
    for (let i = 0; i < channels.length; i++) {
        const isUsing: boolean = i === 0
        promises.push(admin.firestore().collection('users').doc(userRecord.uid).collection('channels').doc(channels[i]).create({ lastUsed: lastUsed[i], name: channels[i], isUsing: isUsing, photo: photos[i], description: descriptions[i], bookmark: bookmarks[i], code: codes[i] }).catch((error) => console.log(error)))
    }
    await Promise.all(promises)
    const names: string[] = []
    for (let i = 0; i < displayName.length; i++) {
        let name: string = ''
        for (let j = 0; j < i + 1; j++) {
            name = name + displayName[j]
        }
        names.push(name)
    }
    const nameLength: number = displayName.length
    const userWriteResult: admin.firestore.WriteResult | void = await admin.firestore().collection('users').doc(userRecord.uid).create({
        username: username,
        nameLength: nameLength,
        names: names,
        profilePhoto: null,
        numberOfIthPosts: { 0: 0, 1: 0 },
        numberOfIthReactions: { 0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 },
        coverPhoto: 'https://firebasestorage.googleapis.com/v0/b/jasper-2ffc6.appspot.com/o/default%2Fimages%2F%20coverPhoto?alt=media&token=49644e28-89bc-4460-aa5b-3454478153f7',
        displayName: displayName
    }).catch((error) => console.log(error))
    if (userWriteResult === undefined) {
        await admin.auth().deleteUser(userRecord.uid).catch((error) => console.log(error))
        return 0
    }
    if (token !== null && token !== 'string') {
        token = null
    }
    const privateInfoWriteResult: admin.firestore.WriteResult | void = await admin.firestore().collection('privateInfo').doc(userRecord.uid).create({
        token: token,
        email: email,
        numberOfUnreadNotifications: 0,
        numberOfUpvotes: 0,
        followingCount: 0,
        followerCount: 0,
        numberOfComments: 0,
        numberOfChannels: 2,
        whenWasThisAccountCreated: Date.now()
    }).catch((error) => console.log(error))
    if (privateInfoWriteResult === undefined) {
        await admin.firestore().collection('users').doc(userRecord.uid).delete().catch((error) => console.log(error))
        await admin.auth().deleteUser(userRecord.uid).catch((error) => console.log(error))
        return 0
    }
    return 1
})

export const onProfileCreated = functions.firestore.document(`users/{user}`).onCreate(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const promises: any = []
    const postQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('posts').get().catch((error) => console.log(error))
    if (postQuery !== undefined) {
        for (const postSnap of postQuery.docs) {
            const postData: any = postSnap.data()
            postData.seen = false
            promises.push(admin.firestore().collection('users').doc(context.params.user).collection('home').doc(postSnap.id).create(postData).catch((error) => console.log(error)))
        }
    }
    const names: string[] = ['Most liked', 'Home', 'In dogs we trust']
    const photos: string[] = ['https://firebasestorage.googleapis.com/v0/b/jasper-2ffc6.appspot.com/o/default%2Fimages%2Fegg.jpg?alt=media&token=434d9a49-ee2f-4e2d-bd05-90a547ae93c9', 'https://firebasestorage.googleapis.com/v0/b/jasper-2ffc6.appspot.com/o/default%2Fimages%2Fsponge.webp?alt=media&token=dfc69d95-7ed9-4897-b728-22a3adc2687d', 'https://firebasestorage.googleapis.com/v0/b/jasper-2ffc6.appspot.com/o/default%2Fimages%2Fking_dog.jpg?alt=media&token=e2d3eab6-66f8-4399-ab6b-70e736d734dc']
    const descriptions: string[] = ['This feed will show you posts that people like the most.', 'This feed will show you the most recent posts that you or people you follow have made.', 'This feed will show you posts about dogs.']
    const bookmarks: number[] = [1603081778195, 1603081778194, 1604210260692]
    const codes: string[] = ['https://firebasestorage.googleapis.com/v0/b/jasper-2ffc6.appspot.com/o/default%2Fdocuments%2Fmost_liked.js?alt=media&token=3eaa0cd7-494b-4301-9e9f-79c0270ceb30', 'https://firebasestorage.googleapis.com/v0/b/jasper-2ffc6.appspot.com/o/default%2Fdocuments%2Fmy_home.js?alt=media&token=23a6156a-2fdf-42f3-bfc1-a3287fb99378', 'https://firebasestorage.googleapis.com/v0/b/jasper-2ffc6.appspot.com/o/default%2Fdocuments%2Fin_dogs_we_trust.js?alt=media&token=967b7358-2697-4915-83be-aaba36177826']
    const lastSearched: number = Date.now()
    for (let i = 0; i < names.length; i++) {
        promises.push(snapshot.ref.collection('recentChannelSearches').doc(names[i]).create({
            name: names[i],
            photo: photos[i],
            description: descriptions[i],
            bookmark: bookmarks[i],
            code: codes[i],
            lastSearched: lastSearched + 1
        }).catch((error) => console.log(error)))
    }
    promises.push(snapshot.ref.collection('recentUserSearches').doc(context.params.user).create({ profilePhoto: snapshot.get('profilePhoto'), coverPhoto: snapshot.get('coverPhoto'), lastSearched: Date.now(), username: snapshot.get('username') }).catch((error) => console.log(error)))
    return Promise.all(promises)
})

export const onProfileChanged = functions.firestore.document(`users/{user}`).onUpdate(async (change: functions.Change<functions.firestore.DocumentSnapshot>, context: functions.EventContext) => {
    const before = change.before
    const after = change.after
    const promises: any = []
    const profilePhotoHasChanged = before.data()!.profilePhoto !== after.data()!.profilePhoto
    const coverPhotoHasChanged = before.data()!.coverPhoto !== after.data()!.coverPhoto
    const usernameHasChanged = before.data()!.username !== after.data()!.username
    const updateData: any = {}
    for (let i = 0; i < 2; i++) {
        if (before.data()!.numberOfIthPosts[i.toString()] !== after.data()!.numberOfIthPosts[i.toString()]) {
            if (after.data()!.numberOfIthPosts[i.toString()] < 0) {
                updateData.numberOfIthPosts[i.toString()] = 0
            }
        }
    }
    for (let i = 0; i < 6; i++) {
        if (before.data()!.numberOfIthReactions[i.toString()] !== after.data()!.numberOfIthReactions[i.toString()]) {
            if (after.data()!.numberOfIthReactions[i.toString()] < 0) {
                updateData.numberOfIthReactions[i.toString()] = 0
            }
        }
    }
    if (profilePhotoHasChanged || usernameHasChanged || coverPhotoHasChanged) {
        const searchedByQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('searchedBy').get().catch((error) => console.log(error))
        if (searchedByQuery !== undefined) {
            for (const userSnap of searchedByQuery.docs) {
                promises.push(admin.firestore().collection('users').doc(userSnap.id).collection('recentUserSearches').doc(context.params.user).update({ profilePhoto: after.data()!.profilePhoto, username: after.data()!.username, coverPhoto: after.data()!.coverPhoto }).catch((error) => console.log(error)))
            }
        }
        const postQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('posts').get().catch((error) => console.log(error))
        if (postQuery !== undefined) {
            for (const postSnap of postQuery.docs) {
                promises.push(admin.firestore().collection('posts').doc(postSnap.id).update({ profilePhoto: after.data()!.profilePhoto, username: after.data()!.username, coverPhoto: after.data()!.coverPhoto }).catch((error) => console.log(error)))
            }
        }
        const commentsQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('comments').get().catch((error) => console.log(error))
        if (commentsQuery !== undefined) {
            for (const commentSnap of commentsQuery.docs) {
                const postID: string = commentSnap.get('postID')
                const postCommentID: string = commentSnap.get('postCommentID')
                promises.push(admin.firestore().collection('posts').doc(postID).collection('comments').doc(postCommentID).update({ profilePhoto: after.data()!.profilePhoto, username: after.data()!.username, coverPhoto: after.data()!.coverPhoto }).catch((error) => console.log(error)))
            }
        }
        const followerQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('followers').get().catch((error) => console.log(error))
        if (followerQuery !== undefined) {
            for (const followerSnap of followerQuery.docs) {
                promises.push(admin.firestore().collection('users').doc(followerSnap.id).collection('following').doc(context.params.user).update({ profilePhoto: after.data()!.profilePhoto, username: after.data()!.username, coverPhoto: after.data()!.coverPhoto }).catch((error) => console.log(error)))
            }
        }
        const followingQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('following').get().catch((error) => console.log(error))
        if (followingQuery !== undefined) {
            for (const followingSnap of followingQuery.docs) {
                promises.push(admin.firestore().collection('users').doc(followingSnap.id).collection('followers').doc(context.params.user).update({ profilePhoto: after.data()!.profilePhoto, username: after.data()!.username, coverPhoto: after.data()!.coverPhoto }).catch((error) => console.log(error)))
            }
        }
        const reactionPostQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('reactions').get().catch((error) => console.log(error))
        if (reactionPostQuery !== undefined) {
            for (const postSnap of reactionPostQuery.docs) {
                promises.push(admin.firestore().collection('posts').doc(postSnap.id).collection('reactions').doc(context.params.user).update({ username: after.data()!.username, profilePhoto: after.data()!.profilePhoto, coverPhoto: after.data()!.coverPhoto }).catch((error) => console.log(error)))
            }
        }
        if (usernameHasChanged) {
            const username: string = after.data()!.username
            const displayName = username.toLowerCase()
            const names: string[] = []
            for (let i = 0; i < displayName.length; i++) {
                let name: string = ''
                for (let j = 0; j < i + 1; j++) {
                    name = name + displayName[j]
                }
                names.push(name)
            }
            const nameLength: number = displayName.length
            updateData.names = names
            updateData.nameLength = nameLength
        }
    }
    if (Object.keys(updateData).length > 0) {
        promises.push(admin.firestore().collection('users').doc(context.params.user).update(updateData).catch((error) => console.log(error)))
    }
    return Promise.all(promises)
})

export const onPrivateInfoChanged = functions.firestore.document(`privateInfo/{user}`).onUpdate(async (change: functions.Change<functions.firestore.DocumentSnapshot>, context: functions.EventContext) => {
    const before = change.before
    const after = change.after
    const updateData: any = {}
    if (before.get('numberOfUnreadNotifications') !== after.get('numberOfUnreadNotifications')) {
        if (after.get('numberOfUnreadNotifications') < 0) {
            updateData.numberOfUnreadNotifications = 0
        }
    }
    if (before.get('numberOfChannels') !== after.get('numberOfChannels')) {
        if (after.get('numberOfChannels') < 0) {
            updateData.numberOfChannels = 0
        }
    }

    const commentCountHasChanged = before.data()!.numberOfComments !== after.data()!.numberOfComments
    if (commentCountHasChanged) {
        if (after.data()!.numberOfComments < 0) {
            updateData.numberOfComments = 0
        }
    }
    const upvoteCountHasChanged = before.data()!.numberOfUpvotes !== after.data()!.numberOfUpvotes
    if (upvoteCountHasChanged) {
        if (after.data()!.numberOfUpvotes < 0) {
            updateData.numberOfUpvotes = 0
        }
    }
    const followingCountHasChanged = before.data()!.followingCount !== after.data()!.followingCount
    const followerCountHasChanged = before.data()!.followerCount !== after.data()!.followerCount
    if (followerCountHasChanged) {
        if (after.data()!.followerCount < 0) {
            updateData.followerCount = 0
        }
    }
    if (followingCountHasChanged) {
        if (after.data()!.followingCount < 0) {
            updateData.followingCount = 0
        }
    }
    if (Object.keys(updateData).length > 0) {
        return admin.firestore().collection('privateInfo').doc(context.params.user).update(updateData).catch((error) => console.log(error))
    }
    return null
})

export const onFeedPostCreated = functions.firestore.document(`users/{user}/feed/{post}`).onCreate(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const updateData: any = {}
    if (snapshot.get('authorUID') === context.params.user) {
        if (snapshot.get('seen') !== true) {
            updateData.seen = true
        }
    }
    const postSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('home').doc(context.params.post).get().catch((error) => console.log(error))
    if (postSnap !== undefined && postSnap.exists) {
        if (postSnap.get('seen') !== snapshot.get('seen') && snapshot.get('authorUID') !== context.params.user) {
            updateData.seen = postSnap.get('seen')
        }
        if (postSnap.get('reactionSelected') !== snapshot.get('reactionSelected')) {
            updateData.reactionSelected = postSnap.get('reactionSelected')
            if (updateData.reactionSelected === undefined) {
                updateData.reactionSelected = admin.firestore.FieldValue.delete()
            }
        }
        if (snapshot.get('numberOfComments') !== postSnap.get('numberOfComments')) {
            updateData.numberOfComments = postSnap.get('numberOfComments')
        }
    }
    if (Object.keys(updateData).length > 0) {
        return snapshot.ref.update(updateData).catch((error) => console.log(error))
    }
    return null
})

export const onHomePostCreated = functions.firestore.document(`users/{user}/home/{post}`).onCreate(async (postSnap: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const promises: any = []
    const updateData: any = {}
    if (context.params.user === postSnap.get('authorUID')) {
        updateData.seen = true
    }
    if (Object.keys(updateData).length > 0) {
        promises.push(postSnap.ref.update(updateData).catch((error) => console.log(error)))
    }
    const channelQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('downloads').get().catch((error) => console.log(error))
    if (channelQuery !== undefined) {
        const authorUID: string = postSnap.get('authorUID')
        const isFollowingReaderSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('users').doc(authorUID).collection('following').doc(context.params.user).get().catch((error) => console.log(error))
        let authorIsFollowingReader: boolean = false
        if (isFollowingReaderSnap !== undefined && isFollowingReaderSnap.exists) {
            authorIsFollowingReader = true
        }
        const isFollowingAuthorSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('following').doc(authorUID).get().catch((error) => console.log(error))
        let readerIsFollowingAuthor: boolean = false
        if (isFollowingAuthorSnap !== undefined && isFollowingAuthorSnap.exists) {
            readerIsFollowingAuthor = true
        }
        let numberOfTimesReaderHasViewed: number = 0
        let numberOfTimesReaderHasReactedTo: number = 0
        let numberOfTimesReaderHasCommentedOn: number = 0
        const connectionSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('connections').doc(authorUID).get().catch((error) => console.log(error))
        if (connectionSnap !== undefined && connectionSnap.exists) {
            if (connectionSnap.get('numberOfTimesReaderHasViewed') !== undefined) {
                numberOfTimesReaderHasViewed = connectionSnap.get('numberOfTimesReaderHasViewed')
            }
            if (connectionSnap.get('numberOfTimesReaderHasReactedTo') !== undefined) {
                numberOfTimesReaderHasReactedTo = connectionSnap.get('numberOfTimesReaderHasReactedTo')
            }
            if (connectionSnap.get('numberOfTimesReaderHasCommentedOn') !== undefined) {
                numberOfTimesReaderHasCommentedOn = connectionSnap.get('numberOfTimesReaderHasCommentedOn')
            }
        }
        const seen = context.params.user === authorUID
        const theData: any = {
            authorIsFollowingReader: authorIsFollowingReader,
            numberOfComments: postSnap.get('numberOfComments'),
            readerIsFollowingAuthor: readerIsFollowingAuthor, numberOfTimesReaderHasReactedTo: numberOfTimesReaderHasReactedTo, numberOfTimesReaderHasCommentedOn: numberOfTimesReaderHasCommentedOn,
            numberOfTimesReaderHasViewed: numberOfTimesReaderHasViewed, seen: seen, authorUID: authorUID, numberOfIthReactions: postSnap.get('numberOfIthReactions'),
            bookmark: postSnap.get('bookmark'), username: postSnap.get('username'), coverPhoto: postSnap.get('coverPhoto'), profilePhoto: postSnap.get('profilePhoto'),
            caption: postSnap.get('caption')
        }
        const reactionSelected = postSnap.get('reactionSelected')
        if (reactionSelected !== undefined) {
            theData.reactionSelected = reactionSelected
        }
        const image = postSnap.get('image')
        if (image !== undefined) {
            theData.image = image
        }
        for (const channelSnap of channelQuery.docs) {
            if (channelSnap.id === 'Home' || channelSnap.id === 'Most liked') {
                continue
            }
            promises.push(admin.firestore().collection('channels').doc(channelSnap.id).collection('downloadedBy').doc(context.params.user).collection('posts').doc(postSnap.id).create(theData).catch((error) => console.log(error)))
        }
    }
    return Promise.all(promises)
})

export const onHomePostDeleted = functions.firestore.document(`users/{user}/home/{post}`).onDelete(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const promises: any = []
    const channelQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('channels').get().catch((error) => console.log(error))
    if (channelQuery !== undefined) {
        for (const channelSnap of channelQuery.docs) {
            promises.push(admin.firestore().collection('channels').doc(channelSnap.id).collection('downloadedBy').doc(context.params.user).collection('posts').doc(context.params.post).delete().catch((error) => console.log(error)))
        }
    }
    return Promise.all(promises)
})

export const onHomePostChanged = functions.firestore.document(`users/{user}/home/{post}`).onUpdate(async (change: functions.Change<functions.firestore.QueryDocumentSnapshot>, context: functions.EventContext) => {
    const before = change.before
    const after = change.after
    const updateData: any = {}
    const connectionData: any = {}
    const promises: any = []
    if (before.data().seen !== after.data().seen && after.data().seen === true) {
        updateData.seen = true
        connectionData.numberOfTimesReaderHasViewed = admin.firestore.FieldValue.increment(1)
        promises.push(admin.firestore().collection('posts').doc(context.params.post).update({ [`numberOfIthReactions.6`]: admin.firestore.FieldValue.increment(1) }).catch((error) => console.log(error)))
    }
    if (before.data().numberOfComments !== after.data().numberOfComments) {
        updateData.numberOfComments = after.data().numberOfComments
    }
    if (before.data().reactionSelected !== after.data().reactionSelected) {
        updateData.reactionSelected = after.data().reactionSelected
        if (updateData.reactionSelected === undefined) {
            updateData.reactionSelected = admin.firestore.FieldValue.delete()
        }
        else {
            connectionData.numberOfTimesReaderHasReactedTo = admin.firestore.FieldValue.increment(1)
        }
    }
    if (Object.keys(updateData).length > 0) {
        promises.push(admin.firestore().collection('users').doc(context.params.user).collection('feed').doc(context.params.post).update(updateData).catch((error) => console.log(error)))
    }
    if (Object.keys(connectionData.length > 0)) {
        promises.push(admin.firestore().collection('users').doc(context.params.user).collection('connections').doc(change.after.get('authorUID')).set(connectionData, { merge: true }).catch((error) => console.log(error)))
    }
    let numberOfIthReactionsHasChanged: boolean = false
    const numberOfIthReactions = change.after.get('numberOfIthReactions')
    for (let i = 0; i < 7; i++) {
        if (before.data().numberOfIthReactions[i.toString()] !== numberOfIthReactions[i.toString()]) {
            numberOfIthReactionsHasChanged = true
        }
    }
    if (Object.keys(updateData).length > 0 || change.before.get('profilePhoto') !== change.after.get('profilePhoto') || change.before.get('coverPhoto') !== change.after.get('coverPhoto') || change.before.get('username') !== change.after.get('username') || numberOfIthReactionsHasChanged) {
        const channelQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('downloads').get().catch((error) => console.log(error))
        updateData.profilePhoto = change.after.get('profilePhoto')
        updateData.coverPhoto = change.after.get('coverPhoto')
        updateData.username = change.after.get('username')
        updateData.numberOfIthReactions = numberOfIthReactions
        if (channelQuery !== undefined) {
            for (const channelSnap of channelQuery.docs) {
                if (channelSnap.id === 'Home' || channelSnap.id === 'Most liked') {
                    continue
                }
                promises.push(admin.firestore().collection('channels').doc(channelSnap.id).collection('downloadedBy').doc(context.params.user).collection('posts').doc(context.params.post).update(updateData).catch((error) => console.log(error)))
            }
        }
    }
    return Promise.all(promises)
})

export const onPostCreated = functions.firestore.document(`posts/{post}`).onCreate(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const promises: any = []
    const authorUID: string = snapshot.get('authorUID')
    const homeData: any = {
        authorUID: snapshot.get('authorUID'),
        caption: snapshot.get('caption'),
        profilePhoto: snapshot.get('profilePhoto'),
        coverPhoto: snapshot.get('coverPhoto'),
        username: snapshot.get('username'),
        bookmark: snapshot.get('bookmark'),
        numberOfComments: 0,
        numberOfIthReactions: snapshot.get('numberOfIthReactions'),
        seen: false,
    }
    const feedData: any = {
        authorUID: snapshot.get('authorUID'),
        caption: snapshot.get('caption'),
        profilePhoto: snapshot.get('profilePhoto'),
        coverPhoto: snapshot.get('coverPhoto'),
        username: snapshot.get('username'),
        bookmark: snapshot.get('bookmark'),
        numberOfComments: 0,
        seen: false
    }
    const postData: any = {
        authorUID: snapshot.get('authorUID'),
        caption: snapshot.get('caption'),
        profilePhoto: snapshot.get('profilePhoto'),
        coverPhoto: snapshot.get('coverPhoto'),
        username: snapshot.get('username'),
        bookmark: snapshot.get('bookmark'),
    }
    if (snapshot.get('image') !== undefined) {
        homeData.image = snapshot.get('image')
        feedData.image = snapshot.get('image')
        postData.image = snapshot.get('image')
    }
    const postOfficeSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('postOffice').doc(context.params.post).get().catch((error) => console.log(error))
    if (postOfficeSnap !== undefined && postOfficeSnap.exists) {
        const data: any = postOfficeSnap.data()
        promises.push(snapshot.ref.update(data).catch((error) => console.log(error)))
        promises.push(postOfficeSnap.ref.delete().catch((error) => console.log(error)))
    }
    const userQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').get().catch((error) => console.log(error))
    if (userQuery !== undefined) {
        for (const userSnap of userQuery.docs) {
            promises.push(admin.firestore().collection('users').doc(userSnap.id).collection('home').doc(context.params.post).set(homeData, { merge: true }).catch((error) => console.log(error)))
        }
    }
    const followerQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(authorUID).collection('followers').get().catch((error) => console.log(error))
    if (followerQuery !== undefined) {
        for (const followerSnap of followerQuery.docs) {
            promises.push(admin.firestore().collection('users').doc(followerSnap.id).collection('feed').doc(context.params.post).create(feedData).catch((error) => console.log(error)))
        }
    }
    promises.push(admin.firestore().collection('users').doc(authorUID).collection('feed').doc(context.params.post).create(feedData).catch((error) => console.log(error)))
    promises.push(admin.firestore().collection('users').doc(authorUID).collection('posts').doc(context.params.post).create(postData).catch((error) => console.log(error)))
    return Promise.all(promises)
})

export const onPostDeleted = functions.firestore.document(`posts/{post}`).onDelete(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const promises: any = []
    promises.push(admin.firestore().collection('reports').doc(context.params.post).delete().catch((error) => console.log(error)))
    const userQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').get().catch((error) => console.log(error))
    if (userQuery !== undefined) {
        for (const userSnap of userQuery.docs) {
            promises.push(admin.firestore().collection('users').doc(userSnap.id).collection('home').doc(context.params.post).delete().catch((error) => console.log(error)))
        }
    }
    promises.push(admin.firestore().collection('users').doc(snapshot.get('authorUID')).collection('feed').doc(context.params.post).delete().catch((error) => console.log(error)))
    promises.push(admin.firestore().collection('users').doc(snapshot.get('authorUID')).collection('posts').doc(context.params.post).delete().catch((error) => console.log(error)))
    const reactionQuery: admin.firestore.QuerySnapshot | void = await snapshot.ref.collection('reactions').get().catch((error) => console.log(error))
    if (reactionQuery !== undefined) {
        for (const reactionSnap of reactionQuery.docs) {
            promises.push(reactionSnap.ref.delete().catch((error) => console.log(error)))
        }
    }
    const commentsQuery: admin.firestore.QuerySnapshot | void = await snapshot.ref.collection('comments').get().catch((error) => console.log(error))
    if (commentsQuery !== undefined) {
        for (const commentSnap of commentsQuery.docs) {
            promises.push(commentSnap.ref.delete().catch((error) => console.log(error)))
        }
    }
    return Promise.all(promises)
})

export const onPostChanged = functions.firestore.document(`posts/{post}`).onUpdate(async (change: functions.Change<functions.firestore.QueryDocumentSnapshot>, context: functions.EventContext) => {
    const before = change.before
    const after = change.after
    const promises: any = []
    const numberOfIthReactions = after.data().numberOfIthReactions
    let numberOfIthReactionsHasChanged: boolean = false
    const updateData: any = {}
    for (let i = 0; i < 7; i++) {
        if (before.data().numberOfIthReactions[i.toString()] !== numberOfIthReactions[i.toString()]) {
            numberOfIthReactionsHasChanged = true
            if (numberOfIthReactions[i.toString()] < 0) {
                numberOfIthReactions[i.toString()] = 0
                updateData.numberOfIthReactions[i.toString()] = 0
            }
        }
    }
    const profilePhotoHasChanged = before.data().profilePhoto !== after.data().profilePhoto
    const coverPhotoHasChanged = before.data().coverPhoto !== after.data().coverPhoto
    const usernameHasChanged = before.data().username !== after.data().username
    const commentCountHasChanged = before.data().numberOfComments !== after.data().numberOfComments
    if (profilePhotoHasChanged || usernameHasChanged || coverPhotoHasChanged || commentCountHasChanged || numberOfIthReactionsHasChanged) {
        const userQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').get().catch((error) => console.log(error))
        if (userQuery !== undefined) {
            for (const userSnap of userQuery.docs) {
                promises.push(userSnap.ref.collection('home').doc(context.params.post).update({ username: after.data().username, profilePhoto: after.data().profilePhoto, coverPhoto: after.data().coverPhoto, numberOfComments: after.data().numberOfComments, numberOfIthReactions: numberOfIthReactions }).catch((error) => console.log(error)))
            }
        }
        if (profilePhotoHasChanged || usernameHasChanged || coverPhotoHasChanged || commentCountHasChanged) {
            const reactionUserQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('posts').doc(context.params.post).collection('reactions').get().catch((error) => console.log(error))
            if (reactionUserQuery !== undefined) {
                for (const userSnap of reactionUserQuery.docs) {
                    promises.push(admin.firestore().collection('users').doc(userSnap.id).collection('reactions').doc(context.params.post).update({ username: after.data().username, profilePhoto: after.data().profilePhoto, coverPhoto: after.data().coverPhoto, numberOfComments: after.get('numberOfComments') }).catch((error) => console.log(error)))
                }
            }
        }
    }
    if (Object.keys(updateData).length > 0) {
        promises.push(admin.firestore().collection('posts').doc(context.params.post).update(updateData).catch((error) => console.log(error)))
    }
    if (profilePhotoHasChanged || usernameHasChanged || coverPhotoHasChanged) {
        promises.push(admin.firestore().collection('users').doc(after.data().authorUID).collection('posts').doc(context.params.post).update({ username: after.data().username, profilePhoto: after.data().profilePhoto, coverPhoto: after.data().coverPhoto }).catch((error) => console.log(error)))
    }
    return Promise.all(promises)
})

export const onUserPostCreated = functions.firestore.document(`users/{user}/posts/{post}`).onCreate(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const promises: any = []
    const reactionSnapshot: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('posts').doc(context.params.post).collection('reactions').doc(context.params.user).get().catch((error) => console.log(error))
    if (reactionSnapshot !== undefined && reactionSnapshot.exists) {
        const reactionData: any = snapshot.data()
        reactionData.reactionSelected = reactionSnapshot.get('reactionSelected')
        reactionData.reactionTime = reactionSnapshot.get('reactionTime')
        promises.push(admin.firestore().collection('users').doc(context.params.user).collection('reactions').doc(context.params.post).create(reactionData).catch((error) => console.log(error)))
    }
    if (snapshot.get('image') === undefined) {
        promises.push(admin.firestore().collection('users').doc(context.params.user).update({ [`numberOfIthPosts.${0}`]: admin.firestore.FieldValue.increment(1) }).catch((error) => console.log(error)))
    }
    else {
        promises.push(admin.firestore().collection('users').doc(context.params.user).update({ [`numberOfIthPosts.${1}`]: admin.firestore.FieldValue.increment(1) }).catch((error) => console.log(error)))
    }
    return Promise.all(promises)
})

export const onUserPostDeleted = functions.firestore.document(`users/{user}/posts/{post}`).onDelete(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const promises: any = []
    const followerQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('followers').get().catch((error) => console.log(error))
    if (followerQuery !== undefined) {
        for (const followerSnap of followerQuery.docs) {
            promises.push(admin.firestore().collection('users').doc(followerSnap.id).collection('feed').doc(context.params.post).delete().catch((error) => console.log(error)))
        }
    }
    const notificationQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('notifications').where('postID', '==', context.params.post).get().catch((error) => console.log(error))
    if (notificationQuery !== undefined) {
        for (const notificationSnap of notificationQuery.docs) {
            promises.push(notificationSnap.ref.delete().catch((error) => console.log(error)))
        }
    }
    if (snapshot.get('image') === undefined) {
        promises.push(admin.firestore().collection('users').doc(context.params.user).update({ [`numberOfIthPosts.${0}`]: admin.firestore.FieldValue.increment(-1) }).catch((error) => console.log(error)))
    }
    else {
        promises.push(admin.storage().bucket().file(`users/${context.params.user}/images/posts/${context.params.post}`).delete().catch((error) => console.log(error)))
        promises.push(admin.firestore().collection('users').doc(context.params.user).update({ [`numberOfIthPosts.${1}`]: admin.firestore.FieldValue.increment(-1) }).catch((error) => console.log(error)))
    }
    return Promise.all(promises)
})



export const onUserPostChanged = functions.firestore.document(`users/{user}/posts/{post}`).onUpdate(async (change: functions.Change<functions.firestore.QueryDocumentSnapshot>, context: functions.EventContext) => {
    const before = change.before
    const after = change.after
    const promises: any = []
    if (before.data().username !== after.data().username || before.data().profilePhoto !== after.data().profilePhoto || before.data().coverPhoto !== after.data().coverPhoto) {
        const followerQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('followers').get().catch((error) => console.log(error))
        if (followerQuery !== undefined) {
            for (const followerSnap of followerQuery.docs) {
                promises.push(admin.firestore().collection('users').doc(followerSnap.id).collection('feed').doc(context.params.post).update({ username: after.data().username, profilePhoto: after.data().profilePhoto, coverPhoto: after.data().coverPhoto }).catch((error) => console.log(error)))
            }
        }
        promises.push(admin.firestore().collection('users').doc(context.params.user).collection('feed').doc(context.params.post).update({ username: after.data().username, profilePhoto: after.data().profilePhoto, coverPhoto: after.data().coverPhoto }).catch((error) => console.log(error)))
    }
    return Promise.all(promises)
})

export const onUserReactionCreated = functions.firestore.document(`users/{user}/reactions/{post}`).onCreate(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const promises: any = []
    promises.push(admin.firestore().collection('users').doc(context.params.user).collection('home').doc(context.params.post).set({ 'reactionSelected': snapshot.get('reactionSelected') }, { merge: true }).catch((error) => console.log(error)))
    promises.push(admin.firestore().collection('users').doc(context.params.user).update({ [`numberOfIthReactions.${snapshot.get('reactionSelected')}`]: admin.firestore.FieldValue.increment(1) }).catch((error) => console.log(error)))
    return Promise.all(promises)
})

export const onUserReactionDeleted = functions.firestore.document(`users/{user}/reactions/{post}`).onDelete(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const promises: any = []
    promises.push(admin.firestore().collection('users').doc(context.params.user).collection('home').doc(context.params.post).update({ 'reactionSelected': admin.firestore.FieldValue.delete() }).catch((error) => console.log(error)))
    promises.push(admin.firestore().collection('users').doc(context.params.user).update({ [`numberOfIthReactions.${snapshot.get('reactionSelected')}`]: admin.firestore.FieldValue.increment(-1) }).catch((error) => console.log(error)))
    return Promise.all(promises)
})

export const onUserReactionChanged = functions.firestore.document(`users/{user}/reactions/{post}`).onUpdate(async (change: functions.Change<functions.firestore.QueryDocumentSnapshot>, context: functions.EventContext) => {
    const before = change.before
    const after = change.after
    const promises: any = []
    if (before.data().reactionSelected !== after.data().reactionSelected) {
        promises.push(admin.firestore().collection('users').doc(context.params.user).collection('home').doc(context.params.post).set({ 'reactionSelected': after.data().reactionSelected }, { merge: true }).catch((error) => console.log(error)))
        promises.push(admin.firestore().collection('users').doc(context.params.user).update({ [`numberOfIthReactions.${before.data().reactionSelected}`]: admin.firestore.FieldValue.increment(-1), [`numberOfIthReactions.${after.data().reactionSelected}`]: admin.firestore.FieldValue.increment(1) }).catch((error) => console.log(error)))
    }
    return Promise.all(promises)
})

export const onPostReactionCreated = functions.firestore.document(`posts/{post}/reactions/{user}`).onCreate(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const postSnapshot: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('posts').doc(context.params.post).get().catch((error) => console.log(error))
    if (postSnapshot === undefined || !postSnapshot.exists) {
        return null
    }
    const promises: any = []
    const postData: any = postSnapshot.data()
    delete postData.numberOfIthReactions
    postData.reactionTime = snapshot.get('reactionTime')
    postData.reactionSelected = snapshot.get('reactionSelected')
    promises.push(admin.firestore().collection('users').doc(context.params.user).collection('reactions').doc(context.params.post).create(postData).catch((error) => console.log(error)))
    promises.push(admin.firestore().collection('posts').doc(context.params.post).update({ [`numberOfIthReactions.${snapshot.get('reactionSelected')}`]: admin.firestore.FieldValue.increment(1) }).catch((error) => console.log(error)))
    if (postSnapshot.get('authorUID') !== context.params.user) {
        promises.push(admin.firestore().collection('users').doc(postSnapshot.get('authorUID')).collection('notifications').doc(context.params.user + ' ' + context.params.post).create({ reactionSelected: snapshot.get('reactionSelected'), username: snapshot.get('username'), coverPhoto: snapshot.get('coverPhoto'), profilePhoto: snapshot.get('profilePhoto'), bookmark: snapshot.get('reactionTime'), seen: false, postID: context.params.post }).catch((error) => console.log(error)))
    }
    return Promise.all(promises)
})

export const onPostReactionDeleted = functions.firestore.document(`posts/{post}/reactions/{user}`).onDelete(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const promises: any = []
    promises.push(admin.firestore().collection('users').doc(context.params.user).collection('reactions').doc(context.params.post).delete().catch((error) => console.log(error)))
    promises.push(admin.firestore().collection('posts').doc(context.params.post).update({ [`numberOfIthReactions.${snapshot.get('reactionSelected')}`]: admin.firestore.FieldValue.increment(-1) }).catch((error) => console.log(error)))
    const postSnapshot: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('posts').doc(context.params.post).get().catch((error) => console.log(error))
    if (postSnapshot !== undefined && postSnapshot.exists && (postSnapshot.get('authorUID') !== context.params.user)) {
        promises.push(admin.firestore().collection('users').doc(postSnapshot.get('authorUID')).collection('notifications').doc(context.params.user + ' ' + context.params.post).delete().catch((error) => console.log(error)))
    }
    return Promise.all(promises)
})

export const onPostReactionChanged = functions.firestore.document(`posts/{post}/reactions/{user}`).onUpdate(async (change: functions.Change<functions.firestore.QueryDocumentSnapshot>, context: functions.EventContext) => {
    const before = change.before
    const after = change.after
    const promises: any = []
    if (before.data().reactionSelected !== after.data().reactionSelected || before.data().reactionTime !== after.data().reactionTime) {
        promises.push(admin.firestore().collection('users').doc(context.params.user).collection('reactions').doc(context.params.post).update({ reactionSelected: after.data().reactionSelected, reactionTime: after.data().reactionTime }).catch((error) => console.log(error)))
        if (before.data().reactionSelected !== after.data().reactionSelected) {
            promises.push(admin.firestore().collection('posts').doc(context.params.post).update({ [`numberOfIthReactions.${before.data().reactionSelected}`]: admin.firestore.FieldValue.increment(-1), [`numberOfIthReactions.${after.data().reactionSelected}`]: admin.firestore.FieldValue.increment(1) }).catch((error) => console.log(error)))
        }
    }
    if (before.data().reactionSelected !== after.data().reactionSelected || before.data().reactionTime !== after.data().reactionTime || before.data().username !== after.data().username || before.data().profilePhoto !== after.data().profilePhoto || before.data().coverPhoto !== after.data().coverPhoto) {
        const postSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('posts').doc(context.params.post).get().catch((error) => console.log(error))
        if (postSnap !== undefined && postSnap.exists && (postSnap.get('authorUID') !== context.params.user)) {
            const newData: any = { reactionSelected: after.get('reactionSelected'), username: after.get('username'), coverPhoto: after.get('coverPhoto'), profilePhoto: after.get('profilePhoto'), bookmark: after.get('reactionTime') }
            if (before.data().reactionTime !== after.data().reactionTime || before.data().reactionSelected !== after.data().reactionSelected) {
                newData.seen = false
            }
            promises.push(admin.firestore().collection('users').doc(postSnap.get('authorUID')).collection('notifications').doc(context.params.user + ' ' + context.params.post).update(newData).catch((error) => console.log(error)))
        }
    }
    return Promise.all(promises)
})

export const onRecentUserSearchCreated = functions.firestore.document(`users/{user}/recentUserSearches/{profile}`).onCreate(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const promises: any = []
    const recentSearchQuery: admin.firestore.QuerySnapshot | void = await snapshot.ref.parent.orderBy('lastSearched', 'desc').get().catch((error) => console.log(error))
    if (recentSearchQuery !== undefined) {
        for (let i = 0; i < recentSearchQuery.docs.length; i++) {
            if (i >= 32) {
                promises.push(recentSearchQuery.docs[i].ref.delete().catch((error) => console.log(error)))
            }
        }
    }
    promises.push(admin.firestore().collection('users').doc(context.params.profile).collection('searchedBy').doc(context.params.user).create({}).catch((error) => console.log(error)))
    return Promise.all(promises)
})

export const onRecentChannelSearchCreated = functions.firestore.document(`users/{user}/recentChannelSearches/{channel}`).onCreate(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const promises: any = []
    const recentSearchQuery: admin.firestore.QuerySnapshot | void = await snapshot.ref.parent.orderBy('lastSearched', 'desc').get().catch((error) => console.log(error))
    if (recentSearchQuery !== undefined) {
        for (let i = 0; i < recentSearchQuery.docs.length; i++) {
            if (i >= 32) {
                promises.push(recentSearchQuery.docs[i].ref.delete().catch((error) => console.log(error)))
            }
        }
    }
    promises.push(admin.firestore().collection('channels').doc(context.params.channel).collection('searchedBy').doc(context.params.user).create({}).catch((error) => console.log(error)))
    return Promise.all(promises)
})

export const onRecentUserSearchDeleted = functions.firestore.document(`users/{user}/recentUserSearches/{profile}`).onDelete(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    return admin.firestore().collection('users').doc(context.params.profile).collection('searchedBy').doc(context.params.user).delete().catch((error) => console.log(error))
})

export const onRecentChannelSearchDeleted = functions.firestore.document(`users/{user}/recentChannelSearches/{channel}`).onDelete(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    return admin.firestore().collection('channels').doc(context.params.channel).collection('searchedBy').doc(context.params.user).delete().catch((error) => console.log(error))
})

export const onFollowerCreated = functions.firestore.document(`users/{user}/followers/{follower}`).onCreate(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const userSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('users').doc(context.params.user).get().catch((error) => console.log(error))
    const promises: any = []
    if (userSnap !== undefined && userSnap.exists) {
        const startedFollowing: number = snapshot.get('startedFollowing')
        promises.push(admin.firestore().collection('users').doc(context.params.follower).collection('following').doc(context.params.user).create({
            username: userSnap.get('username'),
            profilePhoto: userSnap.get('profilePhoto'),
            coverPhoto: userSnap.get('coverPhoto'),
            startedFollowing: startedFollowing
        }).catch((error) => console.log(error)))
    }
    promises.push(admin.firestore().collection('privateInfo').doc(context.params.user).update({ followerCount: admin.firestore.FieldValue.increment(1) }).catch((error) => console.log(error)))
    promises.push(admin.firestore().collection('users').doc(context.params.user).collection('notifications').doc(context.params.follower).create({ profilePhoto: snapshot.get('profilePhoto'), coverPhoto: snapshot.get('coverPhoto'), username: snapshot.get('username'), seen: false, bookmark: snapshot.get('startedFollowing') }).catch((error) => console.log(error)))
    const profilePostQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.follower).collection('posts').get().catch((error) => console.log(error))
    const channelQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('downloads').get().catch((error) => console.log(error))
    if (profilePostQuery !== undefined && channelQuery !== undefined) {
        for (const channelSnap of channelQuery.docs) {
            if (channelSnap.id === 'Home' || channelSnap.id === 'Most liked') {
                continue
            }
            for (const postSnap of profilePostQuery.docs) {
                promises.push(admin.firestore().collection('channels').doc(channelSnap.id).collection('downloadedBy').doc(context.params.user).collection('posts').doc(postSnap.id).update({ authorIsFollowingReader: true }).catch((error) => console.log(error)))
            }
        }
    }
    return Promise.all(promises)
})

export const onFollowerDeleted = functions.firestore.document(`users/{user}/followers/{follower}`).onDelete(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const promises: any = []
    promises.push(admin.firestore().collection('privateInfo').doc(context.params.user).update({ followerCount: admin.firestore.FieldValue.increment(-1) }).catch((error) => console.log(error)))
    promises.push(admin.firestore().collection('users').doc(context.params.follower).collection('following').doc(context.params.user).delete().catch((error) => console.log(error)))
    promises.push(admin.firestore().collection('users').doc(context.params.user).collection('notifications').doc(context.params.follower).delete().catch((error) => console.log(error)))
    const profilePostQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.follower).collection('posts').get().catch((error) => console.log(error))
    const channelQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('downloads').get().catch((error) => console.log(error))
    if (profilePostQuery !== undefined && channelQuery !== undefined) {
        for (const channelSnap of channelQuery.docs) {
            if (channelSnap.id === 'Home' || channelSnap.id === 'Most liked') {
                continue
            }
            for (const postSnap of profilePostQuery.docs) {
                promises.push(admin.firestore().collection('channels').doc(channelSnap.id).collection('downloadedBy').doc(context.params.user).collection('posts').doc(postSnap.id).update({ authorIsFollowingReader: false }).catch((error) => console.log(error)))
            }
        }
    }
    return Promise.all(promises)
})

export const onFollowerChanged = functions.firestore.document(`users/{user}/followers/{follower}`).onUpdate(async (change: functions.Change<functions.firestore.QueryDocumentSnapshot>, context: functions.EventContext) => {
    const before = change.before
    const after = change.after
    if (before.data().startedFollowing !== after.data().startedFollowing) {
        const promises: any = []
        promises.push(admin.firestore().collection('users').doc(context.params.follower).collection('following').doc(context.params.user).update({ startedFollowing: after.data().startedFollowing }).catch((error) => console.log(error)))
        promises.push(admin.firestore().collection('users').doc(context.params.user).collection('notifications').doc(context.params.follower).update({ profilePhoto: after.get('profilePhoto'), coverPhoto: after.get('coverPhoto'), username: after.get('username'), seen: false, bookmark: after.get('startedFollowing') }).catch((error) => console.log(error)))
        return Promise.all(promises)
    }
    else if (before.data().profilePhoto !== after.data().profilePhoto || before.data().coverPhoto !== after.data().coverPhoto || before.data().username !== after.data().username) {
        return admin.firestore().collection('users').doc(context.params.user).collection('notifications').doc(context.params.follower).update({ profilePhoto: after.get('profilePhoto'), coverPhoto: after.get('coverPhoto'), username: after.get('username') }).catch((error) => console.log(error))
    }
    return null
})

export const onFollowingCreated = functions.firestore.document(`users/{user}/following/{profile}`).onCreate(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const postQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.profile).collection('posts').get().catch((error) => console.log(error))
    const promises: any = []
    if (postQuery !== undefined) {
        for (const postSnap of postQuery.docs) {
            const postData: any = postSnap.data()
            const homeSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('home').doc(postSnap.id).get().catch((error) => console.log(error))
            postData.seen = false
            postData.numberOfComments = 0
            if (homeSnap !== undefined && homeSnap.exists) {
                const seen = homeSnap.get('seen')
                if (seen !== undefined) {
                    postData.seen = seen
                }
                const reactionSelected = homeSnap.get('reactionSelected')
                if (reactionSelected !== undefined) {
                    postData.reactionSelected = reactionSelected
                }
                const numberOfComments = homeSnap.get('numberOfComments')
                if (numberOfComments !== undefined) {
                    postData.numberOfComments = numberOfComments
                }
            }
            promises.push(admin.firestore().collection('users').doc(context.params.user).collection('feed').doc(postSnap.id).create(postData).catch((error) => console.log(error)))
        }
    }
    const reverseSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('users').doc(context.params.profile).collection('following').doc(context.params.user).get().catch((error) => console.log(error))
    if (reverseSnap !== undefined && reverseSnap.exists) {
        promises.push(admin.firestore().collection('users').doc(context.params.user).collection('friends').doc(context.params.profile).create({}).catch((error) => console.log(error)))
        promises.push(admin.firestore().collection('users').doc(context.params.profile).collection('friends').doc(context.params.user).create({}).catch((error) => console.log(error)))
    }
    promises.push(admin.firestore().collection('privateInfo').doc(context.params.user).update({ followingCount: admin.firestore.FieldValue.increment(1) }).catch((error) => console.log(error)))
    const profilePostQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.profile).collection('posts').get().catch((error) => console.log(error))
    const channelQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('downloads').get().catch((error) => console.log(error))
    if (profilePostQuery !== undefined && channelQuery !== undefined) {
        for (const channelSnap of channelQuery.docs) {
            if (channelSnap.id === 'Home' || channelSnap.id === 'Most liked') {
                continue
            }
            for (const postSnap of profilePostQuery.docs) {
                promises.push(admin.firestore().collection('channels').doc(channelSnap.id).collection('downloadedBy').doc(context.params.user).collection('posts').doc(postSnap.id).update({ readerIsFollowingAuthor: true }).catch((error) => console.log(error)))
            }
        }
    }
    return Promise.all(promises)
})

export const onFollowingDeleted = functions.firestore.document(`users/{user}/following/{profile}`).onDelete(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const postQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.profile).collection('posts').get().catch((error) => console.log(error))
    const promises: any = []
    if (postQuery !== undefined) {
        for (const postSnap of postQuery.docs) {
            promises.push(admin.firestore().collection('users').doc(context.params.user).collection('feed').doc(postSnap.id).delete().catch((error) => console.log(error)))
        }
    }
    const reverseSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('users').doc(context.params.profile).collection('following').doc(context.params.user).get().catch((error) => console.log(error))
    if (reverseSnap !== undefined && reverseSnap.exists) {
        promises.push(admin.firestore().collection('users').doc(context.params.user).collection('friends').doc(context.params.profile).delete().catch((error) => console.log(error)))
        promises.push(admin.firestore().collection('users').doc(context.params.profile).collection('friends').doc(context.params.user).delete().catch((error) => console.log(error)))
    }
    promises.push(admin.firestore().collection('privateInfo').doc(context.params.user).update({ followingCount: admin.firestore.FieldValue.increment(-1) }).catch((error) => console.log(error)))
    const profilePostQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.profile).collection('posts').get().catch((error) => console.log(error))
    const channelQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('downloads').get().catch((error) => console.log(error))
    if (profilePostQuery !== undefined && channelQuery !== undefined) {
        for (const channelSnap of channelQuery.docs) {
            if (channelSnap.id === 'Home' || channelSnap.id === 'Most liked') {
                continue
            }
            for (const postSnap of profilePostQuery.docs) {
                promises.push(admin.firestore().collection('channels').doc(channelSnap.id).collection('downloadedBy').doc(context.params.user).collection('posts').doc(postSnap.id).update({ readerIsFollowingAuthor: false }).catch((error) => console.log(error)))
            }
        }
    }
    return Promise.all(promises)
})

export const onNotificationCreated = functions.firestore.document(`users/{user}/notifications/{notification}`).onCreate(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    return admin.firestore().collection('privateInfo').doc(context.params.user).update({ numberOfUnreadNotifications: admin.firestore.FieldValue.increment(1) }).catch((error) => console.log(error))
})

export const onNotificationDeleted = functions.firestore.document(`users/{user}/notifications/{notification}`).onDelete(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    if (snapshot.get('seen') === true) {
        return null
    }
    return admin.firestore().collection('privateInfo').doc(context.params.user).update({ numberOfUnreadNotifications: admin.firestore.FieldValue.increment(-1) }).catch((error) => console.log(error))
})

export const onNotificationChanged = functions.firestore.document(`users/{user}/notifications/{notification}`).onUpdate(async (change: functions.Change<functions.firestore.QueryDocumentSnapshot>, context: functions.EventContext) => {
    const before = change.before
    const after = change.after
    if (before.get('seen') !== after.get('seen') && after.get('seen') === true) {
        return admin.firestore().collection('privateInfo').doc(context.params.user).update({ numberOfUnreadNotifications: admin.firestore.FieldValue.increment(-1) }).catch((error) => console.log(error))
    }
    return null
})

export const onPostCommentCreated = functions.firestore.document(`posts/{post}/comments/{comment}`).onCreate(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const promises: any = []
    promises.push(admin.firestore().collection('privateInfo').doc(snapshot.get('authorUID')).update({ numberOfComments: admin.firestore.FieldValue.increment(1) }).catch((error) => console.log(error)))
    promises.push(admin.firestore().collection('posts').doc(context.params.post).update({ numberOfComments: admin.firestore.FieldValue.increment(1) }).catch((error) => console.log(error)))
    const postSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('posts').doc(context.params.post).get().catch((error) => console.log(error))
    if (postSnap !== undefined && postSnap.exists) {
        promises.push(admin.firestore().collection('users').doc(snapshot.get('authorUID')).collection('connections').doc(postSnap.get('authorUID')).set({ numberOfTimesReaderHasCommentedOn: admin.firestore.FieldValue.increment(1) }, { merge: true }).catch((error) => console.log(error)))
    }
    return Promise.all(promises)
})

export const onPostCommentDeleted = functions.firestore.document(`posts/{post}/comments/{comment}`).onDelete(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const promises: any = []
    promises.push(admin.firestore().collection('privateInfo').doc(snapshot.get('authorUID')).update({ numberOfComments: admin.firestore.FieldValue.increment(-1) }).catch((error) => console.log(error)))
    promises.push(admin.firestore().collection('posts').doc(context.params.post).update({ numberOfComments: admin.firestore.FieldValue.increment(-1) }).catch((error) => console.log(error)))
    const upvoteQuery: admin.firestore.QuerySnapshot | void = await snapshot.ref.collection('upvotes').get().catch((error) => console.log(error))
    if (upvoteQuery !== undefined) {
        for (const upvoteSnap of upvoteQuery.docs) {
            promises.push(upvoteSnap.ref.delete().catch((error) => console.log(error)))
        }
    }
    return Promise.all(promises)
})

export const onPostCommentChanged = functions.firestore.document(`posts/{post}/comments/{comment}`).onUpdate(async (change: functions.Change<functions.firestore.DocumentSnapshot>, context: functions.EventContext) => {
    const before = change.before
    const after = change.after
    if (before.data()!.ranking !== after.data()!.ranking) {
        return admin.firestore().collection('users').doc(after.data()!.authorUID).collection('comments').doc(after.data()!.userCommentID).update({ ranking: after.data()!.ranking }).catch((error) => console.log(error))
    }
    return null
})

export const onUpvoteCreated = functions.firestore.document(`posts/{post}/comments/{comment}/upvotes/{upvote}`).onCreate(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const promises: any = []
    promises.push(admin.firestore().collection('posts').doc(context.params.post).collection('comments').doc(context.params.comment).update({ ranking: admin.firestore.FieldValue.increment(1) }).catch((error) => console.log(error)))
    promises.push(admin.firestore().collection('privateInfo').doc(context.params.upvote).update({ numberOfUpvotes: admin.firestore.FieldValue.increment(1) }).catch((error) => console.log(error)))
    return Promise.all(promises)
})

export const onUpvoteDeleted = functions.firestore.document(`posts/{post}/comments/{comment}/upvotes/{upvote}`).onDelete(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const promises: any = []
    promises.push(admin.firestore().collection('posts').doc(context.params.post).collection('comments').doc(context.params.comment).update({ ranking: admin.firestore.FieldValue.increment(-1) }).catch((error) => console.log(error)))
    promises.push(admin.firestore().collection('privateInfo').doc(context.params.upvote).update({ numberOfUpvotes: admin.firestore.FieldValue.increment(-1) }).catch((error) => console.log(error)))
    return Promise.all(promises)
})

export const onUserConnectionCreated = functions.firestore.document(`users/{user}/connections/{otherUser}`).onCreate(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const promises: any = []
    const updateData: any = {}
    if (snapshot.get('numberOfTimesReaderHasReactedTo') !== undefined) {
        updateData.numberOfTimesReaderHasReactedTo = snapshot.get('numberOfTimesReaderHasReactedTo')
    }
    if (snapshot.get('numberOfTimesReaderHasCommentedOn') !== undefined) {
        updateData.numberOfTimesReaderHasCommentedOn = snapshot.get('numberOfTimesReaderHasCommentedOn')
    }

    if (snapshot.get('numberOfTimesReaderHasViewed') !== undefined) {
        updateData.numberOfTimesReaderHasViewed = snapshot.get('numberOfTimesReaderHasViewed')
    }
    if (Object.keys(updateData).length > 0) {
        const channelQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('downloads').get().catch((error) => console.log(error))
        const userPostQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.otherUser).collection('posts').get().catch((error) => console.log(error))
        if (channelQuery !== undefined && userPostQuery !== undefined) {
            for (const channelSnap of channelQuery.docs) {
                if (channelSnap.id === 'Home' || channelSnap.id === 'Most liked') {
                    continue
                }
                for (const userPost of userPostQuery.docs) {
                    promises.push(admin.firestore().collection('channels').doc(channelSnap.id).collection('downloadedBy').doc(context.params.user).collection('posts').doc(userPost.id).update(updateData).catch((error) => console.log(error)))
                }
            }
        }
    }
    return Promise.all(promises)
})

export const onUserConnectionChanged = functions.firestore.document(`users/{user}/connections/{otherUser}`).onUpdate(async (change, context: functions.EventContext) => {
    const promises: any = []
    if (change.after.get('numberOfTimesReaderHasReactedTo') !== change.before.get('numberOfTimesReaderHasReactedTo') || change.before.get('numberOfTimesReaderHasCommentedOn') !== change.after.get('numberOfTimesReaderHasCommentedOn') || change.before.get('numberOfTimesReaderHasViewed') !== change.after.get('numberOfTimesReaderHasViewed')) {
        const updateData: any = {}
        if (change.after.get('numberOfTimesReaderHasReactedTo') !== undefined) {
            updateData.numberOfTimesReaderHasReactedTo = change.after.get('numberOfTimesReaderHasReactedTo')
        }
        if (change.after.get('numberOfTimesReaderHasCommentedOn') !== undefined) {
            updateData.numberOfTimesReaderHasCommentedOn = change.after.get('numberOfTimesReaderHasCommentedOn')
        }
        if (change.after.get('numberOfTimesReaderHasViewed') !== undefined) {
            updateData.numberOfTimesReaderHasViewed = change.after.get('numberOfTimesReaderHasViewed')
        }
        const channelQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('downloads').get().catch((error) => console.log(error))
        const userPostQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.otherUser).collection('posts').get().catch((error) => console.log(error))
        if (channelQuery !== undefined && userPostQuery !== undefined) {
            for (const channelSnap of channelQuery.docs) {
                if (channelSnap.id === 'Home' || channelSnap.id === 'Most liked') {
                    continue
                }
                for (const userPost of userPostQuery.docs) {
                    promises.push(admin.firestore().collection('channels').doc(channelSnap.id).collection('downloadedBy').doc(context.params.user).collection('posts').doc(userPost.id).update(updateData).catch((error) => console.log(error)))
                }
            }
        }
    }
    return Promise.all(promises)
})

export const onImageCreated = functions.storage.object().onFinalize(async (object) => {
    const names: string[] | undefined = object.name?.split('/')
    if (names === undefined || !names.includes('images')) {
        return null
    }
    const vision = require('@google-cloud/vision')
    const visionClient = new vision.ImageAnnotatorClient()
    const safeData = await visionClient.safeSearchDetection(
        `gs://${object.bucket}/${object.name}`
    )
    const safeSearch = safeData[0].safeSearchAnnotation
    if (
        safeSearch !== undefined &&
        (safeSearch.adult === 'VERY_LIKELY' ||
            safeSearch.spoof === 'VERY_LIKELY' ||
            safeSearch.medical === 'VERY_LIKELY' ||
            safeSearch.violence === 'VERY_LIKELY' ||
            safeSearch.racy === 'VERY_LIKELY')
    ) {
        const path = require('path')
        const os = require('os')
        const mkdirp = require('mkdirp')
        const spawn = require('child-process-promise').spawn
        const fs = require('fs')
        const filePath: string | undefined = object.name
        const bucketName: string | undefined = object.bucket
        if (filePath === undefined || bucketName === undefined) {
            return null
        }
        const tempLocalFile = path.join(os.tmpdir(), filePath)
        const tempLocalDir = path.dirname(tempLocalFile)
        const bucket = admin.storage().bucket(bucketName)
        await mkdirp(tempLocalDir)
        await bucket.file(filePath).download({ destination: tempLocalFile })
        await spawn('convert', [tempLocalFile, '-channel', 'RGBA', '-blur', '0x8', tempLocalFile])
        await bucket.upload(tempLocalFile, {
            destination: filePath,
            metadata: { metadata: object.metadata }, // Keeping custom metadata.
        })
        fs.unlinkSync(tempLocalFile)
    }
    if (!names.includes('posts')) {
        return null
    }
    const data: any = {}
    const labelData = await visionClient.labelDetection(
        `gs://${object.bucket}/${object.name}`
    )
    const labelExtracts = labelData[0].labelAnnotations
    if (labelExtracts !== undefined) {
        const labels = labelExtracts.map((label: any) => {
            return label.description.split(' ').join('').toLowerCase()
        })
            .slice(0, 3)
        data.labels = labels
    }
    const landmarkData = await visionClient.landmarkDetection(
        `gs://${object.bucket}/${object.name}`
    )
    const landmarkExtracts = landmarkData[0].landmarkAnnotations
    if (landmarkExtracts !== undefined) {
        const landmarks = landmarkExtracts.map((label: any) => {
            return label.description.split(' ').join('').toLowerCase()
        })
            .slice(0, 3)
        data.landmarks = landmarks
    }
    const postID: string = names[names.length - 1]
    if (Object.keys(data).length > 0) {
        const postSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('posts').doc(postID).get().catch((error) => console.log(error))
        if (postSnap !== undefined && postSnap.exists) {
            return postSnap.ref.update(data).catch((error) => console.log(error))
        }
        else {
            return admin.firestore().collection('postOffice').doc(postID).create(data).catch((error) => console.log(error))
        }
    }
    return null
})

export const makeChannel = functions.https.onCall(async (data: any, _) => {
    let name = data['name']
    const code = data['code']
    const photo = data['photo']
    let description = data['description']
    const documentID = data['documentID']
    let email = data['email']
    if (typeof name === 'string' && name.length <= 64 && name.length >= 3 && typeof documentID === 'string' && typeof description === 'string' && description.length >= 15 && description.length <= 192 && typeof email === 'string' && typeof code === 'string' && typeof photo === 'string') {
        name = name.trim()
        description = description.trim()
        email = email.trim()
        let regex = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
        if (regex.test(email) === false) {
            return 0
        }
        regex = /^[a-zA-Z0-9 _.]*$/
        if (regex.test(name) === false) {
            return 0
        }
        const displayName: string = name.split(' ').join('').toLowerCase()
        if (displayName === 'mostliked' || displayName === 'home' || displayName === 'trending' || displayName === 'myfeeds' || displayName === 'indogswetrust') {
            return 0
        }
        const feedQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('channels').where('displayName', '==', displayName).get().catch((error) => console.log(error))
        if (feedQuery === undefined) {
            return 0
        }
        if (feedQuery.docs.length !== 0) {
            return -1
        }
        const bucket = admin.storage().bucket()
        let filePath: string = `channels/${documentID}/photo`
        let storageFile = bucket.file(filePath)
        let exists: void | [boolean] = await storageFile.exists().catch((error) => console.log(error))
        if (exists === undefined || exists[0] === false) {
            return 0
        }
        filePath = `channels/${documentID}/code`
        storageFile = bucket.file(filePath)
        exists = await storageFile.exists().catch((error) => console.log(error))
        if (exists === undefined || exists[0] === false) {
            return 0
        }
        class Author {
            constructor(_authorID: string, _isFollowing: Set<string>, _readerID: string) {
                this.authorID = _authorID
                this.isFollowingReader = _isFollowing.has(_readerID)
            }
            authorID: string
            isFollowingReader: boolean
        }
        class Post {
            constructor(_postID: string, _caption: string, _numberOfViews: number, _userComments: Set<string>, _userReactions: Set<string>, _numberOfPeopleThisHasMade: Map<string, number>, _whenWasThisCreated: number) {
                this.postID = _postID
                this.caption = _caption
                this.numberOfViews = _numberOfViews
                this.userComments = _userComments
                this.userReactions = _userReactions
                this.numberOfPeopleThisHasMade = _numberOfPeopleThisHasMade
                this.whenWasThisCreated = _whenWasThisCreated
            }
            postID: string
            caption: string
            numberOfViews: number
            userComments: Set<string>
            userReactions: Set<string>
            numberOfPeopleThisHasMade: Map<string, number>
            whenWasThisCreated: number
        }
        class Reader {
            constructor(_readerID: string, _isFollowing: Set<string>, _numberOfTimesReaderHasReactedTo: number, _numberOfTimesReaderHasCommentedOn: number, _numberOfTimesReaderHasViewed: number, _hasViewedPost: boolean, _authorID: string, _post: Post) {
                this.readerID = _readerID
                this.isFollowingAuthor = _isFollowing.has(_authorID)
                this.numberOfTimesReaderHasReactedTo = _numberOfTimesReaderHasReactedTo
                this.numberOfTimesReaderHasCommentedOn = _numberOfTimesReaderHasCommentedOn
                this.numberOfTimesReaderHasViewed = _numberOfTimesReaderHasViewed
                this.hasViewedPost = _hasViewedPost
                this.numberOfCommentsFromPeopleTheReaderFollows = new Set([..._post.userComments].filter(userID => _isFollowing.has(userID))).size
                this.numberOfReactionsFromPeopleTheReaderFollows = new Set([..._post.userReactions].filter(userID => _isFollowing.has(userID))).size
            }
            readerID: string
            isFollowingAuthor: boolean
            numberOfTimesReaderHasReactedTo: number
            numberOfTimesReaderHasCommentedOn: number
            numberOfTimesReaderHasViewed: number
            hasViewedPost: boolean
            numberOfCommentsFromPeopleTheReaderFollows: number
            numberOfReactionsFromPeopleTheReaderFollows: number
        }
        const author = new Author('a', new Set(['r']), 'r')
        const post = new Post('p', 'manhattan bound #3am', 100, new Set(['r']), new Set(['r']), new Map([['happy', 100], ['sad', 8], ['angry', 12]]), 4)
        const reader = new Reader('r', new Set(['a']), 25, 2, 180, false, 'a', post)
        const path = require('path')
        const os = require('os')
        const mkdirp = require('mkdirp')
        const fs = require('fs')
        const tempLocalFile = path.join(os.tmpdir(), filePath)
        const tempLocalDir = path.dirname(tempLocalFile)
        await mkdirp(tempLocalDir)
        await bucket.file(filePath).download({ destination: tempLocalFile })
        let thereIsAnError: boolean = false
        try {
            const algorithm = require(tempLocalFile)
            const { NodeVM } = require('vm2');
            const vm = new NodeVM({});
            const untrustedCode = 'module.exports = {computeRanking:' + algorithm.computeRanking.toString() + '};'
            const untrustedFunction = vm.run(
                untrustedCode
            );
            untrustedFunction.computeRanking(author, post, reader)
        } catch (e) {
            thereIsAnError = true
        }
        await fs.unlinkSync(tempLocalFile)
        if (thereIsAnError) {
            return -2
        }
        const names: string[] = []
        for (let i = 0; i < displayName.length; i++) {
            let n: string = ''
            for (let j = 0; j < i + 1; j++) {
                n = n + displayName[j]
            }
            names.push(n)
        }
        await admin.firestore().collection('channels').doc(documentID).create({
            name: name,
            names: names,
            nameLength: name.length,
            code: code,
            photo: photo,
            description: description,
            bookmark: Date.now(),
            numberOfRecentDownloads: 0,
            recentDownloadCount: 0,
            displayName: displayName
        }).catch((error) => console.log(error))
        await admin.firestore().collection('channels').doc(documentID).collection('emails').doc(email).create({}).catch((error) => console.log(error))
        return 1
    }
    return 0
})

export const onChannelReset = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
    const channelQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('channels').get().catch((error) => console.log(error))
    const updateChannelPromises: any = []
    if (channelQuery !== undefined) {
        for (const channelSnap of channelQuery.docs) {
            if (channelSnap.id === 'Most liked' || channelSnap.id === 'Home' || channelSnap.id === 'In dogs we trust') {
                continue
            }
            updateChannelPromises.push(channelSnap.ref.update({
                numberOfRecentDownloads: channelSnap.get('recentDownloadCount'),
                recentDownloadCount: 0
            }).catch((error) => console.log(error)))
        }
    }
    await Promise.all(updateChannelPromises)
    const createChannelPromises: any = []
    let trendingQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('channels').orderBy('numberOfRecentDownloads', 'desc').limit(36).get().catch((error) => console.log(error))
    let i = 0
    const lastUsed: number = Date.now()
    if (trendingQuery !== undefined) {
        for (const channelSnap of trendingQuery.docs) {
            if (i === 18) {
                break
            }
            const trendingSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('trending').doc(channelSnap.id).get().catch((error) => console.log(error))
            if (trendingSnap === undefined || trendingSnap.exists) {
                continue
            }
            const data: admin.firestore.DocumentData = channelSnap.data()
            delete data.names
            delete data.numberOfRecentDownloads
            delete data.recentDownloadCount
            delete data.nameLength
            data.lastUsed = lastUsed - i
            createChannelPromises.push(admin.firestore().collection('trending').doc(channelSnap.id).create(data).catch((error) => console.log(error)))
            i = i + 1
        }
    }
    await Promise.all(createChannelPromises)
    const deleteChannelPromises: any = []
    trendingQuery = await admin.firestore().collection('trending').where('lastUsed', '<', lastUsed).get().catch((error) => console.log(error))
    if (trendingQuery !== undefined) {
        for (const channelSnap of trendingQuery.docs) {
            deleteChannelPromises.push(channelSnap.ref.delete().catch((error) => console.log(error)))
        }
    }
    await Promise.all(deleteChannelPromises)
    return null
});

export const onTrendingCreated = functions.firestore.document(`trending/{channel}`).onCreate(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const data: admin.firestore.DocumentData | undefined = snapshot.data()
    if (data === undefined) {
        return null
    }
    const promises: any = []
    const userQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').get().catch((error) => console.log(error))
    if (userQuery !== undefined) {
        for (const userSnap of userQuery.docs) {
            promises.push(userSnap.ref.collection('trending').doc(context.params.channel).create(data).catch((error) => console.log(error)))
        }
    }
    return Promise.all(promises)
})

export const onTrendingDeleted = functions.firestore.document(`trending/{channel}`).onDelete(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const promises: any = []
    const userQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').get().catch((error) => console.log(error))
    if (userQuery !== undefined) {
        for (const userSnap of userQuery.docs) {
            promises.push(userSnap.ref.collection('trending').doc(context.params.channel).delete().catch((error) => console.log(error)))
        }
    }
    return Promise.all(promises)
})

export const onChannelDeleted = functions.firestore.document('channels/{channel}').onDelete((snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    if (context.params.channel === 'Most liked' || context.params.channel === 'Home' || context.params.channel === 'In dogs we trust') {
        const data: admin.firestore.DocumentData | undefined = snapshot.data()
        if (data !== undefined) {
            return admin.firestore().collection('channels').doc(context.params.channel).create(data).catch((error) => console.log(error))
        }
    }
    return null
})

export const uninstallChannel = functions.https.onCall(async (data: any, context) => {
    const channelID: string = data['channelID']
    const uid: string = data['uid']
    const newChannelID: string = data['newChannelID']
    if (newChannelID === channelID) {
        return null
    }
    if (channelID === 'Home' || channelID === 'Most liked') {
        return null
    }
    if (typeof channelID === 'string' && typeof uid === 'string' && context.auth !== undefined && context.auth.uid === uid && typeof newChannelID === 'string') {
        const promises: any = []
        const newChannelSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('users').doc(uid).collection('channels').doc(newChannelID).get().catch((error) => console.log(error))
        if (newChannelSnap !== undefined && newChannelSnap.exists) {
            promises.push(newChannelSnap.ref.update({ isUsing: true, lastUsed: Date.now() }).catch((error) => console.log(error)))
            promises.push(admin.firestore().collection('users').doc(uid).collection('channels').doc(channelID).delete().catch((error) => console.log(error)))
            return Promise.all(promises)
        }
    }
    return null
})

export const installChannel = functions.https.onCall(async (data: any, context) => {
    const channelID: string = data['channelID']
    const uid: string = data['uid']
    if (typeof channelID === 'string' && typeof uid === 'string' && context.auth !== undefined && context.auth.uid === uid) {
        const channelSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('channels').doc(channelID).get().catch((error) => console.log(error))
        if (channelSnap !== undefined && channelSnap.exists) {
            const channelQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(uid).collection('channels').get().catch((error) => console.log(error))
            if (channelQuery !== undefined) {
                if (channelQuery.docs.length < 250) {
                    return admin.firestore().collection('users').doc(uid).collection('channels').doc(channelID).create({
                        lastUsed: Date.now(),
                        isUsing: false,
                        name: channelSnap.get('name'),
                        photo: channelSnap.get('photo'),
                        bookmark: channelSnap.get('bookmark'),
                        description: channelSnap.get('description'),
                        code: channelSnap.get('code')
                    }).catch((error) => console.log(error))
                }
            }
        }
    }
    return null
})

export const onUserChannelDeleted = functions.firestore.document(`users/{user}/channels/{channel}`).onDelete(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const promises: any = []
    promises.push(admin.firestore().collection('privateInfo').doc(context.params.user).update({ numberOfChannels: admin.firestore.FieldValue.increment(-1) }).catch((error) => console.log(error)))
    const trendingSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('trending').doc(context.params.channel).get().catch((error) => console.log(error))
    if (trendingSnap !== undefined && !trendingSnap.exists) {
        promises.push(admin.firestore().collection('users').doc(context.params.user).collection('downloads').doc(context.params.channel).delete().catch((error) => console.log(error)))
    }
    return Promise.all(promises)
})

export const onUserChannelCreated = functions.firestore.document(`users/{user}/channels/{channel}`).onCreate(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const promises: any = []
    if (context.params.channel === 'Home' || context.params.channel === 'Most liked') {
        return null
    }
    if (context.params.channel !== 'In dogs we trust') {
        promises.push(admin.firestore().collection('channels').doc(context.params.channel).update({ recentDownloadCount: admin.firestore.FieldValue.increment(1) }).catch((error) => console.log(error)))
    }
    promises.push(admin.firestore().collection('users').doc(context.params.user).collection('downloads').doc(context.params.channel).create({}).catch((error) => console.log(error)))
    promises.push(admin.firestore().collection('privateInfo').doc(context.params.user).update({ numberOfChannels: admin.firestore.FieldValue.increment(1) }).catch((error) => console.log(error)))
    return Promise.all(promises)
})

export const onUserTrendingDeleted = functions.firestore.document(`users/{user}/trending/{channel}`).onDelete(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const promises: any = []
    const channelSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('channels').doc(context.params.channel).get().catch((error) => console.log(error))
    if (channelSnap !== undefined && !channelSnap.exists) {
        promises.push(admin.firestore().collection('users').doc(context.params.user).collection('downloads').doc(context.params.channel).delete().catch((error) => console.log(error)))
    }
    return Promise.all(promises)
})

export const onUserTrendingCreated = functions.firestore.document(`users/{user}/trending/{channel}`).onCreate(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    return admin.firestore().collection('users').doc(context.params.user).collection('downloads').doc(context.params.channel).create({}).catch((error) => console.log(error))
})

export const onUserDownloadCreated = functions.firestore.document(`users/{user}/downloads/{channel}`).onCreate(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    return admin.firestore().collection('channels').doc(context.params.channel).collection('downloadedBy').doc(context.params.user).create({}).catch((error) => console.log(error))
})

export const onUserDownloadDeleted = functions.firestore.document(`users/{user}/downloads/{channel}`).onDelete(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    return admin.firestore().collection('channels').doc(context.params.channel).collection('downloadedBy').doc(context.params.user).delete().catch((error) => console.log(error))
})

export const onDownloadDeleted = functions.firestore.document(`channels/{channel}/downloadedBy/{user}`).onDelete(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const promises: any = []
    const postQuery: admin.firestore.QuerySnapshot | void = await snapshot.ref.collection('posts').get().catch((error) => console.log(error))
    if (postQuery !== undefined) {
        for (const postSnap of postQuery.docs) {
            promises.push(postSnap.ref.delete().catch((error) => console.log(error)))
        }
    }
    return Promise.all(promises)
})

export const onDownloadCreated = functions.firestore.document(`channels/{channel}/downloadedBy/{user}`).onCreate(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const promises: any = []
    const postQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('home').get().catch((error) => console.log(error))
    if (postQuery !== undefined) {
        for (const postSnap of postQuery.docs) {
            const authorUID: string = postSnap.get('authorUID')
            const isFollowingReaderSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('users').doc(authorUID).collection('following').doc(context.params.user).get().catch((error) => console.log(error))
            let authorIsFollowingReader: boolean = false
            if (isFollowingReaderSnap !== undefined && isFollowingReaderSnap.exists) {
                authorIsFollowingReader = true
            }
            const isFollowingAuthorSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('following').doc(authorUID).get().catch((error) => console.log(error))
            let readerIsFollowingAuthor: boolean = false
            if (isFollowingAuthorSnap !== undefined && isFollowingAuthorSnap.exists) {
                readerIsFollowingAuthor = true
            }

            let numberOfTimesReaderHasReactedTo = 0
            let numberOfTimesReaderHasCommentedOn = 0
            let numberOfTimesReaderHasViewed = 0

            const connectionSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('connections').doc(postSnap.get('authorUID')).get().catch((error) => console.log(error))
            if (connectionSnap !== undefined && connectionSnap.exists) {
                if (connectionSnap.get('numberOfTimesReaderHasReactedTo') !== undefined) {
                    numberOfTimesReaderHasReactedTo = connectionSnap.get('numberOfTimesReaderHasReactedTo')
                }
                if (connectionSnap.get('numberOfTimesReaderHasCommentedOn') !== undefined) {
                    numberOfTimesReaderHasCommentedOn = connectionSnap.get('numberOfTimesReaderHasCommentedOn')
                }
                if (connectionSnap.get('numberOfTimesReaderHasViewed') !== undefined) {
                    numberOfTimesReaderHasViewed = connectionSnap.get('numberOfTimesReaderHasViewed')
                }
            }
            const seen = postSnap.get('seen') || postSnap.get('authorUID') === context.params.user
            const theData: any = {
                authorIsFollowingReader: authorIsFollowingReader,
                numberOfComments: postSnap.get('numberOfComments'),
                readerIsFollowingAuthor: readerIsFollowingAuthor, numberOfTimesReaderHasReactedTo: numberOfTimesReaderHasReactedTo, numberOfTimesReaderHasCommentedOn: numberOfTimesReaderHasCommentedOn,
                numberOfTimesReaderHasViewed: numberOfTimesReaderHasViewed, seen: seen, authorUID: postSnap.get('authorUID'), numberOfIthReactions: postSnap.get('numberOfIthReactions'),
                bookmark: postSnap.get('bookmark'), username: postSnap.get('username'), coverPhoto: postSnap.get('coverPhoto'), profilePhoto: postSnap.get('profilePhoto'),
                caption: postSnap.get('caption')
            }
            const reactionSelected = postSnap.get('reactionSelected')
            if (reactionSelected !== undefined) {
                theData.reactionSelected = reactionSelected
            }
            const image = postSnap.get('image')
            if (image !== undefined) {
                theData.image = image
            }
            promises.push(snapshot.ref.collection('posts').doc(postSnap.id).create(theData).catch((error) => console.log(error)))
        }
    }

    return Promise.all(promises)

})

export const onDownloadPostCreated = functions.firestore.document(`channels/{channel}/downloadedBy/{user}/posts/{post}`).onCreate(async (snapshot: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const channelSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('channels').doc(context.params.channel).get().catch((error) => console.log(error))
    if (channelSnap !== undefined && channelSnap.exists) {
        class Author {
            constructor(_authorID: string, _isFollowing: Set<string>, _readerID: string) {
                this.authorID = _authorID
                this.isFollowingReader = _isFollowing.has(_readerID)
            }
            authorID: string
            isFollowingReader: boolean
        }
        class Post {
            constructor(_postID: string, _caption: string, _numberOfViews: number, _userComments: Set<string>, _userReactions: Set<string>, _numberOfPeopleThisHasMade: Map<string, number>, _whenWasThisCreated: number) {
                this.postID = _postID
                this.caption = _caption
                this.numberOfViews = _numberOfViews
                this.userComments = _userComments
                this.userReactions = _userReactions
                this.numberOfPeopleThisHasMade = _numberOfPeopleThisHasMade
                this.whenWasThisCreated = _whenWasThisCreated
            }
            postID: string
            caption: string
            numberOfViews: number
            userComments: Set<string>
            userReactions: Set<string>
            numberOfPeopleThisHasMade: Map<string, number>
            whenWasThisCreated: number
        }
        class Reader {
            constructor(_readerID: string, _isFollowing: Set<string>, _myReactions: Map<string, Map<string, Map<string, Set<string>>>>, _myComments: Map<string, Map<string, Map<string, Set<string>>>>, _myViews: Map<string, Map<string, Map<string, Set<string>>>>, _authorID: string, _post: Post) {
                this.readerID = _readerID
                this.isFollowingAuthor = _isFollowing.has(_authorID)
                this.numberOfTimesReaderHasReactedTo = _myReactions.get('posts')!.get('madeBy')!.get(_authorID)!.size
                this.numberOfTimesReaderHasCommentedOn = _myComments.get('posts')!.get('madeBy')!.get(_authorID)!.size
                this.numberOfTimesReaderHasViewed = _myViews.get('posts')!.get('madeBy')!.get(_authorID)!.size
                this.hasViewedPost = _myViews.get('posts')!.get('madeBy')!.get(_authorID)!.has(_post.postID)
                this.numberOfCommentsFromPeopleTheReaderFollows = new Set([..._post.userComments].filter(userID => _isFollowing.has(userID))).size
                this.numberOfReactionsFromPeopleTheReaderFollows = new Set([..._post.userReactions].filter(userID => _isFollowing.has(userID))).size
            }
            readerID: string
            isFollowingAuthor: boolean
            numberOfTimesReaderHasReactedTo: number
            numberOfTimesReaderHasCommentedOn: number
            numberOfTimesReaderHasViewed: number
            hasViewedPost: boolean
            numberOfCommentsFromPeopleTheReaderFollows: number
            numberOfReactionsFromPeopleTheReaderFollows: number
        }
        const path = require('path')
        const os = require('os')
        const mkdirp = require('mkdirp')
        const fs = require('fs')
        const filePath: string = `channels/${channelSnap.id}/code`
        const tempLocalFile = path.join(os.tmpdir(), filePath)
        const tempLocalDir = path.dirname(tempLocalFile)
        const bucket = admin.storage().bucket()
        await mkdirp(tempLocalDir)
        await bucket.file(filePath).download({ destination: tempLocalFile })
        const authorID: string = snapshot.get('authorUID')
        const authorIsFollowingReader: boolean = snapshot.get('authorIsFollowingReader')
        const readerID: string = context.params.user
        const readerIsFollowingAuthor: boolean = snapshot.get('readerIsFollowingAuthor')
        const numberOfTimesReaderHasReactedTo: number = snapshot.get('numberOfTimesReaderHasReactedTo')
        const numberOfTimesReaderHasCommentedOn: number = snapshot.get('numberOfTimesReaderHasCommentedOn')
        const numberOfTimesReaderHasViewed: number = snapshot.get('numberOfTimesReaderHasViewed')
        const hasViewedPost: boolean = snapshot.get('seen')
        const postID: string = snapshot.id
        const caption: string = snapshot.get('caption')
        const commentsQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('posts').doc(postID).collection('comments').get().catch((error) => console.log(error))
        const reactionQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('posts').doc(postID).collection('reactions').get().catch((error) => console.log(error))
        const numberOfIthReactions = snapshot.get('numberOfIthReactions')
        const numberOfViews: number = numberOfIthReactions['6']
        const whenWasThisCreated: number = snapshot.get('bookmark')

        const authorIsFollowing: Set<string> = new Set<string>()
        if (authorIsFollowingReader) {
            authorIsFollowing.add(readerID)
        }

        const readerIsFollowing: Set<string> = new Set<string>()

        const followingQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(readerID).collection('following').get().catch((error) => console.log(error))

        if (readerIsFollowingAuthor) {
            readerIsFollowing.add(authorID)
        }

        if (followingQuery !== undefined) {
            for (const userID of followingQuery.docs) {
                readerIsFollowing.add(userID.id)
            }
        }

        const myReactions: Map<string, Map<string, Map<string, Set<string>>>> = new Map<string, Map<string, Map<string, Set<string>>>>()

        const rSet: Set<string> = new Set<string>()

        for (let i = 0; i < numberOfTimesReaderHasReactedTo; i++) {
            rSet.add('hellodarknessmyoldfriend' + i.toString())
        }

        const rMap0: Map<string, Set<string>> = new Map<string, Set<string>>()
        rMap0.set(authorID, rSet)
        const rMap1: Map<string, Map<string, Set<string>>> = new Map<string, Map<string, Set<string>>>()
        rMap1.set('madeBy', rMap0)
        myReactions.set('posts', rMap1)

        const myComments: Map<string, Map<string, Map<string, Set<string>>>> = new Map<string, Map<string, Map<string, Set<string>>>>()

        const cSet: Set<string> = new Set<string>()

        for (let i = 0; i < numberOfTimesReaderHasCommentedOn; i++) {
            cSet.add('hellodarknessmyoldfriend' + i.toString())
        }

        const cMap0: Map<string, Set<string>> = new Map<string, Set<string>>()
        cMap0.set(authorID, cSet)
        const cMap1: Map<string, Map<string, Set<string>>> = new Map<string, Map<string, Set<string>>>()
        cMap1.set('madeBy', cMap0)
        myComments.set('posts', cMap1)

        const myViews: Map<string, Map<string, Map<string, Set<string>>>> = new Map<string, Map<string, Map<string, Set<string>>>>()

        const vSet: Set<string> = new Set<string>()

        if (numberOfTimesReaderHasViewed !== 0) {
            for (let i = 0; i < numberOfTimesReaderHasViewed - 1; i++) {
                vSet.add('hellodarknessmyoldfriend' + i.toString())
            }
            if (hasViewedPost) {
                vSet.add(postID)
            }
            else {
                vSet.add('hellodarknessmyoldfriend' + (numberOfTimesReaderHasViewed - 1).toString())
            }
        }

        const vMap0: Map<string, Set<string>> = new Map<string, Set<string>>()
        vMap0.set(authorID, vSet)
        const vMap1: Map<string, Map<string, Set<string>>> = new Map<string, Map<string, Set<string>>>()
        vMap1.set('madeBy', vMap0)
        myViews.set('posts', vMap1)

        const userComments: Set<string> = new Set()

        if (commentsQuery !== undefined) {
            for (const commentSnap of commentsQuery.docs) {
                userComments.add(commentSnap.get('authorUID'))
            }
        }

        const userReactions: Set<string> = new Set()

        if (reactionQuery !== undefined) {
            for (const reactionSnap of reactionQuery.docs) {
                userReactions.add(reactionSnap.id)
            }
        }

        const numberOfPeopleThisHasMade: Map<string, number> = new Map<string, number>()

        const feelings: string[] = ['happy', 'sad', 'angry']

        for (let i = 0; i < feelings.length; i++) {
            numberOfPeopleThisHasMade.set(feelings[i], numberOfIthReactions[i.toString()])
        }


        const author: Author = new Author(authorID, authorIsFollowing, readerID)
        const post: Post = new Post(postID, caption, numberOfViews, userComments, userReactions, numberOfPeopleThisHasMade, whenWasThisCreated)
        const reader: Reader = new Reader(readerID, readerIsFollowing, myReactions, myComments, myViews, authorID, post)
        try {
            const algorithm = require(tempLocalFile)
            const { NodeVM } = require('vm2');
            const vm = new NodeVM({});
            const untrustedCode = 'module.exports = {computeRanking:' + algorithm.computeRanking.toString() + '};'
            const untrustedFunction = vm.run(
                untrustedCode
            );
            const ranking = untrustedFunction.computeRanking(author, post, reader)
            await fs.unlinkSync(tempLocalFile)
            await snapshot.ref.update({ ranking: ranking }).catch((error) => console.log(error))
        } catch (e) {
            console.log(e)
        }
    }
    return null
})

export const onDownloadPostChanged = functions.firestore.document(`channels/{channel}/downloadedBy/{user}/posts/{post}`).onUpdate(async (change, context: functions.EventContext) => {
    let numberOfIthReactionsHasChanged: boolean = false
    for (let i = 0; i < 7; i++) {
        if (change.before.get('numberOfIthReactions')[i.toString()] !== change.after.get('numberOfIthReactions')[i.toString()]) {
            numberOfIthReactionsHasChanged = true
        }
    }
    if (change.before.get('authorIsFollowingReader') !== change.after.get('authorIsFollowingReader')
        || change.before.get('numberOfComments') !== change.after.get('numberOfComments')
        || change.before.get('readerIsFollowingAuthor') !== change.after.get('readerIsFollowingAuthor')
        || change.before.get('numberOfTimesReaderHasReactedTo') !== change.after.get('numberOfTimesReaderHasReactedTo')
        || change.before.get('numberOfTimesReaderHasCommentedOn') !== change.after.get('numberOfTimesReaderHasCommentedOn')
        || change.before.get('numberOfTimesReaderHasViewed') !== change.after.get('numberOfTimesReaderHasViewed')
        || change.before.get('seen') !== change.after.get('seen')
        || numberOfIthReactionsHasChanged
    ) {
        const snapshot = change.after
        const channelSnap: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('channels').doc(context.params.channel).get().catch((error) => console.log(error))
        if (channelSnap !== undefined && channelSnap.exists) {
            class Author {
                constructor(_authorID: string, _isFollowing: Set<string>, _readerID: string) {
                    this.authorID = _authorID
                    this.isFollowingReader = _isFollowing.has(_readerID)
                }
                authorID: string
                isFollowingReader: boolean
            }
            class Post {
                constructor(_postID: string, _caption: string, _numberOfViews: number, _userComments: Set<string>, _userReactions: Set<string>, _numberOfPeopleThisHasMade: Map<string, number>, _whenWasThisCreated: number) {
                    this.postID = _postID
                    this.caption = _caption
                    this.numberOfViews = _numberOfViews
                    this.userComments = _userComments
                    this.userReactions = _userReactions
                    this.numberOfPeopleThisHasMade = _numberOfPeopleThisHasMade
                    this.whenWasThisCreated = _whenWasThisCreated
                }
                postID: string
                caption: string
                numberOfViews: number
                userComments: Set<string>
                userReactions: Set<string>
                numberOfPeopleThisHasMade: Map<string, number>
                whenWasThisCreated: number
            }
            class Reader {
                constructor(_readerID: string, _isFollowing: Set<string>, _myReactions: Map<string, Map<string, Map<string, Set<string>>>>, _myComments: Map<string, Map<string, Map<string, Set<string>>>>, _myViews: Map<string, Map<string, Map<string, Set<string>>>>, _authorID: string, _post: Post) {
                    this.readerID = _readerID
                    this.isFollowingAuthor = _isFollowing.has(_authorID)
                    this.numberOfTimesReaderHasReactedTo = _myReactions.get('posts')!.get('madeBy')!.get(_authorID)!.size
                    this.numberOfTimesReaderHasCommentedOn = _myComments.get('posts')!.get('madeBy')!.get(_authorID)!.size
                    this.numberOfTimesReaderHasViewed = _myViews.get('posts')!.get('madeBy')!.get(_authorID)!.size
                    this.hasViewedPost = _myViews.get('posts')!.get('madeBy')!.get(_authorID)!.has(_post.postID)
                    this.numberOfCommentsFromPeopleTheReaderFollows = new Set([..._post.userComments].filter(userID => _isFollowing.has(userID))).size
                    this.numberOfReactionsFromPeopleTheReaderFollows = new Set([..._post.userReactions].filter(userID => _isFollowing.has(userID))).size
                }
                readerID: string
                isFollowingAuthor: boolean
                numberOfTimesReaderHasReactedTo: number
                numberOfTimesReaderHasCommentedOn: number
                numberOfTimesReaderHasViewed: number
                hasViewedPost: boolean
                numberOfCommentsFromPeopleTheReaderFollows: number
                numberOfReactionsFromPeopleTheReaderFollows: number
            }
            const path = require('path')
            const os = require('os')
            const mkdirp = require('mkdirp')
            const fs = require('fs')
            const filePath: string = `channels/${channelSnap.id}/code`
            const tempLocalFile = path.join(os.tmpdir(), filePath)
            const tempLocalDir = path.dirname(tempLocalFile)
            const bucket = admin.storage().bucket()
            await mkdirp(tempLocalDir)
            await bucket.file(filePath).download({ destination: tempLocalFile })
            const authorID: string = snapshot.get('authorUID')
            const authorIsFollowingReader: boolean = snapshot.get('authorIsFollowingReader')
            const readerID: string = context.params.user
            const readerIsFollowingAuthor: boolean = snapshot.get('readerIsFollowingAuthor')
            const numberOfTimesReaderHasReactedTo: number = snapshot.get('numberOfTimesReaderHasReactedTo')
            const numberOfTimesReaderHasCommentedOn: number = snapshot.get('numberOfTimesReaderHasCommentedOn')
            const numberOfTimesReaderHasViewed: number = snapshot.get('numberOfTimesReaderHasViewed')
            const hasViewedPost: boolean = snapshot.get('seen')
            const postID: string = snapshot.id
            const caption: string = snapshot.get('caption')
            const commentsQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('posts').doc(postID).collection('comments').get().catch((error) => console.log(error))
            const reactionQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('posts').doc(postID).collection('reactions').get().catch((error) => console.log(error))
            const numberOfIthReactions = snapshot.get('numberOfIthReactions')
            const numberOfViews: number = numberOfIthReactions['6']
            const whenWasThisCreated: number = snapshot.get('bookmark')

            const authorIsFollowing: Set<string> = new Set<string>()
            if (authorIsFollowingReader) {
                authorIsFollowing.add(readerID)
            }

            const readerIsFollowing: Set<string> = new Set<string>()

            const followingQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(readerID).collection('following').get().catch((error) => console.log(error))

            if (readerIsFollowingAuthor) {
                readerIsFollowing.add(authorID)
            }

            if (followingQuery !== undefined) {
                for (const userID of followingQuery.docs) {
                    readerIsFollowing.add(userID.id)
                }
            }

            const myReactions: Map<string, Map<string, Map<string, Set<string>>>> = new Map<string, Map<string, Map<string, Set<string>>>>()

            const rSet: Set<string> = new Set<string>()

            for (let i = 0; i < numberOfTimesReaderHasReactedTo; i++) {
                rSet.add('hellodarknessmyoldfriend' + i.toString())
            }

            const rMap0: Map<string, Set<string>> = new Map<string, Set<string>>()
            rMap0.set(authorID, rSet)
            const rMap1: Map<string, Map<string, Set<string>>> = new Map<string, Map<string, Set<string>>>()
            rMap1.set('madeBy', rMap0)
            myReactions.set('posts', rMap1)

            const myComments: Map<string, Map<string, Map<string, Set<string>>>> = new Map<string, Map<string, Map<string, Set<string>>>>()

            const cSet: Set<string> = new Set<string>()

            for (let i = 0; i < numberOfTimesReaderHasCommentedOn; i++) {
                cSet.add('hellodarknessmyoldfriend' + i.toString())
            }

            const cMap0: Map<string, Set<string>> = new Map<string, Set<string>>()
            cMap0.set(authorID, cSet)
            const cMap1: Map<string, Map<string, Set<string>>> = new Map<string, Map<string, Set<string>>>()
            cMap1.set('madeBy', cMap0)
            myComments.set('posts', cMap1)

            const myViews: Map<string, Map<string, Map<string, Set<string>>>> = new Map<string, Map<string, Map<string, Set<string>>>>()

            const vSet: Set<string> = new Set<string>()

            if (numberOfTimesReaderHasViewed !== 0) {
                for (let i = 0; i < numberOfTimesReaderHasViewed - 1; i++) {
                    vSet.add('hellodarknessmyoldfriend' + i.toString())
                }
                if (hasViewedPost) {
                    vSet.add(postID)
                }
                else {
                    vSet.add('hellodarknessmyoldfriend' + (numberOfTimesReaderHasViewed - 1).toString())
                }
            }

            const vMap0: Map<string, Set<string>> = new Map<string, Set<string>>()
            vMap0.set(authorID, vSet)
            const vMap1: Map<string, Map<string, Set<string>>> = new Map<string, Map<string, Set<string>>>()
            vMap1.set('madeBy', vMap0)
            myViews.set('posts', vMap1)


            const userComments: Set<string> = new Set()

            if (commentsQuery !== undefined) {
                for (const commentSnap of commentsQuery.docs) {
                    userComments.add(commentSnap.get('authorUID'))
                }
            }

            const userReactions: Set<string> = new Set()

            if (reactionQuery !== undefined) {
                for (const reactionSnap of reactionQuery.docs) {
                    userReactions.add(reactionSnap.id)
                }
            }

            const numberOfPeopleThisHasMade: Map<string, number> = new Map<string, number>()

            const feelings: string[] = ['happy', 'sad', 'angry']

            for (let i = 0; i < feelings.length; i++) {
                numberOfPeopleThisHasMade.set(feelings[i], numberOfIthReactions[i.toString()])
            }



            const author: Author = new Author(authorID, authorIsFollowing, readerID)
            const post: Post = new Post(postID, caption, numberOfViews, userComments, userReactions, numberOfPeopleThisHasMade, whenWasThisCreated)
            const reader: Reader = new Reader(readerID, readerIsFollowing, myReactions, myComments, myViews, authorID, post)
            try {
                const algorithm = require(tempLocalFile)
                const { NodeVM } = require('vm2');
                const vm = new NodeVM({});
                const untrustedCode = 'module.exports = {computeRanking:' + algorithm.computeRanking.toString() + '};'
                const untrustedFunction = vm.run(
                    untrustedCode
                );
                const ranking = untrustedFunction.computeRanking(author, post, reader)
                await fs.unlinkSync(tempLocalFile)
                await snapshot.ref.update({ ranking: ranking }).catch((error) => console.log(error))
            } catch (e) {
                console.log(e)
            }
        }

    }
    return null
})

export const plusFollowing = functions.firestore.document(`users/{user}/following/{profile}`).onCreate(async (profileSnap: admin.firestore.DocumentSnapshot, context) => {
    const theReactionQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.profile).collection('reactions').get().catch((error) => console.log(error))
    const commentQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.profile).collection('comments').get().catch((error) => console.log(error))
    const channelQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('downloads').get().catch((error) => console.log(error))
    const thePostIDs: Set<string> = new Set<string>()
    if (theReactionQuery !== undefined) {
        for (const reactionSnap of theReactionQuery.docs) {
            const postID: string = reactionSnap.id
            thePostIDs.add(postID)
        }
    }
    if (commentQuery !== undefined) {
        for (const commentSnap of commentQuery.docs) {
            const postID: string = commentSnap.get('postID')
            thePostIDs.add(postID)
        }
    }
    const promises: any = []
    const thePostIDsList = Array.from(thePostIDs.values())
    if (channelQuery !== undefined && thePostIDsList.length !== 0) {
        for (const channelSnap of channelQuery.docs) {
            if (channelSnap.id === 'Home' || channelSnap.id === 'Most liked') {
                continue
            }
            const path = require('path')
            const os = require('os')
            const mkdirp = require('mkdirp')
            const fs = require('fs')
            const filePath: string = `channels/${channelSnap.id}/code`
            const tempLocalFile = path.join(os.tmpdir(), filePath)
            const tempLocalDir = path.dirname(tempLocalFile)
            const bucket = admin.storage().bucket()
            await mkdirp(tempLocalDir)
            await bucket.file(filePath).download({ destination: tempLocalFile })
            for (const postID of thePostIDsList) {
                const snapshot: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('channels').doc(channelSnap.id).collection('downloadedBy').doc(context.params.user).collection('posts').doc(postID).get().catch((error) => console.log(error))
                if (snapshot !== undefined && snapshot.exists) {
                    class Author {
                        constructor(_authorID: string, _isFollowing: Set<string>, _readerID: string) {
                            this.authorID = _authorID
                            this.isFollowingReader = _isFollowing.has(_readerID)
                        }
                        authorID: string
                        isFollowingReader: boolean
                    }
                    class Post {
                        constructor(_postID: string, _caption: string, _numberOfViews: number, _userComments: Set<string>, _userReactions: Set<string>, _numberOfPeopleThisHasMade: Map<string, number>, _whenWasThisCreated: number) {
                            this.postID = _postID
                            this.caption = _caption
                            this.numberOfViews = _numberOfViews
                            this.userComments = _userComments
                            this.userReactions = _userReactions
                            this.numberOfPeopleThisHasMade = _numberOfPeopleThisHasMade
                            this.whenWasThisCreated = _whenWasThisCreated
                        }
                        postID: string
                        caption: string
                        numberOfViews: number
                        userComments: Set<string>
                        userReactions: Set<string>
                        numberOfPeopleThisHasMade: Map<string, number>
                        whenWasThisCreated: number
                    }
                    class Reader {
                        constructor(_readerID: string, _isFollowing: Set<string>, _myReactions: Map<string, Map<string, Map<string, Set<string>>>>, _myComments: Map<string, Map<string, Map<string, Set<string>>>>, _myViews: Map<string, Map<string, Map<string, Set<string>>>>, _authorID: string, _post: Post) {
                            this.readerID = _readerID
                            this.isFollowingAuthor = _isFollowing.has(_authorID)
                            this.numberOfTimesReaderHasReactedTo = _myReactions.get('posts')!.get('madeBy')!.get(_authorID)!.size
                            this.numberOfTimesReaderHasCommentedOn = _myComments.get('posts')!.get('madeBy')!.get(_authorID)!.size
                            this.numberOfTimesReaderHasViewed = _myViews.get('posts')!.get('madeBy')!.get(_authorID)!.size
                            this.hasViewedPost = _myViews.get('posts')!.get('madeBy')!.get(_authorID)!.has(_post.postID)
                            this.numberOfCommentsFromPeopleTheReaderFollows = new Set([..._post.userComments].filter(userID => _isFollowing.has(userID))).size
                            this.numberOfReactionsFromPeopleTheReaderFollows = new Set([..._post.userReactions].filter(userID => _isFollowing.has(userID))).size
                        }
                        readerID: string
                        isFollowingAuthor: boolean
                        numberOfTimesReaderHasReactedTo: number
                        numberOfTimesReaderHasCommentedOn: number
                        numberOfTimesReaderHasViewed: number
                        hasViewedPost: boolean
                        numberOfCommentsFromPeopleTheReaderFollows: number
                        numberOfReactionsFromPeopleTheReaderFollows: number
                    }

                    const authorID: string = snapshot.get('authorUID')
                    const authorIsFollowingReader: boolean = snapshot.get('authorIsFollowingReader')
                    const readerID: string = context.params.user
                    const readerIsFollowingAuthor: boolean = snapshot.get('readerIsFollowingAuthor')
                    const numberOfTimesReaderHasReactedTo: number = snapshot.get('numberOfTimesReaderHasReactedTo')
                    const numberOfTimesReaderHasCommentedOn: number = snapshot.get('numberOfTimesReaderHasCommentedOn')
                    const numberOfTimesReaderHasViewed: number = snapshot.get('numberOfTimesReaderHasViewed')
                    const hasViewedPost: boolean = snapshot.get('seen')
                    const commentsQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('posts').doc(postID).collection('comments').get().catch((error) => console.log(error))
                    const reactionQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('posts').doc(postID).collection('reactions').get().catch((error) => console.log(error))
                    const numberOfIthReactions = snapshot.get('numberOfIthReactions')
                    const numberOfViews: number = numberOfIthReactions['6']
                    const whenWasThisCreated: number = snapshot.get('bookmark')
                    const caption: string = snapshot.get('caption')

                    const authorIsFollowing: Set<string> = new Set<string>()
                    if (authorIsFollowingReader) {
                        authorIsFollowing.add(readerID)
                    }

                    const readerIsFollowing: Set<string> = new Set<string>()

                    const followingQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(readerID).collection('following').get().catch((error) => console.log(error))

                    if (readerIsFollowingAuthor) {
                        readerIsFollowing.add(authorID)
                    }

                    if (followingQuery !== undefined) {
                        for (const userID of followingQuery.docs) {
                            readerIsFollowing.add(userID.id)
                        }
                    }

                    const myReactions: Map<string, Map<string, Map<string, Set<string>>>> = new Map<string, Map<string, Map<string, Set<string>>>>()

                    const rSet: Set<string> = new Set<string>()

                    for (let i = 0; i < numberOfTimesReaderHasReactedTo; i++) {
                        rSet.add('hellodarknessmyoldfriend' + i.toString())
                    }

                    const rMap0: Map<string, Set<string>> = new Map<string, Set<string>>()
                    rMap0.set(authorID, rSet)
                    const rMap1: Map<string, Map<string, Set<string>>> = new Map<string, Map<string, Set<string>>>()
                    rMap1.set('madeBy', rMap0)
                    myReactions.set('posts', rMap1)

                    const myComments: Map<string, Map<string, Map<string, Set<string>>>> = new Map<string, Map<string, Map<string, Set<string>>>>()

                    const cSet: Set<string> = new Set<string>()

                    for (let i = 0; i < numberOfTimesReaderHasCommentedOn; i++) {
                        cSet.add('hellodarknessmyoldfriend' + i.toString())
                    }

                    const cMap0: Map<string, Set<string>> = new Map<string, Set<string>>()
                    cMap0.set(authorID, cSet)
                    const cMap1: Map<string, Map<string, Set<string>>> = new Map<string, Map<string, Set<string>>>()
                    cMap1.set('madeBy', cMap0)
                    myComments.set('posts', cMap1)

                    const myViews: Map<string, Map<string, Map<string, Set<string>>>> = new Map<string, Map<string, Map<string, Set<string>>>>()

                    const vSet: Set<string> = new Set<string>()

                    if (numberOfTimesReaderHasViewed !== 0) {
                        for (let i = 0; i < numberOfTimesReaderHasViewed - 1; i++) {
                            vSet.add('hellodarknessmyoldfriend' + i.toString())
                        }
                        if (hasViewedPost) {
                            vSet.add(postID)
                        }
                        else {
                            vSet.add('hellodarknessmyoldfriend' + (numberOfTimesReaderHasViewed - 1).toString())
                        }
                    }

                    const vMap0: Map<string, Set<string>> = new Map<string, Set<string>>()
                    vMap0.set(authorID, vSet)
                    const vMap1: Map<string, Map<string, Set<string>>> = new Map<string, Map<string, Set<string>>>()
                    vMap1.set('madeBy', vMap0)
                    myViews.set('posts', vMap1)

                    const userComments: Set<string> = new Set()
                    if (commentsQuery !== undefined) {
                        for (const commentSnap of commentsQuery.docs) {
                            userComments.add(commentSnap.get('authorUID'))
                        }
                    }
                    const userReactions: Set<string> = new Set()
                    if (reactionQuery !== undefined) {
                        for (const reactionSnap of reactionQuery.docs) {
                            userReactions.add(reactionSnap.id)
                        }
                    }
                    const numberOfPeopleThisHasMade: Map<string, number> = new Map<string, number>()
                    const feelings: string[] = ['happy', 'sad', 'angry']

                    for (let i = 0; i < feelings.length; i++) {
                        numberOfPeopleThisHasMade.set(feelings[i], numberOfIthReactions[i.toString()])
                    }
                    const author: Author = new Author(authorID, authorIsFollowing, readerID)
                    const post: Post = new Post(postID, caption, numberOfViews, userComments, userReactions, numberOfPeopleThisHasMade, whenWasThisCreated)
                    const reader: Reader = new Reader(readerID, readerIsFollowing, myReactions, myComments, myViews, authorID, post)
                    try {
                        const algorithm = require(tempLocalFile)
                        const { NodeVM } = require('vm2');
                        const vm = new NodeVM({});
                        const untrustedCode = 'module.exports = {computeRanking:' + algorithm.computeRanking.toString() + '};'
                        const untrustedFunction = vm.run(
                            untrustedCode
                        );
                        const ranking = untrustedFunction.computeRanking(author, post, reader)
                        promises.push(snapshot.ref.update({ ranking: ranking }).catch((error) => console.log(error)))
                    } catch (e) {
                        console.log(e)
                    }
                }
            }
            await fs.unlinkSync(tempLocalFile)
        }
    }
    return Promise.all(promises)
})

export const minusFollowing = functions.firestore.document(`users/{user}/following/{profile}`).onDelete(async (profileSnap: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const theReactionQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.profile).collection('reactions').get().catch((error) => console.log(error))
    const commentQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.profile).collection('comments').get().catch((error) => console.log(error))
    const channelQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(context.params.user).collection('downloads').get().catch((error) => console.log(error))
    const thePostIDs: Set<string> = new Set<string>()
    if (theReactionQuery !== undefined) {
        for (const reactionSnap of theReactionQuery.docs) {
            const postID: string = reactionSnap.id
            thePostIDs.add(postID)
        }
    }
    if (commentQuery !== undefined) {
        for (const commentSnap of commentQuery.docs) {
            const postID: string = commentSnap.get('postID')
            thePostIDs.add(postID)
        }
    }
    const promises: any = []
    const thePostIDsList = Array.from(thePostIDs.values())
    if (channelQuery !== undefined && thePostIDsList.length !== 0) {
        for (const channelSnap of channelQuery.docs) {
            if (channelSnap.id === 'Home' || channelSnap.id === 'Most liked') {
                continue
            }
            const path = require('path')
            const os = require('os')
            const mkdirp = require('mkdirp')
            const fs = require('fs')
            const filePath: string = `channels/${channelSnap.id}/code`
            const tempLocalFile = path.join(os.tmpdir(), filePath)
            const tempLocalDir = path.dirname(tempLocalFile)
            const bucket = admin.storage().bucket()
            await mkdirp(tempLocalDir)
            await bucket.file(filePath).download({ destination: tempLocalFile })
            for (const postID of thePostIDsList) {
                const snapshot: admin.firestore.DocumentSnapshot | void = await admin.firestore().collection('channels').doc(channelSnap.id).collection('downloadedBy').doc(context.params.user).collection('posts').doc(postID).get().catch((error) => console.log(error))
                if (snapshot !== undefined && snapshot.exists) {
                    class Author {
                        constructor(_authorID: string, _isFollowing: Set<string>, _readerID: string) {
                            this.authorID = _authorID
                            this.isFollowingReader = _isFollowing.has(_readerID)
                        }
                        authorID: string
                        isFollowingReader: boolean
                    }
                    class Post {
                        constructor(_postID: string, _caption: string, _numberOfViews: number, _userComments: Set<string>, _userReactions: Set<string>, _numberOfPeopleThisHasMade: Map<string, number>, _whenWasThisCreated: number) {
                            this.postID = _postID
                            this.caption = _caption
                            this.numberOfViews = _numberOfViews
                            this.userComments = _userComments
                            this.userReactions = _userReactions
                            this.numberOfPeopleThisHasMade = _numberOfPeopleThisHasMade
                            this.whenWasThisCreated = _whenWasThisCreated
                        }
                        postID: string
                        caption: string
                        numberOfViews: number
                        userComments: Set<string>
                        userReactions: Set<string>
                        numberOfPeopleThisHasMade: Map<string, number>
                        whenWasThisCreated: number
                    }
                    class Reader {
                        constructor(_readerID: string, _isFollowing: Set<string>, _myReactions: Map<string, Map<string, Map<string, Set<string>>>>, _myComments: Map<string, Map<string, Map<string, Set<string>>>>, _myViews: Map<string, Map<string, Map<string, Set<string>>>>, _authorID: string, _post: Post) {
                            this.readerID = _readerID
                            this.isFollowingAuthor = _isFollowing.has(_authorID)
                            this.numberOfTimesReaderHasReactedTo = _myReactions.get('posts')!.get('madeBy')!.get(_authorID)!.size
                            this.numberOfTimesReaderHasCommentedOn = _myComments.get('posts')!.get('madeBy')!.get(_authorID)!.size
                            this.numberOfTimesReaderHasViewed = _myViews.get('posts')!.get('madeBy')!.get(_authorID)!.size
                            this.hasViewedPost = _myViews.get('posts')!.get('madeBy')!.get(_authorID)!.has(_post.postID)
                            this.numberOfCommentsFromPeopleTheReaderFollows = new Set([..._post.userComments].filter(userID => _isFollowing.has(userID))).size
                            this.numberOfReactionsFromPeopleTheReaderFollows = new Set([..._post.userReactions].filter(userID => _isFollowing.has(userID))).size
                        }
                        readerID: string
                        isFollowingAuthor: boolean
                        numberOfTimesReaderHasReactedTo: number
                        numberOfTimesReaderHasCommentedOn: number
                        numberOfTimesReaderHasViewed: number
                        hasViewedPost: boolean
                        numberOfCommentsFromPeopleTheReaderFollows: number
                        numberOfReactionsFromPeopleTheReaderFollows: number
                    }

                    const authorID: string = snapshot.get('authorUID')
                    const authorIsFollowingReader: boolean = snapshot.get('authorIsFollowingReader')
                    const readerID: string = context.params.user
                    const readerIsFollowingAuthor: boolean = snapshot.get('readerIsFollowingAuthor')
                    const numberOfTimesReaderHasReactedTo: number = snapshot.get('numberOfTimesReaderHasReactedTo')
                    const numberOfTimesReaderHasCommentedOn: number = snapshot.get('numberOfTimesReaderHasCommentedOn')
                    const numberOfTimesReaderHasViewed: number = snapshot.get('numberOfTimesReaderHasViewed')
                    const hasViewedPost: boolean = snapshot.get('seen')
                    const commentsQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('posts').doc(postID).collection('comments').get().catch((error) => console.log(error))
                    const reactionQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('posts').doc(postID).collection('reactions').get().catch((error) => console.log(error))
                    const numberOfIthReactions = snapshot.get('numberOfIthReactions')
                    const numberOfViews: number = numberOfIthReactions['6']
                    const whenWasThisCreated: number = snapshot.get('bookmark')
                    const caption: string = snapshot.get('caption')

                    const authorIsFollowing: Set<string> = new Set<string>()
                    if (authorIsFollowingReader) {
                        authorIsFollowing.add(readerID)
                    }

                    const readerIsFollowing: Set<string> = new Set<string>()

                    const followingQuery: admin.firestore.QuerySnapshot | void = await admin.firestore().collection('users').doc(readerID).collection('following').get().catch((error) => console.log(error))

                    if (readerIsFollowingAuthor) {
                        readerIsFollowing.add(authorID)
                    }

                    if (followingQuery !== undefined) {
                        for (const userID of followingQuery.docs) {
                            readerIsFollowing.add(userID.id)
                        }
                    }

                    const myReactions: Map<string, Map<string, Map<string, Set<string>>>> = new Map<string, Map<string, Map<string, Set<string>>>>()

                    const rSet: Set<string> = new Set<string>()

                    for (let i = 0; i < numberOfTimesReaderHasReactedTo; i++) {
                        rSet.add('hellodarknessmyoldfriend' + i.toString())
                    }

                    const rMap0: Map<string, Set<string>> = new Map<string, Set<string>>()
                    rMap0.set(authorID, rSet)
                    const rMap1: Map<string, Map<string, Set<string>>> = new Map<string, Map<string, Set<string>>>()
                    rMap1.set('madeBy', rMap0)
                    myReactions.set('posts', rMap1)

                    const myComments: Map<string, Map<string, Map<string, Set<string>>>> = new Map<string, Map<string, Map<string, Set<string>>>>()

                    const cSet: Set<string> = new Set<string>()

                    for (let i = 0; i < numberOfTimesReaderHasCommentedOn; i++) {
                        cSet.add('hellodarknessmyoldfriend' + i.toString())
                    }

                    const cMap0: Map<string, Set<string>> = new Map<string, Set<string>>()
                    cMap0.set(authorID, cSet)
                    const cMap1: Map<string, Map<string, Set<string>>> = new Map<string, Map<string, Set<string>>>()
                    cMap1.set('madeBy', cMap0)
                    myComments.set('posts', cMap1)

                    const myViews: Map<string, Map<string, Map<string, Set<string>>>> = new Map<string, Map<string, Map<string, Set<string>>>>()

                    const vSet: Set<string> = new Set<string>()

                    if (numberOfTimesReaderHasViewed !== 0) {
                        for (let i = 0; i < numberOfTimesReaderHasViewed - 1; i++) {
                            vSet.add('hellodarknessmyoldfriend' + i.toString())
                        }
                        if (hasViewedPost) {
                            vSet.add(postID)
                        }
                        else {
                            vSet.add('hellodarknessmyoldfriend' + (numberOfTimesReaderHasViewed - 1).toString())
                        }
                    }

                    const vMap0: Map<string, Set<string>> = new Map<string, Set<string>>()
                    vMap0.set(authorID, vSet)
                    const vMap1: Map<string, Map<string, Set<string>>> = new Map<string, Map<string, Set<string>>>()
                    vMap1.set('madeBy', vMap0)
                    myViews.set('posts', vMap1)

                    const userComments: Set<string> = new Set()
                    if (commentsQuery !== undefined) {
                        for (const commentSnap of commentsQuery.docs) {
                            userComments.add(commentSnap.get('authorUID'))
                        }
                    }
                    const userReactions: Set<string> = new Set()
                    if (reactionQuery !== undefined) {
                        for (const reactionSnap of reactionQuery.docs) {
                            userReactions.add(reactionSnap.id)
                        }
                    }
                    const numberOfPeopleThisHasMade: Map<string, number> = new Map<string, number>()
                    const feelings: string[] = ['happy', 'sad', 'angry']

                    for (let i = 0; i < feelings.length; i++) {
                        numberOfPeopleThisHasMade.set(feelings[i], numberOfIthReactions[i.toString()])
                    }
                    const author: Author = new Author(authorID, authorIsFollowing, readerID)
                    const post: Post = new Post(postID, caption, numberOfViews, userComments, userReactions, numberOfPeopleThisHasMade, whenWasThisCreated)
                    const reader: Reader = new Reader(readerID, readerIsFollowing, myReactions, myComments, myViews, authorID, post)
                    try {
                        const algorithm = require(tempLocalFile)
                        const { NodeVM } = require('vm2');
                        const vm = new NodeVM({});
                        const untrustedCode = 'module.exports = {computeRanking:' + algorithm.computeRanking.toString() + '};'
                        const untrustedFunction = vm.run(
                            untrustedCode
                        );
                        const ranking = untrustedFunction.computeRanking(author, post, reader)
                        promises.push(snapshot.ref.update({ ranking: ranking }).catch((error) => console.log(error)))
                    } catch (e) {
                        console.log(e)
                    }
                }
            }
            await fs.unlinkSync(tempLocalFile)
        }
    }
    return Promise.all(promises)
})
