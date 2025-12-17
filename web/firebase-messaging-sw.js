importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

firebase.initializeApp({
    apiKey: "AIzaSyAqQ5VG7oM9JEd617WWtnDatQ13iJz91Qw",
    authDomain: "p22rently.firebaseapp.com",
    projectId: "p22rently",
    storageBucket: "p22rently.appspot.com",
    messagingSenderId: "1030223891349",
    appId: "1:1030223891349:web:b1ab7594364646f239c49c",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function (payload) {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);

    const notificationTitle = payload.notification?.title || 'New Notification';
    const notificationOptions = {
        body: payload.notification?.body || '',
        icon: '/icons/Icon-192.png',
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
});
