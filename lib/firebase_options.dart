// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyD1Cahy8-hRlmafbnFiodukEjwIgyOa7Gc",
  authDomain: "aa-stroypro-apk-v2-9b801.firebaseapp.com",
  databaseURL: "https://aa-stroypro-apk-v2-9b801-default-rtdb.firebaseio.com",
  projectId: "aa-stroypro-apk-v2-9b801",
  storageBucket: "aa-stroypro-apk-v2-9b801.firebasestorage.app",
  messagingSenderId: "255181738766",
  appId: "1:255181738766:web:f3e3cbe9ac4e82a84e3d5f",
  measurementId: "G-7261VMHYP2"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);
