import "./main.css";
import * as firebase from "firebase/app";
import "firebase/auth";

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

let counter = 1;

const app = Elm.Main.init({
  node: document.getElementById("root")
});

app.ports.sendStuff.subscribe(data => {
  console.log(JSON.stringify(data));
});

setInterval(() => {
  counter += 1;
  console.log(JSON.stringify(counter));
  app.ports.receiveStuff.send({ value: counter });
}, 1000);

app.ports.signIn.subscribe(() => {
  console.log("LogIn called");

  firebase
    .auth()
    .signInWithPopup(provider)
    .then(result => {
      app.ports.signInInfo.send({
        token: result.credential.accessToken,
        email: result.user.email
      });
    })
    .catch(error => {
      //TODO: Handle errors
      // Handle Errors here.
      var errorCode = error.code;
      var errorMessage = error.message;
      // The email of the user's account used.
      var email = error.email;
      // The firebase.auth.AuthCredential type that was used.
      var credential = error.credential;
      // ...
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

registerServiceWorker();
