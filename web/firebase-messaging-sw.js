importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js");

firebase.initializeApp({
    apiKey: "AIzaSyDirvLXRbT0xo5oSLPPeTTJ61UPOmeE2p8",
    authDomain: "mybio-neel19.firebaseapp.com",
    projectId: "mybio-neel19",
    storageBucket: "mybio-neel19.firebasestorage.app",
    messagingSenderId: "869441481795",
    appId: "1:869441481795:web:5756e4b11aef5e085bb8f6",
    measurementId: "G-HQDMKS848J"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: '/icons/Icon-192.png'
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
});
