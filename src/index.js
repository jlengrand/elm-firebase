import "./main.css";
import * as firebase from "firebase/app";
import "firebase/auth";
import "firebase/firestore";

import { Elm } from "./Main.elm";
import registerServiceWorker from "./registerServiceWorker";

// Just checking envs are defined - Debug statement
console.log(process.env.ELM_APP_API_KEY !== undefined);

const firebaseConfig = {
  apiKey: process.env.ELM_APP_API_KEY,
  authDomain: process.env.ELM_APP_AUTH_DOMAIN,
  databaseURL: process.env.ELM_APP_DATABASE_URL,
  projectId: process.env.ELM_APP_PROJECT_ID,
  storageBucket: process.env.ELM_APP_STORAGE_BUCKET,
  messagingSenderId: process.env.ELM_APP_MESSAGING_SENDER_ID,
  appId: process.env.ELM_APP_APP_ID
};

firebase.initializeApp(firebaseConfig);

const provider = new firebase.auth.GoogleAuthProvider();
const db = firebase.firestore();
let currentUser;

const app = Elm.Main.init({
  node: document.getElementById("root")
});

app.ports.saveMessage.subscribe(() => {
  console.log("saveMessage called");
  db.collection(`users/${currentUser.uid}/messages`)
    .add({
      data: "test"
    })
    .then(function(docRef) {
      console.log("Document written with ID: ", docRef.id);
    })
    .catch(function(error) {
      console.error("Error adding document: ", error);
    });
});

app.ports.signIn.subscribe(() => {
  console.log("LogIn called");
  firebase
    .auth()
    .signInWithPopup(provider)
    .then(result => {
      result.user
        .getIdToken()
        .then(idToken => {
          app.ports.signInInfo.send({
            token: idToken,
            email: result.user.email,
            uid: result.user.uid
          });
        })
        .catch(error => {
          console.log(error);
        });
    })
    .catch(error => {
      app.ports.signInError.send({
        code: error.code,
        message: error.message
      });
    });
});

app.ports.signOut.subscribe(() => {
  console.log("LogOut called");
  firebase
    .auth()
    .signOut()
    .then(() => {
      // Sign-out successful.
    })
    .catch(error => {
      // An error happened.
    });
});

//  Observer on user info
firebase.auth().onAuthStateChanged(user => {
  if (user) {
    currentUser = user;
    user
      .getIdToken()
      .then(idToken => {
        app.ports.signInInfo.send({
          token: idToken,
          email: user.email,
          uid: user.uid
        });
      })
      .catch(error => {
        console.log("Error when retrieving cached user");
        console.log(error);
      });
  }
});

registerServiceWorker();
